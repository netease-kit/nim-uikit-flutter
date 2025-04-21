// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'team_kit_client_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class TeamKitClientLocalizationsEn extends TeamKitClientLocalizations {
  TeamKitClientLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get teamSettingTitle => 'Setting';

  @override
  String get teamInfoTitle => 'Team info';

  @override
  String get teamGroupInfoTitle => 'Team Group info';

  @override
  String get teamNameTitle => 'Team name';

  @override
  String get teamGroupNameTitle => 'Team Group name';

  @override
  String get teamMemberTitle => 'Team member';

  @override
  String get teamGroupMemberTitle => 'Team Group member';

  @override
  String get teamIconTitle => 'Team icon';

  @override
  String get teamGroupIconTitle => 'Team Group icon';

  @override
  String get teamIntroduceTitle => 'Team introduce';

  @override
  String get teamMyNicknameTitle => 'My nickname in Team';

  @override
  String get teamMark => 'Mark';

  @override
  String get teamHistory => 'History';

  @override
  String get teamMessageTip => 'Open message notice';

  @override
  String get teamSessionPin => 'Set session top';

  @override
  String get teamMute => 'Mute';

  @override
  String get teamInviteOtherPermission => 'Invite others permission';

  @override
  String get teamUpdateInfoPermission => 'Permission to modify Team info';

  @override
  String get teamNeedAgreedWhenBeInvitedPermission =>
      'Whether the invitee\'s consent is required';

  @override
  String get teamAdvancedDismiss => 'Disband the Team chat';

  @override
  String get teamAdvancedQuit => 'Exit Team chat';

  @override
  String get teamGroupQuit => 'Exit Team Group chat';

  @override
  String get teamDefaultIcon => 'Choose default icon';

  @override
  String get teamAllMember => 'All member';

  @override
  String get teamOwner => 'Owner';

  @override
  String get teamUpdateIcon => 'Modify avatar';

  @override
  String get teamCancel => 'cancel';

  @override
  String get teamConfirm => 'confirm';

  @override
  String get teamQuitAdvancedTeamQuery => 'Do you want to leave the Team chat?';

  @override
  String get teamQuitGroupTeamQuery =>
      'Do you want to leave the Team Group chat?';

  @override
  String get teamDismissAdvancedTeamQuery => 'Disband the Team chat?';

  @override
  String get teamSave => 'Save';

  @override
  String get teamSearchMember => 'Search Member';

  @override
  String get teamNoPermission => 'No Permission';

  @override
  String get teamNameMustNotEmpty => 'Team name must not empty';

  @override
  String get teamManage => 'Team Manage';

  @override
  String get teamAitPermission => 'Who can @all';

  @override
  String get teamManager => 'Team Manager';

  @override
  String get teamAddManagers => 'Add Managers';

  @override
  String get teamOwnerManager => 'Owner Add Manager';

  @override
  String get teamMemberRemove => 'Remove';

  @override
  String get teamRemoveConfirm => 'Sure to remove';

  @override
  String get teamRemoveConfirmContent =>
      'This Member will lost Manager Promise after remove';

  @override
  String get teamSettingFailed => 'Setting failed';

  @override
  String get teamMsgAitAllPrivilegeIsAll => '@All privilege update to all';

  @override
  String get teamMsgAitAllPrivilegeIsOwner =>
      '@All privilege update to owner and manager';

  @override
  String get teamManagers => 'Managers';

  @override
  String get teamSelectMembers => 'Select members';

  @override
  String teamManagerLimit(String number) {
    return 'The number of managers cannot exceed $number';
  }

  @override
  String get teamNoOperatePermission => 'No operate permission';

  @override
  String get teamManagerEmpty => 'No manager';

  @override
  String get teamMemberRemoveContent =>
      'This member will leave this team after remove';

  @override
  String get teamMemberRemoveFailed => 'Remove failed';

  @override
  String get teamManagerManagers => 'Manager managers';

  @override
  String get teamMemberSelect => 'Select member';

  @override
  String get teamPermissionDeny => 'you have no permission';

  @override
  String get teamManagerRemoveFailed => 'Remove failed';

  @override
  String get teamMemberEmpty => 'No member';
}
