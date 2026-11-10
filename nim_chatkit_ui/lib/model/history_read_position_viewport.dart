// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:ui';

/// 没有更早分页且最早消息的顶部已进入视口，表示已看到历史起点。
bool isHistoryStartVisible(
  Rect viewportRect,
  Rect? oldestMessageRect, {
  required bool hasMoreOlderMessages,
}) {
  return !hasMoreOlderMessages &&
      oldestMessageRect != null &&
      oldestMessageRect.overlaps(viewportRect) &&
      oldestMessageRect.top >= viewportRect.top;
}

/// 返回视口中顶部最靠前的真实消息索引。
int? findTopVisibleHistoryMessageIndex(
  Rect viewportRect,
  Map<int, Rect> messageRects,
) {
  int? topIndex;
  var top = double.infinity;
  for (final entry in messageRects.entries) {
    final rect = entry.value;
    if (rect.overlaps(viewportRect) && rect.top < top) {
      top = rect.top;
      topIndex = entry.key;
    }
  }
  return topIndex;
}
