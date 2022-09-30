// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh locale. All the
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
  String get localeName => 'zh';

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "team_advanced_dismiss": MessageLookupByLibrary.simpleMessage("解散群聊"),
        "team_advanced_quit": MessageLookupByLibrary.simpleMessage("退出群聊"),
        "team_all_member": MessageLookupByLibrary.simpleMessage("所有人"),
        "team_cancel": MessageLookupByLibrary.simpleMessage("取消"),
        "team_confirm": MessageLookupByLibrary.simpleMessage("确认"),
        "team_default_icon": MessageLookupByLibrary.simpleMessage("选择默认图标"),
        "team_dismiss_advanced_team_query":
            MessageLookupByLibrary.simpleMessage("是否解散群聊？"),
        "team_group_icon_title": MessageLookupByLibrary.simpleMessage("讨论组头像"),
        "team_group_info_title": MessageLookupByLibrary.simpleMessage("讨论组信息"),
        "team_group_member_title":
            MessageLookupByLibrary.simpleMessage("讨论组成员"),
        "team_group_name_title": MessageLookupByLibrary.simpleMessage("讨论组名称"),
        "team_group_quit": MessageLookupByLibrary.simpleMessage("退出讨论组"),
        "team_history": MessageLookupByLibrary.simpleMessage("历史记录"),
        "team_icon_title": MessageLookupByLibrary.simpleMessage("群头像"),
        "team_info_title": MessageLookupByLibrary.simpleMessage("群信息"),
        "team_introduce_title": MessageLookupByLibrary.simpleMessage("群介绍"),
        "team_invite_other_permission":
            MessageLookupByLibrary.simpleMessage("邀请他人权限"),
        "team_mark": MessageLookupByLibrary.simpleMessage("标记"),
        "team_member_title": MessageLookupByLibrary.simpleMessage("群成员"),
        "team_message_tip": MessageLookupByLibrary.simpleMessage("开启消息提醒"),
        "team_mute": MessageLookupByLibrary.simpleMessage("群禁言"),
        "team_my_nickname_title":
            MessageLookupByLibrary.simpleMessage("我在群里的昵称"),
        "team_name_title": MessageLookupByLibrary.simpleMessage("群名称"),
        "team_need_agreed_when_be_invited_permission":
            MessageLookupByLibrary.simpleMessage("是否需要被邀请者同意"),
        "team_no_permission": MessageLookupByLibrary.simpleMessage("没有修改权限"),
        "team_owner": MessageLookupByLibrary.simpleMessage("群主"),
        "team_quit_advanced_team_query":
            MessageLookupByLibrary.simpleMessage("是否退出群聊？"),
        "team_quit_group_team_query":
            MessageLookupByLibrary.simpleMessage("是否退出讨论组？"),
        "team_save": MessageLookupByLibrary.simpleMessage("保存"),
        "team_search_friend": MessageLookupByLibrary.simpleMessage("搜索好友"),
        "team_session_pin": MessageLookupByLibrary.simpleMessage("聊天置顶"),
        "team_setting_title": MessageLookupByLibrary.simpleMessage("设置"),
        "team_update_icon": MessageLookupByLibrary.simpleMessage("修改头像"),
        "team_update_info_permission":
            MessageLookupByLibrary.simpleMessage("群资料修改权限")
      };
}
