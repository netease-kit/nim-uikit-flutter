// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:netease_corekit/report/xkit_report.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../l10n/sticker_localizations.dart';
import 'sticker_config.dart';
import 'sticker_defaults.dart';
import 'sticker_models.dart';
import 'sticker_panel_extension.dart';

const String _extensionId = 'nim_chatkit_sticker';

/// Entry point for the optional Sticker package.
class StickerKitClient {
  StickerKitClient._();

  static bool _reported = false;

  /// Sticker localization delegate for the host App.
  static LocalizationsDelegate<StickerLocalizations> get delegate =>
      StickerLocalizations.delegate;

  /// Registers Sticker tabs using an initialization-time config snapshot.
  static void init({StickerConfig config = const StickerConfig()}) {
    if (!_reported) {
      XKitReporter().register(
        moduleName: 'ChatStickerKit',
        moduleVersion: '10.9.5',
      );
      _reported = true;
    }

    ChatKitClient.instance.unregisterEmojiPanelExtension(_extensionId);
    if (!config.enabled) {
      return;
    }

    final source = config.packs ?? StickerDefaults.packs;
    final packs = _validatedPacks(source);
    if (packs.isEmpty) {
      return;
    }
    ChatKitClient.instance.registerEmojiPanelExtension(
      StickerPanelExtension(packs),
    );
  }

  static List<StickerPack> _validatedPacks(List<StickerPack> source) {
    final packIds = <String>{};
    final valid = <StickerPack>[];
    for (final pack in source) {
      if (pack.id.isEmpty ||
          !packIds.add(pack.id) ||
          pack.tabIcon.assetPath.isEmpty ||
          pack.selectedTabIcon.assetPath.isEmpty ||
          pack.stickers.isEmpty) {
        _logInvalid('skip invalid or duplicate pack: ${pack.id}');
        continue;
      }

      final itemIds = <String>{};
      final items = pack.stickers.where((item) {
        final validItem = item.id.isNotEmpty &&
            item.image.assetPath.isNotEmpty &&
            itemIds.add(item.id);
        if (!validItem) {
          _logInvalid(
            'skip invalid or duplicate item: ${pack.id}/${item.id}',
          );
        }
        return validItem;
      }).toList(growable: false);
      if (items.isEmpty) {
        _logInvalid('skip empty pack after validation: ${pack.id}');
        continue;
      }
      valid.add(
        StickerPack(
          id: pack.id,
          tabIcon: pack.tabIcon,
          selectedTabIcon: pack.selectedTabIcon,
          stickers: UnmodifiableListView<StickerItem>(items),
          semanticsLabel: pack.semanticsLabel,
        ),
      );
    }
    return UnmodifiableListView<StickerPack>(valid);
  }

  static void _logInvalid(String content) {
    Alog.e(tag: 'StickerKit', moduleName: 'StickerConfig', content: content);
  }
}
