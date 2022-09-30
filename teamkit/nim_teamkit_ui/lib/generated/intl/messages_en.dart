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

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "team_advanced_dismiss":
            MessageLookupByLibrary.simpleMessage("Disband the Team chat"),
        "team_advanced_quit":
            MessageLookupByLibrary.simpleMessage("Exit Team chat"),
        "team_all_member": MessageLookupByLibrary.simpleMessage("All member"),
        "team_cancel": MessageLookupByLibrary.simpleMessage("cancel"),
        "team_confirm": MessageLookupByLibrary.simpleMessage("confirm"),
        "team_default_icon":
            MessageLookupByLibrary.simpleMessage("Choose default icon"),
        "team_dismiss_advanced_team_query":
            MessageLookupByLibrary.simpleMessage("Disband the Team chat?"),
        "team_group_icon_title":
            MessageLookupByLibrary.simpleMessage("Team Group icon"),
        "team_group_info_title":
            MessageLookupByLibrary.simpleMessage("Team Group info"),
        "team_group_member_title":
            MessageLookupByLibrary.simpleMessage("Team Group member"),
        "team_group_name_title":
            MessageLookupByLibrary.simpleMessage("Team Group name"),
        "team_group_quit":
            MessageLookupByLibrary.simpleMessage("Exit Team Group chat"),
        "team_history": MessageLookupByLibrary.simpleMessage("History"),
        "team_icon_title": MessageLookupByLibrary.simpleMessage("Team icon"),
        "team_info_title": MessageLookupByLibrary.simpleMessage("Team info"),
        "team_introduce_title":
            MessageLookupByLibrary.simpleMessage("Team introduce"),
        "team_invite_other_permission":
            MessageLookupByLibrary.simpleMessage("Invite others permission"),
        "team_mark": MessageLookupByLibrary.simpleMessage("Mark"),
        "team_member_title":
            MessageLookupByLibrary.simpleMessage("Team member"),
        "team_message_tip":
            MessageLookupByLibrary.simpleMessage("Open message notice"),
        "team_mute": MessageLookupByLibrary.simpleMessage("Mute"),
        "team_my_nickname_title":
            MessageLookupByLibrary.simpleMessage("My nickname in Team"),
        "team_name_title": MessageLookupByLibrary.simpleMessage("Team name"),
        "team_need_agreed_when_be_invited_permission":
            MessageLookupByLibrary.simpleMessage(
                "Whether the invitee\'s consent is required"),
        "team_no_permission":
            MessageLookupByLibrary.simpleMessage("No Permission"),
        "team_owner": MessageLookupByLibrary.simpleMessage("Owner"),
        "team_quit_advanced_team_query": MessageLookupByLibrary.simpleMessage(
            "Do you want to leave the Team chat?"),
        "team_quit_group_team_query": MessageLookupByLibrary.simpleMessage(
            "Do you want to leave the Team Group chat?"),
        "team_save": MessageLookupByLibrary.simpleMessage("Save"),
        "team_search_friend":
            MessageLookupByLibrary.simpleMessage("Search friend"),
        "team_session_pin":
            MessageLookupByLibrary.simpleMessage("Set session top"),
        "team_setting_title": MessageLookupByLibrary.simpleMessage("Setting"),
        "team_update_icon":
            MessageLookupByLibrary.simpleMessage("Modify avatar"),
        "team_update_info_permission": MessageLookupByLibrary.simpleMessage(
            "Permission to modify Team info")
      };
}
