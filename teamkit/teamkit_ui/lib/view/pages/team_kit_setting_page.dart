// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:im_common_ui/router/imkit_router_constants.dart';
import 'package:im_common_ui/router/imkit_router_factory.dart';
import 'package:im_common_ui/ui/avatar.dart';
import 'package:im_common_ui/ui/background.dart';
import 'package:im_common_ui/ui/dialog.dart';
import 'package:im_common_ui/utils/color_utils.dart';
import 'package:im_common_ui/widgets/transparent_scaffold.dart';
import 'package:im_common_ui/widgets/update_text_info_page.dart';
import 'package:corekit_im/model/contact_info.dart';
import 'package:corekit_im/model/team_models.dart';
import 'package:corekit_im/service_locator.dart';
import 'package:corekit_im/services/login/login_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_core/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:teamkit_ui/generated/l10n.dart';
import 'package:teamkit_ui/view/pages/team_kit_member_list_page.dart';
import 'package:teamkit_ui/view/pages/team_kit_team_info_page.dart';

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

  Widget _member(BuildContext context, TeamWithMember teamWithMember,
      List<UserInfoWithTeam>? list) {
    var team = teamWithMember.team;
    var teamMember = teamWithMember.teamMember;

    bool hasPrivilegeToInvite =
        (team.teamInviteMode == NIMTeamInviteModeEnum.all) ||
            (teamMember?.type != TeamMemberType.normal &&
                teamMember?.type != TeamMemberType.apply) ||
            team.type == NIMTeamTypeEnum.normal;

    List<Widget> avatars = [];
    if (hasPrivilegeToInvite) {
      avatars.add(Padding(
        padding: const EdgeInsets.only(right: 12),
        child: GestureDetector(
          onTap: () {
            goToContactSelector(context,
                    filter: list
                        ?.where((element) => element.userInfo != null)
                        .map((e) => e.userInfo!.userId!)
                        .toList(),
                    mostCount: list == null ? 199 : 200 - list.length,
                    returnContact: true)
                .then((contacts) {
              if (contacts is List<ContactInfo> && contacts.isNotEmpty) {
                context.read<TeamSettingViewModel>().addMembers(
                    team.id!, contacts.map((e) => e.user.userId!).toList());
              }
            });
          },
          child: SvgPicture.asset(
            'images/ic_member_add.svg',
            package: 'chatkit_ui',
            height: 32,
            width: 32,
          ),
        ),
      ));
    }
    if (list != null && list.isNotEmpty) {
      avatars.addAll(list.map((e) {
        var userInfo = e.userInfo;
        return userInfo != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    if (userInfo.userId ==
                        getIt<LoginService>().userInfo?.userId!) {
                      gotoMineInfoPage(context);
                    } else {
                      goToContactDetail(context, userInfo.userId!);
                    }
                  },
                  child: Avatar(
                    avatar: e.getAvatar(),
                    name: e.getName(),
                    height: 32,
                    width: 32,
                  ),
                ),
              )
            : Container();
      }).toList());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: GestureDetector(
            onTap: () {
              bool hasPrivilegeToUpdateInfo =
                  (team.teamUpdateMode == NIMTeamUpdateModeEnum.all) ||
                      (teamMember?.type != TeamMemberType.normal &&
                          teamMember?.type != TeamMemberType.apply) ||
                      team.type == NIMTeamTypeEnum.normal;
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
                  team.type == NIMTeamTypeEnum.normal
                      ? S.of(context).team_group_member_title
                      : S.of(context).team_member_title,
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: avatars,
            ),
          ),
        ),
      ],
    );
  }

  Widget _setting(BuildContext context, NIMTeam team) {
    return Column(
      children: ListTile.divideTiles(context: context, tiles: [
        // ListTile(
        //   title: Text(
        //     S.of(context).team_mark,
        //     style: style,
        //   ),
        //   trailing: const Icon(Icons.keyboard_arrow_right_outlined),
        // ),
        ListTile(
          title: Text(
            S.of(context).team_history,
            style: style,
          ),
          trailing: const Icon(Icons.keyboard_arrow_right_outlined),
          onTap: () {
            Navigator.pushNamed(context, RouterConstants.PATH_CHAT_SEARCH_PAGE,
                arguments: {'teamId': widget.teamId});
          },
        ),
        ListTile(
          title: Text(
            S.of(context).team_message_tip,
            style: style,
          ),
          trailing: CupertinoSwitch(
            activeColor: CommonColors.color_337eff,
            onChanged: (bool value) {
              context.read<TeamSettingViewModel>().muteTeam(team.id!, !value);
            },
            value: context.read<TeamSettingViewModel>().messageTip,
          ),
        ),
        ListTile(
          title: Text(
            S.of(context).team_session_pin,
            style: style,
          ),
          trailing: CupertinoSwitch(
            activeColor: CommonColors.color_337eff,
            onChanged: (bool value) {
              context.read<TeamSettingViewModel>().configStick(team.id!, value);
            },
            value: context.read<TeamSettingViewModel>().isStick,
          ),
        ),
      ]).toList(),
    );
  }

  Widget _teamMute(BuildContext context, TeamWithMember teamWithMember) {
    return Column(
      children: ListTile.divideTiles(context: context, tiles: [
        ListTile(
          title: Text(
            S.of(context).team_my_nickname_title,
            style: style,
          ),
          trailing: const Icon(Icons.keyboard_arrow_right_outlined),
          onTap: () {
            var teamNick = context.read<TeamSettingViewModel>().myTeamNickName;
            Future<bool> _updateNick(nickname) {
              return context
                  .read<TeamSettingViewModel>()
                  .updateNickname(teamWithMember.team.id!, nickname);
            }

            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => UpdateTextInfoPage(
                          title: S.of(context).team_my_nickname_title,
                          content: teamNick,
                          maxLength: 30,
                          privilege: true,
                          onSave: _updateNick,
                          leading: Text(
                            S.of(context).team_cancel,
                            style: const TextStyle(
                                fontSize: 16, color: CommonColors.color_666666),
                          ),
                          sureStr: S.of(context).team_save,
                        )));
          },
        ),
        Visibility(
          visible: teamWithMember.teamMember?.type == TeamMemberType.owner,
          child: ListTile(
            title: Text(
              S.of(context).team_mute,
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
      ]).toList(),
    );
  }

  void _showTeamIdentifyDialog(ValueChanged<int?> onChoose) {
    var style = const TextStyle(fontSize: 16, color: CommonColors.color_333333);
    showBottomChoose(
            context: context,
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Text(
                  S.of(context).team_all_member,
                  style: style,
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Text(
                  S.of(context).team_owner,
                  style: style,
                ),
              ),
            ],
            showCancel: true)
        .then((value) => onChoose(value));
  }

  Widget _invitation(BuildContext context, NIMTeam team) {
    return Column(
      children: ListTile.divideTiles(context: context, tiles: [
        ListTile(
          title: Text(
            S.of(context).team_invite_other_permission,
            style: style,
          ),
          subtitle: Text(
            context.read<TeamSettingViewModel>().invitePrivilege ==
                    NIMTeamInviteModeEnum.all
                ? S.of(context).team_all_member
                : S.of(context).team_owner,
            style:
                const TextStyle(fontSize: 14, color: CommonColors.color_999999),
          ),
          trailing: const Icon(Icons.keyboard_arrow_right_outlined),
          onTap: () {
            _showTeamIdentifyDialog((value) {
              if (value != null) {
                context.read<TeamSettingViewModel>().updateInvitePrivilege(
                    team.id!,
                    value == 1
                        ? NIMTeamInviteModeEnum.all
                        : NIMTeamInviteModeEnum.manager);
              }
            });
          },
        ),
        ListTile(
          title: Text(
            S.of(context).team_update_info_permission,
            style: style,
          ),
          subtitle: Text(
            context.read<TeamSettingViewModel>().infoPrivilege ==
                    NIMTeamUpdateModeEnum.all
                ? S.of(context).team_all_member
                : S.of(context).team_owner,
            style:
                const TextStyle(fontSize: 14, color: CommonColors.color_999999),
          ),
          trailing: const Icon(Icons.keyboard_arrow_right_outlined),
          onTap: () {
            _showTeamIdentifyDialog((value) {
              if (value != null) {
                context.read<TeamSettingViewModel>().updateInfoPrivilege(
                    team.id!,
                    value == 1
                        ? NIMTeamUpdateModeEnum.all
                        : NIMTeamUpdateModeEnum.manager);
              }
            });
          },
        ),
        ListTile(
          title: Text(
            S.of(context).team_need_agreed_when_be_invited_permission,
            style: style,
          ),
          trailing: CupertinoSwitch(
            activeColor: CommonColors.color_337eff,
            onChanged: (bool value) {
              context
                  .read<TeamSettingViewModel>()
                  .updateBeInviteMode(team.id!, value);
            },
            value: context.read<TeamSettingViewModel>().beInvitedNeedAgreed,
          ),
        ),
      ]).toList(),
    );
  }

  Widget _actionButton(
      BuildContext context, NIMTeamTypeEnum? type, bool owner) {
    return InkWell(
      onTap: () {
        String title = "";
        String content = "";
        int action = 0; // 1:quit 2:dismiss
        if (type == NIMTeamTypeEnum.normal) {
          title = S.of(context).team_group_quit;
          content = S.of(context).team_quit_group_team_query;
          action = 1;
        } else if (type == NIMTeamTypeEnum.advanced) {
          title = owner
              ? S.of(context).team_advanced_dismiss
              : S.of(context).team_advanced_quit;
          content = owner
              ? S.of(context).team_dismiss_advanced_team_query
              : S.of(context).team_quit_advanced_team_query;
          action = owner ? 2 : 1;
        }

        showCommonDialog(
                context: context,
                title: title,
                content: content,
                positiveContent: S.of(context).team_confirm,
                navigateContent: S.of(context).team_cancel)
            .then((value) {
          if (value == true) {
            if (action == 1) {
              context
                  .read<TeamSettingViewModel>()
                  .quitTeam(widget.teamId)
                  .then((value) {
                if (value) {
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                }
              });
            } else if (action == 2) {
              context
                  .read<TeamSettingViewModel>()
                  .dismissTeam(widget.teamId)
                  .then((value) {
                if (value) {
                  Navigator.popUntil(context, ModalRoute.withName('/'));
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
          type == NIMTeamTypeEnum.normal
              ? S.of(context).team_group_quit
              : owner
                  ? S.of(context).team_advanced_dismiss
                  : S.of(context).team_advanced_quit,
          style: const TextStyle(fontSize: 16, color: Color(0xffe6605c)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
      title: S.of(context).team_setting_title,
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

          var type = teamWithMember?.team.type;
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
                            child: _setting(context, teamWithMember.team)),
                        Visibility(
                            visible: type == NIMTeamTypeEnum.advanced,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: CardBackground(
                                  child: _teamMute(context, teamWithMember)),
                            )),
                        Visibility(
                            visible: type == NIMTeamTypeEnum.advanced &&
                                teamWithMember.teamMember?.type ==
                                    TeamMemberType.owner,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: CardBackground(
                                  child: _invitation(
                                      context, teamWithMember.team)),
                            )),
                        const SizedBox(
                          height: 16,
                        ),
                        CardBackground(
                            child: _actionButton(
                                context,
                                type,
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
