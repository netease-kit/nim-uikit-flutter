// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:nim_core_v2/nim_core.dart';

enum HistoryReadPositionState {
  disabled,
  evaluating,
  ready,
  locating,
  consumed,
}

bool supportsHistoryReadPositionConversation(
  NIMConversationType conversationType, {
  bool isAiUser = false,
  bool isRobot = false,
  bool isTopic = false,
}) {
  if (isTopic) return false;
  if (conversationType == NIMConversationType.team) return true;
  return conversationType == NIMConversationType.p2p && !isAiUser && !isRobot;
}

class HistoryReadPositionTracker {
  HistoryReadPositionState state = HistoryReadPositionState.disabled;
  int? lastReadTime;

  void initialize(int? readTime) {
    if (readTime == null || readTime < 0) {
      lastReadTime = null;
      state = HistoryReadPositionState.disabled;
      return;
    }
    lastReadTime = readTime;
    state = HistoryReadPositionState.evaluating;
  }

  bool evaluateTopMessage(int createTime,
      {bool hasReachedHistoryStart = false}) {
    if ((state != HistoryReadPositionState.evaluating &&
            state != HistoryReadPositionState.ready) ||
        lastReadTime == null ||
        createTime <= 0) {
      return false;
    }
    final nextState = hasReachedHistoryStart || createTime <= lastReadTime!
        ? HistoryReadPositionState.consumed
        : HistoryReadPositionState.ready;
    if (state == nextState) {
      return false;
    }
    state = nextState;
    return true;
  }

  bool beginLocation() {
    if (state != HistoryReadPositionState.ready) {
      return false;
    }
    state = HistoryReadPositionState.locating;
    return true;
  }

  bool completeLocation({required bool success}) {
    if (state != HistoryReadPositionState.locating) {
      return false;
    }
    state = success
        ? HistoryReadPositionState.consumed
        : HistoryReadPositionState.ready;
    return true;
  }
}
