// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'chat_localization/chat_kit_client_localizations.dart';

class S {
  static const LocalizationsDelegate<ChatKitClientLocalizations> delegate =
      ChatKitClientLocalizations.delegate;

  static ChatKitClientLocalizations of([BuildContext? context]) {
    ChatKitClientLocalizations? localizations;
    if (context != null) {
      localizations = ChatKitClientLocalizations.of(context);
    }
    if (localizations == null) {
      Intl.defaultLocale = 'zh';
      localizations = lookupChatKitClientLocalizations(
          Locale.fromSubtags(languageCode: Intl.getCurrentLocale()));
    }
    return localizations;
  }
}
