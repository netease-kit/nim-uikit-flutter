// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'contact_kit_client_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class ContactKitClientLocalizationsZh extends ContactKitClientLocalizations {
  ContactKitClientLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get contactTitle => '通讯录';

  @override
  String contactNick(String userName) {
    return '昵称:$userName';
  }

  @override
  String contactAccount(String userName) {
    return '账号:$userName';
  }

  @override
  String get contactVerifyMessage => '验证消息';

  @override
  String get contactBlackList => '黑名单';

  @override
  String get contactTeam => '我的群聊';

  @override
  String get contactComment => '备注名';

  @override
  String get contactBirthday => '生日';

  @override
  String get contactPhone => '手机';

  @override
  String get contactMail => '邮箱';

  @override
  String get contactSignature => '个性签名';

  @override
  String get contactMessageNotice => '消息提醒';

  @override
  String get contactAddToBlacklist => '加入黑名单';

  @override
  String get contactChat => '聊天';

  @override
  String get contactDelete => '删除好友';

  @override
  String contactDeleteSpecificFriend(String userName) {
    return '将联系人\"$userName\"删除';
  }

  @override
  String get contactCancel => '取消';

  @override
  String get contactAddFriend => '添加好友';

  @override
  String get contactYouWillNeverReceiveAnyMessageFromThosePerson =>
      '你不会收到列表中任何联系人的消息';

  @override
  String get contactRelease => '解除';

  @override
  String get contactUserSelector => '人员选择';

  @override
  String contactSureWithCount(String count) {
    return '确定($count)';
  }

  @override
  String get contactSelectAsMost => '选择人员已达上限';

  @override
  String get contactClean => '清空';

  @override
  String get contactAccept => '同意';

  @override
  String get contactAccepted => '已同意';

  @override
  String get contactRejected => '已拒绝';

  @override
  String get contactIgnored => '已忽略';

  @override
  String get contactExpired => '已过期';

  @override
  String get contactReject => '拒绝';

  @override
  String contactApplyFrom(String user) {
    return '$user好友申请';
  }

  @override
  String contactSomeoneInviteYourJoinTeam(String user, String team) {
    return '$user邀请您加入群聊\"$team\"';
  }

  @override
  String contactSomeAcceptYourApply(String user) {
    return '$user通过了好友申请';
  }

  @override
  String contactSomeRejectYourApply(String user) {
    return '$user拒绝了好友申请';
  }

  @override
  String contactSomeAcceptYourInvitation(String user) {
    return '$user通过入群邀请';
  }

  @override
  String contactSomeRejectYourInvitation(String user) {
    return '$user拒绝了入群邀请';
  }

  @override
  String contactSomeAddYourAsFriend(String user) {
    return '$user已经添加你为好友';
  }

  @override
  String contactSomeoneApplyJoinTeam(String user, String team) {
    return '$user申请加入$team';
  }

  @override
  String contactSomeRejectYourTeamApply(String user) {
    return '$user拒绝了你入群申请';
  }

  @override
  String get contactSave => '保存';

  @override
  String get contactHaveSendApply => '已发送申请';

  @override
  String get systemVerifyMessageEmpty => '暂无验证消息';

  @override
  String get verifyAgreeMessageText => '我已经同意了你的申请，现在开始聊天吧~';

  @override
  String get verifyMessageHaveBeenHandled => '该验证消息已在其他端处理';

  @override
  String operationFailed(String code) {
    return '操作失败:$code';
  }

  @override
  String get contactSelectEmptyTip => '请选择联系人';

  @override
  String get contactFriendEmpty => '暂无好友';
}
