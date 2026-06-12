// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nim_chatkit_pushkit.dart';
import 'nim_chatkit_pushkit_method_channel.dart';

abstract class NimChatkitPushkitPlatform extends PlatformInterface {
  NimChatkitPushkitPlatform() : super(token: _token);

  static final Object _token = Object();

  static NimChatkitPushkitPlatform _instance = MethodChannelNimChatkitPushkit();

  static NimChatkitPushkitPlatform get instance => _instance;

  static set instance(NimChatkitPushkitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<PushKitMessage> get onNotificationClick {
    throw UnimplementedError('onNotificationClick has not been implemented.');
  }

  Future<void> initialize(PushKitConfig config) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<PushKitMessage?> getInitialNotification() {
    throw UnimplementedError(
      'getInitialNotification() has not been implemented.',
    );
  }

  Future<String?> getAndroidNotificationEntranceClassName() {
    throw UnimplementedError(
      'getAndroidNotificationEntranceClassName() has not been implemented.',
    );
  }

  Future<String?> getAndroidPushAction() {
    throw UnimplementedError(
      'getAndroidPushAction() has not been implemented.',
    );
  }
}
