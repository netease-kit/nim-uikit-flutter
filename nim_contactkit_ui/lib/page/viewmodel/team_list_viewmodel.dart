// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:nim_chatkit/repo/team_repo.dart';
import 'package:nim_core_v2/nim_core.dart';

class TeamListViewModel extends ChangeNotifier {
  List<NIMTeam> teamList = List.empty(growable: true);

  final subscriptions = <StreamSubscription>[];

  void fetchTeamList() {
    TeamRepo.getJoinedTeamList().then((value) {
      if (value.isSuccess && value.data != null) {
        teamList = value.data!;
        teamList.sort((a, b) => b.createTime.compareTo(a.createTime));
        notifyListeners();
      }
    });
  }

  void init() {
    fetchTeamList();
    subscriptions
        .add(NimCore.instance.teamService.onTeamDismissed.listen((event) {
      teamList.removeWhere((element) => event.teamId == element.teamId);
      notifyListeners();
    }));

    subscriptions.add(NimCore.instance.teamService.onTeamLeft.listen((event) {
      teamList.removeWhere((element) => event.team.teamId == element.teamId);
      notifyListeners();
    }));

    subscriptions
        .add(NimCore.instance.teamService.onTeamCreated.listen((event) {
      int index =
          teamList.indexWhere((element) => element.teamId == event.teamId);
      if (event.isValidTeam == true) {
        if (index >= 0) {
          teamList[index] = event;
        } else {
          teamList.insert(0, event);
        }
      }
      notifyListeners();
    }));

    subscriptions.add(NimCore.instance.teamService.onTeamJoined.listen((event) {
      int index =
          teamList.indexWhere((element) => element.teamId == event.teamId);
      if (event.isValidTeam == true) {
        if (index >= 0) {
          teamList[index] = event;
        } else {
          teamList.insert(0, event);
        }
      }
      notifyListeners();
    }));

    subscriptions
        .add(NimCore.instance.teamService.onTeamInfoUpdated.listen((event) {
      int index =
          teamList.indexWhere((element) => element.teamId == event.teamId);
      if (event.isValidTeam == true) {
        if (index >= 0) {
          teamList[index] = event;
        } else {
          teamList.insert(0, event);
        }
      }
      notifyListeners();
    }));
  }

  @override
  void dispose() {
    super.dispose();
    for (var sub in subscriptions) {
      sub.cancel();
    }
  }
}
