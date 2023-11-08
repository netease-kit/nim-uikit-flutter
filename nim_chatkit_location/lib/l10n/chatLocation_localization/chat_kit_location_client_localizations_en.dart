// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'chat_kit_location_client_localizations.dart';

/// The translations for English (`en`).
class ChatKitLocationClientLocalizationsEn
    extends ChatKitLocationClientLocalizations {
  ChatKitLocationClientLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get messageCancel => 'Cancel';

  @override
  String get chatMessageSend => 'Send';

  @override
  String get chatMessageAMapNotFound => 'ALi Map not found';

  @override
  String get chatMessageTencentMapNotFound => 'Tencent Map not found';

  @override
  String get chatMessageAMap => 'ALi Map';

  @override
  String get chatMessageTencentMap => 'Tencent Map';
}
