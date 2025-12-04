// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:core';

import 'package:flutter/material.dart';
import 'package:netease_corekit/report/xkit_report.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/router/imkit_router.dart';
import 'package:nim_chatkit/router/imkit_router_constants.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit/chatkit_client_repo.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_pop_actions.dart';
import 'package:nim_chatkit_ui/view/page/chat_pin_page.dart';
import 'package:nim_core_v2/nim_core.dart';

import 'l10n/S.dart';
import 'view/chat_kit_message_list/item/chat_kit_message_item.dart';
import 'view/input/actions.dart';
import 'view/page/chat_page.dart';
import 'view/page/chat_search_page.dart';

///发送消息前的回调类型
///[message] 待发送的消息
///[conversationId] 会话ID
///[params] 参数
typedef NIMMessageAction = Future Function(
    NIMMessage message, String conversationId, NIMSendMessageParams? params);

const String kPackage = 'nim_chatkit_ui';

///聊天页面客户自定义配置
class ChatUIConfig {
  ///接收消息背景装饰器
  BoxDecoration? receiveMessageBg;

  ///发送消息背景装饰器
  BoxDecoration? selfMessageBg;

  ///不设置头像的用户所展示的文字头像中的文字颜色
  Color? userNickColor;

  ///不设置头像的用户所展示的文字头像中的文字字体大小
  double? userNickTextSize;

  ///接收文本消息字体颜色
  Color? receiveMessageTextColor;

  ///发送文本消息字体颜色
  Color? sendMessageTextColor;

  ///接收文本消息字体大小
  double? receiveMessageTextSize;

  ///发送文本消息字体大小
  double? sendMessageTextSize;

  ///文本消息链接颜色，包括@用户显示的颜色
  Color? messageLinkColor;

  ///头像的圆角
  double? avatarCornerRadius;

  ///消息列表中，时间字体大小
  double? timeTextSize;

  ///消息列表中，时间字体颜色
  Color? timeTextColor;

  ///被标记消息的背景色
  Color? signalBgColor;

  ///单聊中是否展示已读未读状态
  bool? showP2pMessageStatus;

  ///群聊中是否展示已读未读状态
  bool? showTeamMessageStatus;

  ///长按弹框功能开关
  bool enableMessageLongPress = true;

  ///长按弹框配置
  PopMenuConfig? popMenuConfig;

  ///保留默认的更多按钮
  bool keepDefaultMoreAction = true;

  ///更多面板自定义按钮
  List<ActionItem>? moreActions;

  ///自定义输入框功能按钮
  List<ActionItem>? inputActions;

  ///保留默认的输入框功能按钮
  bool keepDefaultInputAction = true;

  ///自定义消息构建
  ChatKitMessageBuilder? messageBuilder;

  MessageClickListener? messageClickListener;

  Future<Map<String, dynamic>> Function(
      NIMMessage message, String conversationId)? getPushPayload;

  ///设置图片加载中的占位图
  ///[aspectRatio] 图片宽高比
  ///[width] 图片宽度
  Widget Function(double aspectRatio, {double? width})? imagePlaceHolder;

  ///是否展示头像
  bool? Function(NIMMessage message)? isShowAvatar;

  ///视频消息最大size 单位M，不设置默认200
  int? maxVideoSize;

  ///文件消息最大size 单位M，不设置默认200
  int? maxFileSize;

  ///被@的消息点击回调
  ///[account] 被@的用户id
  ///[text] @的文本
  Function(String account, String text)? onTapAitLink;

  ///消息简要展示,将会显示在被回复的消息，合并转发之后的消息，以及推送内容
  ///[message] 消息
  String? Function(NIMMessage message)? getMessageBrief;

  ///展示时间的消息间隔，单位ms，默认5分钟
  int showTimeInterval;

  ///群被踢或者解散之后的处理方法，如果返回true则完全有此方法处理
  ///如果返回false，此方法处理万之后 会退回到根目录
  bool Function()? onTeamDismissOrLeave;

  ChatUIConfig(
      {this.showTeamMessageStatus,
      this.receiveMessageBg,
      this.selfMessageBg,
      this.showP2pMessageStatus,
      this.signalBgColor,
      this.timeTextColor,
      this.timeTextSize,
      this.receiveMessageTextColor,
      this.sendMessageTextColor,
      this.receiveMessageTextSize,
      this.sendMessageTextSize,
      this.userNickTextSize,
      this.userNickColor,
      this.avatarCornerRadius,
      this.enableMessageLongPress = true,
      this.popMenuConfig,
      this.keepDefaultMoreAction = true,
      this.moreActions,
      this.messageBuilder,
      this.messageClickListener,
      this.getPushPayload,
      this.imagePlaceHolder,
      this.maxVideoSize,
      this.onTapAitLink,
      this.maxFileSize,
      this.keepDefaultInputAction = true,
      this.inputActions,
      this.getMessageBrief,
      this.showTimeInterval = 5 * 60 * 1000,
      this.isShowAvatar,
      this.onTeamDismissOrLeave,
      this.messageLinkColor});
}

///消息点击回调
class MessageClickListener {
  PopMenuAction? customPopActions;

  bool Function(ChatMessage message)? onMessageItemClick;

  bool Function(ChatMessage message)? onMessageItemLongClick;

  bool Function(String? userID, {bool isSelf})? onTapAvatar;

  bool Function(String? userID, {bool isSelf})? onLongPressAvatar;

  MessageClickListener(
      {this.onMessageItemLongClick,
      this.onMessageItemClick,
      this.customPopActions,
      this.onLongPressAvatar,
      this.onTapAvatar});
}

///长按弹框开关配置
class PopMenuConfig {
  ///转发
  bool? enableForward;

  ///复制
  bool? enableCopy;

  ///扬声器切换
  bool? enableVoiceSwitch;

  ///回复
  bool? enableReply;

  ///Pin
  bool? enablePin;

  ///多选
  bool? enableMultiSelect;

  ///收藏
  bool? enableCollect;

  ///删除
  bool? enableDelete;

  ///撤回
  bool? enableRevoke;

  PopMenuConfig(
      {this.enableForward,
      this.enableCopy,
      this.enableReply,
      this.enablePin,
      this.enableMultiSelect,
      this.enableCollect,
      this.enableDelete,
      this.enableRevoke,
      this.enableVoiceSwitch});
}

///全局配置，全局生效，优先级低于参数配置
class ChatKitClient {
  ChatUIConfig chatUIConfig = ChatUIConfig();

  ///消息发送之前的回调，可使用其添加扩展
  NIMMessageAction? messageAction;

  ///是否展示警告消息
  bool showWarningTyps = false;

  ChatKitClient._();

  static final ChatKitClient instance = ChatKitClient._();

  static get delegate {
    return S.delegate;
  }

  //注册撤回消息监听，在其中插入本地消息
  void registerRevokedMessage({String? messageRevokedStr}) {
    ChatKitClientRepo.instance
        .registerRevoke(messageRevokedStr ?? S.of().chatMessageHaveBeenRevoked);
  }

  //反注册撤回消息监听
  void unregisterRevokedMessage() {
    ChatKitClientRepo.instance.unregisterRevoke();
  }

  static init({bool enableCallKit = true}) {
    ChatKitClientRepo.init();
    IMKitRouter.instance.registerRouter(
        RouterConstants.PATH_CHAT_PAGE,
        (context) => ChatPage(
              conversationId: IMKitRouter.getArgumentFormMap<String>(
                  context, 'conversationId')!,
              conversationType:
                  IMKitRouter.getArgumentFormMap<NIMConversationType>(
                      context, 'conversationType')!,
              anchor:
                  IMKitRouter.getArgumentFormMap<NIMMessage>(context, 'anchor'),
            ));
    IMKitRouter.instance.registerRouter(
        RouterConstants.PATH_CHAT_SEARCH_PAGE,
        (context) => ChatSearchPage(
            IMKitRouter.getArgumentFormMap<String>(context, 'teamId')!));

    IMKitRouter.instance.registerRouter(
        RouterConstants.PATH_CHAT_PIN_PAGE,
        (context) => ChatPinPage(
              conversationId: IMKitRouter.getArgumentFormMap<String>(
                  context, 'conversationId')!,
              conversationType:
                  IMKitRouter.getArgumentFormMap<NIMConversationType>(
                      context, 'conversationType')!,
              chatTitle:
                  IMKitRouter.getArgumentFormMap<String>(context, 'chatTitle')!,
            ));

    XKitReporter().register(moduleName: 'ChatUIKit', moduleVersion: '10.0.0');

    // if (enableCallKit) {
    //   CallState.instance.registerEngineObserver();
    //   NECallKitUI.instance.enableFloatWindow(true);
    // }
  }

  // ///初始化呼叫组件,
  // /// 在IM登录后初始化调用
  // /// [appKey]      appKey
  // /// [accountId]     accountId
  // /// [extraConfig]  额外配置参数，包含 lckConfig 等
  // void setupCallKit(
  //     {required String appKey,
  //     required String accountId,
  //     NEExtraConfig? extraConfig}) {
  //   NECallKitUI.instance
  //       .setupEngine(appKey, accountId, extraConfig: extraConfig);
  //   IMKitConfigCenter.enableCallKit = true;
  // }
}
