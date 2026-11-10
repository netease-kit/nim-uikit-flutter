// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netease_common_ui/duo/duo_shell_controller.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/model/forward/forward_selected_beam.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/widgets/chat_forward_dialog.dart';
import 'package:nim_core_v2/nim_core.dart';

void main() {
  testWidgets('forward dialog survives rebuilds of the host page',
      (tester) async {
    late BuildContext hostContext;
    late StateSetter rebuildRoot;
    late StateSetter rebuildHost;
    bool showHost = true;
    double textScale = 1.0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          rebuildRoot = setState;
          return MaterialApp(
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const <Locale>[Locale('en'), Locale('zh')],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child!,
            ),
            home: StatefulBuilder(
              builder: (context, setState) {
                rebuildHost = setState;
                return Column(
                  children: [
                    if (showHost)
                      Builder(
                        builder: (context) {
                          hostContext = context;
                          return const SizedBox.shrink();
                        },
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );

    final Future<ForwardResult?> dialog = showChatForwardNewDialog(
      context: hostContext,
      contentStr: 'forward content',
      selectedBeams: [
        SelectedBeam(
          type: NIMConversationType.p2p,
          conversationId: 'p2p|user-1',
          sessionId: 'user-1',
          name: 'User',
        ),
      ],
    );
    await tester.pump();
    expect(find.byType(SimpleDialog), findsOneWidget);

    // 模拟 Duo 展开双屏：宿主的消息列表被重建，同时弹框跟随 MediaQuery 重建。
    rebuildHost(() => showHost = false);
    rebuildRoot(() => textScale = 1.2);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SimpleDialog), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(await dialog, isNull);
  });

  testWidgets('iPhone Duo 折叠单屏时转发弹框在可见内容区内完整展示', (tester) async {
    // 折叠单屏：整窗 466 宽，右侧 76 宽工具栏绘制在 Navigator 之上。
    const double windowWidth = 466;
    const double toolbarWidth = 76;
    const double contentWidth = windowWidth - toolbarWidth;
    DuoShellController.instance
      ..enabled = true
      ..dual = false
      ..leftWidth = 0
      ..toolbarWidth = toolbarWidth;
    addTearDown(() {
      DuoShellController.instance
        ..enabled = false
        ..dual = false
        ..leftWidth = 0
        ..toolbarWidth = 0;
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(windowWidth, 678);
    addTearDown(tester.view.reset);

    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[Locale('en'), Locale('zh')],
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );

    showChatForwardNewDialog(
      context: hostContext,
      contentStr: '[转发]8801高级群 890666的会话记录',
      selectedBeams: [
        SelectedBeam(
          type: NIMConversationType.team,
          conversationId: 'team|890666',
          sessionId: '890666',
          name: '8801高级群',
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(SimpleDialog), findsOneWidget);
    final Rect dialog = tester.getRect(find.byType(SimpleDialog));
    // 弹框右边缘不能被右侧工具栏盖住，且在可见内容区内居中。
    expect(dialog.right, lessThanOrEqualTo(contentWidth));
    expect(dialog.left, greaterThanOrEqualTo(0));
    expect(dialog.center.dx, closeTo(contentWidth / 2, 0.5));
    expect(tester.takeException(), isNull);
  });
}
