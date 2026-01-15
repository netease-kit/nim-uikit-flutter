// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.



// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'demo_kit_client_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class DemoKitClientLocalizationsZh extends DemoKitClientLocalizations {
  DemoKitClientLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '云信IM';

  @override
  String get yunxinName => '网易云信';

  @override
  String get yunxinDesc => '真正稳定的IM 云服务';

  @override
  String get welcomeButton => '注册/登录';

  @override
  String get message => '消息';

  @override
  String get contact => '通讯录';

  @override
  String get mine => '我的';

  @override
  String get conversation => '会话列表';

  @override
  String get dataIsLoading => '数据加载中...';

  @override
  String tabMineAccount(String account) {
    return '账号:$account';
  }

  @override
  String get mineCollect => '收藏';

  @override
  String get mineAbout => '关于云信';

  @override
  String get mineSetting => '设置';

  @override
  String get mineVersion => '版本号';

  @override
  String get mineProduct => '产品介绍';

  @override
  String get userInfoTitle => '个人信息';

  @override
  String get userInfoAvatar => '头像';

  @override
  String get userInfoAccount => '账号';

  @override
  String get userInfoNickname => '昵称';

  @override
  String get userInfoSexual => '性别';

  @override
  String get userInfoBirthday => '生日';

  @override
  String get userInfoPhone => '手机';

  @override
  String get userInfoEmail => '邮箱';

  @override
  String get userInfoSign => '个性签名';

  @override
  String get actionCopySuccess => '复制成功！';

  @override
  String get sexualMale => '男';

  @override
  String get sexualFemale => '女';

  @override
  String get sexualUnknown => '未知';

  @override
  String get userInfoComplete => '完成';

  @override
  String get requestFail => '操作失败';

  @override
  String get mineLogout => '退出登录';

  @override
  String get logoutDialogContent => '确认注销当前登录账号？';

  @override
  String get logoutDialogAgree => '是';

  @override
  String get logoutDialogDisagree => '否';

  @override
  String get settingNotify => '消息提醒';

  @override
  String get settingClearCache => '清理缓存';

  @override
  String get settingPlayMode => '听筒模式';

  @override
  String get settingFilterNotify => '过滤通知';

  @override
  String get settingFriendDeleteMode => '删除好友是否同步删除备注';

  @override
  String get settingMessageReadMode => '消息已读未读功能';

  @override
  String get settingNotifyInfo => '新消息通知';

  @override
  String get settingNotifyMode => '消息提醒方式';

  @override
  String get settingNotifyModeRing => '响铃模式';

  @override
  String get settingNotifyModeShake => '震动模式';

  @override
  String get settingNotifyPush => '推送设置';

  @override
  String get settingNotifyPushSync => 'PC/Web同步接收推送';

  @override
  String get settingNotifyPushDetail => '通知栏不显示消息详情';

  @override
  String get clearMessage => '清理所有聊天记录';

  @override
  String get clearSdkCache => '清理SDK文件缓存';

  @override
  String get clearMessageTips => '聊天记录已清理';

  @override
  String cacheSizeText(String size) {
    return '$size M';
  }

  @override
  String get notUsable => '功能暂未开放';

  @override
  String get settingFail => '设置失败';

  @override
  String get settingSuccess => '设置成功';

  @override
  String get customMessage => '[自定义消息]';

  @override
  String get localConversation => '本地会话';

  @override
  String get settingAndResetTips => '设置成功，重启后生效';

  @override
  String get swindleTips => '仅用于体验云信IM 产品功能，请勿轻信汇款、中奖等涉及钱款的信息，勿轻易拨打陌生电话，谨防上当受骗。';

  @override
  String get aiStreamMode => 'AI数字人流式输出';

  @override
  String get language => '语言';

  @override
  String get languageChinese => '中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get save => '保存';

  @override
  String get kickedOff => '您已被踢下线';

  @override
  String get textSafetyNotice => '文本安全提示';

  @override
  String get enableCloudMessageSearch => '云端消息搜索';
}
