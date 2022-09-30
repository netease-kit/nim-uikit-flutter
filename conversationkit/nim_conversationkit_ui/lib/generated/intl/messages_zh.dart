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

  static String m0(size) => "确定(${size})";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "add_friend": MessageLookupByLibrary.simpleMessage("添加好友"),
        "add_friend_search_empty_tips":
            MessageLookupByLibrary.simpleMessage("该用户不存在"),
        "add_friend_search_hint": MessageLookupByLibrary.simpleMessage("请输入账号"),
        "cancel_stick_title": MessageLookupByLibrary.simpleMessage("取消置顶"),
        "cancel_title": MessageLookupByLibrary.simpleMessage("取消"),
        "conversation_network_error_tip":
            MessageLookupByLibrary.simpleMessage("当前网络不可用，请检查你当网络设置。"),
        "conversation_title": MessageLookupByLibrary.simpleMessage("云信IM"),
        "create_advanced_team": MessageLookupByLibrary.simpleMessage("创建高级群"),
        "create_advanced_team_success":
            MessageLookupByLibrary.simpleMessage("成功创建高级群"),
        "create_group_team": MessageLookupByLibrary.simpleMessage("创建讨论组"),
        "delete_title": MessageLookupByLibrary.simpleMessage("删除"),
        "recent_title": MessageLookupByLibrary.simpleMessage("最近聊天"),
        "stick_title": MessageLookupByLibrary.simpleMessage("置顶"),
        "sure_count_title": m0,
        "sure_title": MessageLookupByLibrary.simpleMessage("确定")
      };
}
