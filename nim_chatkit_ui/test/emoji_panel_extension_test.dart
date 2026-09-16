// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/view/input/emoji_panel.dart';
import 'package:nim_chatkit_ui/view/input/emoji_panel_extension.dart';

class _TestExtension extends EmojiPanelExtension {
  _TestExtension(this.name);

  final String name;

  @override
  String get id => name;

  @override
  List<EmojiPanelTab> buildTabs() => <EmojiPanelTab>[
        EmojiPanelTab(
          id: 'tab',
          iconBuilder: (context, selected) => const SizedBox.shrink(),
          contentBuilder: (context, tabContext) => const SizedBox.shrink(),
        ),
      ];
}

class _PagedTestExtension extends EmojiPanelExtension {
  @override
  String get id => 'paged';

  @override
  List<EmojiPanelTab> buildTabs() => <EmojiPanelTab>[
        EmojiPanelTab(
          id: 'first',
          semanticsLabel: 'first pack',
          iconBuilder: (context, selected) => const SizedBox.shrink(),
          contentBuilder: (context, tabContext) => const Text('first desktop'),
          mobilePageCount: 2,
          mobilePageBuilder: (context, tabContext, pageIndex) =>
              Text('first page $pageIndex'),
        ),
        EmojiPanelTab(
          id: 'second',
          semanticsLabel: 'second pack',
          iconBuilder: (context, selected) => const SizedBox.shrink(),
          contentBuilder: (context, tabContext) => const Text('second desktop'),
          mobilePageBuilder: (context, tabContext, pageIndex) =>
              Text('second page $pageIndex'),
        ),
      ];
}

void main() {
  final client = ChatKitClient.instance;

  tearDown(() {
    client.unregisterEmojiPanelExtension('first');
    client.unregisterEmojiPanelExtension('second');
    client.unregisterEmojiPanelExtension('paged');
  });

  test('emoji panel extensions preserve order and expose a snapshot', () {
    client.registerEmojiPanelExtension(_TestExtension('first'));
    client.registerEmojiPanelExtension(_TestExtension('second'));

    final snapshot = client.emojiPanelExtensions;
    expect(
        snapshot.map((extension) => extension.id), <String>['first', 'second']);
    expect(() => snapshot.add(_TestExtension('third')), throwsUnsupportedError);
  });

  test('registering the same extension id replaces it in place', () {
    final original = _TestExtension('first');
    final replacement = _TestExtension('first');
    client.registerEmojiPanelExtension(original);
    client.registerEmojiPanelExtension(_TestExtension('second'));
    client.registerEmojiPanelExtension(replacement);

    expect(client.emojiPanelExtensions.first, same(replacement));
    expect(
      client.emojiPanelExtensions.map((extension) => extension.id),
      <String>['first', 'second'],
    );
  });

  test('image request validates message-safe input', () {
    final valid = ChatImageSendRequest(
      bytes: Uint8List.fromList(<int>[1]),
      fileName: 'sticker.png',
      imageType: 'png',
      width: 1,
      height: 1,
      cacheKey: 'asset-key',
    );
    expect(valid.isValid, isTrue);
    expect(
      ChatImageSendRequest(
        bytes: valid.bytes,
        fileName: '../sticker.png',
        imageType: 'png',
        width: 1,
        height: 1,
        cacheKey: 'asset-key',
      ).isValid,
      isFalse,
    );
  });

  testWidgets('mobile pages swipe continuously into the next extension tab',
      (tester) async {
    client.registerEmojiPanelExtension(_PagedTestExtension());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 260,
            child: EmojiPanel(
              onEmojiSelected: (_) {},
              onEmojiSendClick: () {},
              onEmojiDelete: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('first pack'));
    await tester.pumpAndSettle();
    expect(find.text('first page 0'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('emoji-panel-page-indicator')),
      findsOneWidget,
    );
    expect(find.text('Send'), findsNothing);

    await tester.drag(find.byType(PageView), const Offset(-360, 0));
    await tester.pumpAndSettle();
    expect(find.text('first page 1'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-360, 0));
    await tester.pumpAndSettle();
    expect(find.text('second page 0'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('emoji-panel-page-indicator')),
      findsNothing,
    );

    await tester.drag(find.byType(PageView), const Offset(360, 0));
    await tester.pumpAndSettle();
    expect(find.text('first page 1'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('emoji'));
    await tester.pumpAndSettle();
    expect(find.text('Send'), findsOneWidget);
  });

  testWidgets('emoji tab keeps the bundled colored icon', (tester) async {
    client.registerEmojiPanelExtension(_TestExtension('first'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 260,
            child: EmojiPanel(
              onEmojiSelected: (_) {},
              onEmojiSendClick: () {},
              onEmojiDelete: () {},
            ),
          ),
        ),
      ),
    );

    final emojiTab = find.bySemanticsLabel('emoji');
    final icon = tester.widget<Image>(
      find.descendant(of: emojiTab, matching: find.byType(Image)),
    );
    expect(
      (icon.image as AssetImage).assetName,
      'emoji/default/emoji_00.png',
    );
  });
}
