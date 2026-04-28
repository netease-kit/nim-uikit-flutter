// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:netease_common_ui/widgets/search_page.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_chatkit/services/user_info/user_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../conversation_kit_client.dart';
import '../l10n/S.dart';

class JoinTeamPage extends StatefulWidget {
  const JoinTeamPage({Key? key}) : super(key: key);

  @override
  State<JoinTeamPage> createState() => _JoinTeamPageState();
}

class _JoinTeamPageState extends State<JoinTeamPage> {
  Future<NIMTeam?> searchTeamInfo(String teamId) async {
    if (!await haveConnectivity()) {
      return null;
    }
    return (await NimCore.instance.teamService.getTeamInfo(
      teamId,
      NIMTeamType.typeNormal,
    ))
        .data;
  }

  @override
  Widget build(BuildContext context) {
    return SearchPage(
      title: S.of(context).joinTeam,
      searchHint: S.of(context).joinTeamSearchHint,
      buildOnComplete: true,
      builder: (context, keyword) {
        if (keyword.isEmpty)
          return Container();
        else {
          return FutureBuilder<NIMTeam?>(
            future: searchTeamInfo(keyword),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.data == null) {
                  return Column(
                    children: [
                      const SizedBox(height: 68),
                      SvgPicture.asset(
                        'images/ic_search_empty.svg',
                        package: kPackage,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        S.of(context).joinTeamSearchEmptyTips,
                        style: TextStyle(
                          color: Color(0xffb3b7bc),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                } else {
                  final teamId = snapshot.data!.teamId;
                  Future.delayed(Duration(milliseconds: 200), () {
                    if (!mounted) return;
                    // 桌面/Web 端：先关闭当前弹框，再以新弹框展示群组详情，
                    // 避免弹框叠加。使用 rootNavigator 关闭 showDesktopDialog
                    // 创建的 Dialog，然后通过上层 Navigator 打开群组详情弹框
                    if (ChatKitUtils.isDesktopOrWeb) {
                      final rootNav =
                          Navigator.of(context, rootNavigator: true);
                      rootNav.pop();
                      // 使用 WidgetsBinding 确保在 pop 动画完成后再打开新弹框
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final ctx = rootNav.context;
                        goToTeamDetail(ctx, teamId);
                      });
                    } else {
                      goToTeamDetail(context, teamId);
                    }
                  });
                }
              }
              return Container();
            },
          );
        }
      },
    );
  }
}
