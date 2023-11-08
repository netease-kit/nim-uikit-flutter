// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';

import 'chatLocation_localization/chat_kit_location_client_localizations.dart';
import 'chatLocation_localization/chat_kit_location_client_localizations_zh.dart';

class S {
  static const LocalizationsDelegate<ChatKitLocationClientLocalizations>
      delegate = ChatKitLocationClientLocalizations.delegate;

  static ChatKitLocationClientLocalizations of([BuildContext? context]) {
    ChatKitLocationClientLocalizations? localizations;
    if (context != null) {
      localizations = ChatKitLocationClientLocalizations.of(context);
    }
    if (localizations == null) {
      var local = PlatformDispatcher.instance.locale;
      try {
        localizations = lookupChatKitLocationClientLocalizations(local);
      } catch (e) {
        localizations = ChatKitLocationClientLocalizationsZh();
      }
    }
    return localizations;
  }
}
