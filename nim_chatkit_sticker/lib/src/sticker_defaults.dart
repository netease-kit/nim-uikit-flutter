// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'sticker_models.dart';

const String _packageName = 'nim_chatkit_sticker';

/// Bundled Sticker packs that can be used directly or combined with custom packs.
class StickerDefaults {
  StickerDefaults._();

  static final List<StickerPack> _packs = UnmodifiableListView<StickerPack>(
    <StickerPack>[_pack('ajmd', 48), _pack('xxy', 40), _pack('lt', 20)],
  );

  /// Returns the immutable default `ajmd`, `xxy`, and `lt` packs.
  static List<StickerPack> get packs => _packs;

  static StickerPack _pack(String id, int count) {
    return StickerPack(
      id: id,
      semanticsLabel: id,
      tabIcon: StickerAssetSource(
        assetPath: 'assets/sticker/${id}_s_normal.png',
        packageName: _packageName,
      ),
      selectedTabIcon: StickerAssetSource(
        assetPath: 'assets/sticker/${id}_s_pressed.png',
        packageName: _packageName,
      ),
      stickers: UnmodifiableListView<StickerItem>(
        List<StickerItem>.generate(count, (index) {
          final number = (index + 1).toString().padLeft(3, '0');
          return StickerItem(
            id: '${id}_$number',
            semanticsLabel: '${id}_$number',
            image: StickerAssetSource(
              assetPath: 'assets/sticker/$id/$id$number.png',
              packageName: _packageName,
            ),
          );
        }),
      ),
    );
  }
}
