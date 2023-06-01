// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'team_localization/team_kit_client_localizations.dart';

class S {
  static const LocalizationsDelegate<TeamKitClientLocalizations> delegate =
      TeamKitClientLocalizations.delegate;

  static TeamKitClientLocalizations of(BuildContext? context) {
    TeamKitClientLocalizations? localizations;
    if (context != null) {
      localizations = TeamKitClientLocalizations.of(context);
    }
    if (localizations == null) {
      localizations = lookupTeamKitClientLocalizations(
          Locale.fromSubtags(languageCode: Intl.getCurrentLocale()));
    }
    return localizations;
  }
}
