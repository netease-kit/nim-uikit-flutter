// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as Intl;
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:netease_plugin_core_kit/netease_plugin_core_kit.dart';
import 'package:nim_chatkit/message/merge_message.dart';
import 'package:nim_chatkit/message/message_helper.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_file_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_image_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_nonsupport_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_video_item.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../../../helper/merge_message_helper.dart';
import '../../../../l10n/S.dart';
import '../chat_kit_message_avChat_item.dart';
import '../chat_kit_message_item.dart';
import '../chat_kit_message_merged_item.dart';
import '../chat_kit_message_multi_line_text_item.dart';
import '../chat_kit_message_text_item.dart';

///在合并消息详情页展示消息列表
class ChatKitMergedMessageItem extends StatefulWidget {
  final NIMMessage message;

  final ChatKitMessageBuilder? messageBuilder;

  final ChatUIConfig? chatUIConfig;

  final String chatTitle;

  final int? lastMessageTime;

  ChatKitMergedMessageItem(
      {Key? key,
      required this.message,
      required this.chatTitle,
      this.lastMessageTime,
      this.messageBuilder,
      this.chatUIConfig})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChatKitMergedMessageItemState();
}

class _ChatKitMergedMessageItemState extends State<ChatKitMergedMessageItem> {
  int showTimeInterval = ChatKitClient.instance.chatUIConfig.showTimeInterval;

  //item 复用MessageItem
  Widget _buildMessage(NIMMessage message) {
    var messageItemBuilder = widget.messageBuilder;
    switch (message.messageType) {
      case NIMMessageType.text:
        if (messageItemBuilder?.textMessageBuilder != null) {
          return messageItemBuilder!.textMessageBuilder!(message);
        }
        return ChatKitMessageTextItem(
            message: message, chatUIConfig: widget.chatUIConfig);
      case NIMMessageType.audio:
        return Container(
          decoration: BoxDecoration(
              border: Border.all(color: '#F0F0F0'.toColor()),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12))),
          child: Container(
            padding:
                const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 12),
            child: Text(S.of(context).chatMessageBriefAudio,
                style: TextStyle(fontSize: 16, color: '#333333'.toColor())),
          ),
        );
      case NIMMessageType.image:
        if (messageItemBuilder?.imageMessageBuilder != null) {
          return messageItemBuilder!.imageMessageBuilder!(message);
        }
        return ChatKitMessageImageItem(
          message: message,
          showOneImage: true,
          showDirection: false,
        );
      case NIMMessageType.video:
        if (messageItemBuilder?.videoMessageBuilder != null) {
          return messageItemBuilder!.videoMessageBuilder!(message);
        }
        return ChatKitMessageVideoItem(
          message: message,
          independentFile: true,
        );
      case NIMMessageType.file:
        if (messageItemBuilder?.fileMessageBuilder != null) {
          return messageItemBuilder!.fileMessageBuilder!(message);
        }
        return ChatKitMessageFileItem(
          message: message,
          independentFile: true,
        );
      case NIMMessageType.call:
        if (messageItemBuilder?.avChatMessageBuilder != null) {
          return messageItemBuilder!.avChatMessageBuilder!.call(message);
        }
        return ChatKitMessageAvChatItem(
          message: message,
          enableCallback: false,
        );

      case NIMMessageType.location:
      default:
        if (message.messageType == NIMMessageType.location &&
            messageItemBuilder?.locationMessageBuilder != null) {
          return messageItemBuilder!.locationMessageBuilder!.call(message);
        }
        if (message.messageType == NIMMessageType.custom) {
          var mergedMessage = MergeMessageHelper.parseMergeMessage(message);
          if (mergedMessage != null) {
            if (messageItemBuilder?.mergedMessageBuilder != null) {
              return messageItemBuilder!.mergedMessageBuilder!.call(message);
            }
            return ChatKitMessageMergedItem(
              message: message,
              mergedMessage: mergedMessage,
              chatUIConfig: widget.chatUIConfig,
              showMargin: false,
              diffDirection: false,
            );
          }
          var multiLineMap = MessageHelper.parseMultiLineMessage(message);
          var multiLineTitle = multiLineMap?[ChatMessage.keyMultiLineTitle];
          var multiLineBody = multiLineMap?[ChatMessage.keyMultiLineBody];
          if (multiLineTitle != null) {
            return ChatKitMessageMultiLineItem(
              message: message,
              chatUIConfig: widget.chatUIConfig,
              title: multiLineTitle,
              body: multiLineBody,
            );
          }
        }

        ///插件消息
        Widget? pluginBuilder = NimPluginCoreKit()
            .messageBuilderPool
            .buildMessageContent(context, message);
        if (pluginBuilder != null) {
          return pluginBuilder;
        }

        if (messageItemBuilder?.extendBuilder != null) {
          if (messageItemBuilder?.extendBuilder![message.messageType] != null) {
            return messageItemBuilder!
                .extendBuilder![message.messageType]!(message);
          }
        }
        return ChatKitMessageNonsupportItem();
    }
  }

  //时间格式化
  String _timeFormat(int milliSecond) {
    var nowTime = DateTime.now();
    var messageTime = DateTime.fromMillisecondsSinceEpoch(milliSecond);
    if (nowTime.year != messageTime.year) {
      return Intl.DateFormat('yyyy-MM-dd HH:mm').format(messageTime);
    } else if (nowTime.month != messageTime.month ||
        nowTime.day != messageTime.day) {
      return Intl.DateFormat('MM-dd HH:mm').format(messageTime);
    } else {
      return Intl.DateFormat('HH:mm').format(messageTime);
    }
  }

  bool _showTime() {
    if (widget.lastMessageTime == null) {
      return true;
    }
    var currentTime = widget.message.createTime!;
    var lastMessageTime = widget.lastMessageTime!;
    return currentTime - lastMessageTime > showTimeInterval;
  }

  bool _hideMessageBg(NIMMessage message) {
    if (message.messageType == NIMMessageType.image ||
        message.messageType == NIMMessageType.video ||
        message.messageType == NIMMessageType.location) {
      return true;
    }
    //合并消息不显示背景
    if (message.messageType == NIMMessageType.custom) {
      var mergedMessage = MergeMessageHelper.parseMergeMessage(message);
      if (mergedMessage != null) {
        return true;
      }
    }
    return false;
  }

  BoxDecoration _getMessageDecoration() {
    if (widget.chatUIConfig?.receiveMessageBg != null) {
      return widget.chatUIConfig!.receiveMessageBg!;
    } else {
      return BoxDecoration(
        color: _hideMessageBg(widget.message)
            ? Colors.transparent
            : '#E8EAED'.toColor(),
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var extension = null;
    if (widget.message.serverExtension?.isNotEmpty == true) {
      extension = jsonDecode(widget.message.serverExtension!);
    }
    final sendNick =
        extension?[mergedMessageNickKey] ?? widget.message.senderId;
    final sendAvatar = extension?[mergedMessageAvatarKey];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_showTime())
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _timeFormat(widget.message.createTime!),
                style: TextStyle(
                    fontSize: widget.chatUIConfig?.timeTextSize ?? 12,
                    color: widget.chatUIConfig?.timeTextColor ??
                        '#B3B7BC'.toColor()),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(avatar: sendAvatar, name: sendNick, width: 32, height: 32),
              Container(
                margin: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sendNick,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: '#888888'.toColor())),
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      decoration: _getMessageDecoration(),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width - 110),
                      child: _buildMessage(widget.message),
                    )
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
