// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:im_common_ui/router/imkit_router.dart';
import 'package:im_common_ui/router/imkit_router_constants.dart';
import 'package:im_common_ui/utils/color_utils.dart';
import 'package:corekit_im/model/contact_info.dart';
import 'package:flutter/material.dart';

import 'generated/l10n.dart';
import 'page/contact_kit_black_list_page.dart';
import 'page/contact_kit_contact_selector_page.dart';
import 'page/contact_kit_detail_page.dart';
import 'page/contact_kit_system_notify_message_page.dart';
import 'page/contact_kit_team_list_page.dart';
import 'page/contact_page.dart';
import 'widgets/contact_kit_contact_list_view.dart';

typedef TopEntranceClick = bool Function(int position, TopListItem data);
typedef ContactItemClick = bool Function(int position, ContactInfo data);
typedef ContactItemSelect = void Function(bool select, ContactInfo data);

typedef TopListItemBuilder = Widget? Function(TopListItem item);
typedef ContactItemBuilder = Widget Function(ContactInfo data);

class ContactTitleBarConfig {
  /// 是否展示 Title Bar
  final bool showTitleBar;

  /// 是否展示 Title Bar 的最右侧图标
  final bool showTitleBarRightIcon;

  /// 是否展示 Title Bar 的次最右侧图标
  final bool showTitleBarRight2Icon;

  /// Title Bar 最右侧图标
  final Widget? titleBarRightIcon;

  /// Title Bar 次最右侧图标
  final Widget? titleBarRight2Icon;

  /// Title Bar 标题文案
  final String? title;

  /// Title Bar 标题居中
  final bool centerTitle;

  /// Title Bar 标题颜色值
  final Color titleColor;

  const ContactTitleBarConfig(
      {this.showTitleBar = true,
      this.showTitleBarRightIcon = true,
      this.showTitleBarRight2Icon = true,
      this.titleBarRightIcon,
      this.titleBarRight2Icon,
      this.title,
      this.centerTitle = false,
      this.titleColor = CommonColors.color_333333});
}

class ContactListConfig {
  final Color nameTextColor;
  final double nameTextSize;
  final Color indexTextColor;
  final double indexTextSize;
  final bool? showIndexBar;
  final bool? showSelector;

  /// 头像的圆角，0 代表方形，18 为圆形。
  final double avatarCornerRadius;
  final Color divideLineColor;

  const ContactListConfig(
      {this.nameTextColor = CommonColors.color_333333,
      this.nameTextSize = 14,
      this.indexTextColor = CommonColors.color_b3b7bc,
      this.indexTextSize = 14,
      this.showIndexBar,
      this.showSelector,
      this.avatarCornerRadius = 18,
      this.divideLineColor = CommonColors.color_dbe0e8});
}

class ContactUIConfig {
  /// 通讯录标题栏配置信息
  final ContactTitleBarConfig contactTitleBarConfig;

  /// 通讯录列表配置
  final ContactListConfig contactListConfig;

  /// 是否在通讯录界面显示相关功能模块
  final bool showHeader;

  /// 相关功能模块的数据，如果不为空，则覆盖已有数据
  final List<TopListItem>? headerData;

  /// 自定义相关功能模块组件构建，会替换掉默认的Item
  final TopListItemBuilder? topListItemBuilder;

  /// 相关功能模块的点击
  final TopEntranceClick? topEntranceClick;

  /// 自定义通讯录好友组件构建，会替换掉默认的Item
  final ContactItemBuilder? contactItemBuilder;

  /// 通讯录好友的点击
  final ContactItemClick? contactItemClick;

  /// 通讯录好友的选择（通讯录列表 isCanSelectMemberItem 字段为true时有效，默认false）
  final ContactItemSelect? contactItemSelect;

  const ContactUIConfig(
      {this.contactTitleBarConfig = const ContactTitleBarConfig(),
      this.contactListConfig = const ContactListConfig(),
      this.showHeader = true,
      this.headerData,
      this.topListItemBuilder,
      this.topEntranceClick,
      this.contactItemClick,
      this.contactItemSelect,
      this.contactItemBuilder});
}

class ContactKitClient {
  ContactUIConfig contactUIConfig = ContactUIConfig();

  ContactKitClient._();

  static final ContactKitClient instance = ContactKitClient._();

  static get delegate {
    return S.delegate;
  }

  static init() {
    IMKitRouter.instance.registerRouter(
        RouterConstants.PATH_CONTACT_PAGE, (context) => ContactPage());

    IMKitRouter.instance.registerRouter(
        RouterConstants.PATH_CONTACT_SELECTOR_PAGE,
        (context) => ContactKitSelectorPage(
              mostSelectedCount:
                  IMKitRouter.getArgumentFormMap<int>(context, 'mostCount'),
              filterUsers: IMKitRouter.getArgumentFormMap<List<String>>(
                  context, 'filterUser'),
              returnContact: IMKitRouter.getArgumentFormMap<bool>(
                  context, 'returnContact'),
            ));

    IMKitRouter.instance.registerRouter(
      RouterConstants.PATH_USER_INFO_PAGE,
      (context) => ContactKitDetailPage(
        accId: IMKitRouter.getArgumentFormMap<String>(context, 'accId')!,
      ),
    );

    IMKitRouter.instance.registerRouter(
      RouterConstants.PATH_MY_BLACK_PAGE,
      (context) => ContactKitBlackListPage(),
    );

    IMKitRouter.instance.registerRouter(
        RouterConstants.PATH_MY_TEAM_PAGE,
        (context) => ContactKitTeamListPage(
              selectorModel: IMKitRouter.getArgumentFormMap<bool>(
                  context, 'selectorModel'),
            ));

    IMKitRouter.instance.registerRouter(
      RouterConstants.PATH_MY_NOTIFICATION_PAGE,
      (context) => ContactKitSystemNotifyMessagePage(),
    );
  }
}
