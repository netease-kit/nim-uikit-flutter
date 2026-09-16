// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/router/chat_anchor_route_registry.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit_ui/model/history_read_position_tracker.dart';
import 'package:nim_chatkit_ui/view_model/chat_view_model.dart';
import 'package:nim_core_v2/nim_core.dart';

NIMMessage _message(int time) => NIMMessage(isSelf: false)
  ..conversationId = 'conversation-a'
  ..messageClientId = 'message-$time'
  ..createTime = time;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.yunxin.163.com/nim_core');

  setUp(() {
    IMKitConfigCenter.enableMessageReaction = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getMessageList' ||
          call.method == 'getMessageListEx') {
        return {
          'code': 0,
          'data': {'messages': <Object>[]},
        };
      }
      return {'code': 0};
    });
  });

  tearDown(() {
    IMKitConfigCenter.enableMessageReaction = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('uses the loaded unread boundary without entering loading', () {
    final model = ChatViewModel(
      'conversation-a',
      NIMConversationType.p2p,
      initializeRuntime: false,
    );
    addTearDown(model.dispose);
    model.historyReadPositionTracker.initialize(100);
    model.historyReadPositionCount = 3;
    model.evaluateHistoryReadPositionTop(130);
    model.messageList = [
      ChatMessage(_message(130)),
      ChatMessage(_message(120)),
      ChatMessage(_message(110)),
    ];
    model.hasMoreForwardMessages = true;

    final target = model.beginLoadedHistoryReadPositionLocation();

    expect(target?.createTime, 110);
    expect(model.historyReadPositionState, HistoryReadPositionState.locating);
    expect(model.historyReadPositionLoading, isFalse);
  });

  test('queries when the loaded page does not cover every unread message', () {
    final model = ChatViewModel(
      'conversation-a',
      NIMConversationType.p2p,
      initializeRuntime: false,
    );
    addTearDown(model.dispose);
    model.historyReadPositionTracker.initialize(100);
    model.historyReadPositionCount = 20;
    model.evaluateHistoryReadPositionTop(130);
    model.messageList = [
      ChatMessage(_message(130)),
      ChatMessage(_message(120)),
      ChatMessage(_message(110)),
    ];
    model.hasMoreForwardMessages = true;

    expect(model.beginLoadedHistoryReadPositionLocation(), isNull);
    expect(model.historyReadPositionState, HistoryReadPositionState.ready);
    expect(model.historyReadPositionLoading, isFalse);
  });

  for (final source in ['history', 'pin']) {
    for (final anchorTime in [90, 105, 110]) {
      testWidgets('$source return at $anchorTime preserves frozen 20 messages',
          (tester) async {
        final navigator = GlobalKey<NavigatorState>();
        final model = ChatViewModel(
          'conversation-a',
          NIMConversationType.p2p,
          initializeRuntime: false,
        );
        addTearDown(model.dispose);
        model.historyReadPositionTracker.initialize(100);
        model.historyReadPositionCount = 20;
        model.evaluateHistoryReadPositionTop(115);
        final anchor = _message(anchorTime);
        late BuildContext sourceContext;
        await tester.pumpWidget(MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text('home')),
        ));
        final chatRoute = MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('original-chat')),
        );
        navigator.currentState!.push(chatRoute);
        await tester.pumpAndSettle();
        final unregister = ChatAnchorRouteRegistry.register(
          route: chatRoute,
          conversationId: model.conversationId,
          conversationType: model.conversationType,
          onLocate: (message, date) => model.loadMessageWithAnchor(message!),
        );
        addTearDown(unregister);
        navigator.currentState!.push(MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('settings')),
        ));
        navigator.currentState!.push(MaterialPageRoute<void>(
          builder: (context) {
            sourceContext = context;
            return Scaffold(body: Text(source));
          },
        ));
        await tester.pumpAndSettle();
        if (anchorTime == 105) {
          model.newMessages.addAll([
            for (var time = 121; time <= 123; time++)
              ChatMessage(_message(time)),
          ]);
        }

        goToChatAndKeepHome(
          sourceContext,
          model.conversationId,
          model.conversationType,
          message: anchor,
        );
        expect(model.isLoading, isTrue);
        await tester.pumpAndSettle();

        expect(chatRoute.isCurrent, isTrue);
        expect(find.text('original-chat'), findsOneWidget);
        expect(find.text('settings'), findsNothing);
        expect(model.findAnchorDate, anchorTime);
        expect(model.historyReadPositionTracker.lastReadTime, 100);
        expect(model.historyReadPositionCount, 20);
        // 模拟锚点滚动完成后的实际视口上报。
        model.evaluateHistoryReadPositionTop(anchorTime);
        expect(model.showHistoryReadPosition, anchorTime > 100);
        if (anchorTime > 100) {
          expect(model.historyReadPositionDisplayCount, '20');
        }
        if (anchorTime == 105) expect(model.newMessages, hasLength(3));
        navigator.currentState!.pop();
        await tester.pumpAndSettle();
        expect(find.text('home'), findsOneWidget);
      });
    }
  }
}
