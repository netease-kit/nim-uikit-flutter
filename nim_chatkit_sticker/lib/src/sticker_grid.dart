// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nim_chatkit_ui/view/input/emoji_panel_extension.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../l10n/sticker_localizations.dart';
import 'sticker_asset_loader.dart';
import 'sticker_models.dart';

/// Four-column Sticker grid used by mobile and desktop/Web panels.
class StickerGrid extends StatefulWidget {
  /// Number of Stickers displayed on one mobile page.
  static const int mobilePageSize = 8;

  /// Creates a Sticker grid.
  const StickerGrid({
    Key? key,
    required this.pack,
    required this.tabContext,
    this.mobilePageIndex,
  })  : assert(mobilePageIndex == null || mobilePageIndex >= 0),
        super(key: key);

  /// Pack rendered by the grid.
  final StickerPack pack;

  /// Current panel capabilities.
  final EmojiPanelTabContext tabContext;

  /// Mobile page to render. Desktop/Web ignores this value and stays scrollable.
  final int? mobilePageIndex;

  /// Returns the number of horizontal mobile pages needed for [itemCount].
  static int mobilePageCount(int itemCount) {
    return (itemCount / mobilePageSize).ceil();
  }

  @override
  State<StickerGrid> createState() => _StickerGridState();
}

class _StickerGridState extends State<StickerGrid> {
  final Set<String> _sending = <String>{};

  Future<void> _send(StickerItem item) async {
    if (!_sending.add(item.id)) {
      return;
    }
    setState(() {});
    try {
      final loaded = await StickerAssetLoader.load(item.image);
      if (!mounted) {
        return;
      }
      final accepted = await widget.tabContext.sendImage(
        ChatImageSendRequest(
          bytes: loaded.bytes,
          fileName: 'sticker_${item.id}.png',
          imageType: 'png',
          width: loaded.width,
          height: loaded.height,
          cacheKey: item.image.bundleKey,
        ),
      );
      if (!accepted && mounted) {
        _showError(item.image.bundleKey);
      }
    } catch (error) {
      if (mounted) {
        _showError(item.image.bundleKey, error: error);
      }
    } finally {
      if (mounted) {
        setState(() => _sending.remove(item.id));
      }
    }
  }

  void _showError(String resourceKey, {Object? error}) {
    Alog.e(
      tag: 'StickerKit',
      moduleName: 'StickerAssetLoader',
      content: 'load or prepare failed: key=$resourceKey, error=$error',
    );
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(StickerLocalizations.of(context).loadFailed)),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabContext.displayMode == EmojiPanelDisplayMode.mobile) {
      return _buildMobilePage(widget.mobilePageIndex ?? 0);
    }
    return _buildDesktopGrid();
  }

  Widget _buildMobilePage(int pageIndex) {
    final start = pageIndex * StickerGrid.mobilePageSize;
    final end = start + StickerGrid.mobilePageSize < widget.pack.stickers.length
        ? start + StickerGrid.mobilePageSize
        : widget.pack.stickers.length;
    final itemCount = start < widget.pack.stickers.length ? end - start : 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const crossAxisSpacing = 6.0;
          const mainAxisSpacing = 6.0;
          final itemWidth = math.max(
            1.0,
            (constraints.maxWidth - crossAxisSpacing * 3) / 4,
          );
          final itemHeight = math.max(
            1.0,
            (constraints.maxHeight - mainAxisSpacing) / 2,
          );
          return GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: mainAxisSpacing,
              crossAxisSpacing: crossAxisSpacing,
              childAspectRatio: itemWidth / itemHeight,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) => _buildItem(start + index),
          );
        },
      ),
    );
  }

  Widget _buildDesktopGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const maxGridWidth = 4 * 64.0 + 3 * 6.0;
        final gridWidth = constraints.maxWidth < maxGridWidth
            ? constraints.maxWidth
            : maxGridWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: gridWidth,
            height: constraints.maxHeight,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: widget.pack.stickers.length,
              itemBuilder: (context, index) => _buildItem(index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItem(int index) {
    final item = widget.pack.stickers[index];
    return _StickerItem(
      item: item,
      sending: _sending.contains(item.id),
      desktopOrWeb:
          widget.tabContext.displayMode == EmojiPanelDisplayMode.desktopOrWeb,
      onTap: () => _send(item),
    );
  }
}

class _StickerItem extends StatelessWidget {
  const _StickerItem({
    required this.item,
    required this.sending,
    required this.desktopOrWeb,
    required this.onTap,
  });

  final StickerItem item;
  final bool sending;
  final bool desktopOrWeb;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      item.image.assetPath,
      package: item.image.packageName,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image_outlined, color: Color(0xff8E8E93)),
    );
    return Semantics(
      label: item.semanticsLabel ?? item.id,
      button: true,
      child: MouseRegion(
        cursor: desktopOrWeb ? SystemMouseCursors.click : MouseCursor.defer,
        child: InkWell(
          onTap: sending ? null : onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                image,
                if (sending)
                  const Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
