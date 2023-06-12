// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nim_teamkit_ui/l10n/team_localization/team_kit_client_localizations_zh.dart';

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
      var local = PlatformDispatcher.instance.locale;
      try {
        localizations = lookupTeamKitClientLocalizations(local);
      } catch (e) {
        localizations = TeamKitClientLocalizationsZh();
      }
    }
    return localizations;
  }
}
