// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../user_ai_bot_common.dart';

class UserAIBotBindingViewModel extends ChangeNotifier {
  final List<V2NIMUserAIBot> bots = [];
  bool isLoading = false;
  String? error;

  void addBot(V2NIMUserAIBot bot) {
    final index = bots.indexWhere((item) => item.accid == bot.accid);
    if (index >= 0) {
      bots[index] = bot;
    } else {
      bots.add(bot);
    }
    sortUserAIBotsByCreateTimeDesc(bots);
    notifyListeners();
  }

  bool get hasReachedLimit => bots.length >= kMaxUserAIBotCount;

  Future<void> loadBots() async {
    isLoading = true;
    error = null;
    notifyListeners();
    final result = await NimCore.instance.aiService.getUserAIBotList(
      V2NIMGetUserAIBotListParams(limit: kUserAIBotPageLimit),
    );
    if (result.isSuccess) {
      bots
        ..clear()
        ..addAll(result.data?.bots ?? const []);
      sortUserAIBotsByCreateTimeDesc(bots);
    } else {
      error = result.errorDetails;
    }
    isLoading = false;
    notifyListeners();
  }

  Future<NIMResult<V2NIMUserAIBot>> bind(
    String qrCode,
    V2NIMUserAIBot bot,
  ) async {
    final accid = bot.accid;
    if (accid == null || accid.isEmpty) {
      return NIMResult.failure(message: 'no selected bot');
    }
    var selected = bot;
    var token = selected.token;
    if (token == null || token.isEmpty) {
      final detail = await NimCore.instance.aiService.getUserAIBot(
        V2NIMGetUserAIBotParams(accid: accid),
      );
      if (!detail.isSuccess || detail.data == null) {
        return NIMResult.failure(
          code: detail.code,
          message: detail.errorDetails,
        );
      }
      token = detail.data!.token;
      if (token?.isEmpty ?? true) {
        return NIMResult.failure(message: 'token unavailable');
      }
      final index = bots.indexWhere((item) => item.accid == selected.accid);
      if (index >= 0) {
        bots[index] = detail.data!;
      }
      selected = detail.data!;
    }
    final bindResult = await NimCore.instance.aiService.bindUserAIBotToQrCode(
      V2NIMBindUserAIBotToQrCodeParams(
        accid: accid,
        token: token,
        qrCode: qrCode,
      ),
    );
    if (!bindResult.isSuccess) {
      return NIMResult.failure(
        code: bindResult.code,
        message: bindResult.errorDetails,
      );
    }
    final latest = await NimCore.instance.aiService.getUserAIBot(
      V2NIMGetUserAIBotParams(accid: accid),
    );
    if (latest.isSuccess && latest.data != null) {
      return latest;
    }
    return NIMResult.success(data: selected);
  }
}
