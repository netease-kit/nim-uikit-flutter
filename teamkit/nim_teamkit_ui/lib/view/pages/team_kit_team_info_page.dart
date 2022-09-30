// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/background.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:netease_common_ui/widgets/update_text_info_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nim_core/nim_core.dart';
import 'package:nim_teamkit/repo/team_repo.dart';
import 'package:nim_teamkit_ui/view/pages/team_kit_avatar_editor_page.dart';

import '../../generated/l10n.dart';

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

  Future<bool> _updateName(name) {
    return TeamRepo.updateTeamName(widget.team.id!, name).then((value) {
      _updatedName = name;
      return value;
    });
  }

  Future<bool> _updateIntroduce(introduce) {
    return TeamRepo.updateTeamIntroduce(widget.team.id!, introduce)
        .then((result) {
      _updatedIntroduce = introduce;
      return result;
    });
  }

  @override
  void initState() {
    super.initState();
    avatar = widget.team.icon;
  }

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
      title: S.of(context).team_info_title,
      centerTitle: true,
      body: Container(
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: CardBackground(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  if (!widget.hasPrivilegeToUpdateInfo) {
                    Fluttertoast.showToast(
                        msg: S.of(context).team_no_permission);
                    return;
                  }

                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return TeamKitAvatarEditorPage(team: widget.team);
                  })).then((value) {
                    setState(() {
                      avatar = value;
                    });
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
                        child: Text(S.of(context).team_icon_title,
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
                  if (!widget.hasPrivilegeToUpdateInfo) {
                    Fluttertoast.showToast(
                        msg: S.of(context).team_no_permission);
                    return;
                  }
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UpdateTextInfoPage(
                                title: S.of(context).team_name_title,
                                content: _updatedName ?? widget.team.name,
                                maxLength: 30,
                                privilege: true,
                                onSave: _updateName,
                                leading: Text(
                                  S.of(context).team_cancel,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: CommonColors.color_666666),
                                ),
                                sureStr: S.of(context).team_save,
                              )));
                },
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          child: Text(S.of(context).team_name_title,
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
              if (widget.team.type == NIMTeamTypeEnum.advanced)
                InkWell(
                  onTap: () {
                    if (!widget.hasPrivilegeToUpdateInfo) {
                      Fluttertoast.showToast(
                          msg: S.of(context).team_no_permission);
                      return;
                    }

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => UpdateTextInfoPage(
                                  title: S.of(context).team_introduce_title,
                                  content: _updatedIntroduce ??
                                      widget.team.introduce,
                                  maxLength: 100,
                                  privilege: true,
                                  onSave: _updateIntroduce,
                                  leading: Text(
                                    S.of(context).team_cancel,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: CommonColors.color_666666),
                                  ),
                                  sureStr: S.of(context).team_save,
                                )));
                  },
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            child: Text(S.of(context).team_introduce_title,
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
