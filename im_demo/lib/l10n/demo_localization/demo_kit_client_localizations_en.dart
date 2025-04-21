// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.



import 'demo_kit_client_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class DemoKitClientLocalizationsEn extends DemoKitClientLocalizations {
  DemoKitClientLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Netease IM';

  @override
  String get yunxinName => 'Netease CommsEase';

  @override
  String get yunxinDesc => 'Stable instant messaging service';

  @override
  String get welcomeButton => 'register/login';

  @override
  String get message => 'message';

  @override
  String get contact => 'contact';

  @override
  String get mine => 'mine';

  @override
  String get conversation => 'conversation';

  @override
  String get dataIsLoading => 'Loading...';

  @override
  String tabMineAccount(String account) {
    return 'Account:$account';
  }

  @override
  String get mineCollect => 'Collect';

  @override
  String get mineAbout => 'About';

  @override
  String get mineSetting => 'Setting';

  @override
  String get mineVersion => 'Version';

  @override
  String get mineProduct => 'Product introduction';

  @override
  String get userInfoTitle => 'User info';

  @override
  String get userInfoAvatar => 'Avatar';

  @override
  String get userInfoAccount => 'Account';

  @override
  String get userInfoNickname => 'Nickname';

  @override
  String get userInfoSexual => 'Sex';

  @override
  String get userInfoBirthday => 'Birthday';

  @override
  String get userInfoPhone => 'Phone';

  @override
  String get userInfoEmail => 'Email';

  @override
  String get userInfoSign => 'Signature';

  @override
  String get actionCopySuccess => 'Copy success!';

  @override
  String get sexualMale => 'Male';

  @override
  String get sexualFemale => 'Female';

  @override
  String get sexualUnknown => 'Unknown';

  @override
  String get userInfoComplete => 'Complete';

  @override
  String get requestFail => 'Request fail';

  @override
  String get mineLogout => 'Logout';

  @override
  String get logoutDialogContent => 'Are you sure to log out of the current login account?';

  @override
  String get logoutDialogAgree => 'YES';

  @override
  String get logoutDialogDisagree => 'NO';

  @override
  String get settingNotify => 'Notify';

  @override
  String get settingClearCache => 'Clear cache';

  @override
  String get settingPlayMode => 'Handset mode';

  @override
  String get settingFilterNotify => 'Filter notify';

  @override
  String get settingFriendDeleteMode => 'Delete notes when deleting friends';

  @override
  String get settingMessageReadMode => 'Message read and unread function';

  @override
  String get settingNotifyInfo => 'New message notification';

  @override
  String get settingNotifyMode => 'Message reminder mode';

  @override
  String get settingNotifyModeRing => 'Ring Mode';

  @override
  String get settingNotifyModeShake => 'Vibration Mode';

  @override
  String get settingNotifyPush => 'Push settings';

  @override
  String get settingNotifyPushSync => 'Receive pushes synchronously on PC/Web';

  @override
  String get settingNotifyPushDetail => 'Notification bar does not show message details';

  @override
  String get clearMessage => 'Clear all chat history';

  @override
  String get clearSdkCache => 'Clear SDK file cache';

  @override
  String get clearMessageTips => 'Chat history has been cleaned up';

  @override
  String cacheSizeText(String size) {
    return '$size M';
  }

  @override
  String get notUsable => 'Feature not yet available';

  @override
  String get settingFail => 'Setting failed';

  @override
  String get settingSuccess => 'Set successfully';

  @override
  String get customMessage => '[Custom Message]';

  @override
  String get localConversation => 'Local Conversation';

  @override
  String get settingAndResetTips => 'The setting succeeds and takes effect after the restart';

  @override
  String get swindleTips => 'For test only. Beware of money transfer, lottery winnings & strange call scams.';
}
