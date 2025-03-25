// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import 'package:nim_core_v2/nim_core.dart';

class BlackListViewModel extends ChangeNotifier {
  List<NIMUserInfo> blackListUsers = List.empty(growable: true);
  final subscriptions = <StreamSubscription>[];
  void init() {
    fetchBlackList();

    // 断网重连，重新拉取数据
    NimCore.instance.loginService.onDataSync.listen((event) {
      if (event.type == NIMDataSyncType.nimDataSyncMain &&
          event.state == NIMDataSyncState.nimDataSyncStateCompleted) {
        fetchBlackList();
      }
    });

    subscriptions
        .add(ContactRepo.registerBlackListRemovedObserver().listen((event) {
      blackListUsers.removeWhere((element) => event == element.accountId);
      notifyListeners();
    }));

    subscriptions
        .add(ContactRepo.registerBlackListAddedObserver().listen((event) {
      int index = blackListUsers
          .indexWhere((element) => element.accountId == event.accountId);
      if (index >= 0) {
        blackListUsers[index] = event;
      } else {
        blackListUsers.add(event);
      }
      notifyListeners();
    }));

    subscriptions
        .add(ContactRepo.registerFriendInfoChangedObserver().listen((event) {
      int index = blackListUsers
          .indexWhere((element) => element.accountId == event.accountId);
      if (index >= 0 && blackListUsers[index].name != event.alias) {
        blackListUsers[index].name = event.alias;
      }
      notifyListeners();
    }));

    subscriptions
        .add(ContactRepo.registerUserProfileChangedObserver().listen((event) {
      for (var e in event) {
        int index = blackListUsers
            .indexWhere((element) => element.accountId == e.accountId);
        if (index >= 0) {
          blackListUsers[index] = e;
        }
      }
      notifyListeners();
    }));
  }

  void fetchBlackList() {
    ContactRepo.getBlackList().then((value) {
      if (value.isNotEmpty) {
        blackListUsers.clear();
        blackListUsers.addAll(value);
        notifyListeners();
      }
    });
  }

  Future<void> removeFromBlackList(String userId) async {
    if (await haveConnectivity()) {
      ContactRepo.removeBlacklist(userId);
    }
  }

  void addToBlackList(String userId) {
    ContactRepo.addBlacklist(userId);
  }

  void addUserListToBlackList(List<String> users) {
    users.forEach((e) {
      addToBlackList(e);
    });
  }
}
