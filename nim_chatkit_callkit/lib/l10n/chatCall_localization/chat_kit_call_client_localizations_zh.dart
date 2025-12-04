// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'chat_kit_call_client_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class ChatKitCallClientLocalizationsZh extends ChatKitCallClientLocalizations {
  ChatKitCallClientLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get messageCancel => '取消';

  @override
  String get chatMessageSend => '发送';

  @override
  String get chatMessageCallTitle => '音视频通话';

  @override
  String get chatMessageVideoCallAction => '视频通话';

  @override
  String get chatMessageAudioCallAction => '语音通话';

  @override
  String get chatMessageBriefVideoCall => '[视频通话]';

  @override
  String get chatMessageBriefAudioCall => '[语音通话]';

  @override
  String get chatMessageAudioCallText => '[语音通话]';

  @override
  String get chatMessageVideoCallText => '[视频通话]';

  @override
  String get chatMessageCallCancel => '已取消';

  @override
  String get chatMessageCallRefused => '已拒绝';

  @override
  String get chatMessageCallTimeout => '未接听';

  @override
  String get chatMessageCallBusy => '忙线未接听';

  @override
  String get chatMessageCallCompleted => '通话时长';

  @override
  String get chatBeenBlockByOthers => '您已被对方拉黑';
}
