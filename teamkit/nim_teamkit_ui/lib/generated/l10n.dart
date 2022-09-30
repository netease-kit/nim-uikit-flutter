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

  /// `Setting`
  String get team_setting_title {
    return Intl.message(
      'Setting',
      name: 'team_setting_title',
      desc: '',
      args: [],
    );
  }

  /// `Team info`
  String get team_info_title {
    return Intl.message(
      'Team info',
      name: 'team_info_title',
      desc: '',
      args: [],
    );
  }

  /// `Team Group info`
  String get team_group_info_title {
    return Intl.message(
      'Team Group info',
      name: 'team_group_info_title',
      desc: '',
      args: [],
    );
  }

  /// `Team name`
  String get team_name_title {
    return Intl.message(
      'Team name',
      name: 'team_name_title',
      desc: '',
      args: [],
    );
  }

  /// `Team Group name`
  String get team_group_name_title {
    return Intl.message(
      'Team Group name',
      name: 'team_group_name_title',
      desc: '',
      args: [],
    );
  }

  /// `Team member`
  String get team_member_title {
    return Intl.message(
      'Team member',
      name: 'team_member_title',
      desc: '',
      args: [],
    );
  }

  /// `Team Group member`
  String get team_group_member_title {
    return Intl.message(
      'Team Group member',
      name: 'team_group_member_title',
      desc: '',
      args: [],
    );
  }

  /// `Team icon`
  String get team_icon_title {
    return Intl.message(
      'Team icon',
      name: 'team_icon_title',
      desc: '',
      args: [],
    );
  }

  /// `Team Group icon`
  String get team_group_icon_title {
    return Intl.message(
      'Team Group icon',
      name: 'team_group_icon_title',
      desc: '',
      args: [],
    );
  }

  /// `Team introduce`
  String get team_introduce_title {
    return Intl.message(
      'Team introduce',
      name: 'team_introduce_title',
      desc: '',
      args: [],
    );
  }

  /// `My nickname in Team`
  String get team_my_nickname_title {
    return Intl.message(
      'My nickname in Team',
      name: 'team_my_nickname_title',
      desc: '',
      args: [],
    );
  }

  /// `Mark`
  String get team_mark {
    return Intl.message(
      'Mark',
      name: 'team_mark',
      desc: '',
      args: [],
    );
  }

  /// `History`
  String get team_history {
    return Intl.message(
      'History',
      name: 'team_history',
      desc: '',
      args: [],
    );
  }

  /// `Open message notice`
  String get team_message_tip {
    return Intl.message(
      'Open message notice',
      name: 'team_message_tip',
      desc: '',
      args: [],
    );
  }

  /// `Set session top`
  String get team_session_pin {
    return Intl.message(
      'Set session top',
      name: 'team_session_pin',
      desc: '',
      args: [],
    );
  }

  /// `Mute`
  String get team_mute {
    return Intl.message(
      'Mute',
      name: 'team_mute',
      desc: '',
      args: [],
    );
  }

  /// `Invite others permission`
  String get team_invite_other_permission {
    return Intl.message(
      'Invite others permission',
      name: 'team_invite_other_permission',
      desc: '',
      args: [],
    );
  }

  /// `Permission to modify Team info`
  String get team_update_info_permission {
    return Intl.message(
      'Permission to modify Team info',
      name: 'team_update_info_permission',
      desc: '',
      args: [],
    );
  }

  /// `Whether the invitee's consent is required`
  String get team_need_agreed_when_be_invited_permission {
    return Intl.message(
      'Whether the invitee\'s consent is required',
      name: 'team_need_agreed_when_be_invited_permission',
      desc: '',
      args: [],
    );
  }

  /// `Disband the Team chat`
  String get team_advanced_dismiss {
    return Intl.message(
      'Disband the Team chat',
      name: 'team_advanced_dismiss',
      desc: '',
      args: [],
    );
  }

  /// `Exit Team chat`
  String get team_advanced_quit {
    return Intl.message(
      'Exit Team chat',
      name: 'team_advanced_quit',
      desc: '',
      args: [],
    );
  }

  /// `Exit Team Group chat`
  String get team_group_quit {
    return Intl.message(
      'Exit Team Group chat',
      name: 'team_group_quit',
      desc: '',
      args: [],
    );
  }

  /// `Choose default icon`
  String get team_default_icon {
    return Intl.message(
      'Choose default icon',
      name: 'team_default_icon',
      desc: '',
      args: [],
    );
  }

  /// `All member`
  String get team_all_member {
    return Intl.message(
      'All member',
      name: 'team_all_member',
      desc: '',
      args: [],
    );
  }

  /// `Owner`
  String get team_owner {
    return Intl.message(
      'Owner',
      name: 'team_owner',
      desc: '',
      args: [],
    );
  }

  /// `Modify avatar`
  String get team_update_icon {
    return Intl.message(
      'Modify avatar',
      name: 'team_update_icon',
      desc: '',
      args: [],
    );
  }

  /// `cancel`
  String get team_cancel {
    return Intl.message(
      'cancel',
      name: 'team_cancel',
      desc: '',
      args: [],
    );
  }

  /// `confirm`
  String get team_confirm {
    return Intl.message(
      'confirm',
      name: 'team_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to leave the Team chat?`
  String get team_quit_advanced_team_query {
    return Intl.message(
      'Do you want to leave the Team chat?',
      name: 'team_quit_advanced_team_query',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to leave the Team Group chat?`
  String get team_quit_group_team_query {
    return Intl.message(
      'Do you want to leave the Team Group chat?',
      name: 'team_quit_group_team_query',
      desc: '',
      args: [],
    );
  }

  /// `Disband the Team chat?`
  String get team_dismiss_advanced_team_query {
    return Intl.message(
      'Disband the Team chat?',
      name: 'team_dismiss_advanced_team_query',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get team_save {
    return Intl.message(
      'Save',
      name: 'team_save',
      desc: '',
      args: [],
    );
  }

  /// `Search friend`
  String get team_search_friend {
    return Intl.message(
      'Search friend',
      name: 'team_search_friend',
      desc: '',
      args: [],
    );
  }

  /// `No Permission`
  String get team_no_permission {
    return Intl.message(
      'No Permission',
      name: 'team_no_permission',
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
