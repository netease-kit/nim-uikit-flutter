// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_corekit/report/xkit_report.dart';
import 'package:netease_corekit_im/im_kit_client.dart';
import 'package:netease_corekit_im/router/imkit_router.dart';
import 'package:netease_corekit_im/router/imkit_router_constants.dart';
import 'package:nim_conversationkit/conversationkit_client_repo.dart';
import 'package:nim_conversationkit/model/conversation_info.dart';
import 'package:nim_conversationkit_ui/service/ait/ait_server.dart';

import 'l10n/S.dart';
import 'page/add_friend_page.dart';
import 'page/conversation_page.dart';

typedef ConversationItemClick = bool Function(
    ConversationInfo data, int position);
typedef ConversationItemLongClick = bool Function(
    ConversationInfo data, int position);
typedef ConversationAvatarClick = bool Function(
    ConversationInfo data, int position);
typedef ConversationAvatarLongClick = bool Function(
    ConversationInfo data, int position);
typedef ConversationItemBuilder = Widget Function(
    ConversationInfo data, int position);

typedef ConversationLastMessageContentBuilder = String? Function(
    BuildContext context, ConversationInfo data);

const String kPackage = 'nim_conversationkit_ui';

class ConversationTitleBarConfig {
  /// 是否展示 Title Bar
  final bool showTitleBar;

  /// 是否展示 Title Bar 左侧图标
  final bool showTitleBarLeftIcon;

  /// 是否展示 Title Bar 最右侧图标
  final bool showTitleBarRightIcon;

  /// 是否展示 Title Bar 次最右侧图标
  final bool showTitleBarRight2Icon;

  /// 是否将 Title 居中展示
  final bool centerTitle;

  /// Title Bar 左侧图标
  final Widget? titleBarLeftIcon;

  /// Title Bar 最右侧图标
  final Widget? titleBarRightIcon;

  /// Title Bar 次最右侧图标
  final Widget? titleBarRight2Icon;

  /// Title Bar 标题文案
  final String? titleBarTitle;

  /// Title Bar 标题颜色值
  final Color titleBarTitleColor;

  const ConversationTitleBarConfig(
      {this.showTitleBar = true,
      this.showTitleBarLeftIcon = true,
      this.showTitleBarRightIcon = true,
      this.showTitleBarRight2Icon = true,
      this.centerTitle = false,
      this.titleBarLeftIcon,
      this.titleBarRightIcon,
      this.titleBarRight2Icon,
      this.titleBarTitle,
      this.titleBarTitleColor = CommonColors.color_333333});
}

class ConversationItemConfig {
  /// 会话名称的字体颜色
  final Color itemTitleColor;

  /// 会话名称的字体大小
  final double itemTitleSize;

  /// 会话消息缩略内容的字体颜色
  final Color itemContentColor;

  /// 会话消息缩略内容的字体大小
  final double itemContentSize;

  /// 会话时间的字体颜色
  final Color itemDateColor;

  /// 会话@标记字体颜色
  final Color itemAitTextColor;

  /// 会话时间的字体大小
  final double itemDateSize;

  /// 会话列表中会话头像的圆角，0 代表方形，21 为圆形。
  final double avatarCornerRadius;

  /// 会话列表点击事件，包括单击和长按事件
  final ConversationItemClick? itemClick;
  final ConversationItemLongClick? itemLongClick;
  final ConversationAvatarClick? avatarClick;
  final ConversationAvatarLongClick? avatarLongClick;

  /// 会话列表排序自定义规则
  final Comparator<ConversationInfo>? conversationComparator;

  /// 自定义会话item组件，会替换掉默认的item
  final ConversationItemBuilder? customItemBuilder;

  /// 自定义会话最后一条消息内容
  final ConversationLastMessageContentBuilder? lastMessageContentBuilder;

  ///是否在删除会话的时候同步删除消息
  final bool clearMessageWhenDeleteSession;

  const ConversationItemConfig(
      {this.itemTitleColor = CommonColors.color_333333,
      this.itemTitleSize = 16,
      this.itemContentColor = CommonColors.color_999999,
      this.itemContentSize = 13,
      this.itemDateColor = CommonColors.color_cccccc,
      this.itemAitTextColor = Colors.red,
      this.itemDateSize = 12,
      this.avatarCornerRadius = 21,
      this.itemClick,
      this.itemLongClick,
      this.avatarClick,
      this.avatarLongClick,
      this.conversationComparator,
      this.customItemBuilder,
      this.lastMessageContentBuilder,
      this.clearMessageWhenDeleteSession = false});
}

class ConversationUIConfig {
  final ConversationTitleBarConfig titleBarConfig;
  final ConversationItemConfig itemConfig;

  const ConversationUIConfig(
      {this.titleBarConfig = const ConversationTitleBarConfig(),
      this.itemConfig = const ConversationItemConfig()});
}

class ConversationKitClient {
  ConversationUIConfig conversationUIConfig = ConversationUIConfig();

  ConversationKitClient._();

  static final ConversationKitClient instance = ConversationKitClient._();

  static get delegate {
    return S.delegate;
  }

  /// 初始化
  static init() {
    ConversationKitClientRepo.init();
    IMKitRouter.instance.registerRouter(
      RouterConstants.PATH_CONVERSATION_PAGE,
      (context) => ConversationPage(
        config: IMKitRouter.getArgumentFormMap<ConversationUIConfig>(
            context, 'config'),
        onUnreadCountChanged: IMKitRouter.getArgumentFormMap<ValueChanged<int>>(
            context, 'onUnreadCountChanged'),
      ),
    );
    IMKitRouter.instance.registerRouter(
      RouterConstants.PATH_ADD_FRIEND_PAGE,
      (context) => const AddFriendPage(),
    );

    XKitReporter()
        .register(moduleName: 'ConversationUIKit', moduleVersion: '9.7.3');

    if (IMKitClient.enableAit) {
      //初始化@消息服务
      AitServer.instance.initListener();
    }
  }
}
