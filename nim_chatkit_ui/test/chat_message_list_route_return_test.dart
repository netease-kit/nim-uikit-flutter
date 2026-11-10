// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/chat_kit_message_list.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_item.dart';
import 'package:nim_chatkit_ui/view_model/chat_view_model.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:visibility_detector/visibility_detector.dart';

NIMMessage _message(String id, int createTime) => NIMMessage(isSelf: false)
  ..conversationId = 'conversation-a'
  ..messageClientId = id
  ..messageServerId = id
  ..createTime = createTime
  ..messageType = NIMMessageType.text
  ..text = id;

NIMMessage _selfMessage(String id, int createTime) => _message(id, createTime)
  ..senderId = 'self'
  ..conversationType = NIMConversationType.p2p
  ..isSelf = true;

class _TestChatViewModel extends ChatViewModel {
  _TestChatViewModel()
      : super(
          'conversation-a',
          NIMConversationType.p2p,
          initializeRuntime: false,
        );

  void prepareForTest(NIMMessage anchor) {
    prepareForAnchorLoading(visibleThrough: anchor);
  }
}

void main() {
  setUpAll(() {
    setupLocator();
    getIt<IMLoginService>().userInfo = NIMUserInfo(accountId: 'self');
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets(
    'returning from a child route shows new messages when content is short',
    (tester) async {
      final messageListKey = GlobalKey<ChatKitMessageListState>();
      final scrollController = AutoScrollController();
      final viewModel = ChatViewModel(
        'conversation-a',
        NIMConversationType.p2p,
        initializeRuntime: false,
      );
      addTearDown(scrollController.dispose);
      addTearDown(viewModel.dispose);
      viewModel.messageList = [
        ChatMessage(_selfMessage('existing-message', 1)),
      ];

      await tester.pumpWidget(
        ChangeNotifierProvider<ChatViewModel>.value(
          value: viewModel,
          child: MaterialApp(
            home: Scaffold(
              body: ChatKitMessageList(
                key: messageListKey,
                scrollController: scrollController,
                messageBuilder: ChatKitMessageBuilder()
                  ..textMessageBuilder = (message) => SizedBox(
                        height: 72,
                        child: Text(message.text!),
                      ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      messageListKey.currentState!.didPushNext();
      viewModel.newMessages.add(ChatMessage(_selfMessage('new-message', 2)));
      messageListKey.currentState!.didPopNext();
      await tester.pump();

      expect(viewModel.newMessages, isEmpty);
      expect(
        viewModel.messageList.map((message) => message.nimMessage.text),
        contains('new-message'),
      );
      expect(find.byKey(const Key('chat-new-message-entry')), findsNothing);
    },
  );

  testWidgets(
    'returning from a child route shows new messages when full content was at latest',
    (tester) async {
      final messageListKey = GlobalKey<ChatKitMessageListState>();
      final scrollController = AutoScrollController();
      final viewModel = ChatViewModel(
        'conversation-a',
        NIMConversationType.p2p,
        initializeRuntime: false,
      );
      addTearDown(scrollController.dispose);
      addTearDown(viewModel.dispose);
      viewModel.messageList = List.generate(10, (index) {
        return ChatMessage(
          _selfMessage('existing-message-$index', index + 1),
        );
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<ChatViewModel>.value(
          value: viewModel,
          child: MaterialApp(
            home: Scaffold(
              body: ChatKitMessageList(
                key: messageListKey,
                scrollController: scrollController,
                messageBuilder: ChatKitMessageBuilder()
                  ..textMessageBuilder = (message) => SizedBox(
                        height: 100,
                        child: Text(message.text!),
                      ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      messageListKey.currentState!.didPushNext();
      viewModel.newMessages.add(ChatMessage(_selfMessage('new-message', 20)));
      messageListKey.currentState!.didPopNext();
      await tester.pump();

      expect(viewModel.newMessages, isEmpty);
      expect(
        viewModel.messageList.map((message) => message.nimMessage.text),
        contains('new-message'),
      );
      expect(find.byKey(const Key('chat-new-message-entry')), findsNothing);
    },
  );

  test('latest anchor clears messages already covered by the destination', () {
    final viewModel = _TestChatViewModel();
    addTearDown(viewModel.dispose);
    final latest = _message('message-15', 15);
    viewModel.newMessages.addAll([
      ChatMessage(_message('message-14', 14)),
      ChatMessage(latest),
    ]);

    viewModel.prepareForTest(latest);

    expect(viewModel.newMessages, isEmpty);
  });

  test('older anchor preserves messages newer than the destination', () {
    final viewModel = _TestChatViewModel();
    addTearDown(viewModel.dispose);
    final anchor = _message('message-10', 10);
    viewModel.newMessages.addAll([
      ChatMessage(anchor),
      ChatMessage(_message('message-11', 11)),
      ChatMessage(_message('message-12', 12)),
    ]);

    viewModel.prepareForTest(anchor);

    expect(
      viewModel.newMessages.map((message) => message.nimMessage.text),
      ['message-11', 'message-12'],
    );
  });

  testWidgets(
    'dynamic time anchor stays visible after the pivot layout changes',
    (tester) async {
      final scrollController = AutoScrollController();
      final viewModel = ChatViewModel(
        'conversation-a',
        NIMConversationType.p2p,
        findAnchorDate: 10,
        initializeRuntime: false,
      );
      addTearDown(scrollController.dispose);
      addTearDown(viewModel.dispose);
      viewModel.messageList = List.generate(15, (index) {
        final number = 15 - index;
        final message = _message('message-$number', number)
          ..senderId = 'self'
          ..conversationType = NIMConversationType.p2p
          ..isSelf = true;
        return ChatMessage(message);
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<ChatViewModel>.value(
          value: viewModel,
          child: MaterialApp(
            home: Scaffold(
              body: ChatKitMessageList(
                scrollController: scrollController,
                messageBuilder: ChatKitMessageBuilder()
                  ..textMessageBuilder = (message) => SizedBox(
                        height: 72,
                        child: Text(message.text!),
                      ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      final viewport = tester.getRect(find.byType(CustomScrollView));
      final target = tester.getRect(find.text('message-10'));
      expect(target.bottom, greaterThan(viewport.top));
      expect(target.top, lessThan(viewport.bottom));
      expect(viewModel.findAnchorDate, isNull);
    },
  );
}
