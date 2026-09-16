// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/model/message_reaction.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_desktop_context_menu.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_message_pop_menu.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/reaction/message_reaction_bar.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/reaction/message_reaction_emoji.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/reaction/message_reaction_picker.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/reaction/message_reaction_quick_bar.dart';
import 'package:nim_chatkit_ui/view_model/chat_view_model.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

Widget _app(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const <Locale>[Locale('en'), Locale('zh')],
    home: Scaffold(body: Center(child: child)),
  );
}

Widget _appWithPageProvider(ChatViewModel viewModel, Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const <Locale>[Locale('en'), Locale('zh')],
    home: ChangeNotifierProvider<ChatViewModel>.value(
      value: viewModel,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

Widget _emojiBuilder(BuildContext context, int index, double size) {
  return SizedBox.square(
    key: ValueKey<String>('reaction-$index'),
    dimension: size,
  );
}

List<int> _visibleEmojiIndexes(WidgetTester tester) {
  return tester
      .widgetList<MessageReactionEmoji>(find.byType(MessageReactionEmoji))
      .map((emoji) => emoji.index)
      .toList();
}

ChatMessage _supportedMessage({NIMMessageType type = NIMMessageType.text}) {
  return ChatMessage(
    NIMMessage(
      messageType: type,
      isSelf: false,
    )
      ..messageServerId = 'server-1'
      ..messageClientId = 'client-1'
      ..conversationId = 'conversation-1',
  );
}

ChatViewModel _viewModel() {
  return ChatViewModel(
    'conversation-1',
    NIMConversationType.p2p,
    initializeRuntime: false,
    currentAccountIdProvider: () => 'me',
  );
}

void main() {
  setUpAll(() {
    setupLocator();
    getIt<IMLoginService>().userInfo = NIMUserInfo(accountId: 'me');
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });
  setUp(() {
    IMKitConfigCenter.enableMessageReaction = true;
  });
  tearDown(() {
    IMKitConfigCenter.enableMessageReaction = true;
  });

  testWidgets('all default reaction assets are bundled', (tester) async {
    for (final index in MessageReactionConfig.allIndexes) {
      final name = index.toString().padLeft(3, '0');
      final data = await rootBundle.load(
        'packages/nim_chatkit_ui/reaction_emoji/$name.png',
      );
      expect(data.lengthInBytes, greaterThan(0), reason: '$name.png');
    }
  });

  testWidgets('quick bar uses six common emojis and expand in slot seven',
      (tester) async {
    await tester.pumpWidget(
      _app(
        MessageReactionQuickBar(
          popupStyle: true,
          selectedIndexes: const <int>{3},
          emojiBuilder: _emojiBuilder,
          onSelected: (_) {},
          onExpand: () {},
        ),
      ),
    );

    expect(_visibleEmojiIndexes(tester), <int>[3, 5, 1, 21, 65, 19]);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    expect(
      tester
          .widgetList<MessageReactionEmoji>(find.byType(MessageReactionEmoji))
          .every((emoji) => emoji.size == 26),
      isTrue,
    );
    final selectedSlotDecorations = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byKey(const ValueKey<int>(3)),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>();
    expect(
      selectedSlotDecorations
          .any((decoration) => decoration.color == const Color(0xFFEAF2FF)),
      isFalse,
    );
  });

  testWidgets('expanded quick panel reserves slot seven for collapse',
      (tester) async {
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: MessageReactionPicker.width,
          height: 280,
          child: MessageReactionPicker(
            mode: MessageReactionPickerMode.quickBarExpanded,
            emojiBuilder: _emojiBuilder,
            onSelected: (_) {},
            onCollapse: () {},
          ),
        ),
      ),
    );

    expect(
      _visibleEmojiIndexes(tester).take(6),
      <int>[3, 5, 1, 21, 65, 19],
    );
    expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);

    final pinnedTop = List<double>.generate(
      6,
      (index) =>
          tester.getTopLeft(find.byType(MessageReactionEmoji).at(index)).dy,
    );
    await tester.drag(find.byType(GridView), const Offset(0, -80));
    await tester.pump();
    for (var index = 0; index < pinnedTop.length; index++) {
      expect(
        tester.getTopLeft(find.byType(MessageReactionEmoji).at(index)).dy,
        pinnedTop[index],
      );
    }
  });

  testWidgets('message bar picker shows all seven common emojis first',
      (tester) async {
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: MessageReactionPicker.width,
          height: 280,
          child: MessageReactionPicker(
            mode: MessageReactionPickerMode.messageBar,
            emojiBuilder: _emojiBuilder,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(
      _visibleEmojiIndexes(tester).take(7),
      <int>[3, 5, 1, 21, 65, 19, 20],
    );
    expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);
    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 7);
    final emojis = find.byType(MessageReactionEmoji);
    final firstRowTop = tester.getTopLeft(emojis.first).dy;
    for (var index = 1; index < 7; index++) {
      expect(tester.getTopLeft(emojis.at(index)).dy, firstRowTop);
    }
    expect(tester.getTopLeft(emojis.at(7)).dy, greaterThan(firstRowTop));

    final pinnedTop = List<double>.generate(
      7,
      (index) => tester.getTopLeft(emojis.at(index)).dy,
    );
    await tester.drag(find.byType(GridView), const Offset(0, -80));
    await tester.pump();
    for (var index = 0; index < pinnedTop.length; index++) {
      expect(tester.getTopLeft(emojis.at(index)).dy, pinnedTop[index]);
    }
  });

  testWidgets('self short message stays right aligned when reactions are wide',
      (tester) async {
    final message = ChatMessage(
      NIMMessage(messageType: NIMMessageType.text, isSelf: true)
        ..senderId = 'me'
        ..conversationType = NIMConversationType.p2p
        ..conversationId = 'conversation-1'
        ..messageServerId = 'server-1'
        ..messageClientId = 'client-1'
        ..createTime = 1
        ..text = 'short',
    );
    final viewModel = ChatViewModel(
      'conversation-1',
      NIMConversationType.p2p,
      initializeRuntime: false,
      currentAccountIdProvider: () => 'me',
      quickCommentListLoader: (_) async => NIMResult.success(
        data: <String, List<NIMMessageQuickComment>?>{
          'client-1': List<NIMMessageQuickComment>.generate(
            7,
            (index) => NIMMessageQuickComment(
              index: MessageReactionConfig.quickIndexes[index],
              operatorId: 'user-$index',
              createTime: index + 1,
            ),
          ),
        },
      ),
    );
    addTearDown(viewModel.dispose);
    await viewModel.ensureQuickCommentsLoaded(<ChatMessage>[message]);

    await tester.pumpWidget(
      _appWithPageProvider(
        viewModel,
        ChatKitMessageItem(
          key: const ValueKey<String>('self-message-item'),
          chatMessage: message,
          lastMessage: message,
          messageBuilder: ChatKitMessageBuilder()
            ..textMessageBuilder = (_) => const SizedBox(
                  key: ValueKey<String>('self-short-message'),
                  width: 40,
                  height: 20,
                ),
          scrollToIndex: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final messageRect = tester.getRect(
      find.byKey(const ValueKey<String>('self-short-message')),
    );
    final reactionRect = tester.getRect(find.byType(MessageReactionBar));
    expect(messageRect.right, greaterThan(reactionRect.center.dx));
    expect(messageRect.right, closeTo(reactionRect.right, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reaction bar has no horizontal padding for image messages',
      (tester) async {
    final message = ChatMessage(
      NIMMessage(messageType: NIMMessageType.image, isSelf: true)
        ..senderId = 'me'
        ..conversationType = NIMConversationType.p2p
        ..conversationId = 'conversation-1'
        ..messageServerId = 'server-image-1'
        ..messageClientId = 'client-image-1'
        ..createTime = 1,
    );
    final viewModel = ChatViewModel(
      'conversation-1',
      NIMConversationType.p2p,
      initializeRuntime: false,
      currentAccountIdProvider: () => 'me',
      quickCommentListLoader: (_) async => NIMResult.success(
        data: <String, List<NIMMessageQuickComment>?>{
          'client-image-1': <NIMMessageQuickComment>[
            NIMMessageQuickComment(
              index: MessageReactionConfig.quickIndexes.first,
              operatorId: 'other',
              createTime: 1,
            ),
          ],
        },
      ),
    );
    addTearDown(viewModel.dispose);
    await viewModel.ensureQuickCommentsLoaded(<ChatMessage>[message]);

    await tester.pumpWidget(
      _appWithPageProvider(
        viewModel,
        ChatKitMessageItem(
          key: const ValueKey<String>('self-image-message-item'),
          chatMessage: message,
          lastMessage: message,
          messageBuilder: ChatKitMessageBuilder()
            ..imageMessageBuilder = (_) => const SizedBox(
                  key: ValueKey<String>('self-image-message'),
                  width: 80,
                  height: 80,
                ),
          scrollToIndex: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final reactionPadding = tester
        .widgetList<Padding>(
          find.ancestor(
            of: find.byType(MessageReactionBar),
            matching: find.byType(Padding),
          ),
        )
        .firstWhere(
            (padding) => padding.padding == const EdgeInsets.only(bottom: 12));
    expect(reactionPadding.padding, const EdgeInsets.only(bottom: 12));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reaction bar keeps add first and displays reaction counts',
      (tester) async {
    final state = MessageReactionState(
      loaded: true,
      summaries: <int, MessageReactionSummary>{
        3: MessageReactionSummary(
          index: 3,
          operatorIds: const <String>['me', 'other'],
          operatorCreateTimes: const {'me': 300, 'other': 200},
        ),
        5: MessageReactionSummary(
          index: 5,
          operatorIds: const <String>['me'],
          operatorCreateTimes: const {'me': 100},
        ),
      },
    );
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 260,
          child: MessageReactionBar(
            state: state,
            currentAccountId: 'me',
            emojiBuilder: _emojiBuilder,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    final addCenter = tester.getCenter(
      find.byKey(const ValueKey<String>('message-reaction-add')),
    );
    final firstEmojiCenter = tester.getCenter(
      find.byType(MessageReactionEmoji).first,
    );
    expect(addCenter.dx, lessThan(firstEmojiCenter.dx));
    expect(_visibleEmojiIndexes(tester), [5, 3]);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    final chipDecorations = tester
        .widgetList<DecoratedBox>(
          find.ancestor(
            of: find.text('1'),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>();
    expect(
      chipDecorations
          .any((decoration) => decoration.color == const Color(0xFFF6F6F6)),
      isTrue,
    );
    expect(
      chipDecorations
          .any((decoration) => decoration.color == const Color(0xFFEAF2FF)),
      isFalse,
    );
    final selectedCount = tester.widget<Text>(find.text('1'));
    expect(selectedCount.style?.color, const Color(0xFF337EFF));
  });

  testWidgets('reaction bar wraps without changing leftmost add order',
      (tester) async {
    final state = MessageReactionState(
      loaded: true,
      summaries: <int, MessageReactionSummary>{
        for (final index in MessageReactionConfig.quickIndexes)
          index: MessageReactionSummary(
            index: index,
            operatorIds: const <String>['other'],
          ),
      },
    );
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 100,
          child: MessageReactionBar(
            state: state,
            currentAccountId: 'me',
            emojiBuilder: _emojiBuilder,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    final addCenter = tester.getCenter(
      find.byKey(const ValueKey<String>('message-reaction-add')),
    );
    final emojis = find.byType(MessageReactionEmoji);
    expect(addCenter.dx, lessThan(tester.getCenter(emojis.first).dx));
    expect(tester.getCenter(emojis.last).dy, greaterThan(addCenter.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('seven-column reaction controls fit a narrow viewport',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(280, 480);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 240,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MessageReactionQuickBar(
                emojiBuilder: _emojiBuilder,
                onSelected: (_) {},
                onExpand: () {},
              ),
              SizedBox(
                height: 240,
                child: MessageReactionPicker(
                  mode: MessageReactionPickerMode.quickBarExpanded,
                  emojiBuilder: _emojiBuilder,
                  onSelected: (_) {},
                  onCollapse: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.byType(MessageReactionQuickBar)).right,
      lessThanOrEqualTo(280),
    );
    expect(
      tester.getRect(find.byType(MessageReactionPicker)).right,
      lessThanOrEqualTo(280),
    );
  });

  testWidgets('message reaction picker overlay remains inside viewport',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(280, 480);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final state = MessageReactionState(
      loaded: true,
      summaries: <int, MessageReactionSummary>{
        3: MessageReactionSummary(
          index: 3,
          operatorIds: const <String>['other'],
        ),
      },
    );

    await tester.pumpWidget(
      _app(
        MessageReactionBar(
          state: state,
          currentAccountId: 'me',
          emojiBuilder: _emojiBuilder,
          onSelected: (_) {},
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('message-reaction-add')),
    );
    await tester.pump();

    final pickerRect = tester.getRect(find.byType(MessageReactionPicker));
    expect(pickerRect.left, greaterThanOrEqualTo(0));
    expect(pickerRect.right, lessThanOrEqualTo(280));
    expect(pickerRect.top, greaterThanOrEqualTo(0));
    expect(pickerRect.bottom, lessThanOrEqualTo(480));
    expect(tester.takeException(), isNull);
  });

  testWidgets('message reaction picker follows the message vertical position',
      (tester) async {
    final state = MessageReactionState(
      loaded: true,
      summaries: <int, MessageReactionSummary>{
        3: MessageReactionSummary(
          index: 3,
          operatorIds: const <String>['other'],
        ),
      },
    );

    Future<Rect> showPicker({
      required double top,
      required double height,
      required String keyValue,
    }) async {
      final targetKey = GlobalKey();
      await tester.pumpWidget(
        _app(
          SizedBox.expand(
            child: Stack(
              children: [
                Positioned(
                  top: top,
                  left: 340,
                  child: Container(
                    key: targetKey,
                    width: 120,
                    height: height,
                    alignment: Alignment.bottomLeft,
                    child: MessageReactionBar(
                      state: state,
                      currentAccountId: 'me',
                      emojiBuilder: _emojiBuilder,
                      messageTargetKey: targetKey,
                      onSelected: (_) {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('message-reaction-add')),
      );
      await tester.pump();
      final targetRect = tester.getRect(find.byKey(targetKey));
      final pickerRect = tester.getRect(find.byType(MessageReactionPicker));
      expect(pickerRect.height, closeTo(168, 0.01));
      if (keyValue == 'above') {
        expect(pickerRect.bottom, lessThanOrEqualTo(targetRect.top));
      } else if (keyValue == 'below') {
        expect(pickerRect.top, greaterThanOrEqualTo(targetRect.bottom));
      } else {
        expect(pickerRect.center.dy, closeTo(targetRect.center.dy, 0.5));
      }
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(MessageReactionPicker), findsNothing);
      return pickerRect;
    }

    await showPicker(top: 410, height: 40, keyValue: 'above');
    await showPicker(top: 80, height: 40, keyValue: 'below');
    final centeredPicker =
        await showPicker(top: 100, height: 400, keyValue: 'center');
    expect(centeredPicker.top, greaterThanOrEqualTo(0));
    expect(centeredPicker.bottom, lessThanOrEqualTo(600));
  });

  testWidgets('back closes reaction overlays before leaving the page',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final viewModel = _viewModel();
    addTearDown(viewModel.dispose);
    late BuildContext messageContext;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[Locale('en'), Locale('zh')],
        home: const Scaffold(
          body: SizedBox(key: ValueKey<String>('root-page')),
        ),
      ),
    );
    final state = MessageReactionState(
      loaded: true,
      summaries: <int, MessageReactionSummary>{
        3: MessageReactionSummary(
          index: 3,
          operatorIds: const <String>['other'],
        ),
      },
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<ChatViewModel>.value(
          value: viewModel,
          child: Scaffold(
            body: Column(
              key: const ValueKey<String>('popup-test-page'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Builder(
                  builder: (context) {
                    messageContext = context;
                    return const SizedBox(width: 120, height: 40);
                  },
                ),
                MessageReactionBar(
                  state: state,
                  currentAccountId: 'me',
                  emojiBuilder: _emojiBuilder,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final menu = ChatKitMessagePopMenu(
      _supportedMessage(),
      true,
      messageContext,
      globalPosition: const Offset(140, 240),
    );
    menu.show();
    await tester.pump();
    expect(find.byType(MessageReactionQuickBar), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MessageReactionQuickBar), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('popup-test-page')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('message-reaction-add')),
    );
    await tester.pump();
    expect(find.byType(MessageReactionPicker), findsOneWidget);

    // 打开长按菜单会关闭已经显示的 Reaction 面板。
    menu.show();
    await tester.pump();
    expect(find.byType(MessageReactionPicker), findsNothing);
    expect(find.byType(MessageReactionQuickBar), findsOneWidget);

    // 真实点击遮罩下的添加按钮，一次点击即切换到完整面板。
    final addButton =
        find.byKey(const ValueKey<String>('message-reaction-add'));
    await tester.tapAt(tester.getCenter(addButton));
    await tester.pump();
    expect(find.byType(MessageReactionQuickBar), findsNothing);
    expect(find.byType(MessageReactionPicker), findsOneWidget);

    // 已关闭菜单的延迟清理不能取消当前面板的互斥登记。
    menu.clean();
    menu.show();
    await tester.pump();
    expect(find.byType(MessageReactionPicker), findsNothing);
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pump();
    expect(
      tester
          .widget<MessageReactionPicker>(find.byType(MessageReactionPicker))
          .mode,
      MessageReactionPickerMode.quickBarExpanded,
    );
    await tester.tapAt(tester.getCenter(addButton));
    await tester.pump();
    expect(find.byType(MessageReactionPicker), findsOneWidget);
    expect(
      tester
          .widget<MessageReactionPicker>(find.byType(MessageReactionPicker))
          .mode,
      MessageReactionPickerMode.messageBar,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MessageReactionPicker), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('popup-test-page')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('popup-test-page')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey<String>('root-page')), findsOneWidget);
  });

  for (final type in [NIMMessageType.text, NIMMessageType.call]) {
    testWidgets('mobile $type message menu expands the compact reaction row',
        (tester) async {
      final viewModel = _viewModel();
      addTearDown(viewModel.dispose);
      late BuildContext targetContext;
      await tester.pumpWidget(
        _appWithPageProvider(
          viewModel,
          Builder(
            builder: (context) {
              targetContext = context;
              return const SizedBox(width: 120, height: 40);
            },
          ),
        ),
      );

      final menu = ChatKitMessagePopMenu(
        _supportedMessage(type: type),
        true,
        targetContext,
        globalPosition: const Offset(140, 240),
      );
      menu.show();
      await tester.pump();

      final actionItems = find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> &&
            key.value.startsWith('chat-message-action-');
      });
      expect(find.byType(MessageReactionQuickBar), findsOneWidget);
      expect(actionItems, findsWidgets);
      final actionRects = List<Rect>.generate(
        actionItems.evaluate().length,
        (index) => tester.getRect(actionItems.at(index)),
      );
      final firstRowCount = actionRects.length < 5 ? actionRects.length : 5;
      for (var index = 1; index < firstRowCount; index++) {
        expect(actionRects[index].top, actionRects.first.top);
      }
      if (actionRects.length > 5) {
        expect(actionRects[5].top, greaterThan(actionRects.first.top));
        expect(actionRects[5].left, actionRects.first.left);
      }
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pump();
      expect(find.byType(MessageReactionPicker), findsOneWidget);
      expect(actionItems, findsNothing);
      final pickerRect = tester.getRect(find.byType(MessageReactionPicker));
      expect(pickerRect.height, closeTo(168, 0.01));
      expect(pickerRect.width, MessageReactionPicker.width);
      final gridRect = tester.getRect(find.byType(GridView));
      expect(gridRect.left - pickerRect.left, 12);
      expect(gridRect.top - pickerRect.top, 56);
      expect(pickerRect.right - gridRect.right, 12);
      expect(pickerRect.bottom - gridRect.bottom, 12);
      final surfaceRect = tester.getRect(
        find.byKey(const ValueKey<String>('chat-message-pop-menu-surface')),
      );
      expect(surfaceRect.width, pickerRect.width);
      // 气泡箭头和箭头间隔位于面板主体之外。
      expect(surfaceRect.height, pickerRect.height + 12);
      await tester.tap(find.byIcon(Icons.keyboard_arrow_up));
      await tester.pump();
      expect(find.byType(MessageReactionQuickBar), findsOneWidget);
      expect(actionItems, findsWidgets);
      menu.close();
    });
  }

  testWidgets('mobile message menu hides reactions when feature is disabled',
      (tester) async {
    IMKitConfigCenter.enableMessageReaction = false;
    final viewModel = _viewModel();
    addTearDown(viewModel.dispose);
    late BuildContext targetContext;
    await tester.pumpWidget(
      _appWithPageProvider(
        viewModel,
        Builder(
          builder: (context) {
            targetContext = context;
            return const SizedBox(width: 120, height: 40);
          },
        ),
      ),
    );

    final menu = ChatKitMessagePopMenu(
      _supportedMessage(),
      true,
      targetContext,
      globalPosition: const Offset(140, 240),
    );
    menu.show();
    await tester.pump();

    expect(find.byType(MessageReactionQuickBar), findsNothing);
    expect(find.byType(MessageReactionPicker), findsNothing);
    final actionItems = tester.widgetList<SizedBox>(
      find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> &&
            key.value.startsWith('chat-message-action-');
      }),
    ).toList();
    expect(actionItems.length, greaterThan(4));
    final actionRowTops = actionItems
        .map((item) => tester.getTopLeft(find.byKey(item.key!)).dy)
        .toSet();
    expect(actionRowTops, hasLength(2));
    menu.close();
  });

  testWidgets('mobile message menu opens above when there is enough room',
      (tester) async {
    final viewModel = _viewModel();
    addTearDown(viewModel.dispose);
    late BuildContext targetContext;
    await tester.pumpWidget(
      _appWithPageProvider(
        viewModel,
        SizedBox.expand(
          child: Stack(
            children: [
              Positioned(
                top: 360,
                left: 340,
                child: Builder(
                  builder: (context) {
                    targetContext = context;
                    return const SizedBox(
                      key: ValueKey<String>('message-target'),
                      width: 120,
                      height: 40,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final targetRect = tester.getRect(
      find.byKey(const ValueKey<String>('message-target')),
    );
    final menu = ChatKitMessagePopMenu(
      _supportedMessage(),
      true,
      targetContext,
      globalPosition: targetRect.center,
    );
    menu.show();
    await tester.pump();

    final menuRect = tester.getRect(find.byType(MessageReactionQuickBar));
    expect(menuRect.bottom, lessThanOrEqualTo(targetRect.top));
    menu.close();
  });

  testWidgets('mobile message menu opens below when the top has no room',
      (tester) async {
    final viewModel = _viewModel();
    addTearDown(viewModel.dispose);
    late BuildContext targetContext;
    await tester.pumpWidget(
      _appWithPageProvider(
        viewModel,
        SizedBox.expand(
          child: Stack(
            children: [
              Positioned(
                top: 80,
                left: 340,
                child: Builder(
                  builder: (context) {
                    targetContext = context;
                    return const SizedBox(
                      key: ValueKey<String>('message-target-below'),
                      width: 120,
                      height: 40,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final targetRect = tester.getRect(
      find.byKey(const ValueKey<String>('message-target-below')),
    );
    final menu = ChatKitMessagePopMenu(
      _supportedMessage(),
      true,
      targetContext,
      globalPosition: targetRect.center,
    );
    menu.show();
    await tester.pump();

    final menuRect = tester.getRect(find.byType(MessageReactionQuickBar));
    expect(menuRect.top, greaterThanOrEqualTo(targetRect.bottom));
    menu.close();
  });

  testWidgets('mobile message menu centers on an extra-tall message',
      (tester) async {
    final viewModel = _viewModel();
    addTearDown(viewModel.dispose);
    late BuildContext targetContext;
    await tester.pumpWidget(
      _appWithPageProvider(
        viewModel,
        Builder(
          builder: (context) {
            targetContext = context;
            return const SizedBox(
              key: ValueKey<String>('message-target-tall'),
              width: 120,
              height: 400,
            );
          },
        ),
      ),
    );

    final targetRect = tester.getRect(
      find.byKey(const ValueKey<String>('message-target-tall')),
    );
    final menu = ChatKitMessagePopMenu(
      _supportedMessage(),
      true,
      targetContext,
      globalPosition: targetRect.center,
    );
    menu.show();
    await tester.pump();

    final menuRect = tester.getRect(
      find.byKey(const ValueKey<String>('chat-message-pop-menu-surface')),
    );
    expect(menuRect.center.dy, closeTo(targetRect.center.dy, 0.5));
    expect(menuRect.top, greaterThanOrEqualTo(0));
    expect(menuRect.bottom, lessThanOrEqualTo(600));
    menu.close();
  });

  testWidgets('mobile message menu stays inside a narrow viewport',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(280, 480);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final viewModel = _viewModel();
    addTearDown(viewModel.dispose);
    late BuildContext targetContext;
    await tester.pumpWidget(
      _appWithPageProvider(
        viewModel,
        Builder(
          builder: (context) {
            targetContext = context;
            return const SizedBox(width: 120, height: 40);
          },
        ),
      ),
    );

    final menu = ChatKitMessagePopMenu(
      _supportedMessage(),
      true,
      targetContext,
      globalPosition: const Offset(140, 240),
    );
    menu.show();
    await tester.pump();

    var menuRect = tester.getRect(find.byType(MessageReactionQuickBar));
    expect(menuRect.left, greaterThanOrEqualTo(0));
    expect(menuRect.right, lessThanOrEqualTo(280));

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pump();

    menuRect = tester.getRect(find.byType(MessageReactionPicker));
    expect(menuRect.left, greaterThanOrEqualTo(0));
    expect(menuRect.right, lessThanOrEqualTo(280));
    expect(menuRect.top, greaterThanOrEqualTo(0));
    expect(menuRect.bottom, lessThanOrEqualTo(480));
    expect(tester.takeException(), isNull);
    menu.close();
  });

  for (final type in [NIMMessageType.text, NIMMessageType.call]) {
    testWidgets('desktop $type message menu expands the compact reaction row',
        (tester) async {
      final viewModel = _viewModel();
      addTearDown(viewModel.dispose);
      late BuildContext targetContext;
      await tester.pumpWidget(
        ChangeNotifierProvider<ChatViewModel>.value(
          value: viewModel,
          child: _app(
            Builder(
              builder: (context) {
                targetContext = context;
                return const SizedBox(width: 120, height: 40);
              },
            ),
          ),
        ),
      );

      final menu = ChatKitDesktopContextMenu(
        context: targetContext,
        message: _supportedMessage(type: type),
        globalPosition: const Offset(20, 20),
      );
      menu.show();
      await tester.pump();

      expect(find.byType(MessageReactionQuickBar), findsOneWidget);
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pump();
      expect(find.byType(MessageReactionPicker), findsOneWidget);
      menu.close();
    });
  }
}
