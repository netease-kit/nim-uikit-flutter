// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit_ui/model/history_read_position_viewport.dart';

void main() {
  const viewport = Rect.fromLTWH(0, 100, 300, 400);

  test('short history fully in the viewport reaches the history start', () {
    expect(
      isHistoryStartVisible(viewport, const Rect.fromLTWH(0, 110, 300, 50),
          hasMoreOlderMessages: false),
      isTrue,
    );
  });

  test('visible oldest loaded message is not the start while more pages exist',
      () {
    expect(
      isHistoryStartVisible(viewport, const Rect.fromLTWH(0, 110, 300, 50),
          hasMoreOlderMessages: true),
      isFalse,
    );
  });

  test('does not consume when the oldest message is missing or clipped above',
      () {
    for (final rect in <Rect?>[
      null,
      const Rect.fromLTWH(0, 80, 300, 80),
      const Rect.fromLTWH(0, 510, 300, 80),
      Rect.zero,
    ]) {
      expect(isHistoryStartVisible(viewport, rect, hasMoreOlderMessages: false),
          isFalse);
    }
  });

  test('returns the top-most visible message', () {
    final index = findTopVisibleHistoryMessageIndex(viewport, const {
      0: Rect.fromLTWH(0, 520, 300, 80),
      1: Rect.fromLTWH(0, 80, 300, 60),
      2: Rect.fromLTWH(0, 140, 300, 120),
    });

    expect(index, 1);
  });

  test('re-evaluates correctly after a dynamic-height layout change', () {
    final before = findTopVisibleHistoryMessageIndex(viewport, const {
      0: Rect.fromLTWH(0, 90, 300, 40),
      1: Rect.fromLTWH(0, 130, 300, 80),
    });
    final after = findTopVisibleHistoryMessageIndex(viewport, const {
      0: Rect.fromLTWH(0, -40, 300, 140),
      1: Rect.fromLTWH(0, 100, 300, 80),
    });

    expect(before, 0);
    expect(after, 1);
  });

  test('returns null when no real message overlaps the viewport', () {
    final index = findTopVisibleHistoryMessageIndex(viewport, const {
      0: Rect.fromLTWH(0, 0, 300, 80),
      1: Rect.fromLTWH(0, 520, 300, 80),
    });

    expect(index, isNull);
  });
}
