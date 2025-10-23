// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'demo_kit_client_localizations_en.dart';
import 'demo_kit_client_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of DemoKitClientLocalizations
/// returned by `DemoKitClientLocalizations.of(context)`.
///
/// Applications need to include `DemoKitClientLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'demo_localization/demo_kit_client_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: DemoKitClientLocalizations.localizationsDelegates,
///   supportedLocales: DemoKitClientLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the DemoKitClientLocalizations.supportedLocales
/// property.
abstract class DemoKitClientLocalizations {
  DemoKitClientLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static DemoKitClientLocalizations? of(BuildContext context) {
    return Localizations.of<DemoKitClientLocalizations>(
        context, DemoKitClientLocalizations);
  }

  static const LocalizationsDelegate<DemoKitClientLocalizations> delegate =
      _DemoKitClientLocalizationsDelegate();

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

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Netease IM'**
  String get appName;

  /// No description provided for @yunxinName.
  ///
  /// In en, this message translates to:
  /// **'Netease CommsEase'**
  String get yunxinName;

  /// No description provided for @yunxinDesc.
  ///
  /// In en, this message translates to:
  /// **'Stable instant messaging service'**
  String get yunxinDesc;

  /// No description provided for @welcomeButton.
  ///
  /// In en, this message translates to:
  /// **'register/login'**
  String get welcomeButton;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'message'**
  String get message;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'contact'**
  String get contact;

  /// No description provided for @mine.
  ///
  /// In en, this message translates to:
  /// **'mine'**
  String get mine;

  /// No description provided for @conversation.
  ///
  /// In en, this message translates to:
  /// **'conversation'**
  String get conversation;

  /// No description provided for @dataIsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get dataIsLoading;

  /// No description provided for @tabMineAccount.
  ///
  /// In en, this message translates to:
  /// **'Account:{account}'**
  String tabMineAccount(String account);

  /// No description provided for @mineCollect.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get mineCollect;

  /// No description provided for @mineAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get mineAbout;

  /// No description provided for @mineSetting.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get mineSetting;

  /// No description provided for @mineVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get mineVersion;

  /// No description provided for @mineProduct.
  ///
  /// In en, this message translates to:
  /// **'Product introduction'**
  String get mineProduct;

  /// No description provided for @userInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'User info'**
  String get userInfoTitle;

  /// No description provided for @userInfoAvatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get userInfoAvatar;

  /// No description provided for @userInfoAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get userInfoAccount;

  /// No description provided for @userInfoNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get userInfoNickname;

  /// No description provided for @userInfoSexual.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get userInfoSexual;

  /// No description provided for @userInfoBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get userInfoBirthday;

  /// No description provided for @userInfoPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get userInfoPhone;

  /// No description provided for @userInfoEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get userInfoEmail;

  /// No description provided for @userInfoSign.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get userInfoSign;

  /// No description provided for @actionCopySuccess.
  ///
  /// In en, this message translates to:
  /// **'Copy success!'**
  String get actionCopySuccess;

  /// No description provided for @sexualMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get sexualMale;

  /// No description provided for @sexualFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get sexualFemale;

  /// No description provided for @sexualUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get sexualUnknown;

  /// No description provided for @userInfoComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get userInfoComplete;

  /// No description provided for @requestFail.
  ///
  /// In en, this message translates to:
  /// **'Request fail'**
  String get requestFail;

  /// No description provided for @mineLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get mineLogout;

  /// No description provided for @logoutDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to log out of the current login account?'**
  String get logoutDialogContent;

  /// No description provided for @logoutDialogAgree.
  ///
  /// In en, this message translates to:
  /// **'YES'**
  String get logoutDialogAgree;

  /// No description provided for @logoutDialogDisagree.
  ///
  /// In en, this message translates to:
  /// **'NO'**
  String get logoutDialogDisagree;

  /// No description provided for @settingNotify.
  ///
  /// In en, this message translates to:
  /// **'Notify'**
  String get settingNotify;

  /// No description provided for @settingClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get settingClearCache;

  /// No description provided for @settingPlayMode.
  ///
  /// In en, this message translates to:
  /// **'Handset mode'**
  String get settingPlayMode;

  /// No description provided for @settingFilterNotify.
  ///
  /// In en, this message translates to:
  /// **'Filter notify'**
  String get settingFilterNotify;

  /// No description provided for @settingFriendDeleteMode.
  ///
  /// In en, this message translates to:
  /// **'Delete notes when deleting friends'**
  String get settingFriendDeleteMode;

  /// No description provided for @settingMessageReadMode.
  ///
  /// In en, this message translates to:
  /// **'Message read and unread function'**
  String get settingMessageReadMode;

  /// No description provided for @settingNotifyInfo.
  ///
  /// In en, this message translates to:
  /// **'New message notification'**
  String get settingNotifyInfo;

  /// No description provided for @settingNotifyMode.
  ///
  /// In en, this message translates to:
  /// **'Message reminder mode'**
  String get settingNotifyMode;

  /// No description provided for @settingNotifyModeRing.
  ///
  /// In en, this message translates to:
  /// **'Ring Mode'**
  String get settingNotifyModeRing;

  /// No description provided for @settingNotifyModeShake.
  ///
  /// In en, this message translates to:
  /// **'Vibration Mode'**
  String get settingNotifyModeShake;

  /// No description provided for @settingNotifyPush.
  ///
  /// In en, this message translates to:
  /// **'Push settings'**
  String get settingNotifyPush;

  /// No description provided for @settingNotifyPushSync.
  ///
  /// In en, this message translates to:
  /// **'Receive pushes synchronously on PC/Web'**
  String get settingNotifyPushSync;

  /// No description provided for @settingNotifyPushDetail.
  ///
  /// In en, this message translates to:
  /// **'Notification bar does not show message details'**
  String get settingNotifyPushDetail;

  /// No description provided for @clearMessage.
  ///
  /// In en, this message translates to:
  /// **'Clear all chat history'**
  String get clearMessage;

  /// No description provided for @clearSdkCache.
  ///
  /// In en, this message translates to:
  /// **'Clear SDK file cache'**
  String get clearSdkCache;

  /// No description provided for @clearMessageTips.
  ///
  /// In en, this message translates to:
  /// **'Chat history has been cleaned up'**
  String get clearMessageTips;

  /// No description provided for @cacheSizeText.
  ///
  /// In en, this message translates to:
  /// **'{size} M'**
  String cacheSizeText(String size);

  /// No description provided for @notUsable.
  ///
  /// In en, this message translates to:
  /// **'Feature not yet available'**
  String get notUsable;

  /// No description provided for @settingFail.
  ///
  /// In en, this message translates to:
  /// **'Setting failed'**
  String get settingFail;

  /// No description provided for @settingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Set successfully'**
  String get settingSuccess;

  /// No description provided for @customMessage.
  ///
  /// In en, this message translates to:
  /// **'[Custom Message]'**
  String get customMessage;

  /// No description provided for @localConversation.
  ///
  /// In en, this message translates to:
  /// **'Local Conversation'**
  String get localConversation;

  /// No description provided for @settingAndResetTips.
  ///
  /// In en, this message translates to:
  /// **'The setting succeeds and takes effect after the restart'**
  String get settingAndResetTips;

  /// No description provided for @swindleTips.
  ///
  /// In en, this message translates to:
  /// **'For test only. Beware of money transfer, lottery winnings & strange call scams.'**
  String get swindleTips;

  /// No description provided for @aiStreamMode.
  ///
  /// In en, this message translates to:
  /// **'AI Stream Mode'**
  String get aiStreamMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @kickedOff.
  ///
  /// In en, this message translates to:
  /// **'Kicked Off'**
  String get kickedOff;
}

class _DemoKitClientLocalizationsDelegate
    extends LocalizationsDelegate<DemoKitClientLocalizations> {
  const _DemoKitClientLocalizationsDelegate();

  @override
  Future<DemoKitClientLocalizations> load(Locale locale) {
    return SynchronousFuture<DemoKitClientLocalizations>(
        lookupDemoKitClientLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_DemoKitClientLocalizationsDelegate old) => false;
}

DemoKitClientLocalizations lookupDemoKitClientLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return DemoKitClientLocalizationsEn();
    case 'zh':
      return DemoKitClientLocalizationsZh();
  }

  throw FlutterError(
      'DemoKitClientLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
