// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'contact_localization/contact_kit_client_localizations.dart';

class S {
  static const LocalizationsDelegate<ContactKitClientLocalizations> delegate =
      ContactKitClientLocalizations.delegate;

  static ContactKitClientLocalizations of(BuildContext? context) {
    ContactKitClientLocalizations? localizations;
    if (context != null) {
      localizations = ContactKitClientLocalizations.of(context);
    }
    if (localizations == null) {
      localizations = lookupContactKitClientLocalizations(
          Locale.fromSubtags(languageCode: Intl.getCurrentLocale()));
    }
    return localizations;
  }
}
