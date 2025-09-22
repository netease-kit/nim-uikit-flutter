// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/repo/team_repo.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/team/team_provider.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../l10n/S.dart';

class TeamKitDetailPage extends StatefulWidget {
  final String teamId;

  final NIMTeam? team;

  const TeamKitDetailPage({Key? key, required this.teamId, this.team})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _TeamKitDetailPageState();
}

class _TeamKitDetailPageState extends State<TeamKitDetailPage> {
  var subs = <StreamSubscription>[];

  NIMTeam? team;

  String? teamOwnerName;

  final int errorCodeHaveEnter = 109311;

  @override
  void initState() {
    super.initState();

    if (widget.team == null) {
      TeamRepo.getTeamInfo(widget.teamId, NIMTeamType.typeNormal)
          .then((result) {
        setState(() {
          team = result;
          getTeamOwner();
        });
      });
    } else {
      team = widget.team;
      getTeamOwner();
    }

    subs.add(TeamRepo.registerTeamUpdateObserver().listen((e) {
      if (e.teamId == widget.teamId) {
        setState(() {
          team = e;
        });
      }
    }));
  }

  ///获取群主
  void getTeamOwner() async {
    if (team?.ownerAccountId != null) {
      final teamMember = (await NimCore.instance.teamService
              .getTeamMemberListByIds(
                  widget.teamId, team!.teamType, [team!.ownerAccountId]))
          .data
          ?.firstOrNull;
      if (teamMember?.teamNick?.isNotEmpty == true) {
        teamOwnerName = teamMember?.teamNick;
        setState(() {});
        return;
      } else {
        final userInfo = (await NimCore.instance.userService
                .getUserList([team!.ownerAccountId]))
            .data
            ?.first;

        teamOwnerName = userInfo?.name ?? team!.ownerAccountId;
        setState(() {});
      }
    }
  }

  Widget _buildHead() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.only(right: 10, bottom: 10),
          child: Avatar(
            height: 65,
            width: 65,
            fontSize: 22,
            avatar: team?.avatar,
            name: team?.name,
            bgCode: AvatarColor.avatarColor(content: widget.teamId),
          ),
        ),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Text(
                team?.name ?? widget.teamId,
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                    fontSize: 22,
                    color: '#333333'.toColor(),
                    fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Text(
                S.of(context).teamId(widget.teamId),
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(fontSize: 12, color: '#333333'.toColor()),
              ),
            ),
            if (!getIt<TeamProvider>().isGroupTeam(team) &&
                teamOwnerName != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Text(
                  S.of(context).teamOwnerName(teamOwnerName!),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(fontSize: 12, color: '#333333'.toColor()),
                ),
              ),
          ],
        ))
      ],
    );
  }

  void _applyJoinTeam(BuildContext context, String teamId) async {
    if (!await haveConnectivity()) {
      return;
    }

    TeamRepo.applyJoinTeam(widget.teamId, NIMTeamType.typeNormal)
        .then((result) {
      if (result.isSuccess) {
        if (result.data?.joinMode == NIMTeamJoinMode.joinModeFree) {
          //直接去聊天页面
          goToTeamChat(context, widget.teamId);
        } else {
          // Navigator.pop(context);
          Fluttertoast.showToast(
              msg: S.of(context).teamJoinApplicationHaveSent);
        }
      } else {
        if (result.code == errorCodeHaveEnter) {
          //直接去聊天页面
          goToTeamChat(context, widget.teamId);
        } else {
          Fluttertoast.showToast(
              msg: S.of(context).teamJoinApplicationSendError);
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    for (var sub in subs) {
      sub.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    var divider = const Divider(
      height: 6,
      thickness: 6,
      color: Color(0xffeff1f4),
    );

    return TransparentScaffold(
      backgroundColor: Colors.white,
      elevation: 0,
      title: '',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 20, bottom: 8, top: 10),
              child: _buildHead(),
            ),
            if (team?.intro?.isNotEmpty == true) ...[
              divider,
              Container(
                margin: const EdgeInsets.only(left: 20, bottom: 8, top: 10),
                child: Text(S.of(context).teamIntro(team?.intro ?? '')),
              ),
            ] else
              divider,
            SizedBox(
              height: 300,
            ),
            Container(
              alignment: AlignmentDirectional.center,
              child: team?.isValidTeam != true
                  ? TextButton(
                      onPressed: () {
                        _applyJoinTeam(context, widget.teamId);
                      },
                      child: Text(S.of(context).teamJoinApply,
                          style: TextStyle(
                              fontSize: 16, color: '#337EFF'.toColor())),
                    )
                  : TextButton(
                      onPressed: () {
                        goToTeamChat(context, widget.teamId);
                      },
                      child: Text(S.of(context).teamChat,
                          style: TextStyle(
                              fontSize: 16, color: '#337EFF'.toColor())),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
