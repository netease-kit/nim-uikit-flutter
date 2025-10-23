// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'conversation_kit_client_localizations_en.dart';
import 'conversation_kit_client_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ConversationKitClientLocalizations
/// returned by `ConversationKitClientLocalizations.of(context)`.
///
/// Applications need to include `ConversationKitClientLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'conversation_localization/conversation_kit_client_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ConversationKitClientLocalizations.localizationsDelegates,
///   supportedLocales: ConversationKitClientLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the ConversationKitClientLocalizations.supportedLocales
/// property.
abstract class ConversationKitClientLocalizations {
  ConversationKitClientLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ConversationKitClientLocalizations? of(BuildContext context) {
    return Localizations.of<ConversationKitClientLocalizations>(
        context, ConversationKitClientLocalizations);
  }

  static const LocalizationsDelegate<ConversationKitClientLocalizations>
      delegate = _ConversationKitClientLocalizationsDelegate();

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

  /// No description provided for @conversationTitle.
  ///
  /// In en, this message translates to:
  /// **'CommsEase IM'**
  String get conversationTitle;

  /// No description provided for @createAdvancedTeamSuccess.
  ///
  /// In en, this message translates to:
  /// **'create advanced team success'**
  String get createAdvancedTeamSuccess;

  /// No description provided for @stickTitle.
  ///
  /// In en, this message translates to:
  /// **'Stick'**
  String get stickTitle;

  /// No description provided for @cancelStickTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel stick'**
  String get cancelStickTitle;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTitle;

  /// No description provided for @recentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent chat'**
  String get recentTitle;

  /// No description provided for @cancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelTitle;

  /// No description provided for @sureTitle.
  ///
  /// In en, this message translates to:
  /// **'Sure'**
  String get sureTitle;

  /// No description provided for @sureCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Sure({size})'**
  String sureCountTitle(int size);

  /// No description provided for @conversationNetworkErrorTip.
  ///
  /// In en, this message translates to:
  /// **'The current network is unavailable, please check your network settings.'**
  String get conversationNetworkErrorTip;

  /// No description provided for @addFriend.
  ///
  /// In en, this message translates to:
  /// **'add friends'**
  String get addFriend;

  /// No description provided for @addFriendSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Please enter account'**
  String get addFriendSearchHint;

  /// No description provided for @addFriendSearchEmptyTips.
  ///
  /// In en, this message translates to:
  /// **'This user does not exist'**
  String get addFriendSearchEmptyTips;

  /// No description provided for @createGroupTeam.
  ///
  /// In en, this message translates to:
  /// **'create group team'**
  String get createGroupTeam;

  /// No description provided for @createAdvancedTeam.
  ///
  /// In en, this message translates to:
  /// **'create advanced team'**
  String get createAdvancedTeam;

  /// No description provided for @chatMessageNonsupportType.
  ///
  /// In en, this message translates to:
  /// **'[Nonsupport message type]'**
  String get chatMessageNonsupportType;

  /// No description provided for @conversationEmpty.
  ///
  /// In en, this message translates to:
  /// **'no chat'**
  String get conversationEmpty;

  /// No description provided for @somebodyAitMe.
  ///
  /// In en, this message translates to:
  /// **'[somebody @ me]'**
  String get somebodyAitMe;

  /// No description provided for @audioMessageType.
  ///
  /// In en, this message translates to:
  /// **'[Audio]'**
  String get audioMessageType;

  /// No description provided for @imageMessageType.
  ///
  /// In en, this message translates to:
  /// **'[Image]'**
  String get imageMessageType;

  /// No description provided for @videoMessageType.
  ///
  /// In en, this message translates to:
  /// **'[Video]'**
  String get videoMessageType;

  /// No description provided for @locationMessageType.
  ///
  /// In en, this message translates to:
  /// **'[Location]'**
  String get locationMessageType;

  /// No description provided for @fileMessageType.
  ///
  /// In en, this message translates to:
  /// **'[File]'**
  String get fileMessageType;

  /// No description provided for @notificationMessageType.
  ///
  /// In en, this message translates to:
  /// **'[Notification]'**
  String get notificationMessageType;

  /// No description provided for @tipMessageType.
  ///
  /// In en, this message translates to:
  /// **'[Tip]'**
  String get tipMessageType;

  /// No description provided for @chatHistoryBrief.
  ///
  /// In en, this message translates to:
  /// **'[Chat history]'**
  String get chatHistoryBrief;

  /// No description provided for @joinTeam.
  ///
  /// In en, this message translates to:
  /// **'Join Team'**
  String get joinTeam;

  /// No description provided for @joinTeamSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Please enter team Id'**
  String get joinTeamSearchHint;

  /// No description provided for @joinTeamSearchEmptyTips.
  ///
  /// In en, this message translates to:
  /// **'This team does not exist'**
  String get joinTeamSearchEmptyTips;

  /// No description provided for @chatMessageBriefVideoCall.
  ///
  /// In en, this message translates to:
  /// **'[Video Call]'**
  String get chatMessageBriefVideoCall;

  /// No description provided for @chatMessageBriefAudioCall.
  ///
  /// In en, this message translates to:
  /// **'[Voice Call]'**
  String get chatMessageBriefAudioCall;
}

class _ConversationKitClientLocalizationsDelegate
    extends LocalizationsDelegate<ConversationKitClientLocalizations> {
  const _ConversationKitClientLocalizationsDelegate();

  @override
  Future<ConversationKitClientLocalizations> load(Locale locale) {
    return SynchronousFuture<ConversationKitClientLocalizations>(
        lookupConversationKitClientLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_ConversationKitClientLocalizationsDelegate old) => false;
}

ConversationKitClientLocalizations lookupConversationKitClientLocalizations(
    Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ConversationKitClientLocalizationsEn();
    case 'zh':
      return ConversationKitClientLocalizationsZh();
  }

  throw FlutterError(
      'ConversationKitClientLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
