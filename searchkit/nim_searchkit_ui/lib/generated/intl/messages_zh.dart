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
        "search_empty_tips": MessageLookupByLibrary.simpleMessage("该用户不存在"),
        "search_search": MessageLookupByLibrary.simpleMessage("搜索"),
        "search_search_advance_team":
            MessageLookupByLibrary.simpleMessage("高级群"),
        "search_search_friend": MessageLookupByLibrary.simpleMessage("好友"),
        "search_search_hit":
            MessageLookupByLibrary.simpleMessage("请输入你要搜索的关键字"),
        "search_search_normal_team": MessageLookupByLibrary.simpleMessage("讨论组")
      };
}
