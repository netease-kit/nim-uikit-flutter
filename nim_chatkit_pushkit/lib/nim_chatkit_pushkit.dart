// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

library nim_chatkit_pushkit;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting, kIsWeb;
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:netease_corekit/report/xkit_report.dart';

import 'nim_chatkit_pushkit_platform_interface.dart';

const String pushKitSessionIdKey = 'sessionId';
const String pushKitSessionTypeKey = 'sessionType';

/// Called when a notification click is delivered to Dart.
typedef PushKitClickHandler = void Function(PushKitMessage message);

/// Optional application parser for custom notification payloads.
typedef PushKitPayloadParser = PushKitMessage? Function(
    Map<String, dynamic> payload);

/// Native click source normalized by PushKit.
enum PushKitSource { androidOnline, androidOffline, iosApns, custom, unknown }

/// Normalized notification click event.
class PushKitMessage {
  /// Target session id, for example account id for p2p or team id for team.
  final String? sessionId;

  /// Target session type. Built-in values are `p2p` and `team`.
  final String? sessionType;

  /// Optional conversation id when the payload already contains one.
  final String? conversationId;

  /// The original payload received from native code.
  final Map<String, dynamic> rawPayload;

  /// Native source of the event.
  final PushKitSource source;

  const PushKitMessage({
    this.sessionId,
    this.sessionType,
    this.conversationId,
    this.rawPayload = const <String, dynamic>{},
    this.source = PushKitSource.unknown,
  });

  bool get hasSession =>
      sessionId != null &&
      sessionId!.isNotEmpty &&
      sessionType != null &&
      sessionType!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      pushKitSessionIdKey: sessionId,
      pushKitSessionTypeKey: sessionType,
      'conversationId': conversationId,
      'source': _sourceToString(source),
      'rawPayload': rawPayload,
    };
  }

  static PushKitMessage fromMap(Map<String, dynamic> map) {
    final raw = map['rawPayload'];
    return PushKitMessage(
      sessionId: _readString(map[pushKitSessionIdKey]),
      sessionType: _normalizeSessionType(map[pushKitSessionTypeKey]),
      conversationId: _readString(map['conversationId']),
      rawPayload: raw is Map
          ? raw.map((key, value) => MapEntry(key.toString(), value))
          : Map<String, dynamic>.from(map),
      source: _sourceFromString(_readString(map['source'])),
    );
  }

  static PushKitMessage? tryParse(
    Map<String, dynamic> payload, {
    PushKitSource source = PushKitSource.unknown,
  }) {
    final sessionId = _readString(payload[pushKitSessionIdKey]) ??
        _readString(payload['targetId']) ??
        _readString(payload['accountId']) ??
        _readString(payload['teamId']);
    final sessionType = _normalizeSessionType(payload[pushKitSessionTypeKey]) ??
        _normalizeSessionType(payload['conversationType']);
    final conversationId = _readString(payload['conversationId']);
    if ((sessionId == null || sessionId.isEmpty) &&
        (conversationId == null || conversationId.isEmpty)) {
      return null;
    }
    return PushKitMessage(
      sessionId: sessionId,
      sessionType: sessionType,
      conversationId: conversationId,
      rawPayload: Map<String, dynamic>.from(payload),
      source: source,
    );
  }
}

/// PushKit initialization config.
class PushKitConfig {
  /// Optional custom Android notification click action.
  ///
  /// If not set, PushKit uses `${applicationId}.push`.
  final String? androidPushAction;

  /// Optional custom Android notification entrance activity class name.
  final String? androidNotificationEntranceClassName;

  /// Request APNS permission and register remote notifications on iOS.
  final bool registerIOSRemoteNotifications;

  /// Custom payload parsers. The first non-null result wins.
  final List<PushKitPayloadParser> customParsers;

  const PushKitConfig({
    this.androidPushAction,
    this.androidNotificationEntranceClassName,
    this.registerIOSRemoteNotifications = true,
    this.customParsers = const <PushKitPayloadParser>[],
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'androidPushAction': androidPushAction,
      'androidNotificationEntranceClassName':
          androidNotificationEntranceClassName,
      'registerIOSRemoteNotifications': registerIOSRemoteNotifications,
    };
  }
}

/// Flutter PushKit facade for NIM ChatKit notification integration.
class PushKit {
  PushKit._();

  static final PushKit instance = PushKit._();

  PushKitConfig _config = const PushKitConfig();
  bool _initialized = false;

  final StreamController<PushKitMessage> _clickController =
      StreamController<PushKitMessage>.broadcast();
  StreamSubscription<PushKitMessage>? _nativeSubscription;

  /// Stream of notification click events after [init].
  Stream<PushKitMessage> get onNotificationClick => _clickController.stream;

  /// Initializes the plugin and starts native click forwarding.
  Future<void> init({
    PushKitConfig config = const PushKitConfig(),
    PushKitClickHandler? onClick,
  }) async {
    _config = config;
    await NimChatkitPushkitPlatform.instance.initialize(config);
    _nativeSubscription ??= NimChatkitPushkitPlatform
        .instance.onNotificationClick
        .listen(_handleNativeMessage);
    if (onClick != null) {
      onNotificationClick.listen(onClick);
    }
    _initialized = true;
    XKitReporter().register(
      moduleName: 'ChatPushKit',
      moduleVersion: '10.8.0',
    );
  }

  /// Returns and clears a notification click that launched the app.
  Future<PushKitMessage?> getInitialNotification() async {
    final message =
        await NimChatkitPushkitPlatform.instance.getInitialNotification();
    return _parseMessage(message);
  }

  /// Queries the native Android activity class name that can receive
  /// notification click intents.
  Future<String?> getAndroidNotificationEntranceClassName() {
    return NimChatkitPushkitPlatform.instance
        .getAndroidNotificationEntranceClassName();
  }

  /// Queries the Android push action used by the default payload builder.
  Future<String?> getAndroidPushAction() {
    return NimChatkitPushkitPlatform.instance.getAndroidPushAction();
  }

  /// Builds the NIM status bar notification config for Android.
  Future<NIMStatusBarNotificationConfig> buildDefaultAndroidNotificationConfig({
    NIMStatusBarNotificationConfig? baseConfig,
  }) async {
    final entranceClassName = _config.androidNotificationEntranceClassName ??
        await getAndroidNotificationEntranceClassName();
    final config = baseConfig ?? NIMStatusBarNotificationConfig();
    config.notificationEntranceClassName = entranceClassName;
    config.notificationExtraType = NIMNotificationExtraType.jsonArrStr;
    return config;
  }

  /// Builds a NIM push payload compatible with PushKit click parsing.
  Future<Map<String, dynamic>> buildDefaultPushPayload(
    NIMMessage message,
    String conversationId,
  ) async {
    final payload = <String, dynamic>{};
    final typeResult = await NimCore.instance.conversationIdUtil
        .conversationType(conversationId);

    String? sessionId;
    String? sessionType;
    if (typeResult.data == NIMConversationType.p2p) {
      sessionId =
          message.senderId ?? getIt<IMLoginService>().userInfo?.accountId;
      sessionType = 'p2p';
    } else if (typeResult.data == NIMConversationType.team) {
      sessionId = ChatKitUtils.getConversationTargetId(conversationId);
      sessionType = 'team';
    }

    payload[pushKitSessionIdKey] = sessionId;
    payload[pushKitSessionTypeKey] = sessionType;
    payload['senderId'] = message.senderId;
    payload['conversationId'] = conversationId;

    if (!kIsWeb && Platform.isAndroid) {
      final pushAction =
          _config.androidPushAction ?? await getAndroidPushAction();
      if (pushAction != null && pushAction.isNotEmpty) {
        payload['hwField'] = <String, dynamic>{
          'click_action': <String, dynamic>{'type': 1, 'action': pushAction},
          'androidConfig': <String, dynamic>{
            'category': 'IM',
            'data': jsonEncode(<String, dynamic>{
              pushKitSessionIdKey: sessionId,
              pushKitSessionTypeKey: sessionType,
            }),
          },
        };
      }

      final entranceClassName = _config.androidNotificationEntranceClassName ??
          await getAndroidNotificationEntranceClassName();
      if (entranceClassName != null && entranceClassName.isNotEmpty) {
        payload['oppoField'] = <String, dynamic>{
          'click_action_type': 4,
          'click_action_activity': entranceClassName,
          'action_parameters': <String, dynamic>{
            pushKitSessionIdKey: sessionId,
            pushKitSessionTypeKey: sessionType,
          },
        };
      }
    }

    payload['vivoField'] = <String, dynamic>{'pushMode': 1};
    return payload;
  }

  Future<void> dispose() async {
    await _nativeSubscription?.cancel();
    _nativeSubscription = null;
    _initialized = false;
  }

  void _handleNativeMessage(PushKitMessage message) {
    final parsed = _parseMessage(message);
    if (parsed != null && !_clickController.isClosed) {
      _clickController.add(parsed);
    }
  }

  PushKitMessage? _parseMessage(PushKitMessage? message) {
    if (message == null) return null;
    for (final parser in _config.customParsers) {
      final parsed = parser(message.rawPayload);
      if (parsed != null) {
        return _normalizeP2PSession(parsed);
      }
    }
    final parsed = message.hasSession
        ? message
        : PushKitMessage.tryParse(message.rawPayload, source: message.source);
    return _normalizeP2PSession(parsed);
  }

  @visibleForTesting
  bool get initialized => _initialized;
}

PushKitMessage? _normalizeP2PSession(PushKitMessage? message) {
  if (message == null || message.sessionType != 'p2p') {
    return message;
  }
  final currentAccount = getIt.isRegistered<IMLoginService>()
      ? getIt<IMLoginService>().userInfo?.accountId
      : null;
  if (currentAccount == null ||
      currentAccount.isEmpty ||
      message.sessionId != currentAccount) {
    return message;
  }

  final senderId = _readSenderId(message.rawPayload, currentAccount) ??
      _readPeerFromConversationId(message.conversationId, currentAccount);
  if (senderId == null || senderId.isEmpty || senderId == currentAccount) {
    return message;
  }
  return PushKitMessage(
    sessionId: senderId,
    sessionType: message.sessionType,
    conversationId: message.conversationId,
    rawPayload: message.rawPayload,
    source: message.source,
  );
}

String? _readSenderId(Map<String, dynamic> payload, String currentAccount) {
  final candidates = <String>[
    'senderId',
    'fromAccount',
    'fromAccId',
    'fromAccid',
    'fromAccountId',
    'from',
  ];
  for (final key in candidates) {
    final value = _readString(payload[key]);
    if (value != null && value.isNotEmpty && value != currentAccount) {
      return value;
    }
  }

  for (final value in payload.values) {
    final nested = _parseNestedPayload(value);
    if (nested == null) {
      continue;
    }
    final senderId = _readSenderId(nested, currentAccount);
    if (senderId != null && senderId.isNotEmpty) {
      return senderId;
    }
  }
  return null;
}

Map<String, dynamic>? _parseNestedPayload(dynamic value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      return null;
    }
  }
  return null;
}

String? _readPeerFromConversationId(
  String? conversationId,
  String currentAccount,
) {
  if (conversationId == null || conversationId.isEmpty) {
    return null;
  }
  final components = conversationId.split(ChatKitUtils.CONVERSATION_ID_SPLIT);
  if (components.length != 3 || components[1] != '1') {
    return null;
  }
  if (components[0].isNotEmpty && components[0] != currentAccount) {
    return components[0];
  }
  if (components[2].isNotEmpty && components[2] != currentAccount) {
    return components[2];
  }
  return null;
}

String? _readString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

String? _normalizeSessionType(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    if (value == '0' || value.toLowerCase() == 'p2p') return 'p2p';
    if (value == '1' || value == '2' || value.toLowerCase() == 'team') {
      return 'team';
    }
    return value;
  }
  if (value is int) {
    if (value == 0) return 'p2p';
    if (value == 1) return 'team';
  }
  return value.toString();
}

PushKitSource _sourceFromString(String? source) {
  switch (source) {
    case 'androidOnline':
      return PushKitSource.androidOnline;
    case 'androidOffline':
      return PushKitSource.androidOffline;
    case 'iosApns':
      return PushKitSource.iosApns;
    case 'custom':
      return PushKitSource.custom;
    default:
      return PushKitSource.unknown;
  }
}

String _sourceToString(PushKitSource source) {
  switch (source) {
    case PushKitSource.androidOnline:
      return 'androidOnline';
    case PushKitSource.androidOffline:
      return 'androidOffline';
    case PushKitSource.iosApns:
      return 'iosApns';
    case PushKitSource.custom:
      return 'custom';
    case PushKitSource.unknown:
      return 'unknown';
  }
}
