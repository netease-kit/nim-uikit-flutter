// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:im_demo/generated/l10n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:im_demo/src/mine/about.dart';
import 'package:im_demo/src/mine/setting/mine_setting.dart';
import 'package:im_demo/src/mine/user_info_page.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';

class MinePage extends StatefulWidget {
  const MinePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  @override
  Widget build(BuildContext context) {
    LoginService _loginService = getIt<LoginService>();
    Widget arrow = SvgPicture.asset(
      'assets/ic_right_arrow.svg',
      height: 16,
      width: 16,
    );
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(
            height: 56,
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const UserInfoPage()))
                  .then((value) {
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
                    name: _loginService.userInfo?.nick,
                    fontSize: 22,
                    avatar: _loginService.userInfo?.avatar,
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
                          _loginService.userInfo?.nick ?? '',
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
                          S.of(context).tab_mine_account(
                              _loginService.userInfo?.userId ?? ''),
                          style: const TextStyle(
                              fontSize: 16, color: CommonColors.color_333333),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 36.0),
                    child: arrow,
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
            Visibility(
              visible: false,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: SvgPicture.asset('assets/ic_collect.svg'),
                title: Text(S.of(context).mine_collect),
                trailing: arrow,
                onTap: () {
                  // todo collect
                },
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: SvgPicture.asset('assets/ic_about.svg'),
              title: Text(S.of(context).mine_about),
              trailing: arrow,
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const AboutPage()));
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: SvgPicture.asset('assets/ic_user_setting.svg'),
              title: Text(S.of(context).mine_setting),
              trailing: arrow,
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MineSettingPage()));
              },
            ),
          ]).toList(),
        ],
      ),
    );
  }
}
