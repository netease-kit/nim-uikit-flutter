// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../helper/chat_message_helper.dart';
import '../../helper/chat_message_user_helper.dart';

/// 历史消息搜索结果列表项：显示头像、发送者名称、消息内容预览及时间
class HistoryMessageItem extends StatelessWidget {
  const HistoryMessageItem(
    this.message,
    this.keyword, {
    Key? key,
    this.contactInfo,
  }) : super(key: key);

  final NIMMessage message;

  final String keyword;

  final ContactInfo? contactInfo;

  Future<UserAvatarInfo> _getUserAvatarInfo() async {
    if (message.aiConfig?.aiStatus == NIMMessageAIStatus.response &&
        AIUserManager.instance.isAIUser(message.aiConfig?.accountId)) {
      final aiUser = AIUserManager.instance.getAIUserById(
        message.aiConfig!.accountId!,
      );
      return UserAvatarInfo(
        aiUser!.name ?? aiUser.accountId!,
        avatarName: aiUser.name,
        avatar: aiUser.avatar,
      );
    }
    if (message.conversationType == NIMConversationType.p2p) {
      if (message.isSelf != true && contactInfo != null) {
        return UserAvatarInfo(
          contactInfo!.getName(),
          avatarName: contactInfo!.getName(needAlias: false),
          avatar: contactInfo?.user.avatar,
        );
      }
      final selfInfo = IMKitClient.getUserInfo();
      if (message.isSelf == true && selfInfo != null) {
        return UserAvatarInfo(
          selfInfo.name ?? message.senderId!,
          avatar: selfInfo.avatar,
          avatarName: selfInfo.name ?? message.senderId!,
        );
      }
      return UserAvatarInfo(message.senderId!, avatarName: message.senderId!);
    } else {
      var teamId = ChatKitUtils.getConversationTargetId(
        message.conversationId!,
      );
      return await getUserAvatarInfoInTeam(teamId, message.senderId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.centerLeft,
      child: FutureBuilder<UserAvatarInfo>(
        future: _getUserAvatarInfo(),
        builder: (context, snapshot) {
          final userInfo = snapshot.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Text(
                  getFormatTime(message.createTime!.toInt(), context),
                  style: TextStyle(fontSize: 12, color: '#B3B7BC'.toColor()),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Avatar(
                    avatar: userInfo?.avatar,
                    name: userInfo?.avatarName,
                    height: 32,
                    width: 32,
                    radius: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userInfo?.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: CommonColors.color_333333,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        buildHistoryMessage(context, message, keyword: keyword),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
