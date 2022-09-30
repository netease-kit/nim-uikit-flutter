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

  /// `Send to {userName}`
  String chat_message_send_hint(String userName) {
    return Intl.message(
      'Send to $userName',
      name: 'chat_message_send_hint',
      desc: '',
      args: [userName],
    );
  }

  /// `Pressed to speak`
  String get chat_pressed_to_speak {
    return Intl.message(
      'Pressed to speak',
      name: 'chat_pressed_to_speak',
      desc: '',
      args: [],
    );
  }

  /// `Release to send, hold and swipe to an empty area to cancel`
  String get chat_message_voice_in {
    return Intl.message(
      'Release to send, hold and swipe to an empty area to cancel',
      name: 'chat_message_voice_in',
      desc: '',
      args: [],
    );
  }

  /// `Pick photo`
  String get chat_message_pick_photo {
    return Intl.message(
      'Pick photo',
      name: 'chat_message_pick_photo',
      desc: '',
      args: [],
    );
  }

  /// `Pick video`
  String get chat_message_pick_video {
    return Intl.message(
      'Pick video',
      name: 'chat_message_pick_video',
      desc: '',
      args: [],
    );
  }

  /// `Shooting`
  String get chat_message_more_shoot {
    return Intl.message(
      'Shooting',
      name: 'chat_message_more_shoot',
      desc: '',
      args: [],
    );
  }

  /// `Take photo`
  String get chat_message_take_photo {
    return Intl.message(
      'Take photo',
      name: 'chat_message_take_photo',
      desc: '',
      args: [],
    );
  }

  /// `Take video`
  String get chat_message_take_video {
    return Intl.message(
      'Take video',
      name: 'chat_message_take_video',
      desc: '',
      args: [],
    );
  }

  /// `Unknown Type`
  String get chat_message_unknown_type {
    return Intl.message(
      'Unknown Type',
      name: 'chat_message_unknown_type',
      desc: '',
      args: [],
    );
  }

  /// `Image saved successfully`
  String get chat_message_image_save {
    return Intl.message(
      'Image saved successfully',
      name: 'chat_message_image_save',
      desc: '',
      args: [],
    );
  }

  /// `Failed to save image`
  String get chat_message_image_save_fail {
    return Intl.message(
      'Failed to save image',
      name: 'chat_message_image_save_fail',
      desc: '',
      args: [],
    );
  }

  /// `Video saved successfully`
  String get chat_message_video_save {
    return Intl.message(
      'Video saved successfully',
      name: 'chat_message_video_save',
      desc: '',
      args: [],
    );
  }

  /// `Failed to save video`
  String get chat_message_video_save_fail {
    return Intl.message(
      'Failed to save video',
      name: 'chat_message_video_save_fail',
      desc: '',
      args: [],
    );
  }

  /// `copy`
  String get chat_message_action_copy {
    return Intl.message(
      'copy',
      name: 'chat_message_action_copy',
      desc: '',
      args: [],
    );
  }

  /// `reply`
  String get chat_message_action_reply {
    return Intl.message(
      'reply',
      name: 'chat_message_action_reply',
      desc: '',
      args: [],
    );
  }

  /// `forward`
  String get chat_message_action_forward {
    return Intl.message(
      'forward',
      name: 'chat_message_action_forward',
      desc: '',
      args: [],
    );
  }

  /// `pin`
  String get chat_message_action_pin {
    return Intl.message(
      'pin',
      name: 'chat_message_action_pin',
      desc: '',
      args: [],
    );
  }

  /// `unPin`
  String get chat_message_action_un_pin {
    return Intl.message(
      'unPin',
      name: 'chat_message_action_un_pin',
      desc: '',
      args: [],
    );
  }

  /// `multiSelect`
  String get chat_message_action_multi_select {
    return Intl.message(
      'multiSelect',
      name: 'chat_message_action_multi_select',
      desc: '',
      args: [],
    );
  }

  /// `collect`
  String get chat_message_action_collect {
    return Intl.message(
      'collect',
      name: 'chat_message_action_collect',
      desc: '',
      args: [],
    );
  }

  /// `delete`
  String get chat_message_action_delete {
    return Intl.message(
      'delete',
      name: 'chat_message_action_delete',
      desc: '',
      args: [],
    );
  }

  /// `revoke`
  String get chat_message_action_revoke {
    return Intl.message(
      'revoke',
      name: 'chat_message_action_revoke',
      desc: '',
      args: [],
    );
  }

  /// `Copy Success`
  String get chat_message_copy_success {
    return Intl.message(
      'Copy Success',
      name: 'chat_message_copy_success',
      desc: '',
      args: [],
    );
  }

  /// `Collect Success`
  String get chat_message_collect_success {
    return Intl.message(
      'Collect Success',
      name: 'chat_message_collect_success',
      desc: '',
      args: [],
    );
  }

  /// `Delete this message?`
  String get chat_message_delete_confirm {
    return Intl.message(
      'Delete this message?',
      name: 'chat_message_delete_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Revoke this message?`
  String get chat_message_revoke_confirm {
    return Intl.message(
      'Revoke this message?',
      name: 'chat_message_revoke_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Pined by {userName}，visible to both of you`
  String chat_message_pin_message(String userName) {
    return Intl.message(
      'Pined by $userName，visible to both of you',
      name: 'chat_message_pin_message',
      desc: '',
      args: [userName],
    );
  }

  /// `Pined by {userName}，visible to everyone`
  String chat_message_pin_message_for_team(String userName) {
    return Intl.message(
      'Pined by $userName，visible to everyone',
      name: 'chat_message_pin_message_for_team',
      desc: '',
      args: [userName],
    );
  }

  /// `Message revoked`
  String get chat_message_have_been_revoked {
    return Intl.message(
      'Message revoked',
      name: 'chat_message_have_been_revoked',
      desc: '',
      args: [],
    );
  }

  /// ` Reedit >`
  String get chat_message_reedit {
    return Intl.message(
      ' Reedit >',
      name: 'chat_message_reedit',
      desc: '',
      args: [],
    );
  }

  /// `Over Time,Revoke failed`
  String get chat_message_revoke_over_time {
    return Intl.message(
      'Over Time,Revoke failed',
      name: 'chat_message_revoke_over_time',
      desc: '',
      args: [],
    );
  }

  /// `Revoke failed`
  String get chat_message_revoke_failed {
    return Intl.message(
      'Revoke failed',
      name: 'chat_message_revoke_failed',
      desc: '',
      args: [],
    );
  }

  /// `Reply {content}`
  String chat_message_reply_someone(String content) {
    return Intl.message(
      'Reply $content',
      name: 'chat_message_reply_someone',
      desc: '',
      args: [content],
    );
  }

  /// `[Image]`
  String get chat_message_brief_image {
    return Intl.message(
      '[Image]',
      name: 'chat_message_brief_image',
      desc: '',
      args: [],
    );
  }

  /// `[Audio]`
  String get chat_message_brief_audio {
    return Intl.message(
      '[Audio]',
      name: 'chat_message_brief_audio',
      desc: '',
      args: [],
    );
  }

  /// `[Video]`
  String get chat_message_brief_video {
    return Intl.message(
      '[Video]',
      name: 'chat_message_brief_video',
      desc: '',
      args: [],
    );
  }

  /// `[Location]`
  String get chat_message_brief_location {
    return Intl.message(
      '[Location]',
      name: 'chat_message_brief_location',
      desc: '',
      args: [],
    );
  }

  /// `[File]`
  String get chat_message_brief_file {
    return Intl.message(
      '[File]',
      name: 'chat_message_brief_file',
      desc: '',
      args: [],
    );
  }

  /// `[Custom Message]`
  String get chat_message_brief_custom {
    return Intl.message(
      '[Custom Message]',
      name: 'chat_message_brief_custom',
      desc: '',
      args: [],
    );
  }

  /// `Chat setting`
  String get chat_setting {
    return Intl.message(
      'Chat setting',
      name: 'chat_setting',
      desc: '',
      args: [],
    );
  }

  /// `Message mark`
  String get chat_message_signal {
    return Intl.message(
      'Message mark',
      name: 'chat_message_signal',
      desc: '',
      args: [],
    );
  }

  /// `Open message notice`
  String get chat_message_open_message_notice {
    return Intl.message(
      'Open message notice',
      name: 'chat_message_open_message_notice',
      desc: '',
      args: [],
    );
  }

  /// `Set session top`
  String get chat_message_set_top {
    return Intl.message(
      'Set session top',
      name: 'chat_message_set_top',
      desc: '',
      args: [],
    );
  }

  /// `Send`
  String get chat_message_send {
    return Intl.message(
      'Send',
      name: 'chat_message_send',
      desc: '',
      args: [],
    );
  }

  /// `{user} invited join the team`
  String chat_advice_team_notify_invite(String user, String members) {
    return Intl.message(
      '$user invited join the team',
      name: 'chat_advice_team_notify_invite',
      desc: '',
      args: [user, members],
    );
  }

  /// `{user} invited {members} join discuss team`
  String chat_discuss_team_notify_invite(String user, String members) {
    return Intl.message(
      '$user invited $members join discuss team',
      name: 'chat_discuss_team_notify_invite',
      desc: '',
      args: [user, members],
    );
  }

  /// `{users} have been removed from discuss team`
  String chat_discuss_team_notify_remove(String users) {
    return Intl.message(
      '$users have been removed from discuss team',
      name: 'chat_discuss_team_notify_remove',
      desc: '',
      args: [users],
    );
  }

  /// `{users} have been removed from team`
  String chat_advanced_team_notify_remove(String users) {
    return Intl.message(
      '$users have been removed from team',
      name: 'chat_advanced_team_notify_remove',
      desc: '',
      args: [users],
    );
  }

  /// `{users}have left discuss team`
  String chat_discuss_team_notify_leave(String users) {
    return Intl.message(
      '${users}have left discuss team',
      name: 'chat_discuss_team_notify_leave',
      desc: '',
      args: [users],
    );
  }

  /// `{users}have left team`
  String chat_advanced_team_notify_leave(String users) {
    return Intl.message(
      '${users}have left team',
      name: 'chat_advanced_team_notify_leave',
      desc: '',
      args: [users],
    );
  }

  /// `{users}dismissed team`
  String chat_team_notify_dismiss(String users) {
    return Intl.message(
      '${users}dismissed team',
      name: 'chat_team_notify_dismiss',
      desc: '',
      args: [users],
    );
  }

  /// `Manager accepted {members} team apply`
  String chat_team_notify_manager_pass(String members) {
    return Intl.message(
      'Manager accepted $members team apply',
      name: 'chat_team_notify_manager_pass',
      desc: '',
      args: [members],
    );
  }

  /// `{user} transfer owner to {members}`
  String chat_team_notify_trans_owner(String members, String user) {
    return Intl.message(
      '$user transfer owner to $members',
      name: 'chat_team_notify_trans_owner',
      desc: '',
      args: [members, user],
    );
  }

  /// `{member} set as manager`
  String chat_team_notify_add_manager(String member) {
    return Intl.message(
      '$member set as manager',
      name: 'chat_team_notify_add_manager',
      desc: '',
      args: [member],
    );
  }

  /// `{member}remove from managers`
  String chat_team_notify_remove_manager(String member) {
    return Intl.message(
      '${member}remove from managers',
      name: 'chat_team_notify_remove_manager',
      desc: '',
      args: [member],
    );
  }

  /// `{user} accept {members}'s invite and join`
  String chat_team_notify_accept_invite(String members, String user) {
    return Intl.message(
      '$user accept $members\'s invite and join',
      name: 'chat_team_notify_accept_invite',
      desc: '',
      args: [members, user],
    );
  }

  /// `{user} mute by manager`
  String chat_team_notify_mute(String user) {
    return Intl.message(
      '$user mute by manager',
      name: 'chat_team_notify_mute',
      desc: '',
      args: [user],
    );
  }

  /// `{user} un mute by manager`
  String chat_team_notify_un_mute(String user) {
    return Intl.message(
      '$user un mute by manager',
      name: 'chat_team_notify_un_mute',
      desc: '',
      args: [user],
    );
  }

  /// `Unknown Notification`
  String get chat_message_unknown_notification {
    return Intl.message(
      'Unknown Notification',
      name: 'chat_message_unknown_notification',
      desc: '',
      args: [],
    );
  }

  /// `team name updated as {name}`
  String chat_team_notify_update_name(String name) {
    return Intl.message(
      'team name updated as $name',
      name: 'chat_team_notify_update_name',
      desc: '',
      args: [name],
    );
  }

  /// `team introduction updated as {name}`
  String chat_team_notify_update_introduction(String name) {
    return Intl.message(
      'team introduction updated as $name',
      name: 'chat_team_notify_update_introduction',
      desc: '',
      args: [name],
    );
  }

  /// `team announcement update as {notice}`
  String chat_team_notice_update(String notice) {
    return Intl.message(
      'team announcement update as $notice',
      name: 'chat_team_notice_update',
      desc: '',
      args: [notice],
    );
  }

  /// `update as need verify`
  String get chat_team_verify_update_as_need_verify {
    return Intl.message(
      'update as need verify',
      name: 'chat_team_verify_update_as_need_verify',
      desc: '',
      args: [],
    );
  }

  /// `update as need no verify`
  String get chat_team_verify_update_as_need_no_verify {
    return Intl.message(
      'update as need no verify',
      name: 'chat_team_verify_update_as_need_no_verify',
      desc: '',
      args: [],
    );
  }

  /// `update as disallow anyone join`
  String get chat_team_verify_update_as_disallow_anyone_join {
    return Intl.message(
      'update as disallow anyone join',
      name: 'chat_team_verify_update_as_disallow_anyone_join',
      desc: '',
      args: [],
    );
  }

  /// `team extension update as {name}`
  String chat_team_notify_update_extension(String name) {
    return Intl.message(
      'team extension update as $name',
      name: 'chat_team_notify_update_extension',
      desc: '',
      args: [name],
    );
  }

  /// `team extension (server) update as{name}`
  String chat_team_notify_update_extension_server(String name) {
    return Intl.message(
      'team extension (server) update as$name',
      name: 'chat_team_notify_update_extension_server',
      desc: '',
      args: [name],
    );
  }

  /// `team avatar have updated`
  String get chat_team_notify_update_team_avatar {
    return Intl.message(
      'team avatar have updated',
      name: 'chat_team_notify_update_team_avatar',
      desc: '',
      args: [],
    );
  }

  /// `team invite permission update as {permission}`
  String chat_team_invitation_permission_update(String permission) {
    return Intl.message(
      'team invite permission update as $permission',
      name: 'chat_team_invitation_permission_update',
      desc: '',
      args: [permission],
    );
  }

  /// `team resource permission update:{permission}`
  String chat_team_modify_resource_permission_update(String permission) {
    return Intl.message(
      'team resource permission update:$permission',
      name: 'chat_team_modify_resource_permission_update',
      desc: '',
      args: [permission],
    );
  }

  /// `team invited verify update as {permission}`
  String chat_team_invited_id_verify_permission_update(String permission) {
    return Intl.message(
      'team invited verify update as $permission',
      name: 'chat_team_invited_id_verify_permission_update',
      desc: '',
      args: [permission],
    );
  }

  /// `team extension update permission as {permission}`
  String chat_team_modify_extension_permission_update(String permission) {
    return Intl.message(
      'team extension update permission as $permission',
      name: 'chat_team_modify_extension_permission_update',
      desc: '',
      args: [permission],
    );
  }

  /// `Mute`
  String get chat_team_all_mute {
    return Intl.message(
      'Mute',
      name: 'chat_team_all_mute',
      desc: '',
      args: [],
    );
  }

  /// `cancel all mute`
  String get chat_team_cancel_all_mute {
    return Intl.message(
      'cancel all mute',
      name: 'chat_team_cancel_all_mute',
      desc: '',
      args: [],
    );
  }

  /// `mute all`
  String get chat_team_full_mute {
    return Intl.message(
      'mute all',
      name: 'chat_team_full_mute',
      desc: '',
      args: [],
    );
  }

  /// `team {key} updated as {value}`
  String chat_team_update(String key, String value) {
    return Intl.message(
      'team $key updated as $value',
      name: 'chat_team_update',
      desc: '',
      args: [key, value],
    );
  }

  /// `you`
  String get chat_message_you {
    return Intl.message(
      'you',
      name: 'chat_message_you',
      desc: '',
      args: [],
    );
  }

  /// `Search History`
  String get message_search_title {
    return Intl.message(
      'Search History',
      name: 'message_search_title',
      desc: '',
      args: [],
    );
  }

  /// `Search chat content`
  String get message_search_hint {
    return Intl.message(
      'Search chat content',
      name: 'message_search_hint',
      desc: '',
      args: [],
    );
  }

  /// `No chat history`
  String get message_search_empty {
    return Intl.message(
      'No chat history',
      name: 'message_search_empty',
      desc: '',
      args: [],
    );
  }

  /// `Forward to person`
  String get message_forward_to_p2p {
    return Intl.message(
      'Forward to person',
      name: 'message_forward_to_p2p',
      desc: '',
      args: [],
    );
  }

  /// `Forward to team`
  String get message_forward_to_team {
    return Intl.message(
      'Forward to team',
      name: 'message_forward_to_team',
      desc: '',
      args: [],
    );
  }

  /// `Send to`
  String get message_forward_to {
    return Intl.message(
      'Send to',
      name: 'message_forward_to',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get message_cancel {
    return Intl.message(
      'Cancel',
      name: 'message_cancel',
      desc: '',
      args: [],
    );
  }

  /// `[Forward]{user} message`
  String message_forward_message_tips(String user) {
    return Intl.message(
      '[Forward]$user message',
      name: 'message_forward_message_tips',
      desc: '',
      args: [user],
    );
  }

  /// `Message read status`
  String get message_read_status {
    return Intl.message(
      'Message read status',
      name: 'message_read_status',
      desc: '',
      args: [],
    );
  }

  /// `Read ({num})`
  String message_read_with_number(String num) {
    return Intl.message(
      'Read ($num)',
      name: 'message_read_with_number',
      desc: '',
      args: [num],
    );
  }

  /// `Unread ({num})`
  String message_unread_with_number(String num) {
    return Intl.message(
      'Unread ($num)',
      name: 'message_unread_with_number',
      desc: '',
      args: [num],
    );
  }

  /// `All member have read`
  String get message_all_read {
    return Intl.message(
      'All member have read',
      name: 'message_all_read',
      desc: '',
      args: [],
    );
  }

  /// `All member unread`
  String get message_all_unread {
    return Intl.message(
      'All member unread',
      name: 'message_all_unread',
      desc: '',
      args: [],
    );
  }

  /// `Is Typing`
  String get chat_is_typing {
    return Intl.message(
      'Is Typing',
      name: 'chat_is_typing',
      desc: '',
      args: [],
    );
  }

  /// `Choose a reminder`
  String get chat_message_ait_contact_title {
    return Intl.message(
      'Choose a reminder',
      name: 'chat_message_ait_contact_title',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get chat_team_ait_all {
    return Intl.message(
      'All',
      name: 'chat_team_ait_all',
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
