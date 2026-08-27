// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../user_ai_bot_common.dart';

class UserAIBotListViewModel extends ChangeNotifier {
  final List<V2NIMUserAIBot> bots = [];

  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = false;
  String? nextToken;
  String? error;

  Future<void> init() async {
    await refresh();
  }

  Future<void> refresh() async {
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
      hasMore = result.data?.hasMore ?? false;
      nextToken = result.data?.nextToken;
    } else {
      error = result.errorDetails;
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!hasMore || nextToken == null || isLoadingMore) {
      return;
    }
    isLoadingMore = true;
    notifyListeners();
    final result = await NimCore.instance.aiService.getUserAIBotList(
      V2NIMGetUserAIBotListParams(
        pageToken: nextToken,
        limit: kUserAIBotPageLimit,
      ),
    );
    if (result.isSuccess) {
      bots.addAll(result.data?.bots ?? const []);
      sortUserAIBotsByCreateTimeDesc(bots);
      hasMore = result.data?.hasMore ?? false;
      nextToken = result.data?.nextToken;
    } else {
      error = result.errorDetails;
    }
    isLoadingMore = false;
    notifyListeners();
  }

  void showCachedBots(List<V2NIMUserAIBot> cachedBots) {
    bots
      ..clear()
      ..addAll(cachedBots);
    sortUserAIBotsByCreateTimeDesc(bots);
    hasMore = false;
    nextToken = null;
    error = null;
    notifyListeners();
  }

  void upsertBot(V2NIMUserAIBot bot) {
    final index = bots.indexWhere((item) => item.accid == bot.accid);
    if (index >= 0) {
      bots[index] = bot;
    } else {
      bots.add(bot);
    }
    sortUserAIBotsByCreateTimeDesc(bots);
    notifyListeners();
  }

  void removeBot(String accid) {
    bots.removeWhere((item) => item.accid == accid);
    notifyListeners();
  }
}
