// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:netease_corekit_im/model/ait/ait_msg.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_core/nim_core.dart';

import '../../../helper/chat_message_helper.dart';

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
  @override
  Widget build(BuildContext context) {
    final String text = widget.message.content!;
    var matches = RegExp("\\[[^\\[]{1,10}\\]").allMatches(text);
    List<InlineSpan> spans = [];
    int preIndex = 0;
    if (matches.isNotEmpty) {
      for (final match in matches) {
        if (match.start > preIndex) {
          spans.addAll(ChatMessageHelper.textSpan(
              context, text.substring(preIndex, match.start), preIndex,
              end: match.start,
              chatUIConfig: widget.chatUIConfig,
              remoteExtension: widget.message.remoteExtension));
        }
        var span = ChatMessageHelper.imageSpan(match.group(0));
        if (span != null) {
          spans.add(span);
        } else if (match.group(0)?.isNotEmpty == true) {
          spans.addAll(ChatMessageHelper.textSpan(context, match.group(0)!, 0,
              chatUIConfig: widget.chatUIConfig,
              remoteExtension: widget.message.remoteExtension));
        }
        preIndex = match.end;
      }
      if (preIndex < text.length) {
        spans.addAll(ChatMessageHelper.textSpan(
            context, text.substring(preIndex, text.length), preIndex,
            chatUIConfig: widget.chatUIConfig,
            remoteExtension: widget.message.remoteExtension));
      }
    } else {
      spans.addAll(ChatMessageHelper.textSpan(context, text, 0,
          chatUIConfig: widget.chatUIConfig,
          remoteExtension: widget.message.remoteExtension));
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
