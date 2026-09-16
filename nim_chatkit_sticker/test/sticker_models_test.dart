// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit_sticker/nim_chatkit_sticker.dart';

void main() {
  test('asset source builds App and package bundle keys', () {
    expect(
      const StickerAssetSource(assetPath: 'assets/a.png').bundleKey,
      'assets/a.png',
    );
    expect(
      const StickerAssetSource(
        assetPath: 'assets/a.png',
        packageName: 'customer_assets',
      ).bundleKey,
      'packages/customer_assets/assets/a.png',
    );
  });

  test('default packs keep product order and resource counts', () {
    final packs = StickerDefaults.packs;
    expect(packs.map((pack) => pack.id), <String>['ajmd', 'xxy', 'lt']);
    expect(packs.map((pack) => pack.stickers.length), <int>[48, 40, 20]);
    expect(
      packs.first.stickers.first.image.bundleKey,
      'packages/nim_chatkit_sticker/assets/sticker/ajmd/ajmd001.png',
    );
    expect(
      packs.last.stickers.last.image.bundleKey,
      'packages/nim_chatkit_sticker/assets/sticker/lt/lt020.png',
    );
    expect(() => packs.add(packs.first), throwsUnsupportedError);
  });
}
