// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:nim_core_v2/nim_core.dart';

class UserAIBotProfileViewModel extends ChangeNotifier {
  V2NIMUserAIBot? bot;
  bool isLoading = false;

  void setBot(V2NIMUserAIBot value) {
    bot = value;
    notifyListeners();
  }

  Future<NIMResult<V2NIMUserAIBot>> fetchBot(String accid) async {
    isLoading = true;
    notifyListeners();
    final result = await NimCore.instance.aiService.getUserAIBot(
      V2NIMGetUserAIBotParams(accid: accid),
    );
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
    final result = await NimCore.instance.aiService.refreshUserAIBotToken(
      V2NIMRefreshUserAIBotTokenParams(accid: accid),
    );
    if (!result.isSuccess) {
      return NIMResult.failure(message: result.errorDetails);
    }
    if (result.data?.token?.isNotEmpty == true) {
      bot?.token = result.data?.token;
    }
    final latest = await fetchBot(accid);
    if (latest.isSuccess && latest.data != null) {
      latest.data!.token = latest.data!.token ?? result.data?.token;
      bot = latest.data;
      notifyListeners();
      return latest;
    }
    notifyListeners();
    return NIMResult.success(data: bot);
  }

  Future<NIMResult<void>> deleteBot() async {
    final accid = bot?.accid;
    if (accid == null || accid.isEmpty) {
      return NIMResult.failure(message: 'invalid accid');
    }
    return NimCore.instance.aiService.deleteUserAIBot(
      V2NIMDeleteUserAIBotParams(accid: accid),
    );
  }
}
