// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'demo_localization/demo_kit_client_localizations.dart';

class S {
  static const LocalizationsDelegate<DemoKitClientLocalizations> delegate =
      DemoKitClientLocalizations.delegate;

  static DemoKitClientLocalizations of([BuildContext? context]) {
    DemoKitClientLocalizations? localizations;
    if (context != null) {
      localizations = DemoKitClientLocalizations.of(context);
    }
    if (localizations == null) {
      localizations = lookupDemoKitClientLocalizations(
          Locale.fromSubtags(languageCode: Intl.getCurrentLocale()));
    }
    return localizations;
  }
}
