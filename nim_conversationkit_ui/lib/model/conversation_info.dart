// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_common_ui/extension.dart';
import 'package:intl/intl.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/manager/ai_robot_manager.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_core_v2/nim_core.dart';

class ConversationInfo {
  NIMConversation conversation;
  String? _targetId;
  bool haveBeenAit = false;
  String? _nickName;

  ///是否在线，只有P2P 有效
  bool isOnline = false;

  ConversationInfo(this.conversation) {
    _targetId = ChatKitUtils.getConversationTargetId(
      this.conversation.conversationId,
    );
  }

  String get targetId {
    return _targetId!;
  }

  setNickName(String? nick) {
    this._nickName = nick;
  }

  String getName() {
    String name = this._nickName ?? '';
    if (name.isEmpty) {
      name = conversation.name ?? '';
    }
    if (name.isEmpty) {
      name = this.targetId;
    }
    return name;
  }

  String? getAvatar() {
    if (conversation.avatar?.isNotEmpty != true &&
        AIUserManager.instance.isAIUser(targetId)) {
      return AIUserManager.instance.getAIUserById(targetId)?.avatar;
    }
    return conversation.avatar;
  }

  bool isStickTop() {
    return this.conversation.stickTop;
  }

  bool isMute() {
    return this.conversation.mute;
  }

  ///是否是机器人
  bool isRobot() {
    return AIRobotManager.instance.isRobot(targetId);
  }

  NIMLastMessage? getLastMessage() {
    return conversation.lastMessage;
  }

  String getFormatTime({
    String? currentYearDateFormat,
    String? otherYearDateFormat,
  }) {
    final createTime = conversation.lastMessage?.messageRefer?.createTime;
    if (createTime == null) {
      return '';
    }
    if (currentYearDateFormat == null || otherYearDateFormat == null) {
      return createTime.formatDateTime();
    }

    final dateTime = DateTime.fromMillisecondsSinceEpoch(createTime);
    final now = DateTime.now();
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return DateFormat('HH:mm').format(dateTime);
    }
    final format =
        dateTime.year == now.year ? currentYearDateFormat : otherYearDateFormat;
    return DateFormat(format).format(dateTime);
  }

  NIMMessageAttachment? getLastAttachment() {
    return this.conversation.lastMessage?.attachment;
  }

  String getConversationId() {
    return conversation.conversationId;
  }

  NIMConversationType getConversationType() {
    return conversation.type;
  }

  int getUnreadCount() {
    return conversation.unreadCount ?? 0;
  }

  bool isSame(ConversationInfo info) {
    return this.getConversationId() == info.getConversationId();
  }

  @override
  String toString() {
    return 'conversation:${conversation.toJson()}';
  }
}
