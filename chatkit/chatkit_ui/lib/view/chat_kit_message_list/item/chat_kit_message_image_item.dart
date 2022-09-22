// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:chatkit_ui/media/picture.dart';
import 'package:chatkit_ui/view/chat_kit_message_list/widgets/chat_thumb_view.dart';
import 'package:flutter/material.dart';
import 'package:nim_core/nim_core.dart';
import 'package:provider/provider.dart';

import '../../../view_model/chat_view_model.dart';

class ChatKitMessageImageItem extends StatefulWidget {
  final NIMMessage message;

  const ChatKitMessageImageItem({Key? key, required this.message})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageImageState();
}

class ChatKitMessageImageState extends State<ChatKitMessageImageItem> {
  late bool _isReceive;

  @override
  void initState() {
    super.initState();
    _isReceive =
        widget.message.messageDirection == NIMMessageDirection.received;
  }

  @override
  Widget build(BuildContext context) {
    return ChatThumbView(
        message: widget.message,
        radius: BorderRadius.only(
            topLeft: Radius.circular(_isReceive ? 0 : 12),
            topRight: Radius.circular(_isReceive ? 12 : 0),
            bottomLeft: const Radius.circular(12),
            bottomRight: const Radius.circular(12)),
        onTap: () {
          var messagesList = context
              .read<ChatViewModel>()
              .messageList
              .where((element) =>
                  element.nimMessage.messageAttachment is NIMImageAttachment)
              .map((e) => e.nimMessage)
              .toList();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PictureViewer(
                      messages: messagesList,
                      showIndex: messagesList.indexOf(widget.message))));
        });
  }
}
