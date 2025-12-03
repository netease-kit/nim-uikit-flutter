// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'chat_kit_call_client_localizations_en.dart';
import 'chat_kit_call_client_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ChatKitCallClientLocalizations
/// returned by `ChatKitCallClientLocalizations.of(context)`.
///
/// Applications need to include `ChatKitCallClientLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'chatCall_localization/chat_kit_call_client_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ChatKitCallClientLocalizations.localizationsDelegates,
///   supportedLocales: ChatKitCallClientLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the ChatKitCallClientLocalizations.supportedLocales
/// property.
abstract class ChatKitCallClientLocalizations {
  ChatKitCallClientLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ChatKitCallClientLocalizations? of(BuildContext context) {
    return Localizations.of<ChatKitCallClientLocalizations>(
        context, ChatKitCallClientLocalizations);
  }

  static const LocalizationsDelegate<ChatKitCallClientLocalizations> delegate =
      _ChatKitCallClientLocalizationsDelegate();

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

  /// No description provided for @messageCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get messageCancel;

  /// No description provided for @chatMessageSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatMessageSend;

  /// No description provided for @chatMessageCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get chatMessageCallTitle;

  /// No description provided for @chatMessageVideoCallAction.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get chatMessageVideoCallAction;

  /// No description provided for @chatMessageAudioCallAction.
  ///
  /// In en, this message translates to:
  /// **'Voice Call'**
  String get chatMessageAudioCallAction;

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

  /// No description provided for @chatMessageAudioCallText.
  ///
  /// In en, this message translates to:
  /// **'[Voice Call]'**
  String get chatMessageAudioCallText;

  /// No description provided for @chatMessageVideoCallText.
  ///
  /// In en, this message translates to:
  /// **'[Video Call]'**
  String get chatMessageVideoCallText;

  /// No description provided for @chatMessageCallCancel.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get chatMessageCallCancel;

  /// No description provided for @chatMessageCallRefused.
  ///
  /// In en, this message translates to:
  /// **'Refused'**
  String get chatMessageCallRefused;

  /// No description provided for @chatMessageCallTimeout.
  ///
  /// In en, this message translates to:
  /// **'Time Out'**
  String get chatMessageCallTimeout;

  /// No description provided for @chatMessageCallBusy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get chatMessageCallBusy;

  /// No description provided for @chatMessageCallCompleted.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get chatMessageCallCompleted;

  /// No description provided for @chatBeenBlockByOthers.
  ///
  /// In en, this message translates to:
  /// **'You have been blocked.'**
  String get chatBeenBlockByOthers;
}

class _ChatKitCallClientLocalizationsDelegate
    extends LocalizationsDelegate<ChatKitCallClientLocalizations> {
  const _ChatKitCallClientLocalizationsDelegate();

  @override
  Future<ChatKitCallClientLocalizations> load(Locale locale) {
    return SynchronousFuture<ChatKitCallClientLocalizations>(
        lookupChatKitCallClientLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_ChatKitCallClientLocalizationsDelegate old) => false;
}

ChatKitCallClientLocalizations lookupChatKitCallClientLocalizations(
    Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ChatKitCallClientLocalizationsEn();
    case 'zh':
      return ChatKitCallClientLocalizationsZh();
  }

  throw FlutterError(
      'ChatKitCallClientLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
