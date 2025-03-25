// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_corekit_im/model/team_models.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/im_login_service.dart';
import 'package:netease_corekit_im/services/message/nim_chat_cache.dart';
import 'package:nim_chatkit/repo/conversation_repo.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:nim_chatkit/repo/team_repo.dart';

class TeamSettingViewModel extends ChangeNotifier {
  //当前用户在群里的身份
  TeamWithMember? teamWithMember;
  List<UserInfoWithTeam>? userInfoData;

  List<UserInfoWithTeam>? filterList;

  List<UserInfoWithTeam> selectedList = List.empty(growable: true);

  //群通知
  bool messageTip = true;
  //置顶
  bool isStick = false;
  //禁言
  bool muteAllMember = false;
  //邀请
  NIMTeamInviteMode? inviteMode;
  //更改
  NIMTeamUpdateInfoMode? updateInfoMode;
  bool agreeMode = false;
  String? myTeamNickName;
  //搜索关键字
  String? _searchKey;

  List<StreamSubscription> _teamSub = List.empty(growable: true);

  void requestTeamData(String teamId) async {
    final teamInfo = await TeamRepo.getTeamInfo(teamId, NIMTeamType.typeNormal);
    if (teamInfo != null) {
      final teamMember = await NIMChatCache.instance.getMyTeamMember(teamId);
      teamWithMember = TeamWithMember(teamInfo, teamMember?.teamInfo);
    }

    isStick = await TeamRepo.isStickTop(teamId, NIMTeamType.typeNormal);

    messageTip = await TeamRepo.getTeamNotify(teamId);
    muteAllMember = (teamWithMember?.team.chatBannedMode ==
            NIMTeamChatBannedMode.chatBannedModeBannedNormal) ||
        (teamWithMember?.team.chatBannedMode ==
            NIMTeamChatBannedMode.chatBannedModeBannedAll);
    inviteMode = teamWithMember?.team.inviteMode;
    updateInfoMode = teamWithMember?.team.updateInfoMode;
    agreeMode =
        teamWithMember?.team.agreeMode == NIMTeamAgreeMode.agreeModeNoAuth;
    myTeamNickName = teamWithMember?.teamMember?.teamNick;
    notifyListeners();
  }

  void requestTeamMembers(String teamId) async {
    //先从缓存中获取
    userInfoData = NIMChatCache.instance.teamMembers;
    if (userInfoData?.isNotEmpty != true) {
      NIMChatCache.instance.fetchTeamMember(teamId);
    }
    filterList = userInfoData;
    notifyListeners();
  }

  void addTeamSubscribe() {
    _teamSub.add(TeamRepo.registerTeamUpdateObserver().listen((team) {
      if (team.teamId == teamWithMember?.team.teamId) {
        teamWithMember?.team = team;
        notifyListeners();
      }
    }));

    _teamSub.addAll([
      NIMChatCache.instance.teamMembersNotifier.listen((event) {
        userInfoData = event;
        //更新完毕后重新排序,可能有新成员加入
        filterByText(_searchKey);
        //移除选择列表中不存在的成员
        if (selectedList.isNotEmpty) {
          var allMembers =
              userInfoData?.map((e) => e.teamInfo.accountId).toList();
          selectedList.removeWhere(
              (element) => !allMembers!.contains(element.teamInfo.accountId));
        }
        notifyListeners();
      }),
    ]);
  }

  void addSelected(UserInfoWithTeam userInfoWithTeam) {
    selectedList.add(userInfoWithTeam);
    notifyListeners();
  }

  void removeSelected(UserInfoWithTeam userInfoWithTeam) {
    selectedList.remove(userInfoWithTeam);
    notifyListeners();
  }

  bool isSelected(UserInfoWithTeam userInfoWithTeam) {
    return selectedList.contains(userInfoWithTeam);
  }

  void addTeamManager(String tid, List<String> accounts) {
    TeamRepo.addTeamManager(tid, NIMTeamType.typeNormal, accounts)
        .then((value) {});
  }

  Future<NIMResult<void>> removeTeamManager(String tid, String accId) {
    return TeamRepo.removeTeamManager(tid, NIMTeamType.typeNormal, [accId]);
  }

  Future<NIMResult<void>> removeTeamMember(String tid, String accId) {
    return TeamRepo.removeTeamMembers(tid, NIMTeamType.typeNormal, [accId]);
  }

  void filterByText(String? filterStr) {
    _searchKey = filterStr;
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
      return false;
    }).toList();
    filterResult?.sort((a, b) {
      if (a.teamInfo.memberRole == NIMTeamMemberRole.memberRoleOwner) {
        return -1;
      } else if (b.teamInfo.memberRole == NIMTeamMemberRole.memberRoleOwner) {
        return 1;
      } else if (a.teamInfo.memberRole == NIMTeamMemberRole.memberRoleManager &&
          b.teamInfo.memberRole != NIMTeamMemberRole.memberRoleManager) {
        return -1;
      } else if (a.teamInfo.memberRole != NIMTeamMemberRole.memberRoleManager &&
          b.teamInfo.memberRole == NIMTeamMemberRole.memberRoleManager) {
        return 1;
      } else if (a.teamInfo.joinTime == 0) {
        return 1;
      } else if (b.teamInfo.joinTime == 0) {
        return -1;
      }
      return a.teamInfo.joinTime - b.teamInfo.joinTime;
    });
    filterList = filterResult;
    notifyListeners();
  }

  Future<void> muteTeam(String teamId, bool mute) async {
    if (!(await haveConnectivity())) {
      return;
    }

    TeamRepo.updateTeamNotify(teamId, mute).then((value) {
      if (!value) {
        messageTip = mute;
        notifyListeners();
      }
    });
    messageTip = !mute;
    notifyListeners();
  }

  Future<void> configStick(String teamId, bool stick) async {
    if (!(await haveConnectivity())) {
      return;
    }

    if (stick) {
      TeamRepo.addStickTop(teamId).then((value) {
        if (!value.isSuccess) {
          isStick = false;
          notifyListeners();
        }
      });
    } else {
      TeamRepo.removeStickTop(teamId).then((value) {
        if (!value.isSuccess) {
          isStick = true;
          notifyListeners();
        }
      });
    }
    isStick = stick;
    notifyListeners();
  }

  Future<void> muteTeamAllMember(String teamId, bool mute) async {
    if (!(await haveConnectivity())) {
      return;
    }

    TeamRepo.muteAllMembers(teamId, mute).then((value) {
      if (value) {
        muteAllMember = mute;
        notifyListeners();
      }
    });
  }

  void updateInvitePrivilege(String teamId, NIMTeamInviteMode modeEnum) {
    TeamRepo.updateInviteMode(teamId, NIMTeamType.typeNormal, modeEnum)
        .then((value) {
      if (value) {
        inviteMode = modeEnum;
        notifyListeners();
      }
    });
  }

  void updateInfoPrivilege(String teamId, NIMTeamUpdateInfoMode modeEnum) {
    TeamRepo.updateTeamInfoPrivilege(teamId, NIMTeamType.typeNormal, modeEnum)
        .then((value) {
      if (value) {
        updateInfoMode = modeEnum;
        notifyListeners();
      }
    });
  }

  void updateBeInviteMode(String teamId, bool needAgree) {
    TeamRepo.updateBeInviteMode(teamId, NIMTeamType.typeNormal, needAgree)
        .then((value) {
      if (value) {
        agreeMode = needAgree;
        notifyListeners();
      }
    });
  }

  Future<bool> quitTeam(String teamId) async {
    if (await haveConnectivity()) {
      return TeamRepo.quitTeam(
        teamId,
        NIMTeamType.typeNormal,
      );
    } else {
      return Future(() => false);
    }
  }

  Future<bool> dismissTeam(String teamId) async {
    if (await haveConnectivity()) {
      return TeamRepo.dismissTeam(
        teamId,
        NIMTeamType.typeNormal,
      );
    } else {
      return Future(() => false);
    }
  }

  Future<bool> updateNickname(String teamId, String nickname) {
    return TeamRepo.updateMemberNick(teamId, NIMTeamType.typeNormal,
            getIt<IMLoginService>().userInfo!.accountId!, nickname)
        .then((value) {
      if (value) {
        myTeamNickName = nickname;
        notifyListeners();
      }
      return value;
    });
  }

  Future<NIMResult<List<String>>> addMembers(
      String teamId, List<String> members) {
    return TeamRepo.inviteUser(teamId, NIMTeamType.typeNormal, members, null);
  }

  @override
  void dispose() {
    super.dispose();
    for (var sub in _teamSub) {
      sub.cancel();
    }
  }
}
