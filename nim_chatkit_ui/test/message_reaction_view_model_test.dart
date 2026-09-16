// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit_ui/view_model/chat_view_model.dart';
import 'package:nim_core_v2/nim_core.dart';

NIMMessage _message(String id, {String conversationId = 'conversation-1'}) {
  return NIMMessage(
    messageType: NIMMessageType.text,
    isSelf: false,
  )
    ..messageServerId = id
    ..messageClientId = 'client-$id'
    ..conversationId = conversationId;
}

ChatViewModel _viewModel({
  QuickCommentListLoader? loader,
  QuickCommentAdder? adder,
  QuickCommentRemover? remover,
  MessageReactionConnectivityChecker? connectivityChecker,
}) {
  return ChatViewModel(
    'conversation-1',
    NIMConversationType.p2p,
    initializeRuntime: false,
    currentAccountIdProvider: () => 'me',
    quickCommentListLoader: loader,
    quickCommentAdder: adder,
    quickCommentRemover: remover,
    messageReactionConnectivityChecker: connectivityChecker ?? () async => true,
  );
}

void main() {
  setUp(() {
    IMKitConfigCenter.enableMessageReaction = true;
  });

  tearDown(() {
    IMKitConfigCenter.enableMessageReaction = true;
  });

  test(
      'reaction times survive hydration and update when the earliest reply is removed',
      () async {
    final message = _message('time');
    final viewModel = _viewModel(
      loader: (_) async => NIMResult.success(data: {
        'client-time': [
          NIMMessageQuickComment(index: 3, operatorId: 'late', createTime: 300),
          NIMMessageQuickComment(
              index: 5, operatorId: 'other', createTime: 200),
          NIMMessageQuickComment(
              index: 3, operatorId: 'early', createTime: 100),
        ],
      }),
    );
    addTearDown(viewModel.dispose);
    viewModel.messageList = [ChatMessage(message)];
    await viewModel.ensureQuickCommentsLoaded(viewModel.messageList);
    expect(viewModel.getMessageReactionState(message).summaries[3]?.createTime,
        100);

    viewModel.handleQuickCommentNotificationForTest(
        NIMMessageQuickCommentNotification(
      operationType: NIMMessageQuickCommentType.remove,
      quickComment: NIMMessageQuickComment(
          messageRefer: message,
          index: 3,
          operatorId: 'early',
          createTime: 100),
    ));
    expect(viewModel.getMessageReactionState(message).summaries[3]?.createTime,
        300);
    viewModel.handleQuickCommentNotificationForTest(
        NIMMessageQuickCommentNotification(
      operationType: NIMMessageQuickCommentType.add,
      quickComment: NIMMessageQuickComment(
          messageRefer: message, index: 3, operatorId: 'new', createTime: 150),
    ));
    expect(viewModel.getMessageReactionState(message).summaries[3]?.createTime,
        150);
    expect(viewModel.getMessageReactionState(message).summaries[3]?.count, 2);
  });

  for (final originalTime in <int?>[100, null]) {
    test('failed removal restores the original reaction time $originalTime',
        () async {
      final message = _message('rollback-time');
      final viewModel = _viewModel(
        loader: (_) async => NIMResult.success(data: {
          'client-rollback-time': [
            NIMMessageQuickComment(
                index: 3, operatorId: 'me', createTime: originalTime),
            NIMMessageQuickComment(
                index: 3, operatorId: 'other', createTime: 300),
          ],
        }),
        remover: (_, __) async => NIMResult.failure(code: 500),
      );
      addTearDown(viewModel.dispose);
      final chatMessage = ChatMessage(message);
      await viewModel.ensureQuickCommentsLoaded([chatMessage]);
      expect((await viewModel.toggleMessageReaction(chatMessage, 3)).isSuccess,
          isFalse);
      expect(
          viewModel.getMessageReactionState(message).summaries[3]?.createTime,
          originalTime ?? 300);
      expect(
          viewModel
              .getMessageReactionState(message)
              .summaries[3]
              ?.operatorCreateTimes['me'],
          originalTime);
    });
  }

  test('rapid toggles preserve server creation time when removal fails',
      () async {
    final message = ChatMessage(_message('server-time'));
    final addStarted = Completer<void>();
    final addResult = Completer<NIMResult<void>>();
    final deselectApplied = Completer<void>();
    final viewModel = _viewModel(
      loader: (_) async =>
          NIMResult.success(data: <String, List<NIMMessageQuickComment>?>{}),
      adder: (_, __) {
        addStarted.complete();
        return addResult.future;
      },
      remover: (_, __) async => NIMResult.failure(code: 500),
    );
    addTearDown(viewModel.dispose);
    viewModel.messageList = [message];
    await viewModel.ensureQuickCommentsLoaded([message]);
    final select = viewModel.toggleMessageReaction(message, 3);
    await addStarted.future;
    viewModel.handleQuickCommentNotificationForTest(
        NIMMessageQuickCommentNotification(
      operationType: NIMMessageQuickCommentType.add,
      quickComment: NIMMessageQuickComment(
        messageRefer: message.nimMessage,
        index: 3,
        operatorId: 'me',
        createTime: 123,
      ),
    ));
    viewModel.addListener(() {
      if (viewModel
              .getMessageReactionState(message.nimMessage)
              .summaries
              .isEmpty &&
          !deselectApplied.isCompleted) {
        deselectApplied.complete();
      }
    });
    final deselect = viewModel.toggleMessageReaction(message, 3);
    await deselectApplied.future;
    addResult.complete(NIMResult.success());
    await Future.wait([select, deselect]);
    expect(
        viewModel
            .getMessageReactionState(message.nimMessage)
            .summaries[3]
            ?.createTime,
        123);
  });

  test('removing all replies then re-adding uses the new creation time',
      () async {
    final message = _message('readd-time');
    final viewModel = _viewModel(
      loader: (_) async => NIMResult.success(data: {
        'client-readd-time': [
          NIMMessageQuickComment(index: 3, operatorId: 'me', createTime: 100),
        ],
      }),
      adder: (_, __) async => NIMResult.success(),
      remover: (_, __) async => NIMResult.success(),
    );
    addTearDown(viewModel.dispose);
    final chatMessage = ChatMessage(message);
    await viewModel.ensureQuickCommentsLoaded([chatMessage]);
    await viewModel.toggleMessageReaction(chatMessage, 3);
    expect(viewModel.getMessageReactionState(message).summaries, isEmpty);
    await viewModel.toggleMessageReaction(chatMessage, 3);
    expect(viewModel.getMessageReactionState(message).summaries[3]?.createTime,
        greaterThan(100));
  });

  test('call records load, add and remove reactions', () async {
    final message =
        ChatMessage(_message('call')..messageType = NIMMessageType.call);
    var addCalls = 0;
    var removeCalls = 0;
    final viewModel = _viewModel(
      loader: (messages) async {
        expect(messages.single.messageType, NIMMessageType.call);
        return NIMResult.success(data: {
          'client-call': [
            NIMMessageQuickComment(
              messageRefer: message.nimMessage,
              index: 3,
              operatorId: 'other',
            ),
          ],
        });
      },
      adder: (target, index) async {
        expect(target.messageType, NIMMessageType.call);
        addCalls++;
        return NIMResult.success();
      },
      remover: (target, index) async {
        expect(target.messageServerId, message.nimMessage.messageServerId);
        expect(index, 3);
        removeCalls++;
        return NIMResult.success();
      },
    );
    addTearDown(viewModel.dispose);

    await viewModel.ensureQuickCommentsLoaded([message]);
    expect(
        viewModel
            .getMessageReactionState(message.nimMessage)
            .summaries[3]
            ?.count,
        1);
    expect(
        (await viewModel.toggleMessageReaction(message, 3)).isSuccess, isTrue);
    expect(
        viewModel
            .getMessageReactionState(message.nimMessage)
            .summaries[3]
            ?.contains('me'),
        isTrue);
    expect(
        (await viewModel.toggleMessageReaction(message, 3)).isSuccess, isTrue);
    final summary =
        viewModel.getMessageReactionState(message.nimMessage).summaries[3];
    expect(summary?.contains('me'), isFalse);
    expect(summary?.contains('other'), isTrue);
    expect(summary?.count, 1);
    expect(addCalls, 1);
    expect(removeCalls, 1);
  });

  test('empty quick comment result is loaded and is not requested again',
      () async {
    var calls = 0;
    final viewModel = _viewModel(
      loader: (messages) async {
        calls++;
        return NIMResult.success(
            data: <String, List<NIMMessageQuickComment>?>{});
      },
    );
    final message = ChatMessage(_message('1'));

    await viewModel.ensureQuickCommentsLoaded(<ChatMessage>[message]);
    await viewModel.ensureQuickCommentsLoaded(<ChatMessage>[message]);

    expect(calls, 1);
    expect(
        viewModel.getMessageReactionState(message.nimMessage).loaded, isTrue);
    viewModel.dispose();
  });

  test('quick comment hydration requests at most 50 messages per batch',
      () async {
    final batchSizes = <int>[];
    final viewModel = _viewModel(
      loader: (messages) async {
        batchSizes.add(messages.length);
        return NIMResult.success(
          data: <String, List<NIMMessageQuickComment>?>{
            for (final message in messages)
              message.messageClientId!: <NIMMessageQuickComment>[],
          },
        );
      },
    );
    final messages = <ChatMessage>[
      for (var index = 0; index < 120; index++)
        ChatMessage(_message(index.toString())),
    ];

    await viewModel.ensureQuickCommentsLoaded(messages);

    expect(batchSizes, isNotEmpty);
    expect(batchSizes.every((size) => size <= 50), isTrue);
    expect(batchSizes.fold<int>(0, (total, size) => total + size), 120);
    expect(
      messages.every(
        (message) =>
            viewModel.getMessageReactionState(message.nimMessage).loaded,
      ),
      isTrue,
    );
    viewModel.dispose();
  });

  test('concurrent hydration is deduplicated and failed hydration can retry',
      () async {
    var calls = 0;
    final firstResult =
        Completer<NIMResult<Map<String, List<NIMMessageQuickComment>?>>>();
    final viewModel = _viewModel(
      loader: (messages) {
        calls++;
        if (calls == 1) {
          return firstResult.future;
        }
        return Future.value(
          NIMResult.success(
            data: <String, List<NIMMessageQuickComment>?>{},
          ),
        );
      },
    );
    final message = ChatMessage(_message('2'));

    final first = viewModel.ensureQuickCommentsLoaded(<ChatMessage>[message]);
    final duplicate =
        viewModel.ensureQuickCommentsLoaded(<ChatMessage>[message]);
    expect(calls, 1);
    firstResult.complete(NIMResult.failure(code: 500, message: 'failed'));
    await Future.wait(<Future<void>>[first, duplicate]);
    expect(
        viewModel.getMessageReactionState(message.nimMessage).loaded, isFalse);

    await viewModel.ensureQuickCommentsLoaded(<ChatMessage>[message]);
    expect(calls, 2);
    expect(
        viewModel.getMessageReactionState(message.nimMessage).loaded, isTrue);
    viewModel.dispose();
  });

  test(
      'quick comment result aggregates duplicate operators and ignores unknown',
      () async {
    final message = _message('3');
    final viewModel = _viewModel(
      loader: (messages) async => NIMResult.success(
        data: <String, List<NIMMessageQuickComment>?>{
          'client-3': <NIMMessageQuickComment>[
            NIMMessageQuickComment(
              messageRefer: message,
              index: 3,
              operatorId: 'me',
            ),
            NIMMessageQuickComment(
              messageRefer: message,
              index: 3,
              operatorId: 'me',
            ),
            NIMMessageQuickComment(
              messageRefer: message,
              index: 113,
              operatorId: 'other',
            ),
          ],
        },
      ),
    );

    await viewModel.ensureQuickCommentsLoaded(<ChatMessage>[
      ChatMessage(message),
    ]);

    final state = viewModel.getMessageReactionState(message);
    expect(state.summaries[3]?.count, 1);
    expect(state.summaries.containsKey(113), isFalse);
    viewModel.dispose();
  });

  test('added quick comment is restored after recreating chat view model',
      () async {
    final persistedComments = <String, List<NIMMessageQuickComment>?>{};
    final firstMessage = ChatMessage(_message('9'));
    final firstViewModel = _viewModel(
      adder: (message, index) async {
        persistedComments[message.messageClientId!] = <NIMMessageQuickComment>[
          NIMMessageQuickComment(
            index: index,
            operatorId: 'me',
          ),
        ];
        return NIMResult.success();
      },
    );

    await firstViewModel.toggleMessageReaction(firstMessage, 3);
    expect(
      firstViewModel
          .getMessageReactionState(firstMessage.nimMessage)
          .summaries[3]
          ?.contains('me'),
      isTrue,
    );
    firstViewModel.dispose();

    final reloadedMessage = ChatMessage(_message('9'));
    final secondViewModel = _viewModel(
      loader: (messages) async => NIMResult.success(data: persistedComments),
    );
    await secondViewModel.ensureQuickCommentsLoaded(<ChatMessage>[
      reloadedMessage,
    ]);

    final restoredState =
        secondViewModel.getMessageReactionState(reloadedMessage.nimMessage);
    expect(restoredState.loaded, isTrue);
    expect(restoredState.summaries[3]?.contains('me'), isTrue);
    secondViewModel.dispose();
  });

  test('notification only updates a message currently owned by this view model',
      () async {
    final message = _message('4');
    final otherMessage = _message('5');
    final viewModel = _viewModel(
      loader: (messages) async =>
          NIMResult.success(data: <String, List<NIMMessageQuickComment>?>{}),
    );
    viewModel.messageList = <ChatMessage>[ChatMessage(message)];
    await viewModel.ensureQuickCommentsLoaded(viewModel.messageList);

    viewModel.handleQuickCommentNotificationForTest(
      NIMMessageQuickCommentNotification(
        operationType: NIMMessageQuickCommentType.add,
        quickComment: NIMMessageQuickComment(
          messageRefer: message,
          index: 5,
          operatorId: 'other',
        ),
      ),
    );
    viewModel.handleQuickCommentNotificationForTest(
      NIMMessageQuickCommentNotification(
        operationType: NIMMessageQuickCommentType.add,
        quickComment: NIMMessageQuickComment(
          messageRefer: otherMessage,
          index: 3,
          operatorId: 'other',
        ),
      ),
    );

    expect(viewModel.getMessageReactionState(message).summaries[5]?.count, 1);
    expect(
      viewModel.getMessageReactionState(otherMessage).summaries,
      isEmpty,
    );
    viewModel.dispose();
  });

  test('rapid repeated taps converge through add then remove', () async {
    final addResult = Completer<NIMResult<void>>();
    var addCalls = 0;
    var removeCalls = 0;
    final viewModel = _viewModel(
      adder: (message, index) {
        addCalls++;
        return addResult.future;
      },
      remover: (message, index) async {
        removeCalls++;
        return NIMResult.success();
      },
    );
    final message = ChatMessage(_message('6'));

    final select = viewModel.toggleMessageReaction(message, 3);
    final deselect = viewModel.toggleMessageReaction(message, 3);
    addResult.complete(NIMResult.success());
    final results = await Future.wait(<Future<NIMResult<void>>>[
      select,
      deselect,
    ]);

    expect(results.every((result) => result.isSuccess), isTrue);
    expect(addCalls, 1);
    expect(removeCalls, 1);
    expect(viewModel.getMessageReactionState(message.nimMessage).summaries,
        isEmpty);
    viewModel.dispose();
  });

  test('failed optimistic update rolls back only current account', () async {
    final viewModel = _viewModel(
      adder: (message, index) async =>
          NIMResult.failure(code: 500, message: 'failed'),
    );
    final message = ChatMessage(_message('7'));

    final result = await viewModel.toggleMessageReaction(message, 3);

    expect(result.isSuccess, isFalse);
    expect(viewModel.getMessageReactionState(message.nimMessage).summaries,
        isEmpty);
    viewModel.dispose();
  });

  test('offline add returns before changing state or calling the SDK',
      () async {
    var addCalls = 0;
    var connectivityChecks = 0;
    final viewModel = _viewModel(
      connectivityChecker: () async {
        connectivityChecks++;
        return false;
      },
      adder: (message, index) async {
        addCalls++;
        return NIMResult.success();
      },
    );
    final message = ChatMessage(_message('10'));

    final result = await viewModel.toggleMessageReaction(message, 3);

    expect(result.isSuccess, isFalse);
    expect(
      result.code,
      ChatViewModel.messageReactionNetworkUnavailableCode,
    );
    expect(connectivityChecks, 1);
    expect(addCalls, 0);
    expect(
      viewModel.getMessageReactionState(message.nimMessage).summaries,
      isEmpty,
    );
    viewModel.dispose();
  });

  test('offline remove preserves selection and does not call the SDK',
      () async {
    var removeCalls = 0;
    final nimMessage = _message('11');
    final message = ChatMessage(nimMessage);
    final viewModel = _viewModel(
      connectivityChecker: () async => false,
      loader: (messages) async => NIMResult.success(
        data: <String, List<NIMMessageQuickComment>?>{
          'client-11': <NIMMessageQuickComment>[
            NIMMessageQuickComment(
              messageRefer: nimMessage,
              index: 3,
              operatorId: 'me',
            ),
          ],
        },
      ),
      remover: (message, index) async {
        removeCalls++;
        return NIMResult.success();
      },
    );
    await viewModel.ensureQuickCommentsLoaded(<ChatMessage>[message]);

    final result = await viewModel.toggleMessageReaction(message, 3);

    expect(result.isSuccess, isFalse);
    expect(
      result.code,
      ChatViewModel.messageReactionNetworkUnavailableCode,
    );
    expect(removeCalls, 0);
    final summary =
        viewModel.getMessageReactionState(message.nimMessage).summaries[3];
    expect(summary?.contains('me'), isTrue);
    expect(summary?.pending, isFalse);
    viewModel.dispose();
  });

  test('disabled switch skips quick comment hydration', () async {
    var calls = 0;
    final viewModel = _viewModel(
      loader: (messages) async {
        calls++;
        return NIMResult.success(
            data: <String, List<NIMMessageQuickComment>?>{});
      },
    );
    IMKitConfigCenter.enableMessageReaction = false;

    await viewModel.ensureQuickCommentsLoaded(<ChatMessage>[
      ChatMessage(_message('8')),
    ]);

    expect(calls, 0);
    viewModel.dispose();
  });
}
