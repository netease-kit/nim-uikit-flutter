// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:contactkit/repo/contact_repo.dart';
import 'package:flutter/cupertino.dart';
import 'package:nim_core/nim_core.dart';

class BlackListViewModel extends ChangeNotifier {
  List<NIMUser> blackListUsers = List.empty(growable: true);

  void fetchBlackList() {
    ContactRepo.getBlackList().then((value) {
      if (value.isNotEmpty) {
        blackListUsers.addAll(value);
        notifyListeners();
      }
    });
  }

  void removeFromBlackList(String userId) {
    ContactRepo.removeBlacklist(userId).then((result) {
      if (result.isSuccess) {
        blackListUsers.removeWhere((e) => e.userId == userId);
        notifyListeners();
      }
    });
  }

  void addToBlackList(String userId) {
    ContactRepo.addBlacklist(userId).then((value) {
      if (value.isSuccess) {
        NimCore.instance.userService.getUserInfo(userId).then((value) {
          if (value.isSuccess && value.data != null) {
            blackListUsers.add(value.data!);
            notifyListeners();
          }
        });
      }
    });
  }

  void addUserListToBlackList(List<String> users) {
    users.forEach((e) {
      addToBlackList(e);
    });
  }
}
