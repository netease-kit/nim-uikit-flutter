// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit_sticker/nim_chatkit_sticker.dart';
import 'package:nim_chatkit_sticker/src/sticker_grid.dart';
import 'package:nim_chatkit_sticker/src/sticker_panel_extension.dart';
import 'package:nim_chatkit_ui/view/input/emoji_panel_extension.dart';

void main() {
  test('default packs contribute the expected mobile page counts', () {
    final tabs = StickerPanelExtension(StickerDefaults.packs).buildTabs();

    expect(tabs.map((tab) => tab.id), <String>['ajmd', 'xxy', 'lt']);
    expect(tabs.map((tab) => tab.mobilePageCount), <int>[6, 5, 3]);
    expect(tabs.every((tab) => tab.mobilePageBuilder != null), isTrue);
  });

  testWidgets('sticker tab icons stay colored when unselected', (tester) async {
    final tab = StickerPanelExtension(StickerDefaults.packs).buildTabs().first;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Row(
            children: <Widget>[
              tab.iconBuilder(context, false),
              tab.iconBuilder(context, true),
            ],
          ),
        ),
      ),
    );

    final images = tester.widgetList<Image>(find.byType(Image));
    expect(
      images.map((image) => (image.image as AssetImage).assetName),
      everyElement(endsWith('_s_pressed.png')),
    );
  });

  testWidgets('mobile page keeps four columns and uses the padded full width',
      (tester) async {
    final pack = StickerPack(
      id: 'test',
      tabIcon: StickerDefaults.packs.first.tabIcon,
      selectedTabIcon: StickerDefaults.packs.first.selectedTabIcon,
      stickers: StickerDefaults.packs.first.stickers.take(13).toList(),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          StickerKitClient.delegate,
        ],
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 220,
            child: StickerGrid(
              pack: pack,
              tabContext: EmojiPanelTabContext(
                displayMode: EmojiPanelDisplayMode.mobile,
                sendImage: (value) async => true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 4);
    expect(grid.physics, isA<NeverScrollableScrollPhysics>());
    expect(tester.getSize(find.byType(GridView)).width, 370);
    expect(find.byType(Image), findsNWidgets(8));
    final firstSticker = find.bySemanticsLabel(pack.stickers.first.id);
    expect(
      find.descendant(
        of: firstSticker,
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
    );
  });

  testWidgets('mobile page renders the requested Sticker slice',
      (tester) async {
    final pack = StickerPack(
      id: 'test',
      tabIcon: StickerDefaults.packs.first.tabIcon,
      selectedTabIcon: StickerDefaults.packs.first.selectedTabIcon,
      stickers: StickerDefaults.packs.first.stickers.take(13).toList(),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          StickerKitClient.delegate,
        ],
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 220,
            child: StickerGrid(
              pack: pack,
              mobilePageIndex: 1,
              tabContext: EmojiPanelTabContext(
                displayMode: EmojiPanelDisplayMode.mobile,
                sendImage: (value) async => true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsNWidgets(5));
  });
}
