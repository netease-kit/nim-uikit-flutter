// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'chat_kit_call_client_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ChatKitCallClientLocalizationsEn extends ChatKitCallClientLocalizations {
  ChatKitCallClientLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get messageCancel => 'Cancel';

  @override
  String get chatMessageSend => 'Send';

  @override
  String get chatMessageCallTitle => 'Call';

  @override
  String get chatMessageVideoCallAction => 'Video Call';

  @override
  String get chatMessageAudioCallAction => 'Voice Call';

  @override
  String get chatMessageBriefVideoCall => '[Video Call]';

  @override
  String get chatMessageBriefAudioCall => '[Voice Call]';

  @override
  String get chatMessageAudioCallText => '[Voice Call]';

  @override
  String get chatMessageVideoCallText => '[Video Call]';

  @override
  String get chatMessageCallCancel => 'Canceled';

  @override
  String get chatMessageCallRefused => 'Refused';

  @override
  String get chatMessageCallTimeout => 'Time Out';

  @override
  String get chatMessageCallBusy => 'Busy';

  @override
  String get chatMessageCallCompleted => 'Call';

  @override
  String get chatBeenBlockByOthers => 'You have been blocked.';
}
