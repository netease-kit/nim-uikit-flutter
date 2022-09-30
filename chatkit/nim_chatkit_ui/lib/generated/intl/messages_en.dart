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

  static String m0(users) => "${users}have left team";

  static String m1(users) => "${users} have been removed from team";

  static String m2(user, members) => "${user} invited join the team";

  static String m3(user, members) =>
      "${user} invited ${members} join discuss team";

  static String m4(users) => "${users}have left discuss team";

  static String m5(users) => "${users} have been removed from discuss team";

  static String m6(userName) => "Pined by ${userName}，visible to both of you";

  static String m7(userName) => "Pined by ${userName}，visible to everyone";

  static String m8(content) => "Reply ${content}";

  static String m9(userName) => "Send to ${userName}";

  static String m10(permission) =>
      "team invite permission update as ${permission}";

  static String m11(permission) =>
      "team invited verify update as ${permission}";

  static String m12(permission) =>
      "team extension update permission as ${permission}";

  static String m13(permission) =>
      "team resource permission update:${permission}";

  static String m14(notice) => "team announcement update as ${notice}";

  static String m15(members, user) =>
      "${user} accept ${members}\'s invite and join";

  static String m16(member) => "${member} set as manager";

  static String m17(users) => "${users}dismissed team";

  static String m18(members) => "Manager accepted ${members} team apply";

  static String m19(user) => "${user} mute by manager";

  static String m20(member) => "${member}remove from managers";

  static String m21(members, user) => "${user} transfer owner to ${members}";

  static String m22(user) => "${user} un mute by manager";

  static String m23(name) => "team extension update as ${name}";

  static String m24(name) => "team extension (server) update as${name}";

  static String m25(name) => "team introduction updated as ${name}";

  static String m26(name) => "team name updated as ${name}";

  static String m27(key, value) => "team ${key} updated as ${value}";

  static String m28(user) => "[Forward]${user} message";

  static String m29(num) => "Read (${num})";

  static String m30(num) => "Unread (${num})";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "chat_advanced_team_notify_leave": m0,
        "chat_advanced_team_notify_remove": m1,
        "chat_advice_team_notify_invite": m2,
        "chat_discuss_team_notify_invite": m3,
        "chat_discuss_team_notify_leave": m4,
        "chat_discuss_team_notify_remove": m5,
        "chat_is_typing": MessageLookupByLibrary.simpleMessage("Is Typing"),
        "chat_message_action_collect":
            MessageLookupByLibrary.simpleMessage("collect"),
        "chat_message_action_copy":
            MessageLookupByLibrary.simpleMessage("copy"),
        "chat_message_action_delete":
            MessageLookupByLibrary.simpleMessage("delete"),
        "chat_message_action_forward":
            MessageLookupByLibrary.simpleMessage("forward"),
        "chat_message_action_multi_select":
            MessageLookupByLibrary.simpleMessage("multiSelect"),
        "chat_message_action_pin": MessageLookupByLibrary.simpleMessage("pin"),
        "chat_message_action_reply":
            MessageLookupByLibrary.simpleMessage("reply"),
        "chat_message_action_revoke":
            MessageLookupByLibrary.simpleMessage("revoke"),
        "chat_message_action_un_pin":
            MessageLookupByLibrary.simpleMessage("unPin"),
        "chat_message_ait_contact_title":
            MessageLookupByLibrary.simpleMessage("Choose a reminder"),
        "chat_message_brief_audio":
            MessageLookupByLibrary.simpleMessage("[Audio]"),
        "chat_message_brief_custom":
            MessageLookupByLibrary.simpleMessage("[Custom Message]"),
        "chat_message_brief_file":
            MessageLookupByLibrary.simpleMessage("[File]"),
        "chat_message_brief_image":
            MessageLookupByLibrary.simpleMessage("[Image]"),
        "chat_message_brief_location":
            MessageLookupByLibrary.simpleMessage("[Location]"),
        "chat_message_brief_video":
            MessageLookupByLibrary.simpleMessage("[Video]"),
        "chat_message_collect_success":
            MessageLookupByLibrary.simpleMessage("Collect Success"),
        "chat_message_copy_success":
            MessageLookupByLibrary.simpleMessage("Copy Success"),
        "chat_message_delete_confirm":
            MessageLookupByLibrary.simpleMessage("Delete this message?"),
        "chat_message_have_been_revoked":
            MessageLookupByLibrary.simpleMessage("Message revoked"),
        "chat_message_image_save":
            MessageLookupByLibrary.simpleMessage("Image saved successfully"),
        "chat_message_image_save_fail":
            MessageLookupByLibrary.simpleMessage("Failed to save image"),
        "chat_message_more_shoot":
            MessageLookupByLibrary.simpleMessage("Shooting"),
        "chat_message_open_message_notice":
            MessageLookupByLibrary.simpleMessage("Open message notice"),
        "chat_message_pick_photo":
            MessageLookupByLibrary.simpleMessage("Pick photo"),
        "chat_message_pick_video":
            MessageLookupByLibrary.simpleMessage("Pick video"),
        "chat_message_pin_message": m6,
        "chat_message_pin_message_for_team": m7,
        "chat_message_reedit":
            MessageLookupByLibrary.simpleMessage(" Reedit >"),
        "chat_message_reply_someone": m8,
        "chat_message_revoke_confirm":
            MessageLookupByLibrary.simpleMessage("Revoke this message?"),
        "chat_message_revoke_failed":
            MessageLookupByLibrary.simpleMessage("Revoke failed"),
        "chat_message_revoke_over_time":
            MessageLookupByLibrary.simpleMessage("Over Time,Revoke failed"),
        "chat_message_send": MessageLookupByLibrary.simpleMessage("Send"),
        "chat_message_send_hint": m9,
        "chat_message_set_top":
            MessageLookupByLibrary.simpleMessage("Set session top"),
        "chat_message_signal":
            MessageLookupByLibrary.simpleMessage("Message mark"),
        "chat_message_take_photo":
            MessageLookupByLibrary.simpleMessage("Take photo"),
        "chat_message_take_video":
            MessageLookupByLibrary.simpleMessage("Take video"),
        "chat_message_unknown_notification":
            MessageLookupByLibrary.simpleMessage("Unknown Notification"),
        "chat_message_unknown_type":
            MessageLookupByLibrary.simpleMessage("Unknown Type"),
        "chat_message_video_save":
            MessageLookupByLibrary.simpleMessage("Video saved successfully"),
        "chat_message_video_save_fail":
            MessageLookupByLibrary.simpleMessage("Failed to save video"),
        "chat_message_voice_in": MessageLookupByLibrary.simpleMessage(
            "Release to send, hold and swipe to an empty area to cancel"),
        "chat_message_you": MessageLookupByLibrary.simpleMessage("you"),
        "chat_pressed_to_speak":
            MessageLookupByLibrary.simpleMessage("Pressed to speak"),
        "chat_setting": MessageLookupByLibrary.simpleMessage("Chat setting"),
        "chat_team_ait_all": MessageLookupByLibrary.simpleMessage("All"),
        "chat_team_all_mute": MessageLookupByLibrary.simpleMessage("Mute"),
        "chat_team_cancel_all_mute":
            MessageLookupByLibrary.simpleMessage("cancel all mute"),
        "chat_team_full_mute": MessageLookupByLibrary.simpleMessage("mute all"),
        "chat_team_invitation_permission_update": m10,
        "chat_team_invited_id_verify_permission_update": m11,
        "chat_team_modify_extension_permission_update": m12,
        "chat_team_modify_resource_permission_update": m13,
        "chat_team_notice_update": m14,
        "chat_team_notify_accept_invite": m15,
        "chat_team_notify_add_manager": m16,
        "chat_team_notify_dismiss": m17,
        "chat_team_notify_manager_pass": m18,
        "chat_team_notify_mute": m19,
        "chat_team_notify_remove_manager": m20,
        "chat_team_notify_trans_owner": m21,
        "chat_team_notify_un_mute": m22,
        "chat_team_notify_update_extension": m23,
        "chat_team_notify_update_extension_server": m24,
        "chat_team_notify_update_introduction": m25,
        "chat_team_notify_update_name": m26,
        "chat_team_notify_update_team_avatar":
            MessageLookupByLibrary.simpleMessage("team avatar have updated"),
        "chat_team_update": m27,
        "chat_team_verify_update_as_disallow_anyone_join":
            MessageLookupByLibrary.simpleMessage(
                "update as disallow anyone join"),
        "chat_team_verify_update_as_need_no_verify":
            MessageLookupByLibrary.simpleMessage("update as need no verify"),
        "chat_team_verify_update_as_need_verify":
            MessageLookupByLibrary.simpleMessage("update as need verify"),
        "message_all_read":
            MessageLookupByLibrary.simpleMessage("All member have read"),
        "message_all_unread":
            MessageLookupByLibrary.simpleMessage("All member unread"),
        "message_cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "message_forward_message_tips": m28,
        "message_forward_to": MessageLookupByLibrary.simpleMessage("Send to"),
        "message_forward_to_p2p":
            MessageLookupByLibrary.simpleMessage("Forward to person"),
        "message_forward_to_team":
            MessageLookupByLibrary.simpleMessage("Forward to team"),
        "message_read_status":
            MessageLookupByLibrary.simpleMessage("Message read status"),
        "message_read_with_number": m29,
        "message_search_empty":
            MessageLookupByLibrary.simpleMessage("No chat history"),
        "message_search_hint":
            MessageLookupByLibrary.simpleMessage("Search chat content"),
        "message_search_title":
            MessageLookupByLibrary.simpleMessage("Search History"),
        "message_unread_with_number": m30
      };
}
