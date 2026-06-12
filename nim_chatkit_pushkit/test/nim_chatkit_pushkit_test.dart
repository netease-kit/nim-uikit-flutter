// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit_pushkit/nim_chatkit_pushkit.dart';
import 'package:nim_chatkit_pushkit/nim_chatkit_pushkit_method_channel.dart';
import 'package:nim_chatkit_pushkit/nim_chatkit_pushkit_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNimChatkitPushkitPlatform
    with MockPlatformInterfaceMixin
    implements NimChatkitPushkitPlatform {
  @override
  Stream<PushKitMessage> get onNotificationClick =>
      const Stream<PushKitMessage>.empty();

  @override
  Future<void> initialize(PushKitConfig config) async {}

  @override
  Future<PushKitMessage?> getInitialNotification() async {
    return null;
  }

  @override
  Future<String?> getAndroidNotificationEntranceClassName() async {
    return 'com.example.MainActivity';
  }

  @override
  Future<String?> getAndroidPushAction() async {
    return 'com.example.push';
  }
}

void main() {
  final initialPlatform = NimChatkitPushkitPlatform.instance;

  test('$MethodChannelNimChatkitPushkit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNimChatkitPushkit>());
  });

  test('PushKitMessage parses session payload', () {
    final message = PushKitMessage.tryParse(<String, dynamic>{
      'sessionId': 'user1',
      'sessionType': 'p2p',
    });

    expect(message?.sessionId, 'user1');
    expect(message?.sessionType, 'p2p');
    expect(message?.hasSession, isTrue);
  });

  test('PushKit initializes through platform interface', () async {
    final fakePlatform = MockNimChatkitPushkitPlatform();
    NimChatkitPushkitPlatform.instance = fakePlatform;

    await PushKit.instance.init();

    expect(PushKit.instance.initialized, isTrue);
    await PushKit.instance.dispose();
    NimChatkitPushkitPlatform.instance = initialPlatform;
  });
}
