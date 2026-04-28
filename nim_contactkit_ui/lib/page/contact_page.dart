// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_contactkit_ui/contact_kit_client.dart';
import 'package:nim_contactkit_ui/page/contact_kit_contact_page.dart';

import '../l10n/S.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({
    Key? key,
    this.config,
    this.onDesktopCategorySelect,
    this.desktopSelectedCategoryIndex,
  }) : super(key: key);

  final ContactUIConfig? config;

  /// 桌面端通讯录分类选中回调
  final DesktopContactCategorySelect? onDesktopCategorySelect;

  /// 桌面端当前选中的分类索引
  final int? desktopSelectedCategoryIndex;

  @override
  State<StatefulWidget> createState() => _ContactState();
}

class _ContactState extends State<ContactPage> {
  ContactUIConfig get uiConfig =>
      widget.config ?? ContactKitClient.instance.contactUIConfig;

  ContactTitleBarConfig get _titleBarConfig => uiConfig.contactTitleBarConfig;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ChatKitUtils.isDesktopOrWeb;

    if (isDesktop) {
      // 桌面端：不使用 AppBar，直接嵌入到 DesktopShell 中
      return Scaffold(
        backgroundColor: Colors.white,
        body: ContactKitContactPage(
          config: uiConfig,
          onDesktopCategorySelect: widget.onDesktopCategorySelect,
          desktopSelectedCategoryIndex: widget.desktopSelectedCategoryIndex,
        ),
      );
    }

    // 移动端：使用标准 AppBar
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _titleBarConfig.showTitleBar
          ? AppBar(
              title: Text(
                _titleBarConfig.title ?? S.of(context).contactTitle,
                style: TextStyle(
                  fontSize: 20,
                  color: _titleBarConfig.titleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: _titleBarConfig.centerTitle,
              actions: [
                if (_titleBarConfig.showTitleBarRight2Icon)
                  _titleBarConfig.titleBarRight2Icon ??
                      IconButton(
                        onPressed: () {
                          goGlobalSearchPage(context);
                        },
                        icon: SvgPicture.asset(
                          'images/ic_search.svg',
                          width: 26,
                          height: 26,
                          package: kPackage,
                        ),
                      ),
                if (_titleBarConfig.showTitleBarRightIcon)
                  _titleBarConfig.titleBarRightIcon ??
                      IconButton(
                        onPressed: () {
                          goAddFriendPage(context);
                        },
                        icon: SvgPicture.asset(
                          'images/ic_more.svg',
                          width: 26,
                          height: 26,
                          package: kPackage,
                        ),
                      ),
              ],
              elevation: 0,
            )
          : null,
      body: ContactKitContactPage(
        config: uiConfig,
      ),
    );
  }
}
