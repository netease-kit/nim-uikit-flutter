// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/router/imkit_router.dart';
import 'package:nim_chatkit/router/imkit_router_constants.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/team/team_provider.dart';
import 'package:nim_conversationkit_ui/page/add_friend_page.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../conversation_kit_client.dart';
import '../l10n/S.dart';
import '../page/join_team_page.dart';

const String keyAddFriend = 'add_friend';
const String keyCreateGroupTeam = 'create_group_team';
const String keyCreateAdvancedTeam = 'create_advanced_team';
const String keyJoinTeam = 'join_team';
const String keyScanRobot = 'scan_robot';

class ConversationPopMenuButton extends StatelessWidget {
  const ConversationPopMenuButton({
    Key? key,
    this.isDesktopMode = false,
  }) : super(key: key);

  final bool isDesktopMode;

  Future<void> _openNamedPage(BuildContext context, String path) async {
    final builder = IMKitRouter.instance.routes[path];
    if (isDesktopMode) {
      if (builder != null) {
        await showDesktopDialog(context, builder(context));
      }
      return;
    }
    await Navigator.pushNamed(context, path);
  }

  Future<void> _onMenuSelected(BuildContext context, String value) async {
    switch (value) {
      case keyAddFriend:
        if (isDesktopMode) {
          await showDesktopDialog(context, const AddFriendPage());
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddFriendPage()),
          );
        }
        break;
      case keyJoinTeam:
        if (isDesktopMode) {
          await showDesktopDialog(context, const JoinTeamPage());
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JoinTeamPage()),
          );
        }
        break;
      case keyScanRobot:
        if (!isDesktopMode) {
          await _openNamedPage(
              context, RouterConstants.PATH_MY_ROBOT_SCAN_PAGE);
        }
        break;
      case keyCreateGroupTeam:
      case keyCreateAdvancedTeam:
        if (!(await haveConnectivity())) {
          return;
        }
        goToContactSelector(
          context,
          mostCount: TeamProvider.createTeamInviteLimit,
          returnContact: true,
          includeAIUser: true,
          isDialog: ChatKitUtils.isDesktopOrWeb,
        ).then((contacts) {
          if (contacts is List<ContactInfo> && contacts.isNotEmpty) {
            final selectName =
                contacts.map((e) => e.user.name ?? e.user.accountId!).toList();
            getIt<TeamProvider>()
                .createTeam(
              contacts.map((e) => e.user.accountId!).toList(),
              selectNames: selectName,
              isGroup: value == keyCreateGroupTeam,
            )
                .then((teamResult) {
              if (teamResult != null && teamResult.team != null) {
                if (value == keyCreateAdvancedTeam) {
                  final map = <String, String>{
                    RouterConstants.keyTeamCreatedTip:
                        S.of(context).createAdvancedTeamSuccess,
                  };
                  ConversationIdUtil()
                      .teamConversationId(teamResult.team!.teamId)
                      .then((conversationId) {
                    ChatMessageRepo.insertLocalTipsMessageWithExt(
                      conversationId.data!,
                      '',
                      map,
                      time: teamResult.team!.createTime - 100,
                    );
                  });
                }
                Future.delayed(const Duration(milliseconds: 200), () {
                  goToTeamChat(context, teamResult.team!.teamId);
                });
              }
            });
          }
        });
        break;
    }
  }

  List<Map<String, String>> _conversationMenu(BuildContext context) {
    return [
      {
        'image': 'images/icon_add_friend.svg',
        'name': S.of(context).addFriend,
        'value': keyAddFriend,
      },
      if (IMKitConfigCenter.enableTeam) ...[
        {
          'image': 'images/icon_join_team.svg',
          'name': S.of(context).joinTeam,
          'value': keyJoinTeam,
        },
        {
          'image': 'images/icon_create_group_team.svg',
          'name': S.of(context).createGroupTeam,
          'value': keyCreateGroupTeam,
        },
        {
          'image': 'images/icon_create_advanced_team.svg',
          'name': S.of(context).createAdvancedTeam,
          'value': keyCreateAdvancedTeam,
        },
      ],
      if (IMKitClient.enableRobot && !isDesktopMode) ...[
        {
          'image': 'images/ic_scan.svg',
          'name': S.of(context).scanRobot,
          'value': keyScanRobot,
        },
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = _conversationMenu(context);
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) {
        return menuItems
            .map<PopupMenuItem<String>>(
              (item) => PopupMenuItem<String>(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                value: item['value']!,
                child: Row(
                  children: [
                    SvgPicture.asset(
                      item['image']!,
                      package: kPackage,
                      width: 14,
                      height: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['name']!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CommonColors.color_333333,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList();
      },
      icon: SvgPicture.asset(
        'images/ic_more.svg',
        width: 26,
        height: 26,
        package: kPackage,
      ),
      offset: const Offset(0, 40),
      onSelected: (value) => _onMenuSelected(context, value),
    );
  }
}
