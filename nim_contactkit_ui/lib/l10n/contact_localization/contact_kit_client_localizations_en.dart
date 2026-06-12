// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'contact_kit_client_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ContactKitClientLocalizationsEn extends ContactKitClientLocalizations {
  ContactKitClientLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get contactTitle => 'Contacts';

  @override
  String contactNick(String userName) {
    return 'Nick:$userName';
  }

  @override
  String contactAccount(String userName) {
    return 'Account:$userName';
  }

  @override
  String get contactVerifyMessage => 'Verify Message';

  @override
  String get contactBlackList => 'Black List';

  @override
  String get contactTeam => 'My Team';

  @override
  String get contactAIUserList => 'My AI User';

  @override
  String get contactComment => 'Comment';

  @override
  String get contactBirthday => 'Birthday';

  @override
  String get contactPhone => 'Phone';

  @override
  String get contactMail => 'E-Mail';

  @override
  String get contactSignature => 'Signature';

  @override
  String get contactMessageNotice => 'MessageNotice';

  @override
  String get contactAddToBlacklist => 'Add Black List';

  @override
  String get contactChat => 'Go Chat';

  @override
  String get contactDelete => 'Delete Friend';

  @override
  String contactDeleteSpecificFriend(String userName) {
    return 'Delete\"$userName\"';
  }

  @override
  String get contactCancel => 'Cancel';

  @override
  String get contactAddFriend => 'Add Friend';

  @override
  String get contactYouWillNeverReceiveAnyMessageFromThosePerson =>
      'You will never receive any message from those person';

  @override
  String get contactRelease => 'Release';

  @override
  String get contactUserSelector => 'User Selector';

  @override
  String contactSureWithCount(String count) {
    return 'Done($count)';
  }

  @override
  String get contactSelectAsMost => 'Selected too many users';

  @override
  String get contactClean => 'Clean';

  @override
  String get contactAccept => 'Accept';

  @override
  String get contactAccepted => 'Accepted';

  @override
  String get contactRejected => 'Rejected';

  @override
  String get contactIgnored => 'Ignored';

  @override
  String get contactExpired => 'Expired';

  @override
  String get contactReject => 'Reject';

  @override
  String contactApplyFrom(String user) {
    return 'Friend apply $user';
  }

  @override
  String contactSomeoneInviteYourJoinTeam(String user, String team) {
    return '$user had invited you to join $team';
  }

  @override
  String contactSomeAcceptYourApply(String user) {
    return '$user had accepted your apply';
  }

  @override
  String contactSomeRejectYourApply(String user) {
    return '$user had rejected your apply';
  }

  @override
  String contactSomeAcceptYourInvitation(String user) {
    return '$user had accepted your invitation';
  }

  @override
  String contactSomeRejectYourInvitation(String user) {
    return '$user had rejected your invitation';
  }

  @override
  String contactSomeAddYourAsFriend(String user) {
    return '$user have add you as friend';
  }

  @override
  String contactSomeoneApplyJoinTeam(String user, String team) {
    return '$user apply join $team';
  }

  @override
  String contactSomeRejectYourTeamApply(String user) {
    return '$user rejected your team apply';
  }

  @override
  String get contactSave => 'Save';

  @override
  String get contactHaveSendApply => 'Apply have been sent';

  @override
  String get systemVerifyMessageEmpty => 'Verify Message Empty';

  @override
  String get verifyAgreeMessageText => 'Nice to meet you，let\'s chat';

  @override
  String get verifyMessageHaveBeenHandled => 'Already done on other devices';

  @override
  String operationFailed(String code) {
    return 'Handle Fail:$code';
  }

  @override
  String get contactSelectEmptyTip => 'No Member';

  @override
  String get contactSelectedMembers => 'Selected';

  @override
  String get contactFriendEmpty => 'No Friend';

  @override
  String get myFriend => 'MY FRIENDS';

  @override
  String get aiUsers => 'AI USERS';

  @override
  String get aiUsersEmpty => 'No AIUser';

  @override
  String get team => 'Team';

  @override
  String get friend => 'Friend';

  @override
  String teamJoinApply(String teamName) {
    return 'Apply to join:$teamName';
  }

  @override
  String teamJoinApplyReject(String teamName) {
    return 'Reject your Apply join:$teamName';
  }

  @override
  String teamJoinInvitation(String teamName) {
    return 'Invite you join:$teamName';
  }

  @override
  String teamJoinInvitationReject(String teamName) {
    return 'Reject your Invitation for :$teamName';
  }

  @override
  String get teamMemberLimited => 'Team member limited.';

  @override
  String get teamMemberAlreadyExist => 'Team member already exist';

  @override
  String get teamNotExist => 'Team have Dismissed';

  @override
  String get teamVerifyNoPermission => 'Have No Permission';

  @override
  String get contactMyRobot => 'My Robot';

  @override
  String get contactRobotEmpty => 'No robots';

  @override
  String get contactRobotEmptyHint => 'Tap the top-right button to create';

  @override
  String get contactRobotCreate => 'Create Robot';

  @override
  String get contactRobotEdit => 'Edit';

  @override
  String get contactRobotName => 'Nickname';

  @override
  String get contactRobotAvatar => 'Avatar';

  @override
  String get contactRobotSendMessage => 'Chat';

  @override
  String get contactRobotTitle => 'Robot';

  @override
  String get contactRobotEditPageTitle => 'Edit Robot';

  @override
  String get contactRobotViewConfig => 'View Config';

  @override
  String get contactRobotRefreshToken => 'Refresh Token';

  @override
  String get contactRobotDelete => 'Delete Robot';

  @override
  String get contactRobotConfigTitle => 'Config String';

  @override
  String get contactRobotConfigLabel => 'Config String:';

  @override
  String get contactRobotCopy => 'Copy';

  @override
  String get contactRobotConfigNotice => 'Keep it safe and do not share it.';

  @override
  String get contactRobotRefreshConfirmTitle => 'Refresh Token?';

  @override
  String get contactRobotRefreshConfirmContent =>
      'After refreshing, the old token becomes invalid immediately and connected robots need reconfiguration.';

  @override
  String get contactRobotDeleteConfirmTitle => 'Delete Robot?';

  @override
  String get contactRobotDeleteConfirmContent =>
      'After deletion, connected robots will be disconnected and need to be reconfigured.';

  @override
  String get contactRobotBind => 'Bind Robot';

  @override
  String get contactRobotScan => 'Scan';

  @override
  String get contactRobotBindNew => 'Create New Robot';

  @override
  String get contactRobotBindSelectHint => 'Please select a robot to bind:';

  @override
  String get contactRobotBindExistingHint => 'Or select an existing robot:';

  @override
  String get contactRobotBindConfirmTitle => 'Bind this account?';

  @override
  String get contactRobotBindConfirmContent =>
      'After binding, robots already configured with this account will be disconnected and need reconfiguration.';

  @override
  String get contactRobotLimitTitle => 'Robot limit reached';

  @override
  String get contactRobotLimitContent =>
      'You have already created 10 robots. Please select an existing robot or delete one first.';

  @override
  String get contactRobotLimitToast =>
      'Robot limit reached. Select an existing robot or delete one first.';

  @override
  String get contactRobotSelectExisting => 'Select Existing Robot';

  @override
  String get contactRobotGoDelete => 'Delete Robot First';

  @override
  String get contactRobotNameRequired => 'Nickname cannot be empty';

  @override
  String get contactRobotConfigCopied => 'Config copied';

  @override
  String get contactRobotInvalidQrCode => 'Invalid QR code';

  @override
  String get contactRobotScanFailed => 'Scan failed, please try again';

  @override
  String get contactRobotQrCodeExpired => 'QR code expired';

  @override
  String get contactRobotQrCodeBound => 'QR code already bound';

  @override
  String get contactRobotConfirm => 'Confirm';

  @override
  String get contactRobotQrCode => 'QR Code';

  @override
  String get contactRobotManualInputHint => 'Paste QR content';

  @override
  String get contactRobotBindingSuccess => 'Binding successful';
}
