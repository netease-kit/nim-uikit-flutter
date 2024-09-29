// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/background.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:netease_common_ui/widgets/update_text_info_page.dart';
import 'package:netease_corekit_im/model/contact_info.dart';
import 'package:netease_corekit_im/model/team_models.dart';
import 'package:netease_corekit_im/router/imkit_router_constants.dart';
import 'package:netease_corekit_im/router/imkit_router_factory.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:netease_corekit_im/services/message/nim_chat_cache.dart';
import 'package:netease_corekit_im/services/team/team_provider.dart';
import 'package:nim_core/nim_core.dart';
import 'package:nim_teamkit_ui/l10n/S.dart';
import 'package:nim_teamkit_ui/view/pages/team_kit_manage_page.dart';
import 'package:nim_teamkit_ui/view/pages/team_kit_member_list_page.dart';
import 'package:nim_teamkit_ui/view/pages/team_kit_team_info_page.dart';
import 'package:provider/provider.dart';

import '../../team_kit_client.dart';
import '../../view_model/team_setting_view_model.dart';

class TeamSettingPage extends StatefulWidget {
  const TeamSettingPage(this.teamId, {Key? key}) : super(key: key);

  final String teamId;

  @override
  State<StatefulWidget> createState() => _TeamSettingPageState();
}

class _TeamSettingPageState extends State<TeamSettingPage> {
  TextStyle style =
      const TextStyle(color: CommonColors.color_333333, fontSize: 16);

  //是否有权限修改群信息
  bool _hasPrivilegeToModify(TeamWithMember teamWithMember) {
    var team = teamWithMember.team;
    var teamMember = teamWithMember.teamMember;
    return (team.teamUpdateMode == NIMTeamUpdateModeEnum.all) ||
        (team.teamUpdateMode == NIMTeamUpdateModeEnum.manager &&
            (teamMember?.type == TeamMemberType.manager ||
                teamMember?.type == TeamMemberType.owner)) ||
        getIt<TeamProvider>().isGroupTeam(team);
  }

  Widget _member(BuildContext context, TeamWithMember teamWithMember,
      List<UserInfoWithTeam>? list) {
    var team = teamWithMember.team;

    bool hasPrivilegeToInvite = NIMChatCache.instance.hasPrivilegeToInvite();

    int _getListCount() {
      var count = list?.length ?? 0;
      if (hasPrivilegeToInvite)
        return count + 1;
      else
        return count;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: GestureDetector(
            onTap: () {
              bool hasPrivilegeToUpdateInfo =
                  _hasPrivilegeToModify(teamWithMember);
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return TeamKitTeamInfoPage(
                  team: team,
                  hasPrivilegeToUpdateInfo: hasPrivilegeToUpdateInfo,
                );
              }));
            },
            child: Row(
              children: [
                Avatar(
                  avatar: team.icon,
                  name: team.name,
                ),
                const SizedBox(
                  width: 11,
                ),
                Expanded(
                  child: Text(
                    team.name!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, color: CommonColors.color_333333),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_right_outlined,
                  color: CommonColors.color_999999,
                ),
              ],
            ),
          ),
        ),
        const Divider(
          height: 1,
          color: CommonColors.color_f5f8fc,
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => TeamKitMemberListPage(tId: team.id!)));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Text(
                  getIt<TeamProvider>().isGroupTeam(team)
                      ? S.of(context).teamGroupMemberTitle
                      : S.of(context).teamMemberTitle,
                  style: style,
                ),
                Expanded(
                    child: Container(
                        alignment: Alignment.centerRight,
                        child: Text(
                          team.memberCount.toString(),
                          style: const TextStyle(
                              fontSize: 16, color: CommonColors.color_999999),
                        ))),
                const Icon(
                  Icons.keyboard_arrow_right_outlined,
                  color: CommonColors.color_999999,
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          height: 32 + 16,
          child: Stack(
            children: [
              ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _getListCount(),
                  itemBuilder: (BuildContext context, int index) {
                    if (hasPrivilegeToInvite && index == 0) {
                      return Container(
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 32,
                          height: 32,
                        ),
                      );
                    } else {
                      var info =
                          list?[hasPrivilegeToInvite ? index - 1 : index];
                      var userInfo = info?.userInfo;
                      return userInfo != null
                          ? Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () {
                                  if (userInfo.userId ==
                                      getIt<LoginService>().userInfo?.userId!) {
                                    gotoMineInfoPage(context);
                                  } else {
                                    goToContactDetail(
                                        context, userInfo.userId!);
                                  }
                                },
                                child: Avatar(
                                  avatar: info?.getAvatar(),
                                  name: info?.getName(
                                      needAlias: false, needTeamNick: false),
                                  height: 32,
                                  width: 32,
                                ),
                              ),
                            )
                          : Container();
                    }
                  }),
              if (hasPrivilegeToInvite)
                Container(
                  padding: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(color: '#FFFFFF'.toColor()),
                  child: GestureDetector(
                    onTap: () {
                      goToContactSelector(context,
                              filter: list
                                  ?.where((element) => element.userInfo != null)
                                  .map((e) => e.userInfo!.userId!)
                                  .toList(),
                              mostCount: list == null
                                  ? team.memberLimit - 1
                                  : team.memberLimit - list.length,
                              returnContact: true)
                          .then((contacts) {
                        if (contacts is List<ContactInfo> &&
                            contacts.isNotEmpty) {
                          if (NIMChatCache.instance.hasPrivilegeToInvite()) {
                            context
                                .read<TeamSettingViewModel>()
                                .addMembers(
                                    team.id!,
                                    contacts
                                        .map((e) => e.user.userId!)
                                        .toList())
                                .then((value) {
                              if (value.isSuccess != true) {
                                Fluttertoast.showToast(
                                    msg: S.of(context).teamSettingFailed);
                              }
                            });
                          } else {
                            Fluttertoast.showToast(
                                msg: S.of(context).teamNoOperatePermission);
                          }
                        }
                      });
                    },
                    child: SvgPicture.asset(
                      'images/ic_member_add.svg',
                      package: kPackage,
                      height: 32,
                      width: 32,
                    ),
                  ),
                ),
            ],
          ),
        )
      ],
    );
  }

  Widget _setting(BuildContext context, TeamWithMember teamMember) {
    return Column(
      children: ListTile.divideTiles(context: context, tiles: [
        ListTile(
          title: Text(
            S.of(context).teamMark,
            style: style,
          ),
          trailing: const Icon(Icons.keyboard_arrow_right_outlined),
          onTap: () {
            Navigator.pushNamed(context, RouterConstants.PATH_CHAT_PIN_PAGE,
                arguments: {
                  'sessionId': widget.teamId,
                  'sessionType': NIMSessionType.team,
                  'chatTitle': teamMember.team.name ?? '',
                });
          },
        ),
        ListTile(
          title: Text(
            S.of(context).teamHistory,
            style: style,
          ),
          trailing: const Icon(Icons.keyboard_arrow_right_outlined),
          onTap: () {
            Navigator.pushNamed(context, RouterConstants.PATH_CHAT_SEARCH_PAGE,
                arguments: {'teamId': widget.teamId});
          },
        ),
        if (getIt<TeamProvider>().isGroupTeam(teamMember.team)) ...[
          ListTile(
            title: Text(
              S.of(context).teamMessageTip,
              style: style,
            ),
            trailing: CupertinoSwitch(
              activeColor: CommonColors.color_337eff,
              onChanged: (bool value) {
                context
                    .read<TeamSettingViewModel>()
                    .muteTeam(teamMember.team.id!, !value);
              },
              value: context.read<TeamSettingViewModel>().messageTip,
            ),
          ),
          ListTile(
            title: Text(
              S.of(context).teamSessionPin,
              style: style,
            ),
            trailing: CupertinoSwitch(
              activeColor: CommonColors.color_337eff,
              onChanged: (bool value) {
                context
                    .read<TeamSettingViewModel>()
                    .configStick(teamMember.team.id!, value);
              },
              value: context.read<TeamSettingViewModel>().isStick,
            ),
          )
        ],
        if (!getIt<TeamProvider>().isGroupTeam(teamMember.team)) ...[
          ListTile(
            title: Text(
              S.of(context).teamMessageTip,
              style: style,
            ),
            trailing: CupertinoSwitch(
              activeColor: CommonColors.color_337eff,
              onChanged: (bool value) {
                context
                    .read<TeamSettingViewModel>()
                    .muteTeam(teamMember.team.id!, !value);
              },
              value: context.read<TeamSettingViewModel>().messageTip,
            ),
          ),
          ListTile(
            title: Text(
              S.of(context).teamSessionPin,
              style: style,
            ),
            trailing: CupertinoSwitch(
              activeColor: CommonColors.color_337eff,
              onChanged: (bool value) {
                context
                    .read<TeamSettingViewModel>()
                    .configStick(teamMember.team.id!, value);
              },
              value: context.read<TeamSettingViewModel>().isStick,
            ),
          ),
          ListTile(
            title: Text(
              S.of(context).teamMyNicknameTitle,
              style: style,
            ),
            trailing: const Icon(Icons.keyboard_arrow_right_outlined),
            onTap: () {
              var teamNick =
                  context.read<TeamSettingViewModel>().myTeamNickName;
              Future<bool> _updateNick(nickname) async {
                var result = await context
                    .read<TeamSettingViewModel>()
                    .updateNickname(
                        teamMember.team.id!, (nickname as String).trim());
                if (!result) {
                  Fluttertoast.showToast(msg: S.of(context).teamSettingFailed);
                }
                return result;
              }

              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UpdateTextInfoPage(
                            title: S.of(context).teamMyNicknameTitle,
                            content: teamNick,
                            maxLength: 30,
                            privilege: true,
                            onSave: _updateNick,
                            leading: Text(
                              S.of(context).teamCancel,
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: CommonColors.color_666666),
                            ),
                            sureStr: S.of(context).teamSave,
                          )));
            },
          ),
        ]
      ]).toList(),
    );
  }

  Widget _teamManage(BuildContext context, TeamWithMember teamWithMember) {
    return Column(
      children: ListTile.divideTiles(context: context, tiles: [
        Visibility(
          visible: teamWithMember.teamMember?.type == TeamMemberType.owner,
          child: ListTile(
            title: Text(
              S.of(context).teamMute,
              style: style,
            ),
            trailing: CupertinoSwitch(
              activeColor: CommonColors.color_337eff,
              onChanged: (bool value) {
                context
                    .read<TeamSettingViewModel>()
                    .muteTeamAllMember(teamWithMember.team.id!, value);
              },
              value: context.read<TeamSettingViewModel>().muteAllMember,
            ),
          ),
        ),
        if (!getIt<TeamProvider>().isGroupTeam(teamWithMember.team) &&
            (NIMChatCache.instance.myTeamRole() == TeamMemberType.owner ||
                NIMChatCache.instance.myTeamRole() == TeamMemberType.manager))
          ListTile(
            title: Text(
              S.of(context).teamManage,
              style: style,
            ),
            trailing: const Icon(Icons.keyboard_arrow_right_outlined),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return TeamKitManagerPage(
                  team: teamWithMember.team,
                );
              }));
            },
          ),
      ]).toList(),
    );
  }

  Widget _actionButton(BuildContext context, NIMTeam team, bool owner) {
    return InkWell(
      onTap: () {
        String title = "";
        String content = "";
        int action = 0; // 1:quit 2:dismiss
        if (getIt<TeamProvider>().isGroupTeam(team)) {
          title = S.of(context).teamGroupQuit;
          content = S.of(context).teamQuitGroupTeamQuery;
          action = 1;
        } else if (!getIt<TeamProvider>().isGroupTeam(team)) {
          title = owner
              ? S.of(context).teamAdvancedDismiss
              : S.of(context).teamAdvancedQuit;
          content = owner
              ? S.of(context).teamDismissAdvancedTeamQuery
              : S.of(context).teamQuitAdvancedTeamQuery;
          action = owner ? 2 : 1;
        }

        showCommonDialog(
                context: context,
                title: title,
                content: content,
                positiveContent: S.of(context).teamConfirm,
                navigateContent: S.of(context).teamCancel)
            .then((value) {
          if (value == true) {
            if (action == 1) {
              context
                  .read<TeamSettingViewModel>()
                  .quitTeam(widget.teamId)
                  .then((value) {
                if (value) {
                  //退群成功，清理置顶和通知配置
                  context
                      .read<TeamSettingViewModel>()
                      .muteTeam(widget.teamId, true);
                  context
                      .read<TeamSettingViewModel>()
                      .configStick(widget.teamId, false);
                  Navigator.pop(context, true);
                }
              });
            } else if (action == 2) {
              context
                  .read<TeamSettingViewModel>()
                  .dismissTeam(widget.teamId)
                  .then((value) {
                if (value) {
                  Navigator.pop(context, true);
                }
              });
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        child: Text(
          getIt<TeamProvider>().isGroupTeam(team)
              ? S.of(context).teamGroupQuit
              : owner
                  ? S.of(context).teamAdvancedDismiss
                  : S.of(context).teamAdvancedQuit,
          style: const TextStyle(fontSize: 16, color: Color(0xffe6605c)),
        ),
      ),
    );
  }

  @override
  void initState() {
    //ios 端需要重新获取群成员
    if (Platform.isIOS) {
      NIMChatCache.instance.fetchTeamMember(widget.teamId);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
      title: S.of(context).teamSettingTitle,
      body: ChangeNotifierProvider(
        create: (context) {
          var vm = TeamSettingViewModel();
          vm.requestTeamData(widget.teamId);
          vm.requestTeamMembers(widget.teamId);
          vm.addTeamSubscribe();
          return vm;
        },
        builder: (context, child) {
          var teamWithMember =
              context.watch<TeamSettingViewModel>().teamWithMember;
          var teamMemberInfoList =
              context.watch<TeamSettingViewModel>().userInfoData;

          return teamWithMember != null
              ? SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        CardBackground(
                          child: _member(
                              context, teamWithMember, teamMemberInfoList),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        CardBackground(
                            child: _setting(context, teamWithMember)),
                        Visibility(
                            visible: !getIt<TeamProvider>()
                                .isGroupTeam(teamWithMember.team),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: CardBackground(
                                  child: _teamManage(context, teamWithMember)),
                            )),
                        const SizedBox(
                          height: 16,
                        ),
                        CardBackground(
                            child: _actionButton(
                                context,
                                teamWithMember.team,
                                teamWithMember.teamMember?.type ==
                                    TeamMemberType.owner)),
                        const SizedBox(
                          height: 16,
                        ),
                      ],
                    ),
                  ),
                )
              : const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
