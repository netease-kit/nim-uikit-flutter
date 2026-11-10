// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:im_demo/l10n/S.dart';
import 'package:im_demo/src/mine/about.dart';
import 'package:im_demo/src/mine/setting/mine_setting.dart';
import 'package:netease_common_ui/duo/duo_drawer_navigation.dart';
import 'package:netease_common_ui/duo/duo_shell_controller.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/router/imkit_router_constants.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_core_v2/nim_core.dart';

class MinePage extends StatefulWidget {
  const MinePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  NIMUserInfo? _userInfo;

  IMLoginService _loginService = getIt<IMLoginService>();

  List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();

    //数据同步完成之后再请求更新信息

    _refreshUserInfo();

    _subs.addAll([
      NimCore.instance.loginService.onDataSync.listen((event) {
        if (event.type == NIMDataSyncType.nimDataSyncMain &&
            event.state == NIMDataSyncState.nimDataSyncStateCompleted) {
          _refreshUserInfo();
        }
      }),
      NimCore.instance.userService.onUserProfileChanged.listen((event) {
        for (var user in event) {
          if (user.accountId == _userInfo?.accountId) {
            _userInfo = user;
            setState(() {});
          }
        }
      })
    ]);
  }

  void _refreshUserInfo() {
    _loginService.getUserInfo().then((value) {
      setState(() {
        _userInfo = value;
      });
    });
  }

  @override
  void dispose() {
    _subs.length > 0 ? _subs.forEach((element) => element.cancel()) : null;
    _subs.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = DuoShellController.instance;
    final bool isDuoFolded = shell.enabled && !shell.dual;
    // 头像区和下方列表的箭头必须共用同一个右内边距，否则两处箭头会错位。
    // 折叠单屏的页面内容已经由首页壳层限制在右侧工具栏左侧（宽度 = 窗口 - 工具栏），
    // 这里使用列表常规的贴边留白（16）让箭头紧贴右侧工具栏；不能再额外加一个工具栏
    // 宽度，否则会二次内缩、在右侧留下过大空白。
    // 普通 iPhone、Android、桌面/Web 继续使用 36，保持原有布局。
    final double arrowRightInset = isDuoFolded ? 16 : 36;

    Widget buildArrow() => SvgPicture.asset(
          'assets/ic_right_arrow.svg',
          height: 16,
          width: 16,
        );

    var nick = _loginService.userInfo?.name?.trim().isNotEmpty == true
        ? _loginService.userInfo?.name?.trim()
        : null;
    final Widget page = Material(
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(
            height: 56,
          ),
          InkWell(
            onTap: () {
              pushDuoDrawerNamed(
                context,
                RouterConstants.PATH_MINE_INFO_PAGE,
              ).then((value) {
                setState(() {});
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                  ),
                  Avatar(
                    height: 60,
                    width: 60,
                    name: _loginService.userInfo?.name ??
                        _userInfo?.name ??
                        _userInfo?.accountId,
                    fontSize: 22,
                    avatar: _loginService.userInfo?.avatar ?? _userInfo?.avatar,
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          nick ?? _loginService.userInfo?.accountId ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 22,
                              color: CommonColors.color_333333,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          S.of(context).tabMineAccount(
                              _loginService.userInfo?.accountId ?? ''),
                          style: const TextStyle(
                              fontSize: 16, color: CommonColors.color_333333),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: arrowRightInset),
                    child: buildArrow(),
                  )
                ],
              ),
            ),
          ),
          const Divider(
            height: 6,
            thickness: 6,
            color: Color(0xffeff1f4),
          ),
          ...ListTile.divideTiles(context: context, tiles: [
            ListTile(
              contentPadding: EdgeInsets.only(
                left: 20,
                right: arrowRightInset,
              ),
              leading: SvgPicture.asset('assets/ic_collect.svg'),
              title: Text(S.of(context).mineCollect),
              trailing: buildArrow(),
              onTap: () {
                pushDuoDrawerNamed(
                  context,
                  RouterConstants.PATH_CHAT_COLLECTION_LIST_PAGE,
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.only(
                left: 20,
                right: arrowRightInset,
              ),
              leading: SvgPicture.asset('assets/ic_about.svg'),
              title: Text(S.of(context).mineAbout),
              trailing: buildArrow(),
              onTap: () {
                pushDuoDrawerPage(
                  context,
                  (context) => const AboutPage(),
                  routeKey: 'mine.about',
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.only(
                left: 20,
                right: arrowRightInset,
              ),
              leading: SvgPicture.asset('assets/ic_user_setting.svg'),
              title: Text(S.of(context).mineSetting),
              trailing: buildArrow(),
              onTap: () {
                pushDuoDrawerPage(
                  context,
                  (context) => const MineSettingPage(),
                  routeKey: 'mine.setting',
                );
              },
            ),
          ]).toList(),
        ],
      ),
    );
    // Duo 折叠/双屏下，首页/路由已经为右侧工具栏预留了宽度，但系统上报的右侧
    // 安全区（内屏摄像头/状态栏）比工具栏更宽。ListTile 内置的 SafeArea 会再按
    // 安全区内缩一次，让列表箭头整体左移、与头像箭头错位。
    // 这里仅在 Duo 路径去掉右侧安全区；普通 iPhone、Android、桌面/Web 行为不变。
    if (!shell.enabled) {
      return page;
    }
    return MediaQuery.removePadding(
      context: context,
      removeRight: true,
      child: page,
    );
  }
}
