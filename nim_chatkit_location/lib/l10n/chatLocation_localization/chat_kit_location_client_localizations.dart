// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'chat_kit_location_client_localizations_en.dart';
import 'chat_kit_location_client_localizations_zh.dart';

/// Callers can lookup localized strings with an instance of ChatKitLocationClientLocalizations
/// returned by `ChatKitLocationClientLocalizations.of(context)`.
///
/// Applications need to include `ChatKitLocationClientLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'chatLocation_localization/chat_kit_location_client_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ChatKitLocationClientLocalizations.localizationsDelegates,
///   supportedLocales: ChatKitLocationClientLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the ChatKitLocationClientLocalizations.supportedLocales
/// property.
abstract class ChatKitLocationClientLocalizations {
  ChatKitLocationClientLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ChatKitLocationClientLocalizations? of(BuildContext context) {
    return Localizations.of<ChatKitLocationClientLocalizations>(
        context, ChatKitLocationClientLocalizations);
  }

  static const LocalizationsDelegate<ChatKitLocationClientLocalizations>
      delegate = _ChatKitLocationClientLocalizationsDelegate();

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

  /// No description provided for @chatMessageAMapNotFound.
  ///
  /// In en, this message translates to:
  /// **'ALi Map not found'**
  String get chatMessageAMapNotFound;

  /// No description provided for @chatMessageTencentMapNotFound.
  ///
  /// In en, this message translates to:
  /// **'Tencent Map not found'**
  String get chatMessageTencentMapNotFound;

  /// No description provided for @chatMessageAMap.
  ///
  /// In en, this message translates to:
  /// **'ALi Map'**
  String get chatMessageAMap;

  /// No description provided for @chatMessageTencentMap.
  ///
  /// In en, this message translates to:
  /// **'Tencent Map'**
  String get chatMessageTencentMap;

  /// No description provided for @locationDeniedTips.
  ///
  /// In en, this message translates to:
  /// **'Please give your location permission'**
  String get locationDeniedTips;

  /// No description provided for @locationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationTitle;
}

class _ChatKitLocationClientLocalizationsDelegate
    extends LocalizationsDelegate<ChatKitLocationClientLocalizations> {
  const _ChatKitLocationClientLocalizationsDelegate();

  @override
  Future<ChatKitLocationClientLocalizations> load(Locale locale) {
    return SynchronousFuture<ChatKitLocationClientLocalizations>(
        lookupChatKitLocationClientLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_ChatKitLocationClientLocalizationsDelegate old) => false;
}

ChatKitLocationClientLocalizations lookupChatKitLocationClientLocalizations(
    Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ChatKitLocationClientLocalizationsEn();
    case 'zh':
      return ChatKitLocationClientLocalizationsZh();
  }

  throw FlutterError(
      'ChatKitLocationClientLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
