// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common/netease_common.dart';
import 'package:nim_chatkit/message/merge_message.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/mergedMessage/chat_kit_merged_message_item.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../chat_kit_client.dart';
import '../../l10n/S.dart';
import '../chat_kit_message_list/item/chat_kit_message_item.dart';

class MergedMessagePage extends StatefulWidget {
  final MergedMessage mergedMessage;

  final NIMMessage message;

  final ChatUIConfig? chatUIConfig;

  final ChatKitMessageBuilder? messageBuilder;

  const MergedMessagePage(
      {Key? key,
      required this.mergedMessage,
      required this.message,
      this.chatUIConfig,
      this.messageBuilder})
      : super(key: key);

  @override
  _MergedMessagePageState createState() => _MergedMessagePageState();
}

class _MergedMessagePageState extends State<MergedMessagePage> {
  List<NIMMessage> messages = List.empty(growable: true);

  ChatUIConfig? chatUIConfig;

  @override
  void initState() {
    chatUIConfig = widget.chatUIConfig ?? ChatKitClient.instance.chatUIConfig;
    var mergedMsg = widget.mergedMessage;
    mergedMsg.messageId = widget.message.messageClientId;
    ChatMessageRepo.getMessagesFromMergedMessage(mergedMsg).then((value) {
      if (value.isSuccess && value.data != null) {
        setState(() {
          messages.addAll(value.data!);
        });
      } else {
        Alog.e(
            tag: 'MergedMessagePage',
            content:
                'getMessagesFromMergedMessage error: ${value.errorDetails}');
        Fluttertoast.showToast(msg: S.of(context).chatMessageInfoError);
        Navigator.pop(context);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              size: 26,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          centerTitle: true,
          title: Text(
            S.of(context).chatMessageChatHistory,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          elevation: 0.5,
        ),
        body: Container(
          color: Colors.white,
          constraints: BoxConstraints.expand(),
          child: ListView.builder(
            itemCount: messages.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              var msg = messages[index];
              var lastTime = index > 0 ? messages[index - 1].createTime : null;
              return ChatKitMergedMessageItem(
                message: msg,
                chatTitle: widget.mergedMessage.sessionName,
                lastMessageTime: lastTime,
                chatUIConfig: chatUIConfig,
                messageBuilder:
                    widget.messageBuilder ?? chatUIConfig?.messageBuilder,
              );
            },
          ),
        ));
  }
}
