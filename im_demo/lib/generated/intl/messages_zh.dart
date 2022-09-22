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

  static String m0(size) => "${size} M";

  static String m1(account) => "账号:${account}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "action_copy_success": MessageLookupByLibrary.simpleMessage("复制成功！"),
        "appName": MessageLookupByLibrary.simpleMessage("云信IM"),
        "cache_size_text": m0,
        "clear_message": MessageLookupByLibrary.simpleMessage("清理所有聊天记录"),
        "clear_message_tips": MessageLookupByLibrary.simpleMessage("聊天记录已清理"),
        "clear_sdk_cache": MessageLookupByLibrary.simpleMessage("清理SDK文件缓存"),
        "contact": MessageLookupByLibrary.simpleMessage("通讯录"),
        "conversation": MessageLookupByLibrary.simpleMessage("会话列表"),
        "dataIsLoading": MessageLookupByLibrary.simpleMessage("数据加载中..."),
        "logout_dialog_agree": MessageLookupByLibrary.simpleMessage("是"),
        "logout_dialog_content":
            MessageLookupByLibrary.simpleMessage("确认注销当前登录账号？"),
        "logout_dialog_disagree": MessageLookupByLibrary.simpleMessage("否"),
        "message": MessageLookupByLibrary.simpleMessage("消息"),
        "mine": MessageLookupByLibrary.simpleMessage("我的"),
        "mine_about": MessageLookupByLibrary.simpleMessage("关于云信"),
        "mine_collect": MessageLookupByLibrary.simpleMessage("收藏"),
        "mine_logout": MessageLookupByLibrary.simpleMessage("退出登录"),
        "mine_product": MessageLookupByLibrary.simpleMessage("产品介绍"),
        "mine_setting": MessageLookupByLibrary.simpleMessage("设置"),
        "mine_version": MessageLookupByLibrary.simpleMessage("版本号"),
        "not_usable": MessageLookupByLibrary.simpleMessage("功能暂未开放"),
        "request_fail": MessageLookupByLibrary.simpleMessage("操作失败"),
        "setting_clear_cache": MessageLookupByLibrary.simpleMessage("清理缓存"),
        "setting_fail": MessageLookupByLibrary.simpleMessage("设置失败"),
        "setting_filter_notify": MessageLookupByLibrary.simpleMessage("过滤通知"),
        "setting_friend_delete_mode":
            MessageLookupByLibrary.simpleMessage("删除好友是否同步删除备注"),
        "setting_message_read_mode":
            MessageLookupByLibrary.simpleMessage("消息已读未读功能"),
        "setting_notify": MessageLookupByLibrary.simpleMessage("消息提醒"),
        "setting_notify_info": MessageLookupByLibrary.simpleMessage("新消息通知"),
        "setting_notify_mode": MessageLookupByLibrary.simpleMessage("消息提醒方式"),
        "setting_notify_mode_ring":
            MessageLookupByLibrary.simpleMessage("响铃模式"),
        "setting_notify_mode_shake":
            MessageLookupByLibrary.simpleMessage("震动模式"),
        "setting_notify_push": MessageLookupByLibrary.simpleMessage("推送设置"),
        "setting_notify_push_detail":
            MessageLookupByLibrary.simpleMessage("通知栏不显示消息详情"),
        "setting_notify_push_sync":
            MessageLookupByLibrary.simpleMessage("PC/Web同步接收推送"),
        "setting_play_mode": MessageLookupByLibrary.simpleMessage("听筒模式"),
        "setting_success": MessageLookupByLibrary.simpleMessage("设置成功"),
        "sexual_female": MessageLookupByLibrary.simpleMessage("女"),
        "sexual_male": MessageLookupByLibrary.simpleMessage("男"),
        "sexual_unknown": MessageLookupByLibrary.simpleMessage("未知"),
        "tab_mine_account": m1,
        "user_info_account": MessageLookupByLibrary.simpleMessage("账号"),
        "user_info_avatar": MessageLookupByLibrary.simpleMessage("头像"),
        "user_info_birthday": MessageLookupByLibrary.simpleMessage("生日"),
        "user_info_complete": MessageLookupByLibrary.simpleMessage("完成"),
        "user_info_email": MessageLookupByLibrary.simpleMessage("邮箱"),
        "user_info_nickname": MessageLookupByLibrary.simpleMessage("昵称"),
        "user_info_phone": MessageLookupByLibrary.simpleMessage("手机"),
        "user_info_sexual": MessageLookupByLibrary.simpleMessage("性别"),
        "user_info_sign": MessageLookupByLibrary.simpleMessage("个性签名"),
        "user_info_title": MessageLookupByLibrary.simpleMessage("个人信息"),
        "welcome_button": MessageLookupByLibrary.simpleMessage("注册/登录"),
        "yunxin_desc": MessageLookupByLibrary.simpleMessage("真正稳定的IM 云服务"),
        "yunxin_name": MessageLookupByLibrary.simpleMessage("网易云信")
      };
}
