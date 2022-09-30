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

  static String m0(userName) => "账号:${userName}";

  static String m1(user) => "${user}好友申请";

  static String m2(userName) => "将联系人\"${userName}\"删除";

  static String m3(userName) => "昵称:${userName}";

  static String m4(user) => "${user}同意了你的好友请求";

  static String m5(user) => "${user}同意了你入群邀请";

  static String m6(user) => "${user}已经添加你为好友";

  static String m7(user) => "${user}拒绝了你的好友请求";

  static String m8(user) => "${user}拒绝了你入群邀请";

  static String m9(user) => "${user}拒绝了你入群申请";

  static String m10(user, team) => "${user}申请加入${team}";

  static String m11(user, team) => "${user}邀请你加入${team}";

  static String m12(count) => "确定(${count})";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "contact_accept": MessageLookupByLibrary.simpleMessage("同意"),
        "contact_accepted": MessageLookupByLibrary.simpleMessage("已同意"),
        "contact_account": m0,
        "contact_add_friend": MessageLookupByLibrary.simpleMessage("添加好友"),
        "contact_add_to_blacklist":
            MessageLookupByLibrary.simpleMessage("加入黑名单"),
        "contact_apply_from": m1,
        "contact_birthday": MessageLookupByLibrary.simpleMessage("生日"),
        "contact_black_list": MessageLookupByLibrary.simpleMessage("黑名单"),
        "contact_cancel": MessageLookupByLibrary.simpleMessage("取消"),
        "contact_chat": MessageLookupByLibrary.simpleMessage("聊天"),
        "contact_clean": MessageLookupByLibrary.simpleMessage("清空"),
        "contact_comment": MessageLookupByLibrary.simpleMessage("备注名"),
        "contact_delete": MessageLookupByLibrary.simpleMessage("删除好友"),
        "contact_delete_specific_friend": m2,
        "contact_expired": MessageLookupByLibrary.simpleMessage("已过期"),
        "contact_have_send_apply":
            MessageLookupByLibrary.simpleMessage("已发送申请"),
        "contact_ignored": MessageLookupByLibrary.simpleMessage("已忽略"),
        "contact_mail": MessageLookupByLibrary.simpleMessage("邮箱"),
        "contact_message_notice": MessageLookupByLibrary.simpleMessage("消息提醒"),
        "contact_nick": m3,
        "contact_phone": MessageLookupByLibrary.simpleMessage("手机"),
        "contact_reject": MessageLookupByLibrary.simpleMessage("拒绝"),
        "contact_rejected": MessageLookupByLibrary.simpleMessage("已拒绝"),
        "contact_release": MessageLookupByLibrary.simpleMessage("解除"),
        "contact_save": MessageLookupByLibrary.simpleMessage("保存"),
        "contact_select_as_most":
            MessageLookupByLibrary.simpleMessage("选择人员已达上限"),
        "contact_signature": MessageLookupByLibrary.simpleMessage("个性签名"),
        "contact_some_accept_your_apply": m4,
        "contact_some_accept_your_invitation": m5,
        "contact_some_add_your_as_friend": m6,
        "contact_some_reject_your_apply": m7,
        "contact_some_reject_your_invitation": m8,
        "contact_some_reject_your_team_apply": m9,
        "contact_someone_apply_join_team": m10,
        "contact_someone_invite_your_join_team": m11,
        "contact_sure_with_count": m12,
        "contact_team": MessageLookupByLibrary.simpleMessage("我的群聊"),
        "contact_title": MessageLookupByLibrary.simpleMessage("通讯录"),
        "contact_user_selector": MessageLookupByLibrary.simpleMessage("人员选择"),
        "contact_verify_message": MessageLookupByLibrary.simpleMessage("验证消息"),
        "contact_you_will_never_receive_any_message_from_those_person":
            MessageLookupByLibrary.simpleMessage("你不会收到列表中任何联系人的消息")
      };
}
