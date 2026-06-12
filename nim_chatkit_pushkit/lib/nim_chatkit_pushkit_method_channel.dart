// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'nim_chatkit_pushkit.dart';
import 'nim_chatkit_pushkit_platform_interface.dart';

class MethodChannelNimChatkitPushkit extends NimChatkitPushkitPlatform {
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel(
    'nim_chatkit_pushkit',
  );

  StreamController<PushKitMessage>? _clickController;

  @override
  Stream<PushKitMessage> get onNotificationClick {
    _clickController ??= StreamController<PushKitMessage>.broadcast(
      onListen: () {
        methodChannel.setMethodCallHandler(_handleMethodCall);
      },
      onCancel: () {
        if (!_clickController!.hasListener) {
          methodChannel.setMethodCallHandler(null);
        }
      },
    );
    return _clickController!.stream;
  }

  @override
  Future<void> initialize(PushKitConfig config) {
    return methodChannel.invokeMethod<void>('initialize', config.toMap());
  }

  @override
  Future<PushKitMessage?> getInitialNotification() async {
    final value = await methodChannel.invokeMapMethod<String, dynamic>(
      'getInitialNotification',
    );
    if (value == null || value.isEmpty) return null;
    return PushKitMessage.fromMap(value);
  }

  @override
  Future<String?> getAndroidNotificationEntranceClassName() {
    return methodChannel.invokeMethod<String>(
      'getAndroidNotificationEntranceClassName',
    );
  }

  @override
  Future<String?> getAndroidPushAction() {
    return methodChannel.invokeMethod<String>('getAndroidPushAction');
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method != 'onNotificationClick' || call.arguments is! Map) {
      return null;
    }
    final args = (call.arguments as Map).map(
      (key, value) => MapEntry(key.toString(), value),
    );
    _clickController?.add(PushKitMessage.fromMap(args));
    return null;
  }
}
