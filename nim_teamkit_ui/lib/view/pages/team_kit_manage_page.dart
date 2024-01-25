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
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:netease_corekit_im/model/team_models.dart';
import 'package:netease_corekit_im/services/message/nim_chat_cache.dart';
import 'package:nim_core/nim_core.dart';
import 'package:nim_teamkit/repo/team_repo.dart';
import 'package:nim_teamkit_ui/view/pages/team_kit_manager_list_page.dart';

import '../../l10n/S.dart';

class TeamKitManagerPage extends StatefulWidget {
  final NIMTeam team;

  const TeamKitManagerPage({Key? key, required this.team}) : super(key: key);

  @override
  _TeamKitManagerPageState createState() => _TeamKitManagerPageState();
}

class _TeamKitManagerPageState extends State<TeamKitManagerPage> {
  late NIMTeamInviteModeEnum invitePrivilege;

  late NIMTeamUpdateModeEnum updatePrivilege;

  String aitPrivilege = aitPrivilegeAll;

  List<StreamSubscription> _teamSubs = [];

  int _managerCount = 0;

  TextStyle style =
      const TextStyle(color: CommonColors.color_333333, fontSize: 16);

  @override
  void initState() {
    invitePrivilege =
        (NIMChatCache.instance.teamInfo as NIMTeam).teamInviteMode;
    updatePrivilege =
        (NIMChatCache.instance.teamInfo as NIMTeam).teamUpdateMode;
    _parseExtension((NIMChatCache.instance.teamInfo as NIMTeam).extension);
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
        if (event is NIMTeam) {
          invitePrivilege = event.teamInviteMode;
          updatePrivilege = event.teamUpdateMode;
          _parseExtension(event.extension);
          if (mounted) {
            setState(() {});
          }
        }
      }),
      NIMChatCache.instance.teamMembersNotifier.listen((event) {
        if (event is List<UserInfoWithTeam>) {
          _updateManagerCount(event);
          if (mounted) {
            setState(() {});
          }
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
            ?.where(
                (element) => element.teamInfo.type == TeamMemberType.manager)
            .length ??
        0;
  }

  Widget _setting(BuildContext context, NIMTeam team) {
    return Column(
      children: ListTile.divideTiles(context: context, tiles: [
        ListTile(
          title: Text(
            S.of(context).teamUpdateInfoPermission,
            style: style,
          ),
          subtitle: Text(
            updatePrivilege == NIMTeamUpdateModeEnum.all
                ? S.of(context).teamAllMember
                : S.of(context).teamOwnerManager,
            style:
                const TextStyle(fontSize: 14, color: CommonColors.color_999999),
          ),
          trailing: const Icon(Icons.keyboard_arrow_right_outlined),
          onTap: () {
            if (NIMChatCache.instance.myTeamRole() == TeamMemberType.normal) {
              Fluttertoast.showToast(
                  msg: S.of(context).teamNoOperatePermission);
              return;
            }
            _showTeamIdentifyDialog((value) {
              if (value != null) {
                var updateMode = value == 1
                    ? NIMTeamUpdateModeEnum.all
                    : NIMTeamUpdateModeEnum.manager;
                TeamRepo.updateTeamInfoPrivilege(team.id!, updateMode)
                    .then((value) {
                  if (value) {
                    updatePrivilege = updateMode;
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
            invitePrivilege == NIMTeamInviteModeEnum.all
                ? S.of(context).teamAllMember
                : S.of(context).teamOwnerManager,
            style:
                const TextStyle(fontSize: 14, color: CommonColors.color_999999),
          ),
          trailing: const Icon(Icons.keyboard_arrow_right_outlined),
          onTap: () {
            if (NIMChatCache.instance.myTeamRole() == TeamMemberType.normal) {
              Fluttertoast.showToast(
                  msg: S.of(context).teamNoOperatePermission);
              return;
            }
            _showTeamIdentifyDialog((value) {
              if (value != null) {
                var modeEnum = value == 1
                    ? NIMTeamInviteModeEnum.all
                    : NIMTeamInviteModeEnum.manager;
                TeamRepo.updateInviteMode(team.id!, modeEnum).then((value) {
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
          onTap: () {
            if (NIMChatCache.instance.myTeamRole() == TeamMemberType.normal) {
              Fluttertoast.showToast(
                  msg: S.of(context).teamNoOperatePermission);
              return;
            }
            _showTeamIdentifyDialog((value) {
              if (value != null) {
                var aitModel =
                    value == 1 ? aitPrivilegeAll : aitPrivilegeManager;
                TeamRepo.updateTeamExtension(team.id!,
                        _updateTeamExtensionByAitPrivilegeAll(aitModel))
                    .then((value) {
                  if (value == false) {
                    Fluttertoast.showToast(
                        msg: S.of(context).teamSettingFailed);
                  } else {
                    var tip = aitModel == aitPrivilegeAll
                        ? S.of(context).teamMsgAitAllPrivilegeIsAll
                        : S.of(context).teamMsgAitAllPrivilegeIsOwner;
                    MessageBuilder.createTipMessage(
                            sessionId: team.id!,
                            sessionType: NIMSessionType.team,
                            content: tip)
                        .then((value) {
                      if (value.isSuccess && value.data != null) {
                        value.data!.config = NIMCustomMessageConfig(
                            enableUnreadCount: false, enablePush: false);
                        NimCore.instance.messageService
                            .sendMessage(message: value.data!);
                      }
                    });
                  }
                });
              }
            });
          },
        ),
      ]).toList(),
    );
  }

  String _updateTeamExtensionByAitPrivilegeAll(String aitModel) {
    var extension = widget.team.extension;
    if (extension?.isNotEmpty == true) {
      var extMap = (json.decode(extension!) as Map?)?.cast<dynamic, dynamic>();
      if (extMap != null) {
        extMap[aitPrivilegeKey] = aitModel;
        return json.encode(extMap);
      }
    }
    return json.encode({aitPrivilegeKey: aitModel});
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
              children: [
                if (NIMChatCache.instance.myTeamRole() == TeamMemberType.owner)
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
                                      tId: widget.team.id!,
                                    )));
                      },
                    ),
                  ),
                CardBackground(child: _setting(context, widget.team)),
              ],
            )),
      ),
    );
  }
}
