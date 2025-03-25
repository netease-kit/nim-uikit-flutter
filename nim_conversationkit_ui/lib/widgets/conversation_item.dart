// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/extension.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/widgets/unread_message.dart';
import 'package:netease_corekit_im/model/custom_type_constant.dart';
import 'package:netease_corekit_im/services/message/chat_message.dart';
import 'package:netease_plugin_core_kit/netease_plugin_core_kit.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_conversationkit_ui/l10n/S.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../model/conversation_info.dart';

bool isSupportMessageType(NIMMessageType? type) {
  return type == NIMMessageType.text ||
      type == NIMMessageType.audio ||
      type == NIMMessageType.image ||
      type == NIMMessageType.video ||
      type == NIMMessageType.notification ||
      type == NIMMessageType.tip ||
      type == NIMMessageType.file ||
      type == NIMMessageType.location;
}

/// 会话列表Item的高度，设置到ListView中的itemExtent，提高性能
final double conversationItemHeight = 62;

class ConversationItem extends StatelessWidget {
  const ConversationItem(
      {Key? key,
      required this.conversationInfo,
      required this.config,
      required this.index})
      : super(key: key);

  final ConversationInfo conversationInfo;
  final ConversationItemConfig config;
  final int index;

  String _getLastMessageContent(BuildContext context) {
    var configMessageContent =
        config.lastMessageContentBuilder?.call(context, conversationInfo);
    if (configMessageContent?.isNotEmpty == true) {
      return configMessageContent!;
    }
    switch (conversationInfo.getLastMessage()?.messageType) {
      case NIMMessageType.text:
        return conversationInfo.getLastMessage()?.text ?? '';
      case NIMMessageType.tip:
        return S.of(context).tipMessageType;
      case NIMMessageType.audio:
        return S.of(context).audioMessageType;
      case NIMMessageType.image:
        return S.of(context).imageMessageType;
      case NIMMessageType.video:
        return S.of(context).videoMessageType;
      case NIMMessageType.notification:
        return S.of(context).notificationMessageType;
      case NIMMessageType.file:
        return S.of(context).fileMessageType;
      case NIMMessageType.location:
        return S.of(context).locationMessageType;
      case NIMMessageType.call:
        return S.of(context).chatMessageNonsupportType;
      case NIMMessageType.custom:
        var customLastMessageContent =
            _getCustomLastMessageBrief(context, conversationInfo);
        if (customLastMessageContent?.isNotEmpty == true) {
          return customLastMessageContent!;
        }
        //插件消息
        var pluginLastContent = NimPluginCoreKit()
            .conversationPool
            .buildConversationLastText(conversationInfo.conversation);
        if (pluginLastContent != null) {
          return pluginLastContent;
        }
        return conversationInfo.getLastMessage()?.text ??
            S.of(context).chatMessageNonsupportType;
      default:
        return conversationInfo.getLastMessage()?.text ??
            S.of(context).chatMessageNonsupportType;
    }
  }

  String? _getCustomLastMessageBrief(
      BuildContext context, ConversationInfo conversationInfo) {
    if (conversationInfo.getLastAttachment() is NIMMessageAttachment) {
      var attachmentRaw = conversationInfo.getLastMessage()?.attachment?.raw;
      if (attachmentRaw != null) {
        Map<String, dynamic> data = json.decode(attachmentRaw);

        if (data?[CustomMessageKey.type] ==
            CustomMessageType.customMergeMessageType) {
          return S.of(context).chatHistoryBrief;
        }
        if (data?[CustomMessageKey.type] ==
            CustomMessageType.customMultiLineMessageType) {
          var dataMap = data?[CustomMessageKey.data] as Map?;
          var title = dataMap?[ChatMessage.keyMultiLineTitle] as String?;
          if (title != null) {
            return title;
          }
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    String? avatar = conversationInfo.getAvatar();
    return Container(
      height: conversationItemHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: conversationInfo.isStickTop()
          ? const Color(0xffededef)
          : Colors.white,
      alignment: Alignment.centerLeft,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              child: Avatar(
                avatar: avatar,
                name: conversationInfo.getName(),
                bgCode:
                    AvatarColor.avatarColor(content: conversationInfo.targetId),
                height: 42,
                width: 42,
                radius: config.avatarCornerRadius,
              ),
              onTap: () {
                if (config.avatarClick != null &&
                    config.avatarClick!(conversationInfo, index)) {
                  return;
                }
              },
              onLongPress: () {
                if (config.avatarLongClick != null &&
                    config.avatarLongClick!(conversationInfo, index)) {
                  return;
                }
              },
            ),
          ),
          if (!conversationInfo.isMute())
            Positioned(
                top: 7,
                left: 27,
                child: UnreadMessage(
                  count: conversationInfo.conversation.unreadCount ?? 0,
                )),
          Positioned(
            left: 54,
            top: 10,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.only(right: 70),
                    child: Text(
                      conversationInfo.getName(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: config.itemTitleSize,
                          color: config.itemTitleColor),
                    )),
                Text.rich(
                  TextSpan(children: [
                    if (conversationInfo.haveBeenAit &&
                        (conversationInfo.conversation.unreadCount ?? 0) > 0)
                      TextSpan(
                        text: S.of(context).somebodyAitMe,
                        style: TextStyle(
                            fontSize: config.itemContentSize,
                            color: config.itemAitTextColor),
                      ),
                    TextSpan(
                      text: _getLastMessageContent(context),
                      style: TextStyle(
                          fontSize: config.itemContentSize,
                          color: config.itemContentColor),
                    )
                  ]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Positioned(
              right: 0,
              top: 17,
              child: Text(
                conversationInfo.getFormatTime(),
                style: TextStyle(
                    fontSize: config.itemDateSize, color: config.itemDateColor),
              )),
          if (conversationInfo.isMute())
            Positioned(
              right: 0,
              bottom: 10,
              child: SvgPicture.asset(
                'images/ic_mute.svg',
                package: kPackage,
              ),
            )
        ],
      ),
    );
  }
}
