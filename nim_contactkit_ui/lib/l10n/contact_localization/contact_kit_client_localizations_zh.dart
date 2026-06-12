// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
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
  String get contactAIUserList => '我的数字人';

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
  String get contactSelectedMembers => '已选成员';

  @override
  String get contactFriendEmpty => '暂无好友';

  @override
  String get myFriend => '我的好友';

  @override
  String get aiUsers => '数字人';

  @override
  String get aiUsersEmpty => '暂无数字人';

  @override
  String get team => '群';

  @override
  String get friend => '好友';

  @override
  String teamJoinApply(String teamName) {
    return '申请加入:$teamName';
  }

  @override
  String teamJoinApplyReject(String teamName) {
    return '拒绝了申请入群请求:$teamName';
  }

  @override
  String teamJoinInvitation(String teamName) {
    return '邀请你加入:$teamName';
  }

  @override
  String teamJoinInvitationReject(String teamName) {
    return '拒绝了入群邀请 :$teamName';
  }

  @override
  String get teamMemberLimited => '群组人数达到上限';

  @override
  String get teamMemberAlreadyExist => '已在群组';

  @override
  String get teamNotExist => '群组已解散';

  @override
  String get teamVerifyNoPermission => '暂无权限';

  @override
  String get contactMyRobot => '我的机器人';

  @override
  String get contactRobotEmpty => '暂无机器人';

  @override
  String get contactRobotEmptyHint => '点击右上角创建';

  @override
  String get contactRobotCreate => '创建机器人';

  @override
  String get contactRobotEdit => '编辑';

  @override
  String get contactRobotName => '昵称';

  @override
  String get contactRobotAvatar => '头像';

  @override
  String get contactRobotSendMessage => '聊天';

  @override
  String get contactRobotTitle => '机器人';

  @override
  String get contactRobotEditPageTitle => '编辑机器人';

  @override
  String get contactRobotViewConfig => '查看配置串';

  @override
  String get contactRobotRefreshToken => '刷新Token';

  @override
  String get contactRobotDelete => '删除机器人';

  @override
  String get contactRobotConfigTitle => '配置串';

  @override
  String get contactRobotConfigLabel => '配置串：';

  @override
  String get contactRobotCopy => '复制';

  @override
  String get contactRobotConfigNotice => '请妥善保管，不要泄露给他人';

  @override
  String get contactRobotRefreshConfirmTitle => '确认刷新Token？';

  @override
  String get contactRobotRefreshConfirmContent =>
      '刷新后，旧Token将立即失效，正在使用的机器人需要重新配置';

  @override
  String get contactRobotDeleteConfirmTitle => '确认删除机器人？';

  @override
  String get contactRobotDeleteConfirmContent => '删除后，正在使用的机器人将断开连接，需要重新配置';

  @override
  String get contactRobotBind => '绑定机器人';

  @override
  String get contactRobotScan => '扫一扫';

  @override
  String get contactRobotBindNew => '创建机器人';

  @override
  String get contactRobotBindSelectHint => '请选择要绑定的机器人：';

  @override
  String get contactRobotBindExistingHint => '或选择已有机器人：';

  @override
  String get contactRobotBindConfirmTitle => '确认绑定该账号？';

  @override
  String get contactRobotBindConfirmContent => '绑定后，已经配置过该账号的机器人将断开连接，需要重新配置';

  @override
  String get contactRobotLimitTitle => '机器人数量已达上限';

  @override
  String get contactRobotLimitContent => '您已创建10个机器人，请选择已有机器人或先删除一个。';

  @override
  String get contactRobotLimitToast => '机器人数量已达上限，选择已有机器人或去删除机器人';

  @override
  String get contactRobotSelectExisting => '选择已有机器人';

  @override
  String get contactRobotGoDelete => '去删除机器人';

  @override
  String get contactRobotNameRequired => '昵称不能为空';

  @override
  String get contactRobotConfigCopied => '配置串已复制';

  @override
  String get contactRobotInvalidQrCode => '无效二维码';

  @override
  String get contactRobotScanFailed => '扫码失败';

  @override
  String get contactRobotQrCodeExpired => '二维码已过期';

  @override
  String get contactRobotQrCodeBound => '二维码已被绑定';

  @override
  String get contactRobotConfirm => '确认';

  @override
  String get contactRobotQrCode => '二维码';

  @override
  String get contactRobotManualInputHint => '请输入二维码内容';

  @override
  String get contactRobotBindingSuccess => '绑定成功';
}
