// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:netease_corekit_im/model/ait/ait_contacts_model.dart';
import 'package:netease_corekit_im/model/ait/ait_msg.dart';
import 'package:netease_corekit_im/router/imkit_router_factory.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:netease_corekit_im/services/message/chat_message.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/view/input/emoji.dart';
import 'package:collection/collection.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:nim_core/nim_core.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

class ChatKitMessageTextItem extends StatefulWidget {
  final NIMMessage message;

  final ChatUIConfig? chatUIConfig;

  final bool needPadding;

  final int? maxLines;

  const ChatKitMessageTextItem(
      {Key? key,
      required this.message,
      this.chatUIConfig,
      this.needPadding = true,
      this.maxLines})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageTextState();
}

class ChatKitMessageTextState extends State<ChatKitMessageTextItem> {
  List<TextSpan> _textSpan(String text, int start, [int? end]) {
    //定义文本字体大小和颜色
    final textSize = widget.chatUIConfig?.messageTextSize ?? 16;
    final textColor =
        widget.chatUIConfig?.messageTextColor ?? CommonColors.color_333333;
    final textAitColor =
        widget.chatUIConfig?.messageLinkColor ?? CommonColors.color_007aff;

    //需要返回的spans
    final List<TextSpan> spans = [];
    //如果有@消息，则需要将@消息的文本和普通文本分开
    if (widget.message.remoteExtension?[ChatMessage.keyAitMsg] != null) {
      //获取@消息的文本list
      List<AitItemModel> aitSegments = [];
      //将所有@的文本和位置提取出来
      try {
        var aitMap =
            widget.message.remoteExtension![ChatMessage.keyAitMsg] as Map;
        final AitContactsModel aitContactsModel =
            AitContactsModel.fromMap(Map<String, dynamic>.from(aitMap));
        aitContactsModel.aitBlocks.forEach((key, value) {
          var aitMsg = value as AitMsg;
          aitMsg.segments.forEach((segment) {
            aitSegments.add(AitItemModel(key, aitMsg.text, segment));
          });
        });
      } catch (e) {
        Alog.e(
            tag: 'ChatKitMessageTextItem',
            content: 'aitContactsModel.fromMap error: $e');
      }

      //根据@消息的位置，将文本分成多个部分
      aitSegments.sort((a, b) => a.segment.start.compareTo(b.segment.start));
      int preIndex = start;
      for (var aitItem in aitSegments) {
        //@之前的部分
        if (aitItem.segment.start > preIndex) {
          spans.add(TextSpan(
              text: text.substring(preIndex, aitItem.segment.start),
              style: TextStyle(fontSize: textSize, color: textColor)));
        }
        //@部分
        spans.add(TextSpan(
            text: aitItem.text,
            style: TextStyle(fontSize: textSize, color: textAitColor),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                //点击@消息，如果有自定义回调，则回调，否则跳转到用户详情页
                if (widget.chatUIConfig?.onTapAitLink != null) {
                  widget.chatUIConfig?.onTapAitLink
                      ?.call(aitItem.account, aitItem.text);
                } else if (aitItem.account != AitContactsModel.accountAll) {
                  if (getIt<LoginService>().userInfo?.userId !=
                      aitItem.account) {
                    goToContactDetail(context, aitItem.account);
                  } else {
                    gotoMineInfoPage(context);
                  }
                }
              }));
        preIndex =
            end == null ? aitItem.segment.end : end - aitItem.segment.end;
      }
      //最后一个@之后的部分
      if (preIndex < text.length) {
        spans.add(TextSpan(
            text: text.substring(preIndex, text.length),
            style: TextStyle(fontSize: textSize, color: textColor)));
      }
    } else {
      //没有@消息，直接返回
      spans.add(TextSpan(
          text: text, style: TextStyle(fontSize: textSize, color: textColor)));
    }
    return spans;
  }

  WidgetSpan? _imageSpan(String? tag) {
    var item = emojiData.firstWhereOrNull((element) => element['tag'] == tag);
    if (item == null) return null;
    String name = item['name'] as String;
    return WidgetSpan(
      child: Image.asset(
        name,
        package: kPackage,
        height: 24,
        width: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String text = widget.message.content!;
    var matches = RegExp("\\[[^\\[]{1,10}\\]").allMatches(text);
    List<InlineSpan> spans = [];
    int preIndex = 0;
    if (matches.isNotEmpty) {
      for (final match in matches) {
        if (match.start > preIndex) {
          spans.addAll(_textSpan(
              text.substring(preIndex, match.start), preIndex, match.start));
        }
        var span = _imageSpan(match.group(0));
        if (span != null) {
          spans.add(span);
        }
        preIndex = match.end;
      }
      if (preIndex < text.length) {
        spans
            .addAll(_textSpan(text.substring(preIndex, text.length), preIndex));
      }
    } else {
      spans.addAll(_textSpan(text, 0));
    }
    return Container(
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
  }
}

class AitItemModel {
  String account;
  String text;
  AitSegment segment;

  AitItemModel(this.account, this.text, this.segment);
}
