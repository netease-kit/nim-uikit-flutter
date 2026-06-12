// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit_pushkit/nim_chatkit_pushkit.dart';
import 'package:nim_chatkit_pushkit/nim_chatkit_pushkit_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelNimChatkitPushkit();
  const channel = MethodChannel('nim_chatkit_pushkit');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'initialize':
          return null;
        case 'getInitialNotification':
          return <String, dynamic>{
            'sessionId': 'team1',
            'sessionType': 'team',
            'source': 'androidOffline',
            'rawPayload': <String, dynamic>{'sessionId': 'team1'},
          };
        case 'getAndroidNotificationEntranceClassName':
          return 'com.example.MainActivity';
        case 'getAndroidPushAction':
          return 'com.example.push';
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('initialize delegates to native channel', () async {
    await platform.initialize(const PushKitConfig());
  });

  test('getInitialNotification parses native map', () async {
    final message = await platform.getInitialNotification();

    expect(message?.sessionId, 'team1');
    expect(message?.sessionType, 'team');
    expect(message?.source, PushKitSource.androidOffline);
  });

  test('queries Android defaults', () async {
    expect(
      await platform.getAndroidNotificationEntranceClassName(),
      'com.example.MainActivity',
    );
    expect(await platform.getAndroidPushAction(), 'com.example.push');
  });
}
