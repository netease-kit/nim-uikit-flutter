// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Localized strings used by the optional Sticker package.
class StickerLocalizations {
  /// Creates strings for [locale].
  const StickerLocalizations(this.locale);

  /// Current locale.
  final Locale locale;

  /// Finds localized strings and falls back safely when no delegate is added.
  static StickerLocalizations of(BuildContext context) {
    return Localizations.of<StickerLocalizations>(
          context,
          StickerLocalizations,
        ) ??
        StickerLocalizations(
          Localizations.maybeLocaleOf(context) ?? const Locale('en'),
        );
  }

  /// Message shown when a Sticker asset cannot enter the image send flow.
  String get loadFailed => locale.languageCode == 'zh'
      ? '贴图加载失败，请重试'
      : 'Unable to load Sticker. Please try again.';

  /// Package localization delegate.
  static const LocalizationsDelegate<StickerLocalizations> delegate =
      _StickerLocalizationsDelegate();
}

class _StickerLocalizationsDelegate
    extends LocalizationsDelegate<StickerLocalizations> {
  const _StickerLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'zh' || locale.languageCode == 'en';

  @override
  Future<StickerLocalizations> load(Locale locale) =>
      SynchronousFuture<StickerLocalizations>(StickerLocalizations(locale));

  @override
  bool shouldReload(_StickerLocalizationsDelegate old) => false;
}
