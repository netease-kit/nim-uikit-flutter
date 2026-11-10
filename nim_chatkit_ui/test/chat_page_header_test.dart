// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit_ui/view/page/chat_page_header.dart';

const double _paneWidth = 572;

Future<void> _pumpHeader(
  WidgetTester tester, {
  required Widget header,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(_paneWidth, 120);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: header)));
}

void main() {
  testWidgets('Duo 双屏聊天标题在右侧面板内居中', (tester) async {
    await _pumpHeader(
      tester,
      header: const ChatPageHeader(
        title: '历史研讨',
        subTitle: '在线',
        centerTitle: true,
      ),
    );

    final Rect header = tester.getRect(find.byType(ChatPageHeader));
    final Rect title = tester.getRect(find.text('历史研讨'));
    final Rect subTitle = tester.getRect(find.text('在线'));
    expect(header.width, _paneWidth);
    // 标题与副标题作为一个整体居中，而不是从左侧开始排布。
    expect(
      (title.left + subTitle.right) / 2,
      closeTo(header.center.dx, 0.5),
    );
    expect(title.left, greaterThan(header.left + 16));
  });

  testWidgets('桌面端聊天标题保持左对齐', (tester) async {
    await _pumpHeader(
      tester,
      header: const ChatPageHeader(
        title: '历史研讨',
        subTitle: '在线',
      ),
    );

    final Rect header = tester.getRect(find.byType(ChatPageHeader));
    final Rect title = tester.getRect(find.text('历史研讨'));
    expect(title.left, closeTo(header.left + 16, 0.5));
  });

  testWidgets('存在右侧操作时标题保持左对齐，避免与按钮压盖', (tester) async {
    await _pumpHeader(
      tester,
      header: ChatPageHeader(
        title: '历史研讨',
        centerTitle: true,
        trailing: TextButton(
          onPressed: () {},
          child: const Text('取消'),
        ),
      ),
    );

    final Rect header = tester.getRect(find.byType(ChatPageHeader));
    final Rect title = tester.getRect(find.text('历史研讨'));
    expect(title.left, closeTo(header.left + 16, 0.5));
    expect(find.text('取消'), findsOneWidget);
  });
}
