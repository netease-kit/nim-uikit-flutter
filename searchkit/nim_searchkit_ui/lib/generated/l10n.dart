// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as RealIntl;

import 'intl/messages_all.dart';
import 'intl_multi_fix.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = RealIntl.Intl.canonicalizedLocale(name);
    Intl.fixMessageLookup = getMessageLookup(localeName)!;
    return initializeMessages(localeName).then((_) {
      RealIntl.Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Search`
  String get search_search {
    return Intl.message(
      'Search',
      name: 'search_search',
      desc: '',
      args: [],
    );
  }

  /// `Please input your key word`
  String get search_search_hit {
    return Intl.message(
      'Please input your key word',
      name: 'search_search_hit',
      desc: '',
      args: [],
    );
  }

  /// `Friend`
  String get search_search_friend {
    return Intl.message(
      'Friend',
      name: 'search_search_friend',
      desc: '',
      args: [],
    );
  }

  /// `Normal team`
  String get search_search_normal_team {
    return Intl.message(
      'Normal team',
      name: 'search_search_normal_team',
      desc: '',
      args: [],
    );
  }

  /// `Advance Team`
  String get search_search_advance_team {
    return Intl.message(
      'Advance Team',
      name: 'search_search_advance_team',
      desc: '',
      args: [],
    );
  }

  /// `This user not exist`
  String get search_empty_tips {
    return Intl.message(
      'This user not exist',
      name: 'search_empty_tips',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);

  @override
  Future<S> load(Locale locale) => S.load(locale);

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
