// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'conversation_kit_client_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class ConversationKitClientLocalizationsZh
    extends ConversationKitClientLocalizations {
  ConversationKitClientLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get conversationTitle => '云信IM';

  @override
  String get createAdvancedTeamSuccess => '成功创建高级群';

  @override
  String get stickTitle => '置顶';

  @override
  String get cancelStickTitle => '取消置顶';

  @override
  String get deleteTitle => '删除';

  @override
  String get recentTitle => '最近聊天';

  @override
  String get cancelTitle => '取消';

  @override
  String get sureTitle => '确定';

  @override
  String sureCountTitle(int size) {
    return '确定($size)';
  }

  @override
  String get conversationNetworkErrorTip => '当前网络不可用，请检查你当网络设置。';

  @override
  String get addFriend => '添加好友';

  @override
  String get addFriendSearchHint => '请输入账号';

  @override
  String get addFriendSearchEmptyTips => '该用户不存在';

  @override
  String get createGroupTeam => '创建讨论组';

  @override
  String get createAdvancedTeam => '创建高级群';

  @override
  String get chatMessageNonsupportType => '[当前版本暂不支持该消息体]';

  @override
  String get conversationEmpty => '暂无会话';

  @override
  String get somebodyAitMe => '[有人@我]';

  @override
  String get audioMessageType => '[语音]';

  @override
  String get imageMessageType => '[图片]';

  @override
  String get videoMessageType => '[视频]';

  @override
  String get locationMessageType => '[位置]';

  @override
  String get fileMessageType => '[文件]';

  @override
  String get notificationMessageType => '[通知消息]';

  @override
  String get tipMessageType => '[提醒消息]';

  @override
  String get chatHistoryBrief => '[聊天记录]';

  @override
  String get joinTeam => '加入群组';

  @override
  String get joinTeamSearchHint => '请输入群号';

  @override
  String get joinTeamSearchEmptyTips => '该群组不存在';
}
