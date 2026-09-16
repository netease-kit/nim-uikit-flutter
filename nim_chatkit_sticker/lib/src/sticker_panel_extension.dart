// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:nim_chatkit_ui/view/input/emoji_panel_extension.dart';

import 'sticker_grid.dart';
import 'sticker_models.dart';

/// Emoji-panel extension backed by configured Sticker packs.
class StickerPanelExtension extends EmojiPanelExtension {
  /// Creates the package extension.
  StickerPanelExtension(this.packs);

  /// Validated immutable pack snapshot.
  final List<StickerPack> packs;

  @override
  String get id => 'nim_chatkit_sticker';

  @override
  List<EmojiPanelTab> buildTabs() {
    return packs.map((pack) {
      return EmojiPanelTab(
        id: pack.id,
        semanticsLabel: pack.semanticsLabel ?? pack.id,
        iconBuilder: (context, selected) {
          final source = pack.selectedTabIcon;
          return Image.asset(
            source.assetPath,
            package: source.packageName,
            width: 28,
            height: 28,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.image_not_supported_outlined,
              size: 22,
              color: Color(0xff8E8E93),
            ),
          );
        },
        contentBuilder: (context, tabContext) =>
            StickerGrid(pack: pack, tabContext: tabContext),
        mobilePageCount: StickerGrid.mobilePageCount(
          pack.stickers.length,
        ),
        mobilePageBuilder: (context, tabContext, pageIndex) => StickerGrid(
          pack: pack,
          tabContext: tabContext,
          mobilePageIndex: pageIndex,
        ),
      );
    }).toList(growable: false);
  }
}
