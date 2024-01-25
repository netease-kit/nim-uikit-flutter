// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'team_kit_client_localizations_en.dart';
import 'team_kit_client_localizations_zh.dart';

/// Callers can lookup localized strings with an instance of TeamKitClientLocalizations
/// returned by `TeamKitClientLocalizations.of(context)`.
///
/// Applications need to include `TeamKitClientLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'team_localization/team_kit_client_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: TeamKitClientLocalizations.localizationsDelegates,
///   supportedLocales: TeamKitClientLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the TeamKitClientLocalizations.supportedLocales
/// property.
abstract class TeamKitClientLocalizations {
  TeamKitClientLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static TeamKitClientLocalizations? of(BuildContext context) {
    return Localizations.of<TeamKitClientLocalizations>(
        context, TeamKitClientLocalizations);
  }

  static const LocalizationsDelegate<TeamKitClientLocalizations> delegate =
      _TeamKitClientLocalizationsDelegate();

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

  /// No description provided for @teamSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get teamSettingTitle;

  /// No description provided for @teamInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Team info'**
  String get teamInfoTitle;

  /// No description provided for @teamGroupInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Team Group info'**
  String get teamGroupInfoTitle;

  /// No description provided for @teamNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get teamNameTitle;

  /// No description provided for @teamGroupNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Team Group name'**
  String get teamGroupNameTitle;

  /// No description provided for @teamMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Team member'**
  String get teamMemberTitle;

  /// No description provided for @teamGroupMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Team Group member'**
  String get teamGroupMemberTitle;

  /// No description provided for @teamIconTitle.
  ///
  /// In en, this message translates to:
  /// **'Team icon'**
  String get teamIconTitle;

  /// No description provided for @teamGroupIconTitle.
  ///
  /// In en, this message translates to:
  /// **'Team Group icon'**
  String get teamGroupIconTitle;

  /// No description provided for @teamIntroduceTitle.
  ///
  /// In en, this message translates to:
  /// **'Team introduce'**
  String get teamIntroduceTitle;

  /// No description provided for @teamMyNicknameTitle.
  ///
  /// In en, this message translates to:
  /// **'My nickname in Team'**
  String get teamMyNicknameTitle;

  /// No description provided for @teamMark.
  ///
  /// In en, this message translates to:
  /// **'Mark'**
  String get teamMark;

  /// No description provided for @teamHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get teamHistory;

  /// No description provided for @teamMessageTip.
  ///
  /// In en, this message translates to:
  /// **'Open message notice'**
  String get teamMessageTip;

  /// No description provided for @teamSessionPin.
  ///
  /// In en, this message translates to:
  /// **'Set session top'**
  String get teamSessionPin;

  /// No description provided for @teamMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get teamMute;

  /// No description provided for @teamInviteOtherPermission.
  ///
  /// In en, this message translates to:
  /// **'Invite others permission'**
  String get teamInviteOtherPermission;

  /// No description provided for @teamUpdateInfoPermission.
  ///
  /// In en, this message translates to:
  /// **'Permission to modify Team info'**
  String get teamUpdateInfoPermission;

  /// No description provided for @teamNeedAgreedWhenBeInvitedPermission.
  ///
  /// In en, this message translates to:
  /// **'Whether the invitee\'s consent is required'**
  String get teamNeedAgreedWhenBeInvitedPermission;

  /// No description provided for @teamAdvancedDismiss.
  ///
  /// In en, this message translates to:
  /// **'Disband the Team chat'**
  String get teamAdvancedDismiss;

  /// No description provided for @teamAdvancedQuit.
  ///
  /// In en, this message translates to:
  /// **'Exit Team chat'**
  String get teamAdvancedQuit;

  /// No description provided for @teamGroupQuit.
  ///
  /// In en, this message translates to:
  /// **'Exit Team Group chat'**
  String get teamGroupQuit;

  /// No description provided for @teamDefaultIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose default icon'**
  String get teamDefaultIcon;

  /// No description provided for @teamAllMember.
  ///
  /// In en, this message translates to:
  /// **'All member'**
  String get teamAllMember;

  /// No description provided for @teamOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get teamOwner;

  /// No description provided for @teamUpdateIcon.
  ///
  /// In en, this message translates to:
  /// **'Modify avatar'**
  String get teamUpdateIcon;

  /// No description provided for @teamCancel.
  ///
  /// In en, this message translates to:
  /// **'cancel'**
  String get teamCancel;

  /// No description provided for @teamConfirm.
  ///
  /// In en, this message translates to:
  /// **'confirm'**
  String get teamConfirm;

  /// No description provided for @teamQuitAdvancedTeamQuery.
  ///
  /// In en, this message translates to:
  /// **'Do you want to leave the Team chat?'**
  String get teamQuitAdvancedTeamQuery;

  /// No description provided for @teamQuitGroupTeamQuery.
  ///
  /// In en, this message translates to:
  /// **'Do you want to leave the Team Group chat?'**
  String get teamQuitGroupTeamQuery;

  /// No description provided for @teamDismissAdvancedTeamQuery.
  ///
  /// In en, this message translates to:
  /// **'Disband the Team chat?'**
  String get teamDismissAdvancedTeamQuery;

  /// No description provided for @teamSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get teamSave;

  /// No description provided for @teamSearchMember.
  ///
  /// In en, this message translates to:
  /// **'Search Member'**
  String get teamSearchMember;

  /// No description provided for @teamNoPermission.
  ///
  /// In en, this message translates to:
  /// **'No Permission'**
  String get teamNoPermission;

  /// No description provided for @teamNameMustNotEmpty.
  ///
  /// In en, this message translates to:
  /// **'Team name must not empty'**
  String get teamNameMustNotEmpty;

  /// No description provided for @teamManage.
  ///
  /// In en, this message translates to:
  /// **'Team Manage'**
  String get teamManage;

  /// No description provided for @teamAitPermission.
  ///
  /// In en, this message translates to:
  /// **'Who can @all'**
  String get teamAitPermission;

  /// No description provided for @teamManager.
  ///
  /// In en, this message translates to:
  /// **'Team Manager'**
  String get teamManager;

  /// No description provided for @teamAddManagers.
  ///
  /// In en, this message translates to:
  /// **'Add Managers'**
  String get teamAddManagers;

  /// No description provided for @teamOwnerManager.
  ///
  /// In en, this message translates to:
  /// **'Owner Add Manager'**
  String get teamOwnerManager;

  /// No description provided for @teamMemberRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get teamMemberRemove;

  /// No description provided for @teamRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sure to remove'**
  String get teamRemoveConfirm;

  /// No description provided for @teamRemoveConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'This Member will lost Manager Promise after remove'**
  String get teamRemoveConfirmContent;

  /// No description provided for @teamSettingFailed.
  ///
  /// In en, this message translates to:
  /// **'Setting failed'**
  String get teamSettingFailed;

  /// No description provided for @teamMsgAitAllPrivilegeIsAll.
  ///
  /// In en, this message translates to:
  /// **'@All privilege update to all'**
  String get teamMsgAitAllPrivilegeIsAll;

  /// No description provided for @teamMsgAitAllPrivilegeIsOwner.
  ///
  /// In en, this message translates to:
  /// **'@All privilege update to owner and manager'**
  String get teamMsgAitAllPrivilegeIsOwner;

  /// No description provided for @teamManagers.
  ///
  /// In en, this message translates to:
  /// **'Managers'**
  String get teamManagers;

  /// No description provided for @teamSelectMembers.
  ///
  /// In en, this message translates to:
  /// **'Select members'**
  String get teamSelectMembers;

  /// No description provided for @teamManagerLimit.
  ///
  /// In en, this message translates to:
  /// **'The number of managers cannot exceed {number}'**
  String teamManagerLimit(String number);

  /// No description provided for @teamNoOperatePermission.
  ///
  /// In en, this message translates to:
  /// **'No operate permission'**
  String get teamNoOperatePermission;

  /// No description provided for @teamManagerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No manager'**
  String get teamManagerEmpty;

  /// No description provided for @teamMemberRemoveContent.
  ///
  /// In en, this message translates to:
  /// **'This member will leave this team after remove'**
  String get teamMemberRemoveContent;

  /// No description provided for @teamMemberRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Remove failed'**
  String get teamMemberRemoveFailed;

  /// No description provided for @teamManagerManagers.
  ///
  /// In en, this message translates to:
  /// **'Manager managers'**
  String get teamManagerManagers;

  /// No description provided for @teamMemberSelect.
  ///
  /// In en, this message translates to:
  /// **'Select member'**
  String get teamMemberSelect;

  /// No description provided for @teamPermissionDeny.
  ///
  /// In en, this message translates to:
  /// **'you have no permission'**
  String get teamPermissionDeny;

  /// No description provided for @teamManagerRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Remove failed'**
  String get teamManagerRemoveFailed;

  /// No description provided for @teamMemberEmpty.
  ///
  /// In en, this message translates to:
  /// **'No member'**
  String get teamMemberEmpty;
}

class _TeamKitClientLocalizationsDelegate
    extends LocalizationsDelegate<TeamKitClientLocalizations> {
  const _TeamKitClientLocalizationsDelegate();

  @override
  Future<TeamKitClientLocalizations> load(Locale locale) {
    return SynchronousFuture<TeamKitClientLocalizations>(
        lookupTeamKitClientLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_TeamKitClientLocalizationsDelegate old) => false;
}

TeamKitClientLocalizations lookupTeamKitClientLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return TeamKitClientLocalizationsEn();
    case 'zh':
      return TeamKitClientLocalizationsZh();
  }

  throw FlutterError(
      'TeamKitClientLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
