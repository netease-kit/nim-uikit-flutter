// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netease_common_ui/duo/duo_page_chrome.dart';
import 'package:netease_common_ui/duo/duo_shell_controller.dart';
import 'package:nim_contactkit_ui/l10n/S.dart';
import 'package:nim_contactkit_ui/page/contact_kit_user_ai_bot_scan_page.dart';

Widget _host(Widget child, {required bool duoChrome}) {
  final DuoShellController shell = DuoShellController.instance;
  final Widget home = duoChrome
      ? DuoPageChromeScope(
          controller: shell.chrome,
          child: child,
        )
      : child;
  return MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const <Locale>[Locale('en'), Locale('zh')],
    home: home,
  );
}

void main() {
  final DuoShellController shell = DuoShellController.instance;

  tearDown(() {
    shell
      ..enabled = false
      ..dual = false
      ..leftWidth = 0
      ..toolbarWidth = 0;
  });

  testWidgets('Duo 抽屉内扫一扫只保留右侧工具栏返回按钮', (tester) async {
    const Object token = 'scan-page-test';
    shell
      ..enabled = true
      ..dual = false
      ..leftWidth = 0
      ..toolbarWidth = 76;
    shell.detailRouteInstalled(routeKey: 'scan-page-test');
    addTearDown(() {
      shell.chrome.remove(token);
      shell.detailRouteDisposed(routeKey: 'scan-page-test');
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(466, 678);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(const ContactKitUserAIBotScanPage(), duoChrome: true),
    );
    // DuoChrome 在 post-frame 回调里注册工具栏按钮。
    await tester.pump();
    await tester.pump();

    // 页面内不再重复展示左上角返回。
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.arrow_back_ios_rounded),
      ),
      findsNothing,
    );
    // 返回按钮注册到右侧工具栏，折叠单屏和双屏都能使用。
    expect(shell.chrome.current?.leading, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('非 Duo 扫一扫保留页面内返回按钮', (tester) async {
    shell.enabled = false;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(466, 678);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(const ContactKitUserAIBotScanPage(), duoChrome: false),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.arrow_back_ios_rounded),
      ),
      findsOneWidget,
    );
    expect(shell.chrome.current?.leading, isNull);
    expect(tester.takeException(), isNull);
  });
}
