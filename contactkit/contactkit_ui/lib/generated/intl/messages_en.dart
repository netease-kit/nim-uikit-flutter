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

  static String m0(userName) => "Account:${userName}";

  static String m1(user) => "Friend apply from ${user}";

  static String m2(userName) => "Delete\"${userName}\"";

  static String m3(userName) => "Nick:${userName}";

  static String m4(user) => "${user} accepted your apply";

  static String m5(user) => "${user} accepted your invitation";

  static String m6(user) => "${user} have add you as friend";

  static String m7(user) => "${user} reject your apply";

  static String m8(user) => "${user} rejected your invitation";

  static String m9(user) => "${user} rejected your team apply";

  static String m10(user, team) => "${user} apply join ${team}";

  static String m11(user, team) => "${user} invite you join ${team}";

  static String m12(count) => "Done(${count})";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "contact_accept": MessageLookupByLibrary.simpleMessage("Accept"),
        "contact_accepted": MessageLookupByLibrary.simpleMessage("Accepted"),
        "contact_account": m0,
        "contact_add_friend":
            MessageLookupByLibrary.simpleMessage("Add Friend"),
        "contact_add_to_blacklist":
            MessageLookupByLibrary.simpleMessage("Add Black List"),
        "contact_apply_from": m1,
        "contact_birthday": MessageLookupByLibrary.simpleMessage("Birthday"),
        "contact_black_list":
            MessageLookupByLibrary.simpleMessage("Black List"),
        "contact_cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "contact_chat": MessageLookupByLibrary.simpleMessage("Go Chat"),
        "contact_clean": MessageLookupByLibrary.simpleMessage("Clean"),
        "contact_comment": MessageLookupByLibrary.simpleMessage("Comment"),
        "contact_delete": MessageLookupByLibrary.simpleMessage("Delete Friend"),
        "contact_delete_specific_friend": m2,
        "contact_expired": MessageLookupByLibrary.simpleMessage("Expired"),
        "contact_have_send_apply":
            MessageLookupByLibrary.simpleMessage("Apply have been sent"),
        "contact_ignored": MessageLookupByLibrary.simpleMessage("Ignored"),
        "contact_mail": MessageLookupByLibrary.simpleMessage("E-Mail"),
        "contact_message_notice":
            MessageLookupByLibrary.simpleMessage("MessageNotice"),
        "contact_nick": m3,
        "contact_phone": MessageLookupByLibrary.simpleMessage("Phone"),
        "contact_reject": MessageLookupByLibrary.simpleMessage("Reject"),
        "contact_rejected": MessageLookupByLibrary.simpleMessage("Rejected"),
        "contact_release": MessageLookupByLibrary.simpleMessage("Release"),
        "contact_save": MessageLookupByLibrary.simpleMessage("Save"),
        "contact_select_as_most":
            MessageLookupByLibrary.simpleMessage("Selected too many users"),
        "contact_signature": MessageLookupByLibrary.simpleMessage("Signature"),
        "contact_some_accept_your_apply": m4,
        "contact_some_accept_your_invitation": m5,
        "contact_some_add_your_as_friend": m6,
        "contact_some_reject_your_apply": m7,
        "contact_some_reject_your_invitation": m8,
        "contact_some_reject_your_team_apply": m9,
        "contact_someone_apply_join_team": m10,
        "contact_someone_invite_your_join_team": m11,
        "contact_sure_with_count": m12,
        "contact_team": MessageLookupByLibrary.simpleMessage("My Team"),
        "contact_title": MessageLookupByLibrary.simpleMessage("Contacts"),
        "contact_user_selector":
            MessageLookupByLibrary.simpleMessage("User Selector"),
        "contact_verify_message":
            MessageLookupByLibrary.simpleMessage("Verify Message"),
        "contact_you_will_never_receive_any_message_from_those_person":
            MessageLookupByLibrary.simpleMessage(
                "You will never receive any message from those person")
      };
}
