// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit_ui/view_model/chat_view_model.dart';
import 'package:nim_core_v2/nim_core.dart';

NIMMessage _message(int createTime) => NIMMessage(isSelf: false)
  ..conversationId = 'conversation-a'
  ..messageClientId = 'message-$createTime'
  ..createTime = createTime;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.yunxin.163.com/nim_core');

  for (final isNetworkAvailable in <bool>[true, false]) {
    testWidgets(
      'message list strict mode follows connectivity when network is '
      '${isNetworkAvailable ? 'available' : 'unavailable'}',
      (tester) async {
        final strictModes = <bool?>[];
        IMKitConfigCenter.enableMessageReaction = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getMessageList' ||
              call.method == 'getMessageListEx') {
            final arguments = call.arguments as Map<Object?, Object?>;
            final option = arguments['option'] as Map<Object?, Object?>;
            strictModes.add(option['strictMode'] as bool?);
            return {
              'code': 0,
              'data': {'messages': <Object>[]},
            };
          }
          return {'code': 0};
        });
        addTearDown(() {
          IMKitConfigCenter.enableMessageReaction = true;
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null);
        });

        final model = ChatViewModel(
          'conversation-a',
          NIMConversationType.p2p,
          messageListConnectivityChecker: () async => isNetworkAvailable,
          initializeRuntime: false,
        );
        addTearDown(model.dispose);

        await model.loadHistoryReadPositionAnchor(_message(100));
        model.fetchMoreMessage(NIMQueryDirection.desc);
        await tester.pumpAndSettle();
        model.loadMessageWithAnchorDate(100);
        await tester.pumpAndSettle();

        expect(strictModes, hasLength(5));
        expect(strictModes, everyElement(isNetworkAvailable));

        model.historyReadPositionTracker.initialize(100);
        model.historyReadPositionCount = 1;
        model.evaluateHistoryReadPositionTop(101);
        await model.beginHistoryReadPositionLocation();

        expect(strictModes, hasLength(6));
        expect(strictModes.last, isNetworkAvailable ? isTrue : isNull);
        expect(model.historyReadPositionLoading, isFalse);
      },
    );
  }
}
