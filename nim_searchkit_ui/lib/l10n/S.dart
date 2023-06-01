// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'search_localization/search_kit_client_localizations.dart';

class S {
  static const LocalizationsDelegate<SearchKitClientLocalizations> delegate =
      SearchKitClientLocalizations.delegate;

  static SearchKitClientLocalizations of(BuildContext? context) {
    SearchKitClientLocalizations? localizations;
    if (context != null) {
      localizations = SearchKitClientLocalizations.of(context);
    }
    if (localizations == null) {
      localizations = lookupSearchKitClientLocalizations(
          Locale.fromSubtags(languageCode: Intl.getCurrentLocale()));
    }
    return localizations;
  }
}
