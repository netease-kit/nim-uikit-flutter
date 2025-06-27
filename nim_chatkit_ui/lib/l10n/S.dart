// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:netease_common_ui/base/default_language.dart';
import 'package:nim_chatkit_ui/l10n/chat_localization/chat_kit_client_localizations_en.dart';

import 'chat_localization/chat_kit_client_localizations.dart';
import 'chat_localization/chat_kit_client_localizations_zh.dart';

class S {
  static const LocalizationsDelegate<ChatKitClientLocalizations> delegate =
      ChatKitClientLocalizations.delegate;

  static ChatKitClientLocalizations of([BuildContext? context]) {
    ChatKitClientLocalizations? localizations;
    if (CommonUIDefaultLanguage.commonDefaultLanguage == languageZh) {
      return ChatKitClientLocalizationsZh();
    }
    if (CommonUIDefaultLanguage.commonDefaultLanguage == languageEn) {
      return ChatKitClientLocalizationsEn();
    }
    if (context != null) {
      localizations = ChatKitClientLocalizations.of(context);
    }
    if (localizations == null) {
      var local = PlatformDispatcher.instance.locale;
      try {
        localizations = lookupChatKitClientLocalizations(local);
      } catch (e) {
        localizations = ChatKitClientLocalizationsZh();
      }
    }
    return localizations;
  }
}
