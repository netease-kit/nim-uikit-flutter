// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit_ui/model/history_read_position_tracker.dart';
import 'package:nim_core_v2/nim_core.dart';

void main() {
  group('HistoryReadPositionTracker', () {
    for (final readTime in [0, 100]) {
      test('new chat with visible history start consumes unread ($readTime)',
          () {
        final tracker = HistoryReadPositionTracker()..initialize(readTime);
        expect(tracker.evaluateTopMessage(101, hasReachedHistoryStart: true),
            isTrue);
        expect(tracker.state, HistoryReadPositionState.consumed);
        expect(tracker.evaluateTopMessage(200), isFalse);
        expect(tracker.state, HistoryReadPositionState.consumed);
      });
    }

    test('disables the feature for missing or negative read time', () {
      final tracker = HistoryReadPositionTracker();

      tracker.initialize(null);
      expect(tracker.state, HistoryReadPositionState.disabled);

      tracker.initialize(-1);
      expect(tracker.state, HistoryReadPositionState.disabled);
    });

    test('treats zero read time as a valid history boundary', () {
      final tracker = HistoryReadPositionTracker()..initialize(0);

      expect(tracker.lastReadTime, 0);
      expect(tracker.state, HistoryReadPositionState.evaluating);
      expect(tracker.evaluateTopMessage(1), isTrue);
      expect(tracker.state, HistoryReadPositionState.ready);
      expect(tracker.beginLocation(), isTrue);
    });

    test('shows the entry when the top message is newer', () {
      final tracker = HistoryReadPositionTracker()..initialize(100);

      expect(tracker.evaluateTopMessage(101), isTrue);
      expect(tracker.state, HistoryReadPositionState.ready);
      expect(tracker.evaluateTopMessage(101), isFalse);
    });

    test('consumes the entry when the viewport covers the boundary', () {
      final tracker = HistoryReadPositionTracker()..initialize(100);

      tracker.evaluateTopMessage(100);
      expect(tracker.state, HistoryReadPositionState.consumed);

      expect(tracker.evaluateTopMessage(200), isFalse);
      expect(tracker.state, HistoryReadPositionState.consumed);
    });

    test('restores ready after a failed location', () {
      final tracker = HistoryReadPositionTracker()..initialize(100);
      tracker.evaluateTopMessage(101);

      expect(tracker.beginLocation(), isTrue);
      expect(tracker.state, HistoryReadPositionState.locating);

      tracker.completeLocation(success: false);
      expect(tracker.state, HistoryReadPositionState.ready);
    });

    test('consumes the entry after a successful location', () {
      final tracker = HistoryReadPositionTracker()..initialize(100);
      tracker.evaluateTopMessage(101);

      tracker.beginLocation();
      tracker.completeLocation(success: true);

      expect(tracker.state, HistoryReadPositionState.consumed);
      expect(tracker.beginLocation(), isFalse);
    });

    test('rejects duplicate location and completion transitions', () {
      final tracker = HistoryReadPositionTracker()..initialize(100);
      tracker.evaluateTopMessage(101);

      expect(tracker.beginLocation(), isTrue);
      expect(tracker.beginLocation(), isFalse);
      expect(tracker.completeLocation(success: false), isTrue);
      expect(tracker.completeLocation(success: false), isFalse);
    });

    test('a new page initialization owns a fresh lifecycle', () {
      final tracker = HistoryReadPositionTracker()..initialize(100);
      tracker.evaluateTopMessage(100);
      expect(tracker.state, HistoryReadPositionState.consumed);

      tracker.initialize(200);
      expect(tracker.state, HistoryReadPositionState.evaluating);
      expect(tracker.lastReadTime, 200);
    });

    test('ignores invalid top-message times', () {
      final tracker = HistoryReadPositionTracker()..initialize(100);

      expect(tracker.evaluateTopMessage(0), isFalse);
      expect(tracker.state, HistoryReadPositionState.evaluating);
    });
  });

  test('feature switch defaults on and can disable entry initialization', () {
    expect(IMKitConfigCenter.enableLastReadPosition, isTrue);
    IMKitConfigCenter.enableLastReadPosition = false;
    expect(IMKitConfigCenter.enableLastReadPosition, isFalse);
    IMKitConfigCenter.enableLastReadPosition = true;
  });

  test('supports only normal P2P and Team conversations', () {
    expect(
      supportsHistoryReadPositionConversation(NIMConversationType.p2p),
      isTrue,
    );
    expect(
      supportsHistoryReadPositionConversation(NIMConversationType.team),
      isTrue,
    );
    expect(
      supportsHistoryReadPositionConversation(
        NIMConversationType.p2p,
        isAiUser: true,
      ),
      isFalse,
    );
    expect(
      supportsHistoryReadPositionConversation(
        NIMConversationType.p2p,
        isRobot: true,
      ),
      isFalse,
    );
    expect(
      supportsHistoryReadPositionConversation(
        NIMConversationType.team,
        isTopic: true,
      ),
      isFalse,
    );
    expect(
      supportsHistoryReadPositionConversation(NIMConversationType.superTeam),
      isFalse,
    );
  });
}
