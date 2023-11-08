// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:nim_contactkit/repo/contact_repo.dart';
import 'package:nim_core/nim_core.dart';

class TeamListViewModel extends ChangeNotifier {
  List<NIMTeam> teamList = List.empty(growable: true);

  final subscriptions = <StreamSubscription>[];

  void fetchTeamList() {
    ContactRepo.getTeamList().then((value) {
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
        .add(NimCore.instance.teamService.onTeamListRemove.listen((event) {
      for (var e in event) {
        teamList.removeWhere((element) => e.id == element.id);
      }
      notifyListeners();
    }));

    subscriptions
        .add(NimCore.instance.teamService.onTeamListUpdate.listen((event) {
      for (var team in event) {
        int index = teamList.indexWhere((element) => element.id == team.id);
        if (team.isMyTeam == true) {
          if (index >= 0) {
            teamList[index] = team;
          } else {
            teamList.insert(0, team);
          }
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
