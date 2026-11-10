// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'sticker_models.dart';

/// Initialization-time Sticker configuration.
class StickerConfig {
  /// Creates Sticker configuration.
  ///
  /// A null [packs] value selects [StickerDefaults.packs]. An explicit list
  /// replaces the defaults.
  const StickerConfig({this.enabled = true, this.packs});

  /// Whether the Sticker tabs are registered.
  final bool enabled;

  /// Custom packs, or null to use the bundled defaults.
  final List<StickerPack>? packs;
}
