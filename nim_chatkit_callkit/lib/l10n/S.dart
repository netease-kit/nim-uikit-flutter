// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';

import 'chatCall_localization/chat_kit_call_client_localizations.dart';
import 'chatCall_localization/chat_kit_call_client_localizations_zh.dart';

class S {
  static const LocalizationsDelegate<ChatKitCallClientLocalizations> delegate =
      ChatKitCallClientLocalizations.delegate;

  static ChatKitCallClientLocalizations of([BuildContext? context]) {
    ChatKitCallClientLocalizations? localizations;
    if (context != null) {
      localizations = ChatKitCallClientLocalizations.of(context);
    }
    if (localizations == null) {
      var local = PlatformDispatcher.instance.locale;
      try {
        localizations = lookupChatKitCallClientLocalizations(local);
      } catch (e) {
        localizations = ChatKitCallClientLocalizationsZh();
      }
    }
    return localizations;
  }
}
