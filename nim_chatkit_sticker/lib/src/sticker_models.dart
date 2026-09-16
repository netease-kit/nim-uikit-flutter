// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// A Flutter asset used by a Sticker pack.
class StickerAssetSource {
  /// Creates an App or package asset source.
  const StickerAssetSource({required this.assetPath, this.packageName})
      : assert(assetPath != '');

  /// Asset path declared in the owning Flutter pubspec.
  final String assetPath;

  /// Owning package, or null when the asset belongs to the customer App.
  final String? packageName;

  /// Key accepted by [AssetBundle.load].
  String get bundleKey => packageName == null || packageName!.isEmpty
      ? assetPath
      : 'packages/$packageName/$assetPath';
}

/// A single image that can be sent as a Sticker.
class StickerItem {
  /// Creates a Sticker item.
  const StickerItem({
    required this.id,
    required this.image,
    this.semanticsLabel,
  }) : assert(id != '');

  /// Stable identifier within its pack.
  final String id;

  /// Image asset source.
  final StickerAssetSource image;

  /// Optional accessibility label.
  final String? semanticsLabel;
}

/// An ordered Sticker pack represented by one emoji-panel tab.
class StickerPack {
  /// Creates a Sticker pack.
  const StickerPack({
    required this.id,
    required this.tabIcon,
    required this.selectedTabIcon,
    required this.stickers,
    this.semanticsLabel,
  }) : assert(id != '');

  /// Stable pack identifier.
  final String id;

  /// Unselected tab icon.
  final StickerAssetSource tabIcon;

  /// Selected tab icon.
  final StickerAssetSource selectedTabIcon;

  /// Stickers in display order.
  final List<StickerItem> stickers;

  /// Optional accessibility label for the pack tab.
  final String? semanticsLabel;
}
