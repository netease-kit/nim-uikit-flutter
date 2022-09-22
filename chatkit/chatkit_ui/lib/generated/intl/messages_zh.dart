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

  static String m0(users) => "${users}离开了群";

  static String m1(users) => "${users}已被移出群";

  static String m2(user, members) => "${user}邀请${members}加入群";

  static String m3(user, members) => "${user}邀请${members}加入讨论组";

  static String m4(users) => "${users}离开了讨论组";

  static String m5(users) => "${users}已被移出讨论组";

  static String m6(userName) => "${userName}标记了这条信息，对话内容双方均可见";

  static String m7(userName) => "${userName}标记了这条信息，所有群成员均可见";

  static String m8(content) => "回复 ${content}";

  static String m9(userName) => "发送给 ${userName}";

  static String m10(permission) => "群邀请他人权限被更新为${permission}";

  static String m11(permission) => "群被邀请人身份验证权限被更新为${permission}";

  static String m12(permission) => "群扩展字段修改权限被更新为${permission}";

  static String m13(permission) => "群资料修改权限被更新为${permission}";

  static String m14(notice) => "群公告变更为${notice}";

  static String m15(members, user) => "${user}接受了${members}的入群邀请";

  static String m16(member) => "${member}被任命为管理员";

  static String m17(users) => "${users}解散了群";

  static String m18(members) => "管理员通过用户${members}的入群申请";

  static String m19(user) => "${user}被管理员禁言";

  static String m20(member) => "${member}被撤销管理员身份";

  static String m21(members, user) => "${user}将群转移给${members}";

  static String m22(user) => "${user}被管理员解除禁言";

  static String m23(name) => "扩展字段被更新为${name}";

  static String m24(name) => "扩展字段（服务器）被更新为${name}";

  static String m25(name) => "群介绍更新为${name}";

  static String m26(name) => "名称变更为${name}";

  static String m27(key, value) => "群${key}被更新为${value}";

  static String m28(user) => "[转发]${user}的会话记录";

  static String m29(num) => "已读(${num})";

  static String m30(num) => "未读(${num})";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "chat_advanced_team_notify_leave": m0,
        "chat_advanced_team_notify_remove": m1,
        "chat_advice_team_notify_invite": m2,
        "chat_discuss_team_notify_invite": m3,
        "chat_discuss_team_notify_leave": m4,
        "chat_discuss_team_notify_remove": m5,
        "chat_is_typing": MessageLookupByLibrary.simpleMessage("正在输入中..."),
        "chat_message_action_collect":
            MessageLookupByLibrary.simpleMessage("收藏"),
        "chat_message_action_copy": MessageLookupByLibrary.simpleMessage("复制"),
        "chat_message_action_delete":
            MessageLookupByLibrary.simpleMessage("删除"),
        "chat_message_action_forward":
            MessageLookupByLibrary.simpleMessage("转发"),
        "chat_message_action_multi_select":
            MessageLookupByLibrary.simpleMessage("多选"),
        "chat_message_action_pin": MessageLookupByLibrary.simpleMessage("标记"),
        "chat_message_action_reply": MessageLookupByLibrary.simpleMessage("回复"),
        "chat_message_action_revoke":
            MessageLookupByLibrary.simpleMessage("撤回"),
        "chat_message_action_un_pin":
            MessageLookupByLibrary.simpleMessage("取消标记"),
        "chat_message_ait_contact_title":
            MessageLookupByLibrary.simpleMessage("选择提醒"),
        "chat_message_brief_audio":
            MessageLookupByLibrary.simpleMessage("[语音]"),
        "chat_message_brief_custom":
            MessageLookupByLibrary.simpleMessage("[自定义消息]"),
        "chat_message_brief_file": MessageLookupByLibrary.simpleMessage("[文件]"),
        "chat_message_brief_image":
            MessageLookupByLibrary.simpleMessage("[图片]"),
        "chat_message_brief_location":
            MessageLookupByLibrary.simpleMessage("[位置]"),
        "chat_message_brief_video":
            MessageLookupByLibrary.simpleMessage("[视频]"),
        "chat_message_collect_success":
            MessageLookupByLibrary.simpleMessage("收藏成功"),
        "chat_message_copy_success":
            MessageLookupByLibrary.simpleMessage("复制成功"),
        "chat_message_delete_confirm":
            MessageLookupByLibrary.simpleMessage("删除此消息？"),
        "chat_message_have_been_revoked":
            MessageLookupByLibrary.simpleMessage("此消息已撤回"),
        "chat_message_image_save":
            MessageLookupByLibrary.simpleMessage("图片已保存到手机"),
        "chat_message_image_save_fail":
            MessageLookupByLibrary.simpleMessage("图片保存失败"),
        "chat_message_more_shoot": MessageLookupByLibrary.simpleMessage("拍摄"),
        "chat_message_open_message_notice":
            MessageLookupByLibrary.simpleMessage("开启消息提醒"),
        "chat_message_pick_photo": MessageLookupByLibrary.simpleMessage("照片"),
        "chat_message_pick_video": MessageLookupByLibrary.simpleMessage("视频"),
        "chat_message_pin_message": m6,
        "chat_message_pin_message_for_team": m7,
        "chat_message_reedit": MessageLookupByLibrary.simpleMessage(" 重新编辑 >"),
        "chat_message_reply_someone": m8,
        "chat_message_revoke_confirm":
            MessageLookupByLibrary.simpleMessage("撤回此消息？"),
        "chat_message_revoke_failed":
            MessageLookupByLibrary.simpleMessage("撤回失败"),
        "chat_message_revoke_over_time":
            MessageLookupByLibrary.simpleMessage("已超过时间无法撤回"),
        "chat_message_send": MessageLookupByLibrary.simpleMessage("发送"),
        "chat_message_send_hint": m9,
        "chat_message_set_top": MessageLookupByLibrary.simpleMessage("聊天置顶"),
        "chat_message_signal": MessageLookupByLibrary.simpleMessage("标记"),
        "chat_message_take_photo": MessageLookupByLibrary.simpleMessage("拍照"),
        "chat_message_take_video": MessageLookupByLibrary.simpleMessage("摄像"),
        "chat_message_unknown_notification":
            MessageLookupByLibrary.simpleMessage("未知通知"),
        "chat_message_unknown_type":
            MessageLookupByLibrary.simpleMessage("未知类型"),
        "chat_message_video_save":
            MessageLookupByLibrary.simpleMessage("视频已保存到手机"),
        "chat_message_video_save_fail":
            MessageLookupByLibrary.simpleMessage("视频保存失败"),
        "chat_message_voice_in":
            MessageLookupByLibrary.simpleMessage("松开发送，按住滑到空白区域取消"),
        "chat_message_you": MessageLookupByLibrary.simpleMessage("你"),
        "chat_pressed_to_speak": MessageLookupByLibrary.simpleMessage("按住说话"),
        "chat_setting": MessageLookupByLibrary.simpleMessage("聊天设置"),
        "chat_team_ait_all": MessageLookupByLibrary.simpleMessage("所有人"),
        "chat_team_all_mute": MessageLookupByLibrary.simpleMessage("当前群主设置为禁言"),
        "chat_team_cancel_all_mute":
            MessageLookupByLibrary.simpleMessage("取消群全员禁言"),
        "chat_team_full_mute": MessageLookupByLibrary.simpleMessage("群全员禁言"),
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
            MessageLookupByLibrary.simpleMessage("群头像已更新"),
        "chat_team_update": m27,
        "chat_team_verify_update_as_disallow_anyone_join":
            MessageLookupByLibrary.simpleMessage("群身份验证权限更新为不容许任何人申请加入"),
        "chat_team_verify_update_as_need_no_verify":
            MessageLookupByLibrary.simpleMessage("群身份验证权限更新为不需要身份验证"),
        "chat_team_verify_update_as_need_verify":
            MessageLookupByLibrary.simpleMessage("群身份验证权限更新为需要身份验证"),
        "message_all_read": MessageLookupByLibrary.simpleMessage("全部成员已读"),
        "message_all_unread": MessageLookupByLibrary.simpleMessage("全部成员未读"),
        "message_cancel": MessageLookupByLibrary.simpleMessage("取消"),
        "message_forward_message_tips": m28,
        "message_forward_to": MessageLookupByLibrary.simpleMessage("发送给"),
        "message_forward_to_p2p": MessageLookupByLibrary.simpleMessage("转发到个人"),
        "message_forward_to_team":
            MessageLookupByLibrary.simpleMessage("转发到群组"),
        "message_read_status": MessageLookupByLibrary.simpleMessage("消息阅读状态"),
        "message_read_with_number": m29,
        "message_search_empty": MessageLookupByLibrary.simpleMessage("暂无聊天记录"),
        "message_search_hint": MessageLookupByLibrary.simpleMessage("搜索聊天内容"),
        "message_search_title": MessageLookupByLibrary.simpleMessage("历史记录"),
        "message_unread_with_number": m30
      };
}
