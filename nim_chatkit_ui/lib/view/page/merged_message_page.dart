// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
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

  /// 是否在 Dialog 中展示（桌面端/Web 端）
  final bool isDialog;

  const MergedMessagePage({
    Key? key,
    required this.mergedMessage,
    required this.message,
    this.chatUIConfig,
    this.messageBuilder,
    this.isDialog = false,
  }) : super(key: key);

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
          content: 'getMessagesFromMergedMessage error: ${value.errorDetails}',
        );
        ChatUIToast.show(S.of(context).chatMessageInfoError, context: context);
        if (mounted) {
          Navigator.pop(context);
        }
      }
    });
    super.initState();
  }

  Widget _buildMessageList() {
    return Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Scaffold(
          appBar: AppBar(
            title: Text(S.of(context).chatMessageChatHistory),
            centerTitle: true,
            elevation: 0.5,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _buildMessageList(),
        ),
      );
    }
    return TransparentScaffold(
      centerTitle: true,
      title: S.of(context).chatMessageChatHistory,
      elevation: 0.5,
      appBarBackgroundColor: Colors.white,
      body: _buildMessageList(),
    );
  }
}
