// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit_ui/model/history_read_position_tracker.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/history_read_position_entry.dart';

void main() {
  test('shows only for a positive ready or locating non-multiselect state', () {
    expect(
      shouldShowHistoryReadPositionEntry(
        state: HistoryReadPositionState.ready,
        count: 1,
        isMultiSelected: false,
      ),
      isTrue,
    );
    expect(
      shouldShowHistoryReadPositionEntry(
        state: HistoryReadPositionState.locating,
        count: 100,
        isMultiSelected: false,
      ),
      isTrue,
    );
    for (final hidden in <bool>[
      shouldShowHistoryReadPositionEntry(
        state: HistoryReadPositionState.disabled,
        count: 1,
        isMultiSelected: false,
      ),
      shouldShowHistoryReadPositionEntry(
        state: HistoryReadPositionState.ready,
        count: 0,
        isMultiSelected: false,
      ),
      shouldShowHistoryReadPositionEntry(
        state: HistoryReadPositionState.ready,
        count: 1,
        isMultiSelected: true,
      ),
    ]) {
      expect(hidden, isFalse);
    }
  });

  testWidgets('displays the frozen count and triggers location',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryReadPositionEntry(
            label: '99+ new messages',
            locating: false,
            isDesktopOrWeb: false,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(find.text('99+ new messages'), findsOneWidget);
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, Icons.keyboard_double_arrow_up);
    await tester.tap(
      find.byKey(const ValueKey('history-read-position-entry')),
    );
    expect(taps, 1);
  });

  testWidgets('keeps its label and disables taps while locating',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryReadPositionEntry(
            label: '12条新消息',
            locating: true,
            isDesktopOrWeb: true,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(find.text('12条新消息'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('history-read-position-entry')),
    );
    expect(taps, 0);
  });

  testWidgets('keeps stable dimensions while entering locating state',
      (tester) async {
    Widget buildEntry(bool locating) {
      return MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: HistoryReadPositionEntry(
              label: '99+ new messages',
              locating: locating,
              isDesktopOrWeb: false,
              onTap: () {},
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildEntry(false));
    final idleSize = tester.getSize(
      find.byKey(const ValueKey('history-read-position-entry')),
    );
    await tester.pumpWidget(buildEntry(true));
    final locatingSize = tester.getSize(
      find.byKey(const ValueKey('history-read-position-entry')),
    );

    expect(locatingSize, idleSize);
  });

  testWidgets('restores the arrow while scrolling without enabling taps',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryReadPositionEntry(
            label: '12条新消息',
            locating: true,
            loading: false,
            isDesktopOrWeb: false,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.keyboard_double_arrow_up), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('history-read-position-entry')),
    );
    expect(taps, 0);
  });

  testWidgets('does not overlap the existing bottom action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 180,
            child: Stack(
              children: [
                Positioned(
                  top: 20,
                  right: 20,
                  child: HistoryReadPositionEntry(
                    label: '12 new messages',
                    locating: false,
                    isDesktopOrWeb: false,
                    onTap: () {},
                  ),
                ),
                const Positioned(
                  key: ValueKey('existing-bottom-action'),
                  right: 20,
                  bottom: 20,
                  child: SizedBox(width: 40, height: 40),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final historyRect = tester.getRect(
      find.byKey(const ValueKey('history-read-position-entry')),
    );
    final bottomRect = tester.getRect(
      find.byKey(const ValueKey('existing-bottom-action')),
    );
    expect(historyRect.overlaps(bottomRect), isFalse);
  });
}
