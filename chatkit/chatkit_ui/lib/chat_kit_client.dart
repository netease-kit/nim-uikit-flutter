// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:core';

import 'package:chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_pop_actions.dart';
import 'package:corekit_im/services/message/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_common_ui/router/imkit_router.dart';
import 'package:im_common_ui/router/imkit_router_constants.dart';
import 'package:nim_core/nim_core.dart';

import 'chat_page.dart';
import 'chat_search_page.dart';
import 'generated/l10n.dart';
import 'view/chat_kit_message_list/item/chat_kit_message_item.dart';
import 'view/input/actions.dart';

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

  ///文本消息字体颜色
  Color? messageTextColor;

  ///文本消息字体大小
  double? messageTextSize;

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

  ///自定义消息构建
  ChatKitMessageBuilder? messageBuilder;

  MessageClickListener? messageClickListener;

  ChatUIConfig(
      {this.showTeamMessageStatus,
      this.receiveMessageBg,
      this.selfMessageBg,
      this.showP2pMessageStatus,
      this.signalBgColor,
      this.timeTextColor,
      this.timeTextSize,
      this.messageTextSize,
      this.messageTextColor,
      this.userNickTextSize,
      this.userNickColor,
      this.avatarCornerRadius,
      this.enableMessageLongPress = true,
      this.popMenuConfig,
      this.keepDefaultMoreAction = true,
      this.moreActions,
      this.messageBuilder,
      this.messageClickListener});
}

///消息点击回调
class MessageClickListener {
  PopMenuAction? customPopActions;

  bool Function(ChatMessage message)? onMessageItemClick;

  bool Function(ChatMessage message)? onMessageItemLongClick;

  bool Function(String? userID, {bool isSelf})? onTapAvatar;

  MessageClickListener(
      {this.onMessageItemLongClick,
      this.onMessageItemClick,
      this.customPopActions,
      this.onTapAvatar});
}

///长按弹框开关配置
class PopMenuConfig {
  ///转发
  bool? enableForward;

  ///复制
  bool? enableCopy;

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
      this.enableRevoke});
}

///全局配置，全局生效，优先级低于参数配置
class ChatKitClient {
  ChatUIConfig chatUIConfig = ChatUIConfig();

  ChatKitClient._();

  static final ChatKitClient instance = ChatKitClient._();

  // 注入听筒扬声器转换方法
  void Function(bool isSpeakerphoneOn) setSpeakerphoneOnAndroid =
      (bool isSpeakerphoneOn) {
    MethodChannel('audioChannel').invokeMethod(
        'setSpeakerphoneOn', {'isSpeakerphoneOn': isSpeakerphoneOn});
  };

  static get delegate {
    return S.delegate;
  }

  static init() {
    IMKitRouter.instance.registerRouter(
        RouterConstants.PATH_CHAT_PAGE,
        (context) => ChatPage(
              sessionId:
                  IMKitRouter.getArgumentFormMap<String>(context, 'sessionId')!,
              sessionType: IMKitRouter.getArgumentFormMap<NIMSessionType>(
                  context, 'sessionType')!,
              anchor:
                  IMKitRouter.getArgumentFormMap<NIMMessage>(context, 'anchor'),
            ));
    IMKitRouter.instance.registerRouter(
        RouterConstants.PATH_CHAT_SEARCH_PAGE,
        (context) => ChatSearchPage(
            IMKitRouter.getArgumentFormMap<String>(context, 'teamId')!));
  }
}
