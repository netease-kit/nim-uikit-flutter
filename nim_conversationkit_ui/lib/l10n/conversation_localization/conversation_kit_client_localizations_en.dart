// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

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
}
