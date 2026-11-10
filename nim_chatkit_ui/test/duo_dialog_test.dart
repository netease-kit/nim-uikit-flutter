// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netease_common_ui/duo/duo_dialog.dart';
import 'package:netease_common_ui/duo/duo_page_chrome.dart';
import 'package:netease_common_ui/duo/duo_shell_controller.dart';

const double _windowWidth = 890;
const double _windowHeight = 600;
const double _leftWidth = 318;
const double _toolbarWidth = 76;

const Rect _leftPane = Rect.fromLTWH(0, 0, _leftWidth, _windowHeight);
const Rect _rightPane = Rect.fromLTRB(
  _leftWidth,
  0,
  _windowWidth - _toolbarWidth,
  _windowHeight,
);

Widget _host({
  required void Function(BuildContext) onLeftContext,
  required void Function(BuildContext) onRightContext,
  required VoidCallback onLeftTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Row(
        children: <Widget>[
          SizedBox(
            width: _leftWidth,
            child: Builder(
              builder: (BuildContext context) {
                onLeftContext(context);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onLeftTap,
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
          Expanded(
            child: Builder(
              builder: (BuildContext context) {
                onRightContext(context);
                return const SizedBox.expand();
              },
            ),
          ),
          const SizedBox(width: _toolbarWidth),
        ],
      ),
    ),
  );
}

/// 折叠单屏宿主：右侧区域模拟 Duo 抽屉页（带 [DuoPageChromeScope]），
/// 左侧区域模拟首页 Tab。
Widget _foldedHost({
  required void Function(BuildContext) onLeftContext,
  required void Function(BuildContext) onDrawerContext,
  required VoidCallback onLeftTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Row(
        children: <Widget>[
          SizedBox(
            width: 300,
            child: Builder(
              builder: (BuildContext context) {
                onLeftContext(context);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onLeftTap,
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
          Expanded(
            child: DuoPageChromeScope(
              controller: DuoShellController.instance.chrome,
              child: Builder(
                builder: (BuildContext context) {
                  onDrawerContext(context);
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void _resetDuoShell() {
  DuoShellController.instance
    ..enabled = false
    ..dual = false
    ..leftWidth = 0
    ..toolbarWidth = 0;
}

void main() {
  setUp(() {
    DuoShellController.instance
      ..enabled = true
      ..dual = true
      ..leftWidth = _leftWidth
      ..toolbarWidth = _toolbarWidth;
  });

  tearDown(_resetDuoShell);

  testWidgets('right-page dialog stays inside the right pane', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(_windowWidth, _windowHeight);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    late BuildContext leftContext;
    late BuildContext rightContext;
    int leftTapCount = 0;
    await tester.pumpWidget(
      _host(
        onLeftContext: (context) => leftContext = context,
        onRightContext: (context) => rightContext = context,
        onLeftTap: () => leftTapCount++,
      ),
    );

    showDuoDialog<void>(
      context: rightContext,
      builder: (_) => const AlertDialog(title: Text('right-pane-dialog')),
    );
    await tester.pumpAndSettle();

    final Rect dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(_rightPane.left));
    expect(dialogRect.right, lessThanOrEqualTo(_rightPane.right));
    expect(dialogRect.top, greaterThanOrEqualTo(_rightPane.top));
    expect(dialogRect.bottom, lessThanOrEqualTo(_rightPane.bottom));

    final Rect barrierRect = tester.getRect(
      find.byKey(const ValueKey<String>('duo-pane-dialog-barrier')),
    );
    expect(barrierRect, _rightPane);

    // 左侧面板没有被遮罩，仍可独立交互。
    await tester.tapAt(const Offset(10, 300));
    await tester.pump();
    expect(leftTapCount, 1);
    expect(find.text('right-pane-dialog'), findsOneWidget);

    // 点击右侧面板空白区域关闭弹框。
    await tester.tapAt(const Offset(_leftWidth + 5, 5));
    await tester.pumpAndSettle();
    expect(find.text('right-pane-dialog'), findsNothing);
    expect(leftContext.mounted, isTrue);
  });

  testWidgets('left-page dialog stays inside the left pane', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(_windowWidth, _windowHeight);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    late BuildContext leftContext;
    late BuildContext rightContext;
    await tester.pumpWidget(
      _host(
        onLeftContext: (context) => leftContext = context,
        onRightContext: (context) => rightContext = context,
        onLeftTap: () {},
      ),
    );

    showDuoCupertinoDialog<void>(
      context: leftContext,
      builder: (_) => const CupertinoAlertDialog(
        title: Text('left-pane-dialog'),
      ),
    );
    await tester.pumpAndSettle();

    final Rect dialogRect = tester.getRect(find.byType(CupertinoAlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(_leftPane.left));
    expect(dialogRect.right, lessThanOrEqualTo(_leftPane.right));

    final Rect barrierRect = tester.getRect(
      find.byKey(const ValueKey<String>('duo-pane-dialog-barrier')),
    );
    expect(barrierRect, _leftPane);
    expect(rightContext.mounted, isTrue);
  });

  testWidgets('action sheet opens at the bottom of its own pane',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(_windowWidth, _windowHeight);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    late BuildContext leftContext;
    late BuildContext rightContext;
    await tester.pumpWidget(
      _host(
        onLeftContext: (context) => leftContext = context,
        onRightContext: (context) => rightContext = context,
        onLeftTap: () {},
      ),
    );

    showDuoCupertinoModalPopup<void>(
      context: rightContext,
      builder: (_) => CupertinoActionSheet(
        title: const Text('right-pane-sheet'),
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () {},
            child: const Text('action'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final Rect sheetRect = tester.getRect(find.byType(CupertinoActionSheet));
    expect(sheetRect.left, greaterThanOrEqualTo(_rightPane.left));
    expect(sheetRect.right, lessThanOrEqualTo(_rightPane.right));
    expect(sheetRect.bottom, lessThanOrEqualTo(_rightPane.bottom));
    expect(sheetRect.bottom, greaterThan(_rightPane.bottom - 100));

    final Rect barrierRect = tester.getRect(
      find.byKey(const ValueKey<String>('duo-pane-dialog-barrier')),
    );
    expect(barrierRect, _rightPane);
    expect(leftContext.mounted, isTrue);

    await tester.tapAt(_rightPane.topLeft + const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('right-pane-sheet'), findsNothing);
  });

  testWidgets('bottom sheet opens at the bottom of its own pane',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(_windowWidth, _windowHeight);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    late BuildContext leftContext;
    late BuildContext rightContext;
    int leftTapCount = 0;
    await tester.pumpWidget(
      _host(
        onLeftContext: (context) => leftContext = context,
        onRightContext: (context) => rightContext = context,
        onLeftTap: () => leftTapCount++,
      ),
    );

    showDuoModalBottomSheet<void>(
      context: rightContext,
      builder: (_) => const SizedBox(
        key: ValueKey<String>('pane-bottom-sheet-content'),
        height: 200,
      ),
    );
    await tester.pumpAndSettle();

    final Rect sheetRect = tester.getRect(
      find.byKey(const ValueKey<String>('pane-bottom-sheet-content')),
    );
    expect(sheetRect.left, greaterThanOrEqualTo(_rightPane.left));
    expect(sheetRect.right, lessThanOrEqualTo(_rightPane.right));
    expect(sheetRect.bottom, lessThanOrEqualTo(_rightPane.bottom));
    expect(sheetRect.bottom, greaterThan(_rightPane.bottom - 50));

    final Rect barrierRect = tester.getRect(
      find.byKey(const ValueKey<String>('duo-pane-bottom-sheet-barrier')),
    );
    expect(barrierRect, _rightPane);
    expect(leftContext.mounted, isTrue);

    await tester.tapAt(const Offset(10, 300));
    await tester.pump();
    expect(leftTapCount, 1);

    await tester.tapAt(_rightPane.topLeft + const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('pane-bottom-sheet-content')),
      findsNothing,
    );
  });

  testWidgets('full-screen Duo route keeps dialogs full-window',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(_windowWidth, _windowHeight);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    late BuildContext rightContext;
    await tester.pumpWidget(
      _host(
        onLeftContext: (_) {},
        onRightContext: (context) => rightContext = context,
        onLeftTap: () {},
      ),
    );

    DuoShellController.instance.fullScreenPushed();
    addTearDown(DuoShellController.instance.fullScreenPopped);

    expect(duoPaneBounds(rightContext), isNull);
  });

  testWidgets('non-Duo devices keep the original full-window dialog',
      (tester) async {
    _resetDuoShell();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(_windowWidth, _windowHeight);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    late BuildContext rightContext;
    await tester.pumpWidget(
      _host(
        onLeftContext: (_) {},
        onRightContext: (context) => rightContext = context,
        onLeftTap: () {},
      ),
    );

    expect(duoPaneBounds(rightContext), isNull);

    showDuoDialog<void>(
      context: rightContext,
      builder: (_) => const AlertDialog(title: Text('full-window-dialog')),
    );
    await tester.pumpAndSettle();

    expect(find.text('full-window-dialog'), findsOneWidget);
    final Rect barrierRect = tester.getRect(find.byType(ModalBarrier).last);
    expect(
      barrierRect,
      const Rect.fromLTWH(0, 0, _windowWidth, _windowHeight),
    );
  });

  testWidgets('dialog opened while folded moves to its pane after unfolding',
      (tester) async {
    DuoShellController.instance
      ..enabled = true
      ..dual = false
      ..leftWidth = 0
      ..toolbarWidth = _toolbarWidth;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(_windowWidth, _windowHeight);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    late BuildContext drawerContext;
    await tester.pumpWidget(
      _foldedHost(
        onLeftContext: (_) {},
        onDrawerContext: (BuildContext context) => drawerContext = context,
        onLeftTap: () {},
      ),
    );

    showDuoDialog<void>(
      context: drawerContext,
      builder: (_) => const AlertDialog(title: Text('drawer-dialog')),
    );
    await tester.pumpAndSettle();

    // 折叠单屏时铺满整窗，与原来的原生弹框一致。
    expect(
      tester.getRect(
        find.byKey(const ValueKey<String>('duo-pane-dialog-barrier')),
      ),
      const Rect.fromLTWH(0, 0, _windowWidth, _windowHeight),
    );

    // 展开双屏：弹框跟随抽屉页收缩到右侧内容区。
    DuoShellController.instance
      ..dual = true
      ..leftWidth = _leftWidth
      ..notifyLayoutChanged();
    await tester.pumpAndSettle();

    final Rect barrierRect = tester.getRect(
      find.byKey(const ValueKey<String>('duo-pane-dialog-barrier')),
    );
    expect(barrierRect, _rightPane);
    final Rect dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(_rightPane.left));
    expect(dialogRect.right, lessThanOrEqualTo(_rightPane.right));
  });

  testWidgets('home-page dialog opened while folded stays in the left pane',
      (tester) async {
    DuoShellController.instance
      ..enabled = true
      ..dual = false
      ..leftWidth = 0
      ..toolbarWidth = _toolbarWidth;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(_windowWidth, _windowHeight);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    late BuildContext leftContext;
    await tester.pumpWidget(
      _foldedHost(
        onLeftContext: (BuildContext context) => leftContext = context,
        onDrawerContext: (_) {},
        onLeftTap: () {},
      ),
    );

    showDuoCupertinoDialog<void>(
      context: leftContext,
      builder: (_) => const CupertinoAlertDialog(
        title: Text('home-dialog'),
      ),
    );
    await tester.pumpAndSettle();

    DuoShellController.instance
      ..dual = true
      ..leftWidth = _leftWidth
      ..notifyLayoutChanged();
    await tester.pumpAndSettle();

    final Rect barrierRect = tester.getRect(
      find.byKey(const ValueKey<String>('duo-pane-dialog-barrier')),
    );
    expect(barrierRect, _leftPane);
    final Rect dialogRect = tester.getRect(find.byType(CupertinoAlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(_leftPane.left));
    expect(dialogRect.right, lessThanOrEqualTo(_leftPane.right));
  });

  testWidgets('bottom sheet opened while folded follows its pane later',
      (tester) async {
    DuoShellController.instance
      ..enabled = true
      ..dual = false
      ..leftWidth = 0
      ..toolbarWidth = _toolbarWidth;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(_windowWidth, _windowHeight);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    late BuildContext drawerContext;
    await tester.pumpWidget(
      _foldedHost(
        onLeftContext: (_) {},
        onDrawerContext: (BuildContext context) => drawerContext = context,
        onLeftTap: () {},
      ),
    );

    showDuoModalBottomSheet<void>(
      context: drawerContext,
      builder: (_) => const SizedBox(
        key: ValueKey<String>('folded-bottom-sheet-content'),
        height: 200,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getRect(
        find.byKey(const ValueKey<String>('duo-pane-bottom-sheet-barrier')),
      ),
      const Rect.fromLTWH(0, 0, _windowWidth, _windowHeight),
    );

    DuoShellController.instance
      ..dual = true
      ..leftWidth = _leftWidth
      ..notifyLayoutChanged();
    await tester.pumpAndSettle();

    final Rect barrierRect = tester.getRect(
      find.byKey(const ValueKey<String>('duo-pane-bottom-sheet-barrier')),
    );
    expect(barrierRect, _rightPane);
    final Rect sheetRect = tester.getRect(
      find.byKey(const ValueKey<String>('folded-bottom-sheet-content')),
    );
    expect(sheetRect.left, greaterThanOrEqualTo(_rightPane.left));
    expect(sheetRect.right, lessThanOrEqualTo(_rightPane.right));
  });

  testWidgets('dialog opened from a pane dialog stays in the same pane',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(_windowWidth, _windowHeight);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    late BuildContext rightContext;
    await tester.pumpWidget(
      _host(
        onLeftContext: (_) {},
        onRightContext: (BuildContext context) => rightContext = context,
        onLeftTap: () {},
      ),
    );

    showDuoDialog<void>(
      context: rightContext,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: TextButton(
          key: const Key('open-nested-dialog'),
          onPressed: () {
            showDuoDialog<void>(
              context: dialogContext,
              builder: (_) => const AlertDialog(title: Text('nested-dialog')),
            );
          },
          child: const Text('open'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-nested-dialog')));
    await tester.pumpAndSettle();

    expect(find.text('nested-dialog'), findsOneWidget);
    final Rect barrierRect = tester.getRect(
      find.byKey(const ValueKey<String>('duo-pane-dialog-barrier')).last,
    );
    expect(barrierRect, _rightPane);
  });

  testWidgets(
      'folded dialog opened with root context follows the active drawer pane',
      (tester) async {
    DuoShellController.instance
      ..enabled = true
      ..dual = false
      ..leftWidth = 0
      ..toolbarWidth = _toolbarWidth
      ..detailRouteInstalled(routeKey: 'chat');
    addTearDown(() {
      DuoShellController.instance.detailRouteDisposed(routeKey: 'chat');
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(_windowWidth, _windowHeight);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    late BuildContext rootContext;
    await tester.pumpWidget(
      _foldedHost(
        onLeftContext: (_) {},
        onDrawerContext: (BuildContext context) {
          // 模拟转发弹框：提前捕获根 Navigator 的 context，拿不到页面级
          // DuoPageChromeScope。
          rootContext = Navigator.of(context, rootNavigator: true).context;
        },
        onLeftTap: () {},
      ),
    );

    showDuoDialog<void>(
      context: rootContext,
      builder: (_) => const AlertDialog(title: Text('root-context-dialog')),
    );
    await tester.pumpAndSettle();

    // 折叠单屏：遮罩铺满整窗。
    expect(
      tester.getRect(
        find.byKey(const ValueKey<String>('duo-pane-dialog-barrier')),
      ),
      const Rect.fromLTWH(0, 0, _windowWidth, _windowHeight),
    );

    // 展开双屏：弹框应跟随当前聊天抽屉页进入右侧面板，而不是跑到左侧。
    DuoShellController.instance
      ..dual = true
      ..leftWidth = _leftWidth
      ..notifyLayoutChanged();
    await tester.pumpAndSettle();

    final Rect barrierRect = tester.getRect(
      find.byKey(const ValueKey<String>('duo-pane-dialog-barrier')),
    );
    expect(barrierRect, _rightPane);
    final Rect dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(dialogRect.left, greaterThanOrEqualTo(_rightPane.left));
    expect(dialogRect.right, lessThanOrEqualTo(_rightPane.right));
  });

  testWidgets(
      'folded root-context dialog without drawer stays in the left pane',
      (tester) async {
    DuoShellController.instance
      ..enabled = true
      ..dual = false
      ..leftWidth = 0
      ..toolbarWidth = _toolbarWidth;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(_windowWidth, _windowHeight);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    late BuildContext rootContext;
    await tester.pumpWidget(
      _foldedHost(
        onLeftContext: (_) {},
        onDrawerContext: (BuildContext context) {
          rootContext = Navigator.of(context, rootNavigator: true).context;
        },
        onLeftTap: () {},
      ),
    );

    showDuoDialog<void>(
      context: rootContext,
      builder: (_) => const AlertDialog(title: Text('home-root-dialog')),
    );
    await tester.pumpAndSettle();

    DuoShellController.instance
      ..dual = true
      ..leftWidth = _leftWidth
      ..notifyLayoutChanged();
    await tester.pumpAndSettle();

    expect(
      tester.getRect(
        find.byKey(const ValueKey<String>('duo-pane-dialog-barrier')),
      ),
      _leftPane,
    );
  });
}
