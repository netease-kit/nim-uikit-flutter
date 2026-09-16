// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:nim_chatkit/model/team_models.dart';
import 'package:nim_chatkit/repo/team_repo.dart';
import 'package:nim_chatkit/repo/team_member_search_repository.dart';
import 'package:nim_chatkit/model/user_search_models.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_chatkit/services/message/nim_chat_cache.dart';
import 'package:nim_core_v2/nim_core.dart';

class TeamSettingViewModel extends ChangeNotifier {
  final String? configuredTeamId;

  TeamSettingViewModel({this.configuredTeamId});

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
  String get searchKey => _searchKey ?? '';
  int _searchGeneration = 0;
  int _memberRequestGeneration = 0;
  final Map<String, UserInfoWithTeam> _privilegedMembers = {};
  final Set<String> _removedDuringSearch = {};
  bool _disposed = false;
  bool isFilterLoading = false;
  bool isFilterError = false;

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
    if (!_disposed) notifyListeners();
  }

  void requestTeamMembers(String teamId) {
    final effectiveTeamId = configuredTeamId ?? teamId;
    final generation = ++_memberRequestGeneration;
    //先从缓存中获取
    final cachedMembers = NIMChatCache.instance.teamMembers;
    _updatePrivilegedMembers(cachedMembers);
    userInfoData = _mergePrivilegedMembers(cachedMembers);
    if (cachedMembers.isEmpty) {
      NIMChatCache.instance.fetchTeamMember(effectiveTeamId);
    }
    filterList = userInfoData;
    if (!_disposed) notifyListeners();
    unawaited(_loadPrivilegedMembers(effectiveTeamId, generation));
  }

  Future<void> _loadPrivilegedMembers(String teamId, int generation) async {
    try {
      final firstMember =
          userInfoData?.isNotEmpty == true ? userInfoData!.first : null;
      final teamType = teamWithMember?.team.teamType ??
          firstMember?.teamInfo.teamType ??
          NIMTeamType.typeNormal;
      final members = await getIt<TeamMemberSearchRepository>().loadAll(
        teamId,
        teamType,
        roleQueryType: NIMTeamMemberRoleQueryType.memberRoleQueryTypeManager,
      );
      if (_disposed || generation != _memberRequestGeneration) return;
      _privilegedMembers
        ..clear()
        ..addEntries(
          members.map(
            (member) => MapEntry(member.teamInfo.accountId, member),
          ),
        );
      userInfoData = _mergePrivilegedMembers(
        userInfoData ?? NIMChatCache.instance.teamMembers,
      );
      if (searchKey.isEmpty) {
        filterList = userInfoData;
      } else if (!isFilterLoading) {
        _filterLocal(searchKey, _searchGeneration);
      }
      notifyListeners();
    } catch (_) {
      // Keep the normal paged member list usable if the role query fails.
    }
  }

  void _updatePrivilegedMembers(Iterable<UserInfoWithTeam> members) {
    for (final member in members) {
      final accountId = member.teamInfo.accountId;
      if (member.teamInfo.memberRole == NIMTeamMemberRole.memberRoleOwner ||
          member.teamInfo.memberRole == NIMTeamMemberRole.memberRoleManager) {
        _privilegedMembers[accountId] = member;
      } else {
        _privilegedMembers.remove(accountId);
      }
    }
  }

  List<UserInfoWithTeam> _mergePrivilegedMembers(
    Iterable<UserInfoWithTeam> members,
  ) {
    final merged = <String, UserInfoWithTeam>{
      for (final member in members) member.teamInfo.accountId: member,
      ..._privilegedMembers,
    };
    return sortList(merged.values.toList()) ?? <UserInfoWithTeam>[];
  }

  void addTeamSubscribe() {
    _teamSub.add(
      TeamRepo.registerTeamUpdateObserver().listen((team) {
        if (team.teamId == teamWithMember?.team.teamId) {
          teamWithMember?.team = team;
          notifyListeners();
        }
      }),
    );

    _teamSub.addAll([
      NIMChatCache.instance.teamMembersNotifier.listen((event) {
        _updatePrivilegedMembers(event);
        final mergedEvent = _mergePrivilegedMembers(event);
        final accountIds =
            mergedEvent.map((member) => member.teamInfo.accountId).toSet();
        final removedAccountIds = userInfoData
                ?.map((member) => member.teamInfo.accountId)
                .where((accountId) => !accountIds.contains(accountId))
                .toSet() ??
            <String>{};
        final teamId = configuredTeamId ??
            teamWithMember?.team.teamId ??
            (userInfoData?.isNotEmpty == true
                ? userInfoData!.first.teamInfo.teamId
                : event.isNotEmpty
                    ? event.first.teamInfo.teamId
                    : null);
        if (teamId != null) {
          getIt<TeamMemberSearchRepository>().invalidate(teamId);
        }
        userInfoData = mergedEvent;
        if (searchKey.isNotEmpty && filterList != null && !isFilterLoading) {
          // 普通成员缓存可能只加载了部分分页，保留其他分页中的搜索结果。
          final members = {
            for (final member in filterList!)
              if (!removedAccountIds.contains(member.teamInfo.accountId))
                member.teamInfo.accountId: member,
            for (final member in mergedEvent) member.teamInfo.accountId: member,
          };
          _filterLocal(searchKey, _searchGeneration, members: members.values);
        } else {
          filterByText(_searchKey);
        }
        //移除选择列表中不存在的成员
        if (selectedList.isNotEmpty) {
          var allMembers =
              userInfoData?.map((e) => e.teamInfo.accountId).toList();
          selectedList.removeWhere(
            (element) => !allMembers!.contains(element.teamInfo.accountId),
          );
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

  void clearAllSelected() {
    selectedList.clear();
    notifyListeners();
  }

  bool isSelected(UserInfoWithTeam userInfoWithTeam) {
    return selectedList.contains(userInfoWithTeam);
  }

  void addTeamManager(String tid, List<String> accounts) {
    TeamRepo.addTeamManager(
      tid,
      NIMTeamType.typeNormal,
      accounts,
    ).then((value) {});
  }

  Future<NIMResult<void>> removeTeamManager(String tid, String accId) {
    return TeamRepo.removeTeamManager(tid, NIMTeamType.typeNormal, [accId]);
  }

  Future<NIMResult<void>> removeTeamMember(String tid, String accId) async {
    final result =
        await TeamRepo.removeTeamMembers(tid, NIMTeamType.typeNormal, [accId]);
    if (result.isSuccess) {
      _privilegedMembers.remove(accId);
      getIt<TeamMemberSearchRepository>().invalidate(tid);
      if (!_disposed) {
        userInfoData = userInfoData
            ?.where((member) => member.teamInfo.accountId != accId)
            .toList();
        selectedList
            .removeWhere((member) => member.teamInfo.accountId == accId);
        filterList = filterList
            ?.where((member) => member.teamInfo.accountId != accId)
            .toList();
        if (isFilterLoading) _removedDuringSearch.add(accId);
        notifyListeners();
      }
    }
    return result;
  }

  void filterByText(String? filterStr) {
    final query = filterStr?.trim() ?? '';
    _searchKey = query;
    final generation = ++_searchGeneration;
    _removedDuringSearch.clear();
    if (query.isEmpty) {
      isFilterLoading = false;
      isFilterError = false;
      //过滤关键字为空时显示所有成员
      filterList = userInfoData;
      notifyListeners();
      return;
    }
    final firstMember =
        userInfoData?.isNotEmpty == true ? userInfoData!.first : null;
    final teamId = configuredTeamId ??
        teamWithMember?.team.teamId ??
        firstMember?.teamInfo.teamId;
    if (teamId == null || teamId.isEmpty) {
      _filterLocal(query, generation);
      return;
    }
    final teamType = teamWithMember?.team.teamType ??
        firstMember?.teamInfo.teamType ??
        NIMTeamType.typeNormal;
    isFilterLoading = true;
    isFilterError = false;
    filterList = null;
    notifyListeners();
    unawaited(_filterMembers(teamId, teamType, query, generation));
  }

  Future<void> _filterMembers(
    String teamId,
    NIMTeamType teamType,
    String query,
    int generation,
  ) async {
    try {
      final members = await getIt<TeamMemberSearchRepository>().loadAll(
        teamId,
        teamType,
      );
      if (_disposed || generation != _searchGeneration || _searchKey != query) {
        return;
      }
      final matches = UserSearchService.search<UserInfoWithTeam>(
        values: members.where(
          (member) => !_removedDuringSearch.contains(member.teamInfo.accountId),
        ),
        fieldsOf: UserSearchService.teamMemberFields,
        accountIdOf: (member) => member.teamInfo.accountId,
        query: query,
      );
      filterList = matches.map((match) => match.value).toList();
      isFilterLoading = false;
      isFilterError = false;
      notifyListeners();
    } catch (_) {
      if (_disposed || generation != _searchGeneration || _searchKey != query) {
        return;
      }
      isFilterLoading = false;
      isFilterError = true;
      filterList = null;
      notifyListeners();
    }
  }

  void _filterLocal(
    String query,
    int generation, {
    Iterable<UserInfoWithTeam>? members,
  }) {
    final values = UserSearchService.search<UserInfoWithTeam>(
      values: members ?? userInfoData ?? const <UserInfoWithTeam>[],
      fieldsOf: UserSearchService.teamMemberFields,
      accountIdOf: (member) => member.teamInfo.accountId,
      query: query,
    );
    if (_disposed || generation != _searchGeneration) return;
    filterList = values.map((match) => match.value).toList();
    isFilterLoading = false;
    isFilterError = false;
    notifyListeners();
  }

  /// Retries the latest full-member search after a loading failure.
  void retryFilter() {
    if (_searchKey?.isNotEmpty == true && !isFilterLoading) {
      filterByText(_searchKey);
    }
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
    TeamRepo.updateInviteMode(teamId, NIMTeamType.typeNormal, modeEnum).then((
      value,
    ) {
      if (value) {
        inviteMode = modeEnum;
        notifyListeners();
      }
    });
  }

  void updateInfoPrivilege(String teamId, NIMTeamUpdateInfoMode modeEnum) {
    TeamRepo.updateTeamInfoPrivilege(
      teamId,
      NIMTeamType.typeNormal,
      modeEnum,
    ).then((value) {
      if (value) {
        updateInfoMode = modeEnum;
        notifyListeners();
      }
    });
  }

  void updateBeInviteMode(String teamId, bool needAgree) {
    TeamRepo.updateBeInviteMode(teamId, NIMTeamType.typeNormal, needAgree).then(
      (value) {
        if (value) {
          agreeMode = needAgree;
          notifyListeners();
        }
      },
    );
  }

  Future<bool> quitTeam(String teamId) async {
    if (await haveConnectivity()) {
      return TeamRepo.quitTeam(teamId, NIMTeamType.typeNormal);
    } else {
      return Future(() => false);
    }
  }

  Future<bool> dismissTeam(String teamId) async {
    if (await haveConnectivity()) {
      return TeamRepo.dismissTeam(teamId, NIMTeamType.typeNormal);
    } else {
      return Future(() => false);
    }
  }

  Future<bool> updateNickname(String teamId, String nickname) {
    return TeamRepo.updateMemberNick(
      teamId,
      NIMTeamType.typeNormal,
      getIt<IMLoginService>().userInfo!.accountId!,
      nickname,
    ).then((value) {
      if (value) {
        myTeamNickName = nickname;
        notifyListeners();
      }
      return value;
    });
  }

  Future<NIMResult<List<String>>> addMembers(
    String teamId,
    List<String> members,
  ) {
    return TeamRepo.inviteUser(teamId, NIMTeamType.typeNormal, members, null);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
    for (var sub in _teamSub) {
      sub.cancel();
    }
  }
}
