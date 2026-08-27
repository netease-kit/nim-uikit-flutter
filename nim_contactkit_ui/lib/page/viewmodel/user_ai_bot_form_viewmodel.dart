// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:nim_chatkit/manager/ai_robot_manager.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../user_ai_bot_common.dart';

class UserAIBotFormViewModel extends ChangeNotifier {
  bool isSubmitting = false;
  String? uploadedAvatar;

  Future<NIMResult<String>> uploadAvatar(String filePath) async {
    final result = await uploadUserAIBotAvatar(filePath);
    if (result.isSuccess) {
      uploadedAvatar = result.data;
      notifyListeners();
    }
    return result;
  }

  Future<NIMResult<V2NIMUserAIBot>> createBot({
    required String accid,
    required String name,
    String? icon,
  }) async {
    isSubmitting = true;
    notifyListeners();
    final result = await AIRobotManager.instance.createRobot(
      V2NIMCreateUserAIBotParams(
        accid: accid,
        name: name,
        icon: icon,
      ),
    );
    isSubmitting = false;
    notifyListeners();
    return result;
  }

  Future<NIMResult<V2NIMUserAIBot>> updateBot({
    required String accid,
    required String name,
    String? icon,
  }) async {
    isSubmitting = true;
    notifyListeners();
    final result = await AIRobotManager.instance.updateRobot(
      V2NIMUpdateUserAIBotParams(
        accid: accid,
        name: name,
        icon: icon,
      ),
    );
    isSubmitting = false;
    notifyListeners();
    return result;
  }
}
