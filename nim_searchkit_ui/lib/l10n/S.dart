// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:netease_common_ui/base/default_language.dart';
import 'package:nim_searchkit_ui/l10n/search_localization/search_kit_client_localizations_en.dart';
import 'package:nim_searchkit_ui/l10n/search_localization/search_kit_client_localizations_zh.dart';
import 'search_localization/search_kit_client_localizations.dart';

class S {
  static const LocalizationsDelegate<SearchKitClientLocalizations> delegate =
      SearchKitClientLocalizations.delegate;

  static SearchKitClientLocalizations of(BuildContext? context) {
    SearchKitClientLocalizations? localizations;
    if (CommonUIDefaultLanguage.commonDefaultLanguage == languageZh) {
      return SearchKitClientLocalizationsZh();
    }
    if (CommonUIDefaultLanguage.commonDefaultLanguage == languageEn) {
      return SearchKitClientLocalizationsEn();
    }
    if (context != null) {
      localizations = SearchKitClientLocalizations.of(context);
    }
    if (localizations == null) {
      var local = PlatformDispatcher.instance.locale;
      try {
        localizations = lookupSearchKitClientLocalizations(local);
      } catch (e) {
        localizations = SearchKitClientLocalizationsEn();
      }
    }
    return localizations;
  }
}
