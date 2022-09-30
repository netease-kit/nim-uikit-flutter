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

  /// `Contacts`
  String get contact_title {
    return Intl.message(
      'Contacts',
      name: 'contact_title',
      desc: '',
      args: [],
    );
  }

  /// `Nick:{userName}`
  String contact_nick(String userName) {
    return Intl.message(
      'Nick:$userName',
      name: 'contact_nick',
      desc: '',
      args: [userName],
    );
  }

  /// `Account:{userName}`
  String contact_account(String userName) {
    return Intl.message(
      'Account:$userName',
      name: 'contact_account',
      desc: '',
      args: [userName],
    );
  }

  /// `Verify Message`
  String get contact_verify_message {
    return Intl.message(
      'Verify Message',
      name: 'contact_verify_message',
      desc: '',
      args: [],
    );
  }

  /// `Black List`
  String get contact_black_list {
    return Intl.message(
      'Black List',
      name: 'contact_black_list',
      desc: '',
      args: [],
    );
  }

  /// `My Team`
  String get contact_team {
    return Intl.message(
      'My Team',
      name: 'contact_team',
      desc: '',
      args: [],
    );
  }

  /// `Comment`
  String get contact_comment {
    return Intl.message(
      'Comment',
      name: 'contact_comment',
      desc: '',
      args: [],
    );
  }

  /// `Birthday`
  String get contact_birthday {
    return Intl.message(
      'Birthday',
      name: 'contact_birthday',
      desc: '',
      args: [],
    );
  }

  /// `Phone`
  String get contact_phone {
    return Intl.message(
      'Phone',
      name: 'contact_phone',
      desc: '',
      args: [],
    );
  }

  /// `E-Mail`
  String get contact_mail {
    return Intl.message(
      'E-Mail',
      name: 'contact_mail',
      desc: '',
      args: [],
    );
  }

  /// `Signature`
  String get contact_signature {
    return Intl.message(
      'Signature',
      name: 'contact_signature',
      desc: '',
      args: [],
    );
  }

  /// `MessageNotice`
  String get contact_message_notice {
    return Intl.message(
      'MessageNotice',
      name: 'contact_message_notice',
      desc: '',
      args: [],
    );
  }

  /// `Add Black List`
  String get contact_add_to_blacklist {
    return Intl.message(
      'Add Black List',
      name: 'contact_add_to_blacklist',
      desc: '',
      args: [],
    );
  }

  /// `Go Chat`
  String get contact_chat {
    return Intl.message(
      'Go Chat',
      name: 'contact_chat',
      desc: '',
      args: [],
    );
  }

  /// `Delete Friend`
  String get contact_delete {
    return Intl.message(
      'Delete Friend',
      name: 'contact_delete',
      desc: '',
      args: [],
    );
  }

  /// `Delete"{userName}"`
  String contact_delete_specific_friend(String userName) {
    return Intl.message(
      'Delete"$userName"',
      name: 'contact_delete_specific_friend',
      desc: '',
      args: [userName],
    );
  }

  /// `Cancel`
  String get contact_cancel {
    return Intl.message(
      'Cancel',
      name: 'contact_cancel',
      desc: '',
      args: [],
    );
  }

  /// `Add Friend`
  String get contact_add_friend {
    return Intl.message(
      'Add Friend',
      name: 'contact_add_friend',
      desc: '',
      args: [],
    );
  }

  /// `You will never receive any message from those person`
  String get contact_you_will_never_receive_any_message_from_those_person {
    return Intl.message(
      'You will never receive any message from those person',
      name: 'contact_you_will_never_receive_any_message_from_those_person',
      desc: '',
      args: [],
    );
  }

  /// `Release`
  String get contact_release {
    return Intl.message(
      'Release',
      name: 'contact_release',
      desc: '',
      args: [],
    );
  }

  /// `User Selector`
  String get contact_user_selector {
    return Intl.message(
      'User Selector',
      name: 'contact_user_selector',
      desc: '',
      args: [],
    );
  }

  /// `Done({count})`
  String contact_sure_with_count(String count) {
    return Intl.message(
      'Done($count)',
      name: 'contact_sure_with_count',
      desc: '',
      args: [count],
    );
  }

  /// `Selected too many users`
  String get contact_select_as_most {
    return Intl.message(
      'Selected too many users',
      name: 'contact_select_as_most',
      desc: '',
      args: [],
    );
  }

  /// `Clean`
  String get contact_clean {
    return Intl.message(
      'Clean',
      name: 'contact_clean',
      desc: '',
      args: [],
    );
  }

  /// `Accept`
  String get contact_accept {
    return Intl.message(
      'Accept',
      name: 'contact_accept',
      desc: '',
      args: [],
    );
  }

  /// `Accepted`
  String get contact_accepted {
    return Intl.message(
      'Accepted',
      name: 'contact_accepted',
      desc: '',
      args: [],
    );
  }

  /// `Rejected`
  String get contact_rejected {
    return Intl.message(
      'Rejected',
      name: 'contact_rejected',
      desc: '',
      args: [],
    );
  }

  /// `Ignored`
  String get contact_ignored {
    return Intl.message(
      'Ignored',
      name: 'contact_ignored',
      desc: '',
      args: [],
    );
  }

  /// `Expired`
  String get contact_expired {
    return Intl.message(
      'Expired',
      name: 'contact_expired',
      desc: '',
      args: [],
    );
  }

  /// `Reject`
  String get contact_reject {
    return Intl.message(
      'Reject',
      name: 'contact_reject',
      desc: '',
      args: [],
    );
  }

  /// `Friend apply from {user}`
  String contact_apply_from(String user) {
    return Intl.message(
      'Friend apply from $user',
      name: 'contact_apply_from',
      desc: '',
      args: [user],
    );
  }

  /// `{user} invite you join {team}`
  String contact_someone_invite_your_join_team(String user, String team) {
    return Intl.message(
      '$user invite you join $team',
      name: 'contact_someone_invite_your_join_team',
      desc: '',
      args: [user, team],
    );
  }

  /// `{user} accepted your apply`
  String contact_some_accept_your_apply(String user) {
    return Intl.message(
      '$user accepted your apply',
      name: 'contact_some_accept_your_apply',
      desc: '',
      args: [user],
    );
  }

  /// `{user} reject your apply`
  String contact_some_reject_your_apply(String user) {
    return Intl.message(
      '$user reject your apply',
      name: 'contact_some_reject_your_apply',
      desc: '',
      args: [user],
    );
  }

  /// `{user} accepted your invitation`
  String contact_some_accept_your_invitation(String user) {
    return Intl.message(
      '$user accepted your invitation',
      name: 'contact_some_accept_your_invitation',
      desc: '',
      args: [user],
    );
  }

  /// `{user} rejected your invitation`
  String contact_some_reject_your_invitation(String user) {
    return Intl.message(
      '$user rejected your invitation',
      name: 'contact_some_reject_your_invitation',
      desc: '',
      args: [user],
    );
  }

  /// `{user} have add you as friend`
  String contact_some_add_your_as_friend(String user) {
    return Intl.message(
      '$user have add you as friend',
      name: 'contact_some_add_your_as_friend',
      desc: '',
      args: [user],
    );
  }

  /// `{user} apply join {team}`
  String contact_someone_apply_join_team(String user, String team) {
    return Intl.message(
      '$user apply join $team',
      name: 'contact_someone_apply_join_team',
      desc: '',
      args: [user, team],
    );
  }

  /// `{user} rejected your team apply`
  String contact_some_reject_your_team_apply(String user) {
    return Intl.message(
      '$user rejected your team apply',
      name: 'contact_some_reject_your_team_apply',
      desc: '',
      args: [user],
    );
  }

  /// `Save`
  String get contact_save {
    return Intl.message(
      'Save',
      name: 'contact_save',
      desc: '',
      args: [],
    );
  }

  /// `Apply have been sent`
  String get contact_have_send_apply {
    return Intl.message(
      'Apply have been sent',
      name: 'contact_have_send_apply',
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
