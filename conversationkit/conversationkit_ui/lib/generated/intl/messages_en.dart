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

  static String m0(size) => "Sure(${size})";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "add_friend": MessageLookupByLibrary.simpleMessage("add friends"),
        "add_friend_search_empty_tips":
            MessageLookupByLibrary.simpleMessage("This user does not exist"),
        "add_friend_search_hint":
            MessageLookupByLibrary.simpleMessage("Please enter account"),
        "cancel_stick_title":
            MessageLookupByLibrary.simpleMessage("Cancel stick"),
        "cancel_title": MessageLookupByLibrary.simpleMessage("Cancel"),
        "conversation_network_error_tip": MessageLookupByLibrary.simpleMessage(
            "The current network is unavailable, please check your network settings."),
        "conversation_title":
            MessageLookupByLibrary.simpleMessage("CommsEase IM"),
        "create_advanced_team":
            MessageLookupByLibrary.simpleMessage("create advanced team"),
        "create_advanced_team_success": MessageLookupByLibrary.simpleMessage(
            "create advanced team success"),
        "create_group_team":
            MessageLookupByLibrary.simpleMessage("create group team"),
        "delete_title": MessageLookupByLibrary.simpleMessage("Delete"),
        "recent_title": MessageLookupByLibrary.simpleMessage("Recent chat"),
        "stick_title": MessageLookupByLibrary.simpleMessage("Stick"),
        "sure_count_title": m0,
        "sure_title": MessageLookupByLibrary.simpleMessage("Sure")
      };
}
