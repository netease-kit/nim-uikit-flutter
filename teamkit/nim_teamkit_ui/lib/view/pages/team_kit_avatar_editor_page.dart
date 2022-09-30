// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_common_ui/extension.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/background.dart';
import 'package:netease_common_ui/ui/photo.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_core/nim_core.dart';
import 'package:nim_teamkit/model/team_default_icon.dart';
import 'package:nim_teamkit/repo/team_repo.dart';

import '../../generated/l10n.dart';

class TeamKitAvatarEditorPage extends StatefulWidget {
  final NIMTeam team;

  const TeamKitAvatarEditorPage({Key? key, required this.team})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => TeamKitAvatarEditorState();
}

class TeamKitAvatarEditorState extends State<TeamKitAvatarEditorPage> {
  String? photoAvatar;

  void _setDefaultIcon(int index) {
    setState(() {
      photoAvatar = TeamDefaultIcons.getIconByIndex(index);
    });
  }

  _selectPic() {
    showPhotoSelector(context).then((value) {
      setState(() {
        if (value != null && value.isNotEmpty) {
          photoAvatar = value;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
      leading: TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text(
          S.of(context).team_cancel,
          style: TextStyle(fontSize: 16, color: '#666666'.toColor()),
        ),
      ),
      title: S.of(context).team_update_icon,
      centerTitle: true,
      actions: [
        TextButton(
            onPressed: () async {
              if (!(await Connectivity().checkNetwork(context))) {
                return;
              }
              if (photoAvatar != null) {
                TeamRepo.updateTeamIcon(widget.team.id!, photoAvatar!)
                    .then((value) {
                  Navigator.pop(context, photoAvatar!);
                });
              }
            },
            child: Text(S.of(context).team_save,
                style: TextStyle(fontSize: 16, color: '#337EFF'.toColor())))
      ],
      body: Column(
        children: [
          CardBackground(
            margin:
                const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 12),
            child: Container(
                padding: const EdgeInsets.only(top: 28, bottom: 20),
                alignment: Alignment.center,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: GestureDetector(
                    onTap: _selectPic,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Avatar(
                          width: 80,
                          height: 80,
                          avatar: photoAvatar ?? widget.team.icon,
                          name: widget.team.name,
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: SvgPicture.asset(
                            'images/ic_camera.svg',
                            package: 'nim_teamkit_ui',
                          ),
                        )
                      ],
                    ),
                  ),
                )),
          ),
          CardBackground(
            margin: const EdgeInsets.only(left: 20, right: 20),
            child: Container(
                padding: const EdgeInsets.only(top: 15, left: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).team_default_icon,
                      style:
                          TextStyle(fontSize: 16, color: '#333333'.toColor()),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () {
                              _setDefaultIcon(0);
                            },
                            child: Image.asset(
                              'images/ic_team_0.png',
                              package: 'nim_teamkit_ui',
                              width: 48,
                              height: 48,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _setDefaultIcon(1);
                            },
                            child: Image.asset(
                              'images/ic_team_1.png',
                              package: 'nim_teamkit_ui',
                              width: 48,
                              height: 48,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _setDefaultIcon(2);
                            },
                            child: Image.asset(
                              'images/ic_team_2.png',
                              package: 'nim_teamkit_ui',
                              width: 48,
                              height: 48,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _setDefaultIcon(3);
                            },
                            child: Image.asset(
                              'images/ic_team_3.png',
                              package: 'nim_teamkit_ui',
                              width: 48,
                              height: 48,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _setDefaultIcon(4);
                            },
                            child: Image.asset(
                              'images/ic_team_4.png',
                              package: 'nim_teamkit_ui',
                              width: 48,
                              height: 48,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                )),
          ),
        ],
      ),
    );
  }
}
