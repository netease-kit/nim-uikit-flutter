// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'contact_kit_client_localizations_en.dart';
import 'contact_kit_client_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ContactKitClientLocalizations
/// returned by `ContactKitClientLocalizations.of(context)`.
///
/// Applications need to include `ContactKitClientLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'contact_localization/contact_kit_client_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ContactKitClientLocalizations.localizationsDelegates,
///   supportedLocales: ContactKitClientLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the ContactKitClientLocalizations.supportedLocales
/// property.
abstract class ContactKitClientLocalizations {
  ContactKitClientLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ContactKitClientLocalizations? of(BuildContext context) {
    return Localizations.of<ContactKitClientLocalizations>(
        context, ContactKitClientLocalizations);
  }

  static const LocalizationsDelegate<ContactKitClientLocalizations> delegate =
      _ContactKitClientLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @contactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactTitle;

  /// No description provided for @contactNick.
  ///
  /// In en, this message translates to:
  /// **'Nick:{userName}'**
  String contactNick(String userName);

  /// No description provided for @contactAccount.
  ///
  /// In en, this message translates to:
  /// **'Account:{userName}'**
  String contactAccount(String userName);

  /// No description provided for @contactVerifyMessage.
  ///
  /// In en, this message translates to:
  /// **'Verify Message'**
  String get contactVerifyMessage;

  /// No description provided for @contactBlackList.
  ///
  /// In en, this message translates to:
  /// **'Black List'**
  String get contactBlackList;

  /// No description provided for @contactTeam.
  ///
  /// In en, this message translates to:
  /// **'My Team'**
  String get contactTeam;

  /// No description provided for @contactAIUserList.
  ///
  /// In en, this message translates to:
  /// **'My AI User'**
  String get contactAIUserList;

  /// No description provided for @contactComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get contactComment;

  /// No description provided for @contactBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get contactBirthday;

  /// No description provided for @contactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get contactPhone;

  /// No description provided for @contactMail.
  ///
  /// In en, this message translates to:
  /// **'E-Mail'**
  String get contactMail;

  /// No description provided for @contactSignature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get contactSignature;

  /// No description provided for @contactMessageNotice.
  ///
  /// In en, this message translates to:
  /// **'MessageNotice'**
  String get contactMessageNotice;

  /// No description provided for @contactAddToBlacklist.
  ///
  /// In en, this message translates to:
  /// **'Add Black List'**
  String get contactAddToBlacklist;

  /// No description provided for @contactChat.
  ///
  /// In en, this message translates to:
  /// **'Go Chat'**
  String get contactChat;

  /// No description provided for @contactDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Friend'**
  String get contactDelete;

  /// No description provided for @contactDeleteSpecificFriend.
  ///
  /// In en, this message translates to:
  /// **'Delete\"{userName}\"'**
  String contactDeleteSpecificFriend(String userName);

  /// No description provided for @contactCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get contactCancel;

  /// No description provided for @contactAddFriend.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get contactAddFriend;

  /// No description provided for @contactYouWillNeverReceiveAnyMessageFromThosePerson.
  ///
  /// In en, this message translates to:
  /// **'You will never receive any message from those person'**
  String get contactYouWillNeverReceiveAnyMessageFromThosePerson;

  /// No description provided for @contactRelease.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get contactRelease;

  /// No description provided for @contactUserSelector.
  ///
  /// In en, this message translates to:
  /// **'User Selector'**
  String get contactUserSelector;

  /// No description provided for @contactSureWithCount.
  ///
  /// In en, this message translates to:
  /// **'Done({count})'**
  String contactSureWithCount(String count);

  /// No description provided for @contactSelectAsMost.
  ///
  /// In en, this message translates to:
  /// **'Selected too many users'**
  String get contactSelectAsMost;

  /// No description provided for @contactClean.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get contactClean;

  /// No description provided for @contactAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get contactAccept;

  /// No description provided for @contactAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get contactAccepted;

  /// No description provided for @contactRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get contactRejected;

  /// No description provided for @contactIgnored.
  ///
  /// In en, this message translates to:
  /// **'Ignored'**
  String get contactIgnored;

  /// No description provided for @contactExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get contactExpired;

  /// No description provided for @contactReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get contactReject;

  /// No description provided for @contactApplyFrom.
  ///
  /// In en, this message translates to:
  /// **'Friend apply {user}'**
  String contactApplyFrom(String user);

  /// No description provided for @contactSomeoneInviteYourJoinTeam.
  ///
  /// In en, this message translates to:
  /// **'{user} had invited you to join {team}'**
  String contactSomeoneInviteYourJoinTeam(String user, String team);

  /// No description provided for @contactSomeAcceptYourApply.
  ///
  /// In en, this message translates to:
  /// **'{user} had accepted your apply'**
  String contactSomeAcceptYourApply(String user);

  /// No description provided for @contactSomeRejectYourApply.
  ///
  /// In en, this message translates to:
  /// **'{user} had rejected your apply'**
  String contactSomeRejectYourApply(String user);

  /// No description provided for @contactSomeAcceptYourInvitation.
  ///
  /// In en, this message translates to:
  /// **'{user} had accepted your invitation'**
  String contactSomeAcceptYourInvitation(String user);

  /// No description provided for @contactSomeRejectYourInvitation.
  ///
  /// In en, this message translates to:
  /// **'{user} had rejected your invitation'**
  String contactSomeRejectYourInvitation(String user);

  /// No description provided for @contactSomeAddYourAsFriend.
  ///
  /// In en, this message translates to:
  /// **'{user} have add you as friend'**
  String contactSomeAddYourAsFriend(String user);

  /// No description provided for @contactSomeoneApplyJoinTeam.
  ///
  /// In en, this message translates to:
  /// **'{user} apply join {team}'**
  String contactSomeoneApplyJoinTeam(String user, String team);

  /// No description provided for @contactSomeRejectYourTeamApply.
  ///
  /// In en, this message translates to:
  /// **'{user} rejected your team apply'**
  String contactSomeRejectYourTeamApply(String user);

  /// No description provided for @contactSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get contactSave;

  /// No description provided for @contactHaveSendApply.
  ///
  /// In en, this message translates to:
  /// **'Apply have been sent'**
  String get contactHaveSendApply;

  /// No description provided for @systemVerifyMessageEmpty.
  ///
  /// In en, this message translates to:
  /// **'Verify Message Empty'**
  String get systemVerifyMessageEmpty;

  /// No description provided for @verifyAgreeMessageText.
  ///
  /// In en, this message translates to:
  /// **'Nice to meet you，let\'s chat'**
  String get verifyAgreeMessageText;

  /// No description provided for @verifyMessageHaveBeenHandled.
  ///
  /// In en, this message translates to:
  /// **'Already done on other devices'**
  String get verifyMessageHaveBeenHandled;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Handle Fail:{code}'**
  String operationFailed(String code);

  /// No description provided for @contactSelectEmptyTip.
  ///
  /// In en, this message translates to:
  /// **'No Member'**
  String get contactSelectEmptyTip;

  /// No description provided for @contactFriendEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Friend'**
  String get contactFriendEmpty;

  /// No description provided for @myFriend.
  ///
  /// In en, this message translates to:
  /// **'MY FRIENDS'**
  String get myFriend;

  /// No description provided for @aiUsers.
  ///
  /// In en, this message translates to:
  /// **'AI USERS'**
  String get aiUsers;

  /// No description provided for @aiUsersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No AIUser'**
  String get aiUsersEmpty;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @friend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friend;

  /// No description provided for @teamJoinApply.
  ///
  /// In en, this message translates to:
  /// **'Apply to join:{teamName}'**
  String teamJoinApply(String teamName);

  /// No description provided for @teamJoinApplyReject.
  ///
  /// In en, this message translates to:
  /// **'Reject your Apply join:{teamName}'**
  String teamJoinApplyReject(String teamName);

  /// No description provided for @teamJoinInvitation.
  ///
  /// In en, this message translates to:
  /// **'Invite you join:{teamName}'**
  String teamJoinInvitation(String teamName);

  /// No description provided for @teamJoinInvitationReject.
  ///
  /// In en, this message translates to:
  /// **'Reject your Invitation for :{teamName}'**
  String teamJoinInvitationReject(String teamName);

  /// No description provided for @teamMemberLimited.
  ///
  /// In en, this message translates to:
  /// **'Team member limited.'**
  String get teamMemberLimited;

  /// No description provided for @teamMemberAlreadyExist.
  ///
  /// In en, this message translates to:
  /// **'Team member already exist'**
  String get teamMemberAlreadyExist;

  /// No description provided for @teamNotExist.
  ///
  /// In en, this message translates to:
  /// **'Team have Dismissed'**
  String get teamNotExist;

  /// No description provided for @teamVerifyNoPermission.
  ///
  /// In en, this message translates to:
  /// **'Have No Permission'**
  String get teamVerifyNoPermission;
}

class _ContactKitClientLocalizationsDelegate
    extends LocalizationsDelegate<ContactKitClientLocalizations> {
  const _ContactKitClientLocalizationsDelegate();

  @override
  Future<ContactKitClientLocalizations> load(Locale locale) {
    return SynchronousFuture<ContactKitClientLocalizations>(
        lookupContactKitClientLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_ContactKitClientLocalizationsDelegate old) => false;
}

ContactKitClientLocalizations lookupContactKitClientLocalizations(
    Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ContactKitClientLocalizationsEn();
    case 'zh':
      return ContactKitClientLocalizationsZh();
  }

  throw FlutterError(
      'ContactKitClientLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
