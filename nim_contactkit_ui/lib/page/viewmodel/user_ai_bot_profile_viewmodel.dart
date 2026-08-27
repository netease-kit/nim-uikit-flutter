// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:nim_chatkit/manager/ai_robot_manager.dart';
import 'package:nim_core_v2/nim_core.dart';

class UserAIBotProfileViewModel extends ChangeNotifier {
  V2NIMUserAIBot? bot;
  bool isLoading = false;

  void setBot(V2NIMUserAIBot value) {
    bot = value;
    AIRobotManager.instance.upsertRobot(value);
    notifyListeners();
  }

  Future<NIMResult<V2NIMUserAIBot>> fetchBot(String accid) async {
    isLoading = true;
    notifyListeners();
    final result = await AIRobotManager.instance.fetchRobot(accid);
    if (result.isSuccess) {
      bot = result.data;
    }
    isLoading = false;
    notifyListeners();
    return result;
  }

  Future<NIMResult<V2NIMUserAIBot>> refreshToken() async {
    final accid = bot?.accid;
    if (accid == null || accid.isEmpty) {
      return NIMResult.failure(message: 'invalid accid');
    }
    final result = await AIRobotManager.instance.refreshRobotToken(accid);
    if (result.isSuccess && result.data != null) {
      bot = result.data;
      notifyListeners();
    }
    return result;
  }

  Future<NIMResult<void>> deleteBot() async {
    final accid = bot?.accid;
    if (accid == null || accid.isEmpty) {
      return NIMResult.failure(message: 'invalid accid');
    }
    return AIRobotManager.instance.deleteRobot(accid);
  }
}
