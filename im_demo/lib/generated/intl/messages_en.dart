// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(size) => "${size} M";

  static String m1(account) => "Account:${account}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "action_copy_success":
            MessageLookupByLibrary.simpleMessage("Copy success!"),
        "appName": MessageLookupByLibrary.simpleMessage("Netease IM"),
        "cache_size_text": m0,
        "clear_message":
            MessageLookupByLibrary.simpleMessage("Clear all chat history"),
        "clear_message_tips": MessageLookupByLibrary.simpleMessage(
            "Chat history has been cleaned up"),
        "clear_sdk_cache":
            MessageLookupByLibrary.simpleMessage("Clear SDK file cache"),
        "contact": MessageLookupByLibrary.simpleMessage("contact"),
        "conversation": MessageLookupByLibrary.simpleMessage("conversation"),
        "dataIsLoading": MessageLookupByLibrary.simpleMessage("Loading..."),
        "logout_dialog_agree": MessageLookupByLibrary.simpleMessage("YES"),
        "logout_dialog_content": MessageLookupByLibrary.simpleMessage(
            "Are you sure to log out of the current login account?"),
        "logout_dialog_disagree": MessageLookupByLibrary.simpleMessage("NO"),
        "message": MessageLookupByLibrary.simpleMessage("message"),
        "mine": MessageLookupByLibrary.simpleMessage("mine"),
        "mine_about": MessageLookupByLibrary.simpleMessage("About"),
        "mine_collect": MessageLookupByLibrary.simpleMessage("Collect"),
        "mine_logout": MessageLookupByLibrary.simpleMessage("Logout"),
        "mine_product":
            MessageLookupByLibrary.simpleMessage("Product introduction"),
        "mine_setting": MessageLookupByLibrary.simpleMessage("Setting"),
        "mine_version": MessageLookupByLibrary.simpleMessage("Version"),
        "not_usable":
            MessageLookupByLibrary.simpleMessage("Feature not yet available"),
        "request_fail": MessageLookupByLibrary.simpleMessage("Request fail"),
        "setting_clear_cache":
            MessageLookupByLibrary.simpleMessage("Clear cache"),
        "setting_fail": MessageLookupByLibrary.simpleMessage("Setting failed"),
        "setting_filter_notify":
            MessageLookupByLibrary.simpleMessage("Filter notify"),
        "setting_friend_delete_mode": MessageLookupByLibrary.simpleMessage(
            "Delete notes when deleting friends"),
        "setting_message_read_mode": MessageLookupByLibrary.simpleMessage(
            "Message read and unread function"),
        "setting_notify": MessageLookupByLibrary.simpleMessage("Notify"),
        "setting_notify_info":
            MessageLookupByLibrary.simpleMessage("New message notification"),
        "setting_notify_mode":
            MessageLookupByLibrary.simpleMessage("Message reminder mode"),
        "setting_notify_mode_ring":
            MessageLookupByLibrary.simpleMessage("Ring Mode"),
        "setting_notify_mode_shake":
            MessageLookupByLibrary.simpleMessage("Vibration Mode"),
        "setting_notify_push":
            MessageLookupByLibrary.simpleMessage("Push settings"),
        "setting_notify_push_detail": MessageLookupByLibrary.simpleMessage(
            "Notification bar does not show message details"),
        "setting_notify_push_sync": MessageLookupByLibrary.simpleMessage(
            "Receive pushes synchronously on PC/Web"),
        "setting_play_mode":
            MessageLookupByLibrary.simpleMessage("Handset mode"),
        "setting_success":
            MessageLookupByLibrary.simpleMessage("Set successfully"),
        "sexual_female": MessageLookupByLibrary.simpleMessage("Female"),
        "sexual_male": MessageLookupByLibrary.simpleMessage("Male"),
        "sexual_unknown": MessageLookupByLibrary.simpleMessage("Unknown"),
        "tab_mine_account": m1,
        "user_info_account": MessageLookupByLibrary.simpleMessage("Account"),
        "user_info_avatar": MessageLookupByLibrary.simpleMessage("Avatar"),
        "user_info_birthday": MessageLookupByLibrary.simpleMessage("Birthday"),
        "user_info_complete": MessageLookupByLibrary.simpleMessage("Complete"),
        "user_info_email": MessageLookupByLibrary.simpleMessage("Email"),
        "user_info_nickname": MessageLookupByLibrary.simpleMessage("Nickname"),
        "user_info_phone": MessageLookupByLibrary.simpleMessage("Phone"),
        "user_info_sexual": MessageLookupByLibrary.simpleMessage("Sex"),
        "user_info_sign": MessageLookupByLibrary.simpleMessage("Signature"),
        "user_info_title": MessageLookupByLibrary.simpleMessage("User info"),
        "welcome_button":
            MessageLookupByLibrary.simpleMessage("register/login"),
        "yunxin_desc": MessageLookupByLibrary.simpleMessage(
            "Stable instant messaging service"),
        "yunxin_name": MessageLookupByLibrary.simpleMessage("Netease CommsEase")
      };
}
