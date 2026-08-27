// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
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
  String get conversationSearchHint => '搜索好友或群组';

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
  String get robotSubConversation => '[子会话]';

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

  @override
  String get scanRobot => '扫一扫';

  @override
  String get chatMessageBriefVideoCall => '[视频通话]';

  @override
  String get chatMessageBriefAudioCall => '[语音通话]';

  @override
  String get muteTitle => '开启免打扰';

  @override
  String get cancelMuteTitle => '取消免打扰';

  @override
  String get closeTitle => '关闭';

  @override
  String get saveTitle => '保存';

  @override
  String get conversationGroupTitle => '会话分组';

  @override
  String get conversationGroupAll => '全部';

  @override
  String get conversationGroupAitMe => '@我';

  @override
  String get conversationGroupUnread => '未读';

  @override
  String get conversationGroupVisible => '常用分组';

  @override
  String get conversationGroupHidden => '隐藏分组';

  @override
  String get conversationGroupCreate => '新建分组';

  @override
  String get conversationGroupSetting => '设置会话分组';

  @override
  String get conversationGroupName => '分组名称';

  @override
  String get conversationGroupNameHint => '请输入分组名称';

  @override
  String get conversationGroupConversationList => '会话列表';

  @override
  String conversationGroupConversationCount(int count) {
    return '会话($count)';
  }

  @override
  String get conversationGroupAddConversation => '添加会话';

  @override
  String get conversationGroupSearchHint => '请输入你需要搜索的会话';

  @override
  String get conversationGroupOperationFailed => '操作失败';

  @override
  String get conversationGroupLimit => '会话分组超限';

  @override
  String get conversationGroupPartialAddFailed => '部分会话添加失败';

  @override
  String get conversationGroupConversationNotExist => '会话不存在';

  @override
  String get conversationGroupConversationCountLimit => '会话分组中的会话数量超限';

  @override
  String get conversationGroupDeleteConfirmTitle => '删除分组';

  @override
  String get conversationGroupDeleteConfirmContent => '删除后仅删除分组关系，不会删除会话。';

  @override
  String get conversationGroupConversationLimit => '会话数量已达上限';

  @override
  String get conversationGroupJoinedLimit => '该会话已达到可加入分组数量上限';

  @override
  String get conversationTimeCurrentYearFormat => 'M月d日';

  @override
  String get conversationTimeOtherYearFormat => 'yyyy年M月d日';

  @override
  String conversationGroupAddTitle(int selected, int max) {
    return '添加会话($selected/$max)';
  }
}
