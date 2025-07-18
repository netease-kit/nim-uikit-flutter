// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common_ui/ui/background.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/model/team_models.dart';
import 'package:nim_chatkit/services/message/nim_chat_cache.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:nim_chatkit/repo/team_repo.dart';
import 'package:nim_teamkit_ui/view/pages/team_kit_manager_list_page.dart';

import '../../l10n/S.dart';

class TeamKitManagerPage extends StatefulWidget {
  final NIMTeam team;

  const TeamKitManagerPage({Key? key, required this.team}) : super(key: key);

  @override
  _TeamKitManagerPageState createState() => _TeamKitManagerPageState();
}

class _TeamKitManagerPageState extends State<TeamKitManagerPage> {
  late NIMTeamInviteMode inviteMode;

  late NIMTeamUpdateInfoMode updateInfoMode;

  /// 申请入群模式
  late NIMTeamJoinMode joinMode;

  /// 被邀请人同意入群模式
  late NIMTeamAgreeMode agreeMode;

  String aitPrivilege = aitPrivilegeAll;

  List<StreamSubscription> _teamSubs = [];

  int _managerCount = 0;

  TextStyle style =
      const TextStyle(color: CommonColors.color_333333, fontSize: 16);

  @override
  void initState() {
    inviteMode = (NIMChatCache.instance.teamInfo as NIMTeam).inviteMode;
    updateInfoMode = (NIMChatCache.instance.teamInfo as NIMTeam).updateInfoMode;
    joinMode = (NIMChatCache.instance.teamInfo as NIMTeam).joinMode;
    agreeMode = (NIMChatCache.instance.teamInfo as NIMTeam).agreeMode;
    _parseExtension(
        (NIMChatCache.instance.teamInfo as NIMTeam).serverExtension);
    _updateManagerCount(NIMChatCache.instance.teamMembers);
    _initListener();
    super.initState();
  }

  @override
  void dispose() {
    _teamSubs.forEach((element) {
      element.cancel();
    });
    super.dispose();
  }

  void _initListener() {
    _teamSubs.addAll([
      NIMChatCache.instance.teamInfoNotifier.listen((event) {
        inviteMode = event.inviteMode;
        updateInfoMode = event.updateInfoMode;
        joinMode = event.joinMode;
        agreeMode = event.agreeMode;
        _parseExtension(event.serverExtension);
        if (mounted) {
          setState(() {});
        }
      }),
      NIMChatCache.instance.teamMembersNotifier.listen((event) {
        _updateManagerCount(event);
        if (mounted) {
          setState(() {});
        }
      }),
    ]);
  }

  void _parseExtension(String? extension) {
    if (extension?.isNotEmpty == true) {
      var extMap = json.decode(extension!) as Map<String, dynamic>?;
      if (extMap != null) {
        aitPrivilege = extMap[aitPrivilegeKey] as String? ?? aitPrivilegeAll;
      }
    }
  }

  void _updateManagerCount(List<UserInfoWithTeam>? memberList) {
    _managerCount = memberList
            ?.where((element) =>
                element.teamInfo.memberRole ==
                NIMTeamMemberRole.memberRoleManager)
            .length ??
        0;
  }

  Widget _friendApplicationSetting(BuildContext context, NIMTeam team) {
    return Column(
      children: ListTile.divideTiles(context: context, tiles: [
        ListTile(
          title: Text(
            S.of(context).teamUpdateInfoPermission,
            style: style,
          ),
          subtitle: Text(
            updateInfoMode == NIMTeamUpdateInfoMode.updateInfoModeAll
                ? S.of(context).teamAllMember
                : S.of(context).teamOwnerManager,
            style:
                const TextStyle(fontSize: 14, color: CommonColors.color_999999),
          ),
          trailing: const Icon(Icons.keyboard_arrow_right_outlined),
          onTap: () async {
            if (!(await haveConnectivity())) {
              return;
            }

            if (NIMChatCache.instance.myTeamRole() ==
                NIMTeamMemberRole.memberRoleNormal) {
              Fluttertoast.showToast(
                  msg: S.of(context).teamNoOperatePermission);
              return;
            }
            _showTeamIdentifyDialog((value) {
              if (value != null) {
                var updateMode = value == 1
                    ? NIMTeamUpdateInfoMode.updateInfoModeAll
                    : NIMTeamUpdateInfoMode.updateInfoModeManager;
                TeamRepo.updateTeamInfoPrivilege(
                        team.teamId, team.teamType, updateMode)
                    .then((value) {
                  if (value) {
                    updateInfoMode = updateMode;
                    setState(() {});
                  }
                });
              }
            });
          },
        ),
        ListTile(
          title: Text(
            S.of(context).teamInviteOtherPermission,
            style: style,
          ),
          subtitle: Text(
            inviteMode == NIMTeamInviteMode.inviteModeAll
                ? S.of(context).teamAllMember
                : S.of(context).teamOwnerManager,
            style:
                const TextStyle(fontSize: 14, color: CommonColors.color_999999),
          ),
          trailing: const Icon(Icons.keyboard_arrow_right_outlined),
          onTap: () async {
            if (!(await haveConnectivity())) {
              return;
            }

            if (NIMChatCache.instance.myTeamRole() ==
                NIMTeamMemberRole.memberRoleNormal) {
              Fluttertoast.showToast(
                  msg: S.of(context).teamNoOperatePermission);
              return;
            }
            _showTeamIdentifyDialog((value) {
              if (value != null) {
                var modeEnum = value == 1
                    ? NIMTeamInviteMode.inviteModeAll
                    : NIMTeamInviteMode.inviteModeManager;
                TeamRepo.updateInviteMode(team.teamId, team.teamType, modeEnum)
                    .then((value) {
                  if (value) {}
                });
              }
            });
          },
        ),
        ListTile(
          title: Text(
            S.of(context).teamAitPermission,
            style: style,
          ),
          subtitle: Text(
            aitPrivilege == aitPrivilegeAll
                ? S.of(context).teamAllMember
                : S.of(context).teamOwnerManager,
            style:
                const TextStyle(fontSize: 14, color: CommonColors.color_999999),
          ),
          trailing: const Icon(Icons.keyboard_arrow_right_outlined),
          onTap: () async {
            if (!(await haveConnectivity())) {
              return;
            }

            if (NIMChatCache.instance.myTeamRole() ==
                NIMTeamMemberRole.memberRoleNormal) {
              Fluttertoast.showToast(
                  msg: S.of(context).teamNoOperatePermission);
              return;
            }
            _showTeamIdentifyDialog((value) {
              if (value != null) {
                var aitModel =
                    value == 1 ? aitPrivilegeAll : aitPrivilegeManager;
                TeamRepo.updateTeamExtension(team.teamId, team.teamType,
                        _updateTeamExtensionByAitPrivilegeAll(aitModel))
                    .then((value) async {
                  if (value == false) {
                    Fluttertoast.showToast(
                        msg: S.of(context).teamSettingFailed);
                  }
                });
              }
            });
          },
        ),
      ]).toList(),
    );
  }

  Widget _teamJoinSetting(BuildContext context, NIMTeam team) {
    return Column(
      children: ListTile.divideTiles(context: context, tiles: [
        ListTile(
          title: Text(
            S.of(context).teamManageJoinNeedAccept,
            style: style,
          ),
          subtitle: Text(
            S.of(context).teamManageJoinNeedAcceptDetail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 14, color: CommonColors.color_999999),
          ),
          trailing: CupertinoSwitch(
            activeColor: CommonColors.color_337eff,
            onChanged: (bool value) {
              if (value != (agreeMode == NIMTeamAgreeMode.agreeModeAuth)) {
                TeamRepo.updateBeInviteMode(team.teamId, team.teamType, value);
              }
            },
            value: agreeMode == NIMTeamAgreeMode.agreeModeAuth,
          ),
        ),
        ListTile(
          title: Text(
            S.of(context).teamManageApplyNeedAccept,
            style: style,
          ),
          subtitle: Text(
            S.of(context).teamManageApplyNeedAcceptDetail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 14, color: CommonColors.color_999999),
          ),
          trailing: CupertinoSwitch(
            activeColor: CommonColors.color_337eff,
            onChanged: (bool value) {
              if (value != (joinMode == NIMTeamJoinMode.joinModeApply)) {
                TeamRepo.updateApplyAgreeMode(
                    team.teamId, team.teamType, value);
              }
            },
            value: joinMode == NIMTeamJoinMode.joinModeApply,
          ),
        ),
      ]).toList(),
    );
  }

  String _updateTeamExtensionByAitPrivilegeAll(String aitModel) {
    var extension = widget.team.serverExtension;
    if (extension?.isNotEmpty == true) {
      var extMap = (json.decode(extension!) as Map?)?.cast<dynamic, dynamic>();
      if (extMap != null) {
        extMap[aitPrivilegeKey] = aitModel;
        extMap[lastOption] = aitPrivilegeKey;
        return json.encode(extMap);
      }
    }
    return json
        .encode({aitPrivilegeKey: aitModel, lastOption: aitPrivilegeKey});
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
                  S.of(context).teamAllMember,
                  style: style,
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Text(
                  S.of(context).teamOwnerManager,
                  style: style,
                ),
              ),
            ],
            showCancel: true)
        .then((value) => onChoose(value));
  }

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
      title: S.of(context).teamManage,
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (NIMChatCache.instance.myTeamRole() ==
                    NIMTeamMemberRole.memberRoleOwner)
                  CardBackground(
                    child: ListTile(
                      title: Text(
                        S.of(context).teamManagerManagers,
                        style: style,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _managerCount.toString(),
                            style: TextStyle(
                                fontSize: 16, color: CommonColors.color_999999),
                          ),
                          const Icon(Icons.keyboard_arrow_right_outlined)
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TeamKitManagerListPage(
                                      tId: widget.team.teamId,
                                    )));
                      },
                    ),
                  ),
                CardBackground(
                    child: _friendApplicationSetting(context, widget.team)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                  child: Text(S.of(context).teamEnterManager),
                ),
                CardBackground(child: _teamJoinSetting(context, widget.team))
              ],
            )),
      ),
    );
  }
}
