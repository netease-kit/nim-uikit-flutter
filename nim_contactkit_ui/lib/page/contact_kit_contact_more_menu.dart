// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_chatkit/router/imkit_router.dart';
import 'package:nim_chatkit/router/imkit_router_constants.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';

import '../l10n/S.dart';
import 'contact_kit_user_ai_bot_scan_page.dart';

class ContactKitContactMoreMenu extends StatelessWidget {
  final bool isDesktopMode;

  const ContactKitContactMoreMenu({
    Key? key,
    this.isDesktopMode = false,
  }) : super(key: key);

  Future<void> _onSelected(BuildContext context, String value) async {
    switch (value) {
      case 'add_friend':
        if (isDesktopMode) {
          final builder =
              IMKitRouter.instance.routes[RouterConstants.PATH_ADD_FRIEND_PAGE];
          if (builder != null) {
            await showDesktopDialog(context, builder(context));
          } else {
            await goAddFriendPage(context);
          }
        } else {
          await goAddFriendPage(context);
        }
        break;
      case 'scan_robot':
        if (isDesktopMode) {
          await showDesktopDialog(context, const ContactKitUserAIBotScanPage());
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ContactKitUserAIBotScanPage(),
            ),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'add_friend',
          child: Text(S.of(context).contactAddFriend),
        ),
        PopupMenuItem(
          value: 'scan_robot',
          child: Text(S.of(context).contactRobotScan),
        ),
      ],
      icon: SvgPicture.asset(
        'images/ic_more.svg',
        width: 26,
        height: 26,
        package: 'nim_contactkit_ui',
      ),
      offset: const Offset(0, 50),
      onSelected: (value) => _onSelected(context, value),
    );
  }
}
