// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/background.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:netease_common_ui/widgets/update_text_info_page.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/message/nim_chat_cache.dart';
import 'package:netease_corekit_im/services/team/team_provider.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:nim_chatkit/repo/team_repo.dart';
import 'package:nim_teamkit_ui/view/pages/team_kit_avatar_editor_page.dart';

import '../../l10n/S.dart';

class TeamKitTeamInfoPage extends StatefulWidget {
  final NIMTeam team;

  final bool hasPrivilegeToUpdateInfo;

  const TeamKitTeamInfoPage(
      {Key? key, required this.team, this.hasPrivilegeToUpdateInfo = true})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _TeamKitTeamInfoState();
}

class _TeamKitTeamInfoState extends State<TeamKitTeamInfoPage> {
  String? _updatedName;

  String? _updatedIntroduce;

  String? avatar;

  Future<bool> _updateName(String name) async {
    if (!(await haveConnectivity())) {
      return Future(() => false);
      ;
    }

    if (name.trim().isEmpty) {
      Fluttertoast.showToast(msg: S.of(context).teamNameMustNotEmpty);
      return Future(() => false);
    }
    return TeamRepo.updateTeamName(
            widget.team.teamId, widget.team.teamType, name)
        .then((value) {
      _updatedName = name;
      if (!value) {
        if (!NIMChatCache.instance.hasPrivilegeToModify()) {
          Fluttertoast.showToast(
              msg: S.of(context).teamPermissionDeny, gravity: ToastGravity.TOP);
        } else {
          Fluttertoast.showToast(
              msg: S.of(context).teamSettingFailed, gravity: ToastGravity.TOP);
        }
      }
      return value;
    });
  }

  Future<bool> _updateIntroduce(introduce) async {
    if (!(await haveConnectivity())) {
      return Future(() => false);
      ;
    }

    return TeamRepo.updateTeamIntroduce(
            widget.team.teamId, widget.team.teamType, introduce)
        .then((result) {
      _updatedIntroduce = introduce;
      if (!result) {
        if (!NIMChatCache.instance.hasPrivilegeToModify()) {
          Fluttertoast.showToast(msg: S.of(context).teamPermissionDeny);
        } else {
          Fluttertoast.showToast(msg: S.of(context).teamSettingFailed);
        }
      }
      return result;
    });
  }

  @override
  void initState() {
    super.initState();
    avatar = widget.team.avatar;
  }

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
      title: S.of(context).teamInfoTitle,
      centerTitle: true,
      body: Container(
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: CardBackground(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  if (!NIMChatCache.instance.hasPrivilegeToModify()) {
                    Fluttertoast.showToast(msg: S.of(context).teamNoPermission);
                    return;
                  }

                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return TeamKitAvatarEditorPage(
                        team: widget.team, avatar: avatar);
                  })).then((value) {
                    if (value?.isNotEmpty == true) {
                      setState(() {
                        avatar = value;
                      });
                    }
                  });
                },
                child: Stack(
                  alignment: AlignmentDirectional.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        child: Text(S.of(context).teamIconTitle,
                            style: TextStyle(
                                fontSize: 16, color: '#333333'.toColor())),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                              child: Avatar(
                                width: 42,
                                height: 42,
                                avatar: avatar,
                                name: widget.team.name,
                              )),
                          const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Icon(
                              Icons.keyboard_arrow_right_outlined,
                              color: CommonColors.color_999999,
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UpdateTextInfoPage(
                                title: S.of(context).teamNameTitle,
                                content: _updatedName ?? widget.team.name,
                                maxLength: 30,
                                privilege: NIMChatCache.instance
                                    .hasPrivilegeToModify(),
                                onSave: _updateName,
                                leading: Text(
                                  S.of(context).teamCancel,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: CommonColors.color_666666),
                                ),
                                sureStr: S.of(context).teamSave,
                              )));
                },
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          child: Text(S.of(context).teamNameTitle,
                              style: TextStyle(
                                  fontSize: 16, color: '#333333'.toColor()))),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: Icon(
                          Icons.keyboard_arrow_right_outlined,
                          color: CommonColors.color_999999,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              if (!getIt<TeamProvider>().isGroupTeam(widget.team))
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => UpdateTextInfoPage(
                                  title: S.of(context).teamIntroduceTitle,
                                  content:
                                      _updatedIntroduce ?? widget.team.intro,
                                  maxLength: 100,
                                  privilege: NIMChatCache.instance
                                      .hasPrivilegeToModify(),
                                  onSave: _updateIntroduce,
                                  leading: Text(
                                    S.of(context).teamCancel,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: CommonColors.color_666666),
                                  ),
                                  sureStr: S.of(context).teamSave,
                                )));
                  },
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            child: Text(S.of(context).teamIntroduceTitle,
                                style: TextStyle(
                                    fontSize: 16, color: '#333333'.toColor()))),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Icon(
                            Icons.keyboard_arrow_right_outlined,
                            color: CommonColors.color_999999,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
