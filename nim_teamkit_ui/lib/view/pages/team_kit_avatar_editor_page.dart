// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common_ui/extension.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/background.dart';
import 'package:netease_common_ui/ui/photo.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:netease_corekit_im/services/message/nim_chat_cache.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:nim_chatkit/model/team_default_icon.dart';
import 'package:nim_chatkit/repo/team_repo.dart';

import '../../l10n/S.dart';
import '../../team_kit_client.dart';

class TeamKitAvatarEditorPage extends StatefulWidget {
  final NIMTeam team;

  final String? avatar;

  const TeamKitAvatarEditorPage({Key? key, required this.team, this.avatar})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => TeamKitAvatarEditorState();
}

class TeamKitAvatarEditorState extends State<TeamKitAvatarEditorPage> {
  String? photoAvatar;

  Future<void> _setDefaultIcon(int index) async {
    if (!(await haveConnectivity())) {
      return;
    }

    setState(() {
      photoAvatar = TeamDefaultIcons.getIconByIndex(index);
    });
  }

  _selectPic() {
    showPhotoSelector(context).then((value) async {
      if (!(await haveConnectivity())) {
        return;
      }

      if (value != null && value.isNotEmpty) {
        NIMUploadFileParams params = NIMUploadFileParams(filePath: value);
        final uploadTask =
            await NimCore.instance.storageService.createUploadFileTask(params);
        if (uploadTask.data != null) {
          NimCore.instance.storageService
              .uploadFile(uploadTask.data!)
              .then((result) {
            setState(() {
              if (result.data != null && result.data!.isNotEmpty) {
                photoAvatar = result.data;
              }
            });
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Text(S.of(context).teamCancel,
            style: TextStyle(fontSize: 16, color: '#666666'.toColor()),
            maxLines: 1),
      ),
      title: S.of(context).teamUpdateIcon,
      centerTitle: true,
      actions: [
        TextButton(
            onPressed: () async {
              if (!(await haveConnectivity())) {
                return;
              }
              if (photoAvatar != null) {
                TeamRepo.updateTeamIcon(
                        widget.team.teamId, widget.team.teamType, photoAvatar!)
                    .then((value) {
                  if (!value) {
                    if (!NIMChatCache.instance.hasPrivilegeToModify()) {
                      Fluttertoast.showToast(
                          msg: S.of(context).teamPermissionDeny);
                    } else {
                      Fluttertoast.showToast(
                          msg: S.of(context).teamSettingFailed);
                    }
                    Navigator.pop(context);
                  } else {
                    Navigator.pop(context, photoAvatar!);
                  }
                });
              }
            },
            child: Text(S.of(context).teamSave,
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
                          avatar: photoAvatar ??
                              (widget.avatar ?? widget.team.avatar),
                          name: widget.team.name,
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: SvgPicture.asset(
                            'images/ic_camera.svg',
                            package: kPackage,
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
                      S.of(context).teamDefaultIcon,
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
                              package: kPackage,
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
                              package: kPackage,
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
                              package: kPackage,
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
                              package: kPackage,
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
                              package: kPackage,
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
