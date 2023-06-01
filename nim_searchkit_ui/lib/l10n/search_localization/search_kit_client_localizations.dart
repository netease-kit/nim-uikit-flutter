// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'search_kit_client_localizations_en.dart';
import 'search_kit_client_localizations_zh.dart';

/// Callers can lookup localized strings with an instance of SearchKitClientLocalizations
/// returned by `SearchKitClientLocalizations.of(context)`.
///
/// Applications need to include `SearchKitClientLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'search_localization/search_kit_client_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: SearchKitClientLocalizations.localizationsDelegates,
///   supportedLocales: SearchKitClientLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the SearchKitClientLocalizations.supportedLocales
/// property.
abstract class SearchKitClientLocalizations {
  SearchKitClientLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static SearchKitClientLocalizations? of(BuildContext context) {
    return Localizations.of<SearchKitClientLocalizations>(
        context, SearchKitClientLocalizations);
  }

  static const LocalizationsDelegate<SearchKitClientLocalizations> delegate =
      _SearchKitClientLocalizationsDelegate();

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

  /// No description provided for @searchSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchSearch;

  /// No description provided for @searchSearchHit.
  ///
  /// In en, this message translates to:
  /// **'Please input your key word'**
  String get searchSearchHit;

  /// No description provided for @searchSearchFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get searchSearchFriend;

  /// No description provided for @searchSearchNormalTeam.
  ///
  /// In en, this message translates to:
  /// **'Normal team'**
  String get searchSearchNormalTeam;

  /// No description provided for @searchSearchAdvanceTeam.
  ///
  /// In en, this message translates to:
  /// **'Advance Team'**
  String get searchSearchAdvanceTeam;

  /// No description provided for @searchEmptyTips.
  ///
  /// In en, this message translates to:
  /// **'This user not exist'**
  String get searchEmptyTips;
}

class _SearchKitClientLocalizationsDelegate
    extends LocalizationsDelegate<SearchKitClientLocalizations> {
  const _SearchKitClientLocalizationsDelegate();

  @override
  Future<SearchKitClientLocalizations> load(Locale locale) {
    return SynchronousFuture<SearchKitClientLocalizations>(
        lookupSearchKitClientLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SearchKitClientLocalizationsDelegate old) => false;
}

SearchKitClientLocalizations lookupSearchKitClientLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SearchKitClientLocalizationsEn();
    case 'zh':
      return SearchKitClientLocalizationsZh();
  }

  throw FlutterError(
      'SearchKitClientLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
