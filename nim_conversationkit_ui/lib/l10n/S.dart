// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';

import 'conversation_localization/conversation_kit_client_localizations.dart';
import 'conversation_localization/conversation_kit_client_localizations_zh.dart';

class S {
  static const LocalizationsDelegate<ConversationKitClientLocalizations>
      delegate = ConversationKitClientLocalizations.delegate;

  static ConversationKitClientLocalizations of([BuildContext? context]) {
    ConversationKitClientLocalizations? localizations;
    if (context != null) {
      localizations = ConversationKitClientLocalizations.of(context);
    }
    if (localizations == null) {
      var local = PlatformDispatcher.instance.locale;
      try {
        localizations = lookupConversationKitClientLocalizations(local);
      } catch (e) {
        localizations = ConversationKitClientLocalizationsZh();
      }
    }
    return localizations;
  }
}
