// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:netease_corekit_im/model/team_models.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:flutter/material.dart';
import 'package:nim_core/nim_core.dart';
import 'package:nim_teamkit/repo/team_repo.dart';

class TeamSettingViewModel extends ChangeNotifier {
  TeamWithMember? teamWithMember;
  List<UserInfoWithTeam>? userInfoData;

  List<UserInfoWithTeam>? filterList;

  bool messageTip = true;
  bool isStick = false;
  bool muteAllMember = false;
  NIMTeamInviteModeEnum? invitePrivilege;
  NIMTeamUpdateModeEnum? infoPrivilege;
  bool beInvitedNeedAgreed = false;
  String? myTeamNickName;

  StreamSubscription? _teamSub;

  void requestTeamData(String teamId) async {
    teamWithMember = await TeamRepo.queryTeamWithMember(
        teamId, getIt<LoginService>().userInfo!.userId!);
    isStick = await TeamRepo.isStickTop(teamId);

    messageTip = teamWithMember?.team.messageNotifyType ==
        NIMTeamMessageNotifyTypeEnum.all;
    muteAllMember = teamWithMember?.team.isAllMute ?? false;
    invitePrivilege = teamWithMember?.team.teamInviteMode;
    infoPrivilege = teamWithMember?.team.teamUpdateMode;
    beInvitedNeedAgreed = teamWithMember?.team.teamBeInviteModeEnum ==
        NIMTeamBeInviteModeEnum.needAuth;
    myTeamNickName = teamWithMember?.teamMember?.teamNick;
    notifyListeners();
  }

  void requestTeamMembers(String teamId) async {
    userInfoData = await TeamRepo.getMemberList(teamId);
    filterList = userInfoData;
    notifyListeners();
  }

  void addTeamSubscribe() {
    _teamSub = TeamRepo.registerTeamUpdateObserver().listen((event) {
      for (var e in event) {
        if (e.id == teamWithMember?.team.id) {
          // 这里iOS需要在回调之后请求，否则查询结果不对
          if (teamWithMember?.team.memberCount != e.memberCount) {
            requestTeamMembers(e.id!);
          }
          teamWithMember?.team = e;
          notifyListeners();
        }
      }
    });
  }

  void filterByText(String? filterStr) {
    if (filterStr == null || filterStr.isEmpty) {
      //过滤关键字为空时显示所有成员
      filterList = userInfoData;
      notifyListeners();
      return;
    }
    var filterResult = userInfoData?.where((member) {
      if (member.getName().contains(filterStr)) {
        member.searchPoint = member.getName().length;
        return true;
      }
      if (member.teamInfo.account?.contains(filterStr) == true) {
        member.searchPoint = 100 + member.teamInfo.account!.length;
        return true;
      }
      return false;
    }).toList();
    filterResult?.sort((a, b) {
      return b.searchPoint - a.searchPoint;
    });
    filterList = filterResult;
    notifyListeners();
  }

  void muteTeam(String teamId, bool mute) {
    TeamRepo.updateTeamNotify(teamId, mute).then((value) {
      if (!value) {
        messageTip = mute;
        notifyListeners();
      }
    });
    messageTip = !mute;
    notifyListeners();
  }

  void configStick(String sessionId, bool stick) {
    if (stick) {
      TeamRepo.addStickTop(sessionId, '').then((value) {
        if (value == null) {
          isStick = false;
          notifyListeners();
        }
      });
    } else {
      TeamRepo.removeStickTop(sessionId, '').then((value) {
        if (!value) {
          isStick = true;
          notifyListeners();
        }
      });
    }
    isStick = stick;
    notifyListeners();
  }

  void muteTeamAllMember(String teamId, bool mute) {
    TeamRepo.muteAllMembers(teamId, mute).then((value) {
      if (value) {
        muteAllMember = mute;
        notifyListeners();
      }
    });
  }

  void updateInvitePrivilege(String teamId, NIMTeamInviteModeEnum modeEnum) {
    TeamRepo.updateInviteMode(teamId, modeEnum).then((value) {
      if (value) {
        invitePrivilege = modeEnum;
        notifyListeners();
      }
    });
  }

  void updateInfoPrivilege(String teamId, NIMTeamUpdateModeEnum modeEnum) {
    TeamRepo.updateTeamInfoPrivilege(teamId, modeEnum).then((value) {
      if (value) {
        infoPrivilege = modeEnum;
        notifyListeners();
      }
    });
  }

  void updateBeInviteMode(String teamId, bool needAgree) {
    TeamRepo.updateBeInviteMode(teamId, needAgree).then((value) {
      if (value) {
        beInvitedNeedAgreed = needAgree;
        notifyListeners();
      }
    });
  }

  Future<bool> quitTeam(String teamId) {
    return TeamRepo.quitTeam(teamId);
  }

  Future<bool> dismissTeam(String teamId) {
    return TeamRepo.dismissTeam(teamId);
  }

  Future<bool> updateNickname(String teamId, String nickname) {
    return TeamRepo.updateMemberNick(
            teamId, getIt<LoginService>().userInfo!.userId!, nickname)
        .then((value) {
      if (value) {
        myTeamNickName = nickname;
        notifyListeners();
      }
      return value;
    });
  }

  void addMembers(String teamId, List<String> members) {
    TeamRepo.inviteUser(teamId, members).then((value) {
      if (value.isSuccess &&
          (teamWithMember?.team.type == NIMTeamTypeEnum.normal ||
              !beInvitedNeedAgreed)) {
        requestTeamMembers(teamId);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _teamSub?.cancel();
  }
}
