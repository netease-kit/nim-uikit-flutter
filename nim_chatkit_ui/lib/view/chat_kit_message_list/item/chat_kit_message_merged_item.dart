// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/string_utils.dart';
import 'package:netease_common_ui/widgets/text_untils.dart';
import 'package:nim_chatkit/message/merge_message.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_core/nim_core.dart';

import '../../../l10n/S.dart';
import '../../page/merged_message_page.dart';

///在消息体里展示合并消息
class ChatKitMessageMergedItem extends StatefulWidget {
  final NIMMessage message;

  final MergedMessage mergedMessage;

  final ChatUIConfig? chatUIConfig;

  ///是否展示margin
  final bool showMargin;

  ///是否区分不同方向的消息
  final bool diffDirection;

  const ChatKitMessageMergedItem(
      {Key? key,
      required this.message,
      this.chatUIConfig,
      required this.mergedMessage,
      this.showMargin = true,
      this.diffDirection = true})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChatKitMessageMergedItemState();
  }
}

class _ChatKitMessageMergedItemState extends State<ChatKitMessageMergedItem> {
  late MergedMessage _mergedMessage;

  ///摘要中昵称的最大长度
  static const int _maxLengthOfNick = 5;

  String getAbstract() {
    StringBuffer abstract = StringBuffer();
    for (int i = 0; i < _mergedMessage.abstracts.length; i++) {
      var abs = _mergedMessage.abstracts[i];
      abstract.write(
          '${abs.senderNick.subStringWithMaxLength(_maxLengthOfNick)}: ${abs.content}');
      if (i != _mergedMessage.abstracts.length - 1) {
        abstract.write('\n');
      }
    }
    return abstract.toString();
  }

  @override
  void initState() {
    _mergedMessage = widget.mergedMessage;
    super.initState();
  }

  bool isSelf() {
    return widget.message.messageDirection == NIMMessageDirection.outgoing;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return MergedMessagePage(
              mergedMessage: _mergedMessage, message: widget.message);
        }));
      },
      child: Container(
        margin: widget.showMargin ? EdgeInsets.all(8) : null,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: widget.diffDirection
              ? (isSelf()
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8))
                  : const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8)))
              : BorderRadius.circular(8),
          border: widget.showMargin
              ? null
              : Border.all(color: '#E4E9F2'.toColor(), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            getSingleMiddleEllipsisText(
                S
                    .of(context)
                    .chatMessageMergedTitle(_mergedMessage.sessionName),
                endLen: 4,
                lessLen: isSelf() ? 10 : 0,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w500,
                )),
            SizedBox(
              height: 4,
            ),
            Text(
              getAbstract(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: '#999999'.toColor(),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              height: 0.5,
              color: '#999999'.toColor(),
            ),
            Text(
              S.of(context).chatMessageChatHistory,
              style: TextStyle(
                fontSize: 12,
                color: '#999999'.toColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
