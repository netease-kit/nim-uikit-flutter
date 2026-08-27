// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'conversation_kit_client_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ConversationKitClientLocalizationsEn
    extends ConversationKitClientLocalizations {
  ConversationKitClientLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get conversationTitle => 'CommsEase IM';

  @override
  String get createAdvancedTeamSuccess => 'create advanced team success';

  @override
  String get stickTitle => 'Stick';

  @override
  String get cancelStickTitle => 'Cancel stick';

  @override
  String get deleteTitle => 'Delete';

  @override
  String get recentTitle => 'Recent chat';

  @override
  String get cancelTitle => 'Cancel';

  @override
  String get sureTitle => 'Sure';

  @override
  String sureCountTitle(int size) {
    return 'Sure($size)';
  }

  @override
  String get conversationNetworkErrorTip =>
      'The current network is unavailable, please check your network settings.';

  @override
  String get addFriend => 'add friends';

  @override
  String get conversationSearchHint => 'Search friends or groups';

  @override
  String get addFriendSearchHint => 'Please enter account';

  @override
  String get addFriendSearchEmptyTips => 'This user does not exist';

  @override
  String get createGroupTeam => 'create group team';

  @override
  String get createAdvancedTeam => 'create advanced team';

  @override
  String get chatMessageNonsupportType => '[Nonsupport message type]';

  @override
  String get conversationEmpty => 'no chat';

  @override
  String get somebodyAitMe => '[somebody @ me]';

  @override
  String get robotSubConversation => '[Sub-conversation]';

  @override
  String get audioMessageType => '[Audio]';

  @override
  String get imageMessageType => '[Image]';

  @override
  String get videoMessageType => '[Video]';

  @override
  String get locationMessageType => '[Location]';

  @override
  String get fileMessageType => '[File]';

  @override
  String get notificationMessageType => '[Notification]';

  @override
  String get tipMessageType => '[Tip]';

  @override
  String get chatHistoryBrief => '[Chat history]';

  @override
  String get joinTeam => 'Join Team';

  @override
  String get joinTeamSearchHint => 'Please enter team Id';

  @override
  String get joinTeamSearchEmptyTips => 'This team does not exist';

  @override
  String get scanRobot => 'Scan';

  @override
  String get chatMessageBriefVideoCall => '[Video Call]';

  @override
  String get chatMessageBriefAudioCall => '[Voice Call]';

  @override
  String get muteTitle => 'Mute';

  @override
  String get cancelMuteTitle => 'Unmute';

  @override
  String get closeTitle => 'Close';

  @override
  String get saveTitle => 'Save';

  @override
  String get conversationGroupTitle => 'Conversation Groups';

  @override
  String get conversationGroupAll => 'All';

  @override
  String get conversationGroupAitMe => '@Me';

  @override
  String get conversationGroupUnread => 'Unread';

  @override
  String get conversationGroupVisible => 'Visible Groups';

  @override
  String get conversationGroupHidden => 'Hidden Groups';

  @override
  String get conversationGroupCreate => 'New Group';

  @override
  String get conversationGroupSetting => 'Group Settings';

  @override
  String get conversationGroupName => 'Group Name';

  @override
  String get conversationGroupNameHint => 'Enter group name';

  @override
  String get conversationGroupConversationList => 'Conversation List';

  @override
  String conversationGroupConversationCount(int count) {
    return 'Conversations ($count)';
  }

  @override
  String get conversationGroupAddConversation => 'Add Conversation';

  @override
  String get conversationGroupSearchHint => 'Search conversations';

  @override
  String get conversationGroupOperationFailed => 'Operation failed';

  @override
  String get conversationGroupLimit => 'Conversation group limit reached';

  @override
  String get conversationGroupPartialAddFailed =>
      'Some conversations failed to add';

  @override
  String get conversationGroupConversationNotExist =>
      'Conversation does not exist';

  @override
  String get conversationGroupConversationCountLimit =>
      'Conversation count in the group exceeded the limit';

  @override
  String get conversationGroupDeleteConfirmTitle => 'Delete Group';

  @override
  String get conversationGroupDeleteConfirmContent =>
      'Only the group relation will be deleted. Conversations remain.';

  @override
  String get conversationGroupConversationLimit => 'Conversation limit reached';

  @override
  String get conversationGroupJoinedLimit =>
      'This conversation has reached the group limit';

  @override
  String get conversationTimeCurrentYearFormat => 'MM-dd';

  @override
  String get conversationTimeOtherYearFormat => 'yyyy-MM-dd';

  @override
  String conversationGroupAddTitle(int selected, int max) {
    return 'Add Conversation($selected/$max)';
  }
}
