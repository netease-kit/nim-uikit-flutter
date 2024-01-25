// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'team_kit_client_localizations.dart';

/// The translations for Chinese (`zh`).
class TeamKitClientLocalizationsZh extends TeamKitClientLocalizations {
  TeamKitClientLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get teamSettingTitle => '设置';

  @override
  String get teamInfoTitle => '群信息';

  @override
  String get teamGroupInfoTitle => '讨论组信息';

  @override
  String get teamNameTitle => '群名称';

  @override
  String get teamGroupNameTitle => '讨论组名称';

  @override
  String get teamMemberTitle => '群成员';

  @override
  String get teamGroupMemberTitle => '讨论组成员';

  @override
  String get teamIconTitle => '群头像';

  @override
  String get teamGroupIconTitle => '讨论组头像';

  @override
  String get teamIntroduceTitle => '群介绍';

  @override
  String get teamMyNicknameTitle => '我在群里的昵称';

  @override
  String get teamMark => '标记';

  @override
  String get teamHistory => '历史记录';

  @override
  String get teamMessageTip => '开启消息提醒';

  @override
  String get teamSessionPin => '聊天置顶';

  @override
  String get teamMute => '群禁言';

  @override
  String get teamInviteOtherPermission => '谁可以添加群成员';

  @override
  String get teamUpdateInfoPermission => '谁可以编辑群信息';

  @override
  String get teamNeedAgreedWhenBeInvitedPermission => '是否需要被邀请者同意';

  @override
  String get teamAdvancedDismiss => '解散群聊';

  @override
  String get teamAdvancedQuit => '退出群聊';

  @override
  String get teamGroupQuit => '退出讨论组';

  @override
  String get teamDefaultIcon => '选择默认图标';

  @override
  String get teamAllMember => '所有人';

  @override
  String get teamOwner => '群主';

  @override
  String get teamUpdateIcon => '修改头像';

  @override
  String get teamCancel => '取消';

  @override
  String get teamConfirm => '确认';

  @override
  String get teamQuitAdvancedTeamQuery => '是否退出群聊？';

  @override
  String get teamQuitGroupTeamQuery => '是否退出讨论组？';

  @override
  String get teamDismissAdvancedTeamQuery => '是否解散群聊？';

  @override
  String get teamSave => '保存';

  @override
  String get teamSearchMember => '搜索成员';

  @override
  String get teamNoPermission => '没有修改权限';

  @override
  String get teamNameMustNotEmpty => '群名称不可为空';

  @override
  String get teamManage => '群管理';

  @override
  String get teamAitPermission => '谁可以@所有人';

  @override
  String get teamManager => '管理员';

  @override
  String get teamAddManagers => '添加管理员';

  @override
  String get teamOwnerManager => '群主和管理员';

  @override
  String get teamMemberRemove => '移除';

  @override
  String get teamRemoveConfirm => '是否移除';

  @override
  String get teamRemoveConfirmContent => '移除后该成员将无管理权限';

  @override
  String get teamSettingFailed => '设置失败';

  @override
  String get teamMsgAitAllPrivilegeIsAll => '@所有人权限更新为所有人';

  @override
  String get teamMsgAitAllPrivilegeIsOwner => '@所有人权限更新为群主和管理员';

  @override
  String get teamManagers => '群管理员';

  @override
  String get teamSelectMembers => '请选择成员';

  @override
  String teamManagerLimit(String number) {
    return '最多只能设置$number个管理员';
  }

  @override
  String get teamNoOperatePermission => '您暂无操作权限';

  @override
  String get teamManagerEmpty => '暂无群管理人员';

  @override
  String get teamMemberRemoveContent => '移除后该成员将离开当前群聊';

  @override
  String get teamMemberRemoveFailed => '移除失败';

  @override
  String get teamManagerManagers => '管理管理员';

  @override
  String get teamMemberSelect => '人员选择';

  @override
  String get teamPermissionDeny => '您暂无权限操作';

  @override
  String get teamManagerRemoveFailed => '管理员移除失败';

  @override
  String get teamMemberEmpty => '暂无成员';
}
