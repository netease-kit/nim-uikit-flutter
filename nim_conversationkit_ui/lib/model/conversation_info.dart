// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_common_ui/extension.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
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
    _targetId =
        ChatKitUtils.getConversationTargetId(this.conversation.conversationId);
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

  NIMLastMessage? getLastMessage() {
    return conversation.lastMessage;
  }

  String getFormatTime() {
    // 使用空安全操作符来安全地访问嵌套属性
    final formattedTime =
        conversation.lastMessage?.messageRefer?.createTime?.formatDateTime();

    // 如果 formattedTime 是非空的，返回它；否则返回空字符串
    return formattedTime ?? '';
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
