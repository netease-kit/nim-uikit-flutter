// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'sticker_models.dart';

/// Loaded Sticker bytes and decoded dimensions.
class LoadedStickerAsset {
  /// Creates decoded Sticker asset data.
  const LoadedStickerAsset({
    required this.bytes,
    required this.width,
    required this.height,
  });

  /// Encoded bytes used to create the image message.
  final Uint8List bytes;

  /// Pixel width.
  final int width;

  /// Pixel height.
  final int height;
}

/// Lazily loads Sticker assets and coalesces concurrent reads.
class StickerAssetLoader {
  StickerAssetLoader._();

  static final Map<String, Future<LoadedStickerAsset>> _cache =
      <String, Future<LoadedStickerAsset>>{};

  /// Loads and decodes [source]. Failed entries are removed to allow retry.
  static Future<LoadedStickerAsset> load(StickerAssetSource source) {
    final existing = _cache[source.bundleKey];
    if (existing != null) {
      return existing;
    }

    final pending = _loadAndEvictOnFailure(source);
    _cache[source.bundleKey] = pending;
    return pending;
  }

  static Future<LoadedStickerAsset> _loadAndEvictOnFailure(
    StickerAssetSource source,
  ) async {
    try {
      return await _load(source);
    } catch (_) {
      _cache.remove(source.bundleKey);
      rethrow;
    }
  }

  static Future<LoadedStickerAsset> _load(StickerAssetSource source) async {
    final data = await rootBundle.load(source.bundleKey);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      try {
        return LoadedStickerAsset(
          bytes: bytes,
          width: frame.image.width,
          height: frame.image.height,
        );
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}
