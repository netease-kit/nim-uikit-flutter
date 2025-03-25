// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_corekit_im/model/ait/ait_msg.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/helper/chat_message_helper.dart';
import 'package:nim_core_v2/nim_core.dart';

class ChatKitMessageMultiLineItem extends StatefulWidget {
  final NIMMessage message;

  final ChatUIConfig? chatUIConfig;

  final bool needPadding;

  final String title;

  final String? body;

  final int? titleMaxLines;

  final int? bodyMaxLines;

  const ChatKitMessageMultiLineItem(
      {Key? key,
      required this.message,
      this.chatUIConfig,
      this.body,
      this.needPadding = true,
      this.titleMaxLines,
      this.bodyMaxLines,
      required this.title})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageMultiLineState();
}

class ChatKitMessageMultiLineState extends State<ChatKitMessageMultiLineItem> {
  @override
  Widget build(BuildContext context) {
    ///处理title
    final String title = widget.title;

    ///处理body
    final String text = widget.body ?? '';
    var matches = RegExp("\\[[^\\[]{1,10}\\]").allMatches(text);
    List<InlineSpan> spans = [];
    int preIndex = 0;
    var remoteExtension = null;
    if (widget.message.serverExtension?.isNotEmpty == true) {
      remoteExtension = jsonDecode(widget.message.serverExtension!);
    }
    if (matches.isNotEmpty) {
      for (final match in matches) {
        if (match.start > preIndex) {
          spans.addAll(ChatMessageHelper.textSpan(
              context, text.substring(preIndex, match.start), preIndex,
              end: match.start,
              chatUIConfig: widget.chatUIConfig,
              remoteExtension: remoteExtension));
        }
        var span = ChatMessageHelper.imageSpan(match.group(0));
        if (span != null) {
          spans.add(span);
        } else if (match.group(0)?.isNotEmpty == true) {
          spans.addAll(ChatMessageHelper.textSpan(context, match.group(0)!, 0,
              chatUIConfig: widget.chatUIConfig,
              remoteExtension: remoteExtension));
        }
        preIndex = match.end;
      }
      if (preIndex < text.length) {
        spans.addAll(ChatMessageHelper.textSpan(
            context, text.substring(preIndex, text.length), preIndex,
            chatUIConfig: widget.chatUIConfig,
            remoteExtension: remoteExtension));
      }
    } else {
      spans.addAll(ChatMessageHelper.textSpan(context, text, 0,
          chatUIConfig: widget.chatUIConfig, remoteExtension: remoteExtension));
    }
    return Container(
      //放到里面
      padding: widget.needPadding
          ? const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 12)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              maxLines: widget.titleMaxLines,
              overflow:
                  (widget.titleMaxLines != null) ? TextOverflow.ellipsis : null,
              style: TextStyle(
                  fontSize: widget.chatUIConfig?.messageTextSize ?? 16,
                  color: widget.chatUIConfig?.messageTextColor ??
                      CommonColors.color_333333,
                  fontWeight: FontWeight.w600)),
          if (text.isNotEmpty)
            Text.rich(
              TextSpan(children: spans),
              overflow:
                  (widget.bodyMaxLines != null) ? TextOverflow.ellipsis : null,
              maxLines: widget.bodyMaxLines,
            ),
        ],
      ),
    );
  }
}

class AitItemModel {
  String account;
  String text;
  AitSegment segment;

  AitItemModel(this.account, this.text, this.segment);
}
