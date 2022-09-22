// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'intl/messages_all.dart';

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
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
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

  /// `Netease IM`
  String get appName {
    return Intl.message(
      'Netease IM',
      name: 'appName',
      desc: '',
      args: [],
    );
  }

  /// `Netease CommsEase`
  String get yunxin_name {
    return Intl.message(
      'Netease CommsEase',
      name: 'yunxin_name',
      desc: '',
      args: [],
    );
  }

  /// `Stable instant messaging service`
  String get yunxin_desc {
    return Intl.message(
      'Stable instant messaging service',
      name: 'yunxin_desc',
      desc: '',
      args: [],
    );
  }

  /// `register/login`
  String get welcome_button {
    return Intl.message(
      'register/login',
      name: 'welcome_button',
      desc: '',
      args: [],
    );
  }

  /// `message`
  String get message {
    return Intl.message(
      'message',
      name: 'message',
      desc: '',
      args: [],
    );
  }

  /// `contact`
  String get contact {
    return Intl.message(
      'contact',
      name: 'contact',
      desc: '',
      args: [],
    );
  }

  /// `mine`
  String get mine {
    return Intl.message(
      'mine',
      name: 'mine',
      desc: '',
      args: [],
    );
  }

  /// `conversation`
  String get conversation {
    return Intl.message(
      'conversation',
      name: 'conversation',
      desc: '',
      args: [],
    );
  }

  /// `Loading...`
  String get dataIsLoading {
    return Intl.message(
      'Loading...',
      name: 'dataIsLoading',
      desc: '',
      args: [],
    );
  }

  /// `Account:{account}`
  String tab_mine_account(String account) {
    return Intl.message(
      'Account:$account',
      name: 'tab_mine_account',
      desc: '',
      args: [account],
    );
  }

  /// `Collect`
  String get mine_collect {
    return Intl.message(
      'Collect',
      name: 'mine_collect',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get mine_about {
    return Intl.message(
      'About',
      name: 'mine_about',
      desc: '',
      args: [],
    );
  }

  /// `Setting`
  String get mine_setting {
    return Intl.message(
      'Setting',
      name: 'mine_setting',
      desc: '',
      args: [],
    );
  }

  /// `Version`
  String get mine_version {
    return Intl.message(
      'Version',
      name: 'mine_version',
      desc: '',
      args: [],
    );
  }

  /// `Product introduction`
  String get mine_product {
    return Intl.message(
      'Product introduction',
      name: 'mine_product',
      desc: '',
      args: [],
    );
  }

  /// `User info`
  String get user_info_title {
    return Intl.message(
      'User info',
      name: 'user_info_title',
      desc: '',
      args: [],
    );
  }

  /// `Avatar`
  String get user_info_avatar {
    return Intl.message(
      'Avatar',
      name: 'user_info_avatar',
      desc: '',
      args: [],
    );
  }

  /// `Account`
  String get user_info_account {
    return Intl.message(
      'Account',
      name: 'user_info_account',
      desc: '',
      args: [],
    );
  }

  /// `Nickname`
  String get user_info_nickname {
    return Intl.message(
      'Nickname',
      name: 'user_info_nickname',
      desc: '',
      args: [],
    );
  }

  /// `Sex`
  String get user_info_sexual {
    return Intl.message(
      'Sex',
      name: 'user_info_sexual',
      desc: '',
      args: [],
    );
  }

  /// `Birthday`
  String get user_info_birthday {
    return Intl.message(
      'Birthday',
      name: 'user_info_birthday',
      desc: '',
      args: [],
    );
  }

  /// `Phone`
  String get user_info_phone {
    return Intl.message(
      'Phone',
      name: 'user_info_phone',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get user_info_email {
    return Intl.message(
      'Email',
      name: 'user_info_email',
      desc: '',
      args: [],
    );
  }

  /// `Signature`
  String get user_info_sign {
    return Intl.message(
      'Signature',
      name: 'user_info_sign',
      desc: '',
      args: [],
    );
  }

  /// `Copy success!`
  String get action_copy_success {
    return Intl.message(
      'Copy success!',
      name: 'action_copy_success',
      desc: '',
      args: [],
    );
  }

  /// `Male`
  String get sexual_male {
    return Intl.message(
      'Male',
      name: 'sexual_male',
      desc: '',
      args: [],
    );
  }

  /// `Female`
  String get sexual_female {
    return Intl.message(
      'Female',
      name: 'sexual_female',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get sexual_unknown {
    return Intl.message(
      'Unknown',
      name: 'sexual_unknown',
      desc: '',
      args: [],
    );
  }

  /// `Complete`
  String get user_info_complete {
    return Intl.message(
      'Complete',
      name: 'user_info_complete',
      desc: '',
      args: [],
    );
  }

  /// `Request fail`
  String get request_fail {
    return Intl.message(
      'Request fail',
      name: 'request_fail',
      desc: '',
      args: [],
    );
  }

  /// `Logout`
  String get mine_logout {
    return Intl.message(
      'Logout',
      name: 'mine_logout',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure to log out of the current login account?`
  String get logout_dialog_content {
    return Intl.message(
      'Are you sure to log out of the current login account?',
      name: 'logout_dialog_content',
      desc: '',
      args: [],
    );
  }

  /// `YES`
  String get logout_dialog_agree {
    return Intl.message(
      'YES',
      name: 'logout_dialog_agree',
      desc: '',
      args: [],
    );
  }

  /// `NO`
  String get logout_dialog_disagree {
    return Intl.message(
      'NO',
      name: 'logout_dialog_disagree',
      desc: '',
      args: [],
    );
  }

  /// `Notify`
  String get setting_notify {
    return Intl.message(
      'Notify',
      name: 'setting_notify',
      desc: '',
      args: [],
    );
  }

  /// `Clear cache`
  String get setting_clear_cache {
    return Intl.message(
      'Clear cache',
      name: 'setting_clear_cache',
      desc: '',
      args: [],
    );
  }

  /// `Handset mode`
  String get setting_play_mode {
    return Intl.message(
      'Handset mode',
      name: 'setting_play_mode',
      desc: '',
      args: [],
    );
  }

  /// `Filter notify`
  String get setting_filter_notify {
    return Intl.message(
      'Filter notify',
      name: 'setting_filter_notify',
      desc: '',
      args: [],
    );
  }

  /// `Delete notes when deleting friends`
  String get setting_friend_delete_mode {
    return Intl.message(
      'Delete notes when deleting friends',
      name: 'setting_friend_delete_mode',
      desc: '',
      args: [],
    );
  }

  /// `Message read and unread function`
  String get setting_message_read_mode {
    return Intl.message(
      'Message read and unread function',
      name: 'setting_message_read_mode',
      desc: '',
      args: [],
    );
  }

  /// `New message notification`
  String get setting_notify_info {
    return Intl.message(
      'New message notification',
      name: 'setting_notify_info',
      desc: '',
      args: [],
    );
  }

  /// `Message reminder mode`
  String get setting_notify_mode {
    return Intl.message(
      'Message reminder mode',
      name: 'setting_notify_mode',
      desc: '',
      args: [],
    );
  }

  /// `Ring Mode`
  String get setting_notify_mode_ring {
    return Intl.message(
      'Ring Mode',
      name: 'setting_notify_mode_ring',
      desc: '',
      args: [],
    );
  }

  /// `Vibration Mode`
  String get setting_notify_mode_shake {
    return Intl.message(
      'Vibration Mode',
      name: 'setting_notify_mode_shake',
      desc: '',
      args: [],
    );
  }

  /// `Push settings`
  String get setting_notify_push {
    return Intl.message(
      'Push settings',
      name: 'setting_notify_push',
      desc: '',
      args: [],
    );
  }

  /// `Receive pushes synchronously on PC/Web`
  String get setting_notify_push_sync {
    return Intl.message(
      'Receive pushes synchronously on PC/Web',
      name: 'setting_notify_push_sync',
      desc: '',
      args: [],
    );
  }

  /// `Notification bar does not show message details`
  String get setting_notify_push_detail {
    return Intl.message(
      'Notification bar does not show message details',
      name: 'setting_notify_push_detail',
      desc: '',
      args: [],
    );
  }

  /// `Clear all chat history`
  String get clear_message {
    return Intl.message(
      'Clear all chat history',
      name: 'clear_message',
      desc: '',
      args: [],
    );
  }

  /// `Clear SDK file cache`
  String get clear_sdk_cache {
    return Intl.message(
      'Clear SDK file cache',
      name: 'clear_sdk_cache',
      desc: '',
      args: [],
    );
  }

  /// `Chat history has been cleaned up`
  String get clear_message_tips {
    return Intl.message(
      'Chat history has been cleaned up',
      name: 'clear_message_tips',
      desc: '',
      args: [],
    );
  }

  /// `{size} M`
  String cache_size_text(String size) {
    return Intl.message(
      '$size M',
      name: 'cache_size_text',
      desc: '',
      args: [size],
    );
  }

  /// `Feature not yet available`
  String get not_usable {
    return Intl.message(
      'Feature not yet available',
      name: 'not_usable',
      desc: '',
      args: [],
    );
  }

  /// `Setting failed`
  String get setting_fail {
    return Intl.message(
      'Setting failed',
      name: 'setting_fail',
      desc: '',
      args: [],
    );
  }

  /// `Set successfully`
  String get setting_success {
    return Intl.message(
      'Set successfully',
      name: 'setting_success',
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
