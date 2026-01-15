// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lottie/lottie.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/view/page/chat_kit_message_detail_text_page.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../../helper/chat_message_helper.dart';

class ChatKitMessageTextItem extends StatefulWidget {
  final NIMMessage message;

  final ChatUIConfig? chatUIConfig;

  final bool needPadding;

  final int? maxLines;

  final String? keyword;

  final bool checkDetailEnable;

  const ChatKitMessageTextItem(
      {Key? key,
      required this.message,
      this.chatUIConfig,
      this.needPadding = true,
      this.checkDetailEnable = false,
      this.keyword,
      this.maxLines})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageTextState();
}

class ChatKitMessageTextState extends State<ChatKitMessageTextItem> {
  // 电话号码正则表达式
  static final RegExp _phoneRegex = RegExp(
    r'(?:(?:\+86)|(?:86))?\s*1[3-9]\d{9}|(?:0\d{2,3}[-\s]?)?\d{7,8}',
  );

  @override
  Widget build(BuildContext context) {
    //处理数字人返回的消息
    if (widget.maxLines == null &&
        ChatMessageHelper.isReceivedMessageFromAi(widget.message)) {
      //占位
      if (widget.message.aiConfig?.aiStreamStatus ==
          V2NIMMessageAIStreamStatus
              .V2NIM_MESSAGE_AI_STREAM_STATUS_PLACEHOLDER) {
        return Container(
            // lottie 动画占位
            padding: widget.needPadding
                ? const EdgeInsets.only(
                    left: 16, top: 12, right: 16, bottom: 12)
                : null,
            child: Lottie.asset('lottie/ani_ai_stream_holder.json',
                package: kPackage, width: 24, height: 24));
      } else {
        return Container(
            padding: widget.needPadding
                ? const EdgeInsets.only(
                    left: 16, top: 12, right: 16, bottom: 12)
                : null,
            child: Markdown(
              data: widget.message.text ?? '',
              shrinkWrap: true, // 关键：收缩内容高度// 最大行数控制// 溢出处理)),
              padding: EdgeInsets.all(0.0),
              physics: ClampingScrollPhysics(), //禁用内部的滚动
            ));
      }
    }
    final String text = widget.message.text ?? '';
    var matches = RegExp("\\[[^\\[]{1,10}\\]").allMatches(text);
    List<InlineSpan> spans = [];
    int preIndex = 0;
    var remoteExtension = null;
    if (widget.message.serverExtension?.isNotEmpty == true &&
        !ChatMessageHelper.isReceivedMessageFromAi(widget.message)) {
      remoteExtension = jsonDecode(widget.message.serverExtension!);
    }
    if (matches.isNotEmpty) {
      for (final match in matches) {
        if (match.start > preIndex) {
          spans.addAll(_buildTextSpans(
              context, text.substring(preIndex, match.start), preIndex,
              end: match.start,
              chatUIConfig: widget.chatUIConfig,
              remoteExtension: remoteExtension));
        }
        var span = ChatMessageHelper.imageSpan(match.group(0));
        if (span != null) {
          spans.add(span);
        } else if (match.group(0)?.isNotEmpty == true) {
          spans.addAll(_buildTextSpans(context, match.group(0)!, 0,
              chatUIConfig: widget.chatUIConfig,
              remoteExtension: remoteExtension));
        }
        preIndex = match.end;
      }
      if (preIndex < text.length) {
        spans.addAll(_buildTextSpans(
            context, text.substring(preIndex, text.length), preIndex,
            chatUIConfig: widget.chatUIConfig,
            remoteExtension: remoteExtension));
      }
    } else {
      spans.addAll(_buildTextSpans(context, text, 0,
          chatUIConfig: widget.chatUIConfig, remoteExtension: remoteExtension));
    }
    Widget content = Container(
      //放到里面
      padding: widget.needPadding
          ? const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 12)
          : null,
      child: widget.maxLines == null
          ? Text.rich(TextSpan(children: spans))
          : Text.rich(
              TextSpan(children: spans),
              maxLines: widget.maxLines,
              overflow: TextOverflow.ellipsis,
            ),
    );
    if (widget.checkDetailEnable) {
      return GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return ChatKitMessageDetailTextPage(
              content: widget.message.text ?? '',
              chatUIConfig: widget.chatUIConfig,
            );
          }));
        },
        child: content,
      );
    } else {
      return content;
    }
  }

  List<InlineSpan> _buildTextSpans(
    BuildContext context,
    String text,
    int startIndex, {
    int? end,
    ChatUIConfig? chatUIConfig,
    dynamic remoteExtension,
  }) {
    // 如果是数字人消息，使用原有逻辑
    if (ChatMessageHelper.isReceivedMessageFromAi(widget.message)) {
      return ChatMessageHelper.textSpan(
        context,
        false,
        text,
        startIndex,
        end: end,
        chatUIConfig: chatUIConfig,
        remoteExtension: remoteExtension,
      );
    }

    var spans = ChatMessageHelper.buildTextSpansWithPhoneAndUrlDetection(
      context,
      widget.message.isSelf ?? false,
      text,
      startIndex,
      end: end,
      chatUIConfig: chatUIConfig,
      remoteExtension: remoteExtension,
    );

    if (widget.keyword != null && widget.keyword!.isNotEmpty) {
      List<InlineSpan> newSpans = [];
      for (var span in spans) {
        if (span is TextSpan && span.text != null) {
          newSpans.addAll(_highlightSpan(span, widget.keyword!));
        } else {
          newSpans.add(span);
        }
      }
      return newSpans;
    }
    return spans;
  }

  List<InlineSpan> _highlightSpan(TextSpan span, String keyword) {
    String text = span.text!;
    List<InlineSpan> result = [];
    int currentStartIndex = 0;
    int matchIndex = text.indexOf(keyword);

    if (matchIndex == -1) {
      return [span];
    }

    while (matchIndex != -1) {
      if (matchIndex > currentStartIndex) {
        result.add(TextSpan(
          text: text.substring(currentStartIndex, matchIndex),
          style: span.style,
          recognizer: span.recognizer,
          mouseCursor: span.mouseCursor,
          onEnter: span.onEnter,
          onExit: span.onExit,
          semanticsLabel: span.semanticsLabel,
          locale: span.locale,
          spellOut: span.spellOut,
        ));
      }

      // Highlighted part
      TextStyle highlightStyle = (span.style ?? const TextStyle())
          .copyWith(color: CommonColors.color_007aff);

      result.add(TextSpan(
        text: keyword,
        style: highlightStyle,
        recognizer: span.recognizer,
        mouseCursor: span.mouseCursor,
        onEnter: span.onEnter,
        onExit: span.onExit,
        semanticsLabel: span.semanticsLabel,
        locale: span.locale,
        spellOut: span.spellOut,
      ));

      currentStartIndex = matchIndex + keyword.length;
      matchIndex = text.indexOf(keyword, currentStartIndex);
    }

    if (currentStartIndex < text.length) {
      result.add(TextSpan(
        text: text.substring(currentStartIndex),
        style: span.style,
        recognizer: span.recognizer,
        mouseCursor: span.mouseCursor,
        onEnter: span.onEnter,
        onExit: span.onExit,
        semanticsLabel: span.semanticsLabel,
        locale: span.locale,
        spellOut: span.spellOut,
      ));
    }

    return result;
  }
}
