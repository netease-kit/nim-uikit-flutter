// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_core_v2/nim_core.dart';

class AIUserListViewModel extends ChangeNotifier {
  List<NIMAIUser> aiUserList = List.empty(growable: true);
  final subscriptions = <StreamSubscription>[];

  void init() {
    getAIUserList();
  }

  void getAIUserList() {
    aiUserList = AIUserManager.instance.getAllAIUsers();
    notifyListeners();
  }
}
