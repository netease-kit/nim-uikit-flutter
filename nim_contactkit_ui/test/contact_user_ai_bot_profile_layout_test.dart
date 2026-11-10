// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netease_common_ui/duo/duo_shell_controller.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_contactkit_ui/page/contact_kit_user_ai_bot_profile_page.dart';
import 'package:nim_core_v2/nim_core.dart';

/// 页面构造 ViewModel 时会读取当前登录账号，测试里提供一个空的登录服务。
class _FakeLoginService extends IMLoginService {
  @override
  Future<NIMResult<void>> loginIM(
    String accountId,
    String token, {
    NIMLoginOption? option,
  }) async {
    return NIMResult.success();
  }

  @override
  Future<void> syncUserInfo(String account) async {}

  @override
  Future<NIMResult<void>> logoutIM() async {
    return NIMResult.success();
  }

  @override
  Future<NIMUserInfo?> getUserInfo() async => userInfo;
}

const Size _windowSize = Size(430, 900);
const double _duoRightSafeArea = 90;

V2NIMUserAIBot _bot() {
  return V2NIMUserAIBot()
    ..accid = 'bot_accid'
    ..name = 'Bot_Claw'
    ..token = 'bot_token';
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required bool duoEnabled,
  required double rightSafeArea,
}) async {
  tester.view.physicalSize = _windowSize;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(right: rightSafeArea);
  addTearDown(tester.view.reset);

  if (!getIt.isRegistered<IMLoginService>()) {
    getIt.registerSingleton<IMLoginService>(_FakeLoginService());
    addTearDown(() => getIt.unregister<IMLoginService>());
  }

  final DuoShellController shell = DuoShellController.instance;
  shell
    ..enabled = duoEnabled
    ..dual = false;
  addTearDown(() {
    shell
      ..enabled = false
      ..dual = false;
  });

  await tester.pumpWidget(
    MaterialApp(
      home: ContactKitUserAIBotProfilePage(bot: _bot()),
    ),
  );
  await tester.pumpAndSettle();
}

/// 头像卡片和操作行里的右侧箭头（同一页面共 3 个）。
List<Rect> _arrowRects(WidgetTester tester) {
  final Finder finder = find.byWidgetPredicate((Widget widget) {
    if (widget is! SvgPicture) return false;
    final BytesLoader loader = widget.bytesLoader;
    return loader is SvgAssetLoader &&
        loader.assetName.contains('ic_right_arrow');
  });
  final int count = tester.widgetList<SvgPicture>(finder).length;
  return List<Rect>.generate(
    count,
    (int index) => tester.getRect(finder.at(index)),
  );
}

void main() {
  testWidgets('Duo 右侧安全区下箭头与标题对齐', (tester) async {
    await _pumpPage(
      tester,
      duoEnabled: true,
      rightSafeArea: _duoRightSafeArea,
    );

    final List<Rect> arrows = _arrowRects(tester);
    expect(arrows.length, 3);
    // 头像卡片与两条操作行的箭头必须共用同一条右边界。
    for (final Rect arrow in arrows) {
      expect(arrow.right, closeTo(arrows.first.right, 0.01));
    }
    // 箭头贴齐卡片右侧 16 的 contentPadding，而不再额外内缩系统安全区。
    expect(arrows.first.right, closeTo(_windowSize.width - 20 - 16, 0.01));

    final Rect title = tester.getRect(
      find.descendant(of: find.byType(AppBar), matching: find.byType(Text)),
    );
    expect(title.center.dx, closeTo(_windowSize.width / 2, 0.5));

    // “聊天 / 删除机器人”两个按钮的文字在卡片内居中。
    final Finder tileFinder = find.byType(ListTile);
    final List<Rect> tiles = List<Rect>.generate(
      tester.widgetList<ListTile>(tileFinder).length,
      (int index) => tester.getRect(tileFinder.at(index)),
    );
    expect(tiles.length, 4);
    for (final int index in <int>[2, 3]) {
      final Rect text = tester.getRect(
        find.descendant(
          of: find.byType(ListTile).at(index),
          matching: find.byType(Text),
        ),
      );
      expect(text.center.dx, closeTo(tiles[index].center.dx, 0.5));
      expect(text.center.dx, closeTo(_windowSize.width / 2, 0.5));
    }
  });

  testWidgets('非 Duo 设备箭头同样右对齐', (tester) async {
    await _pumpPage(
      tester,
      duoEnabled: false,
      rightSafeArea: 0,
    );

    final List<Rect> arrows = _arrowRects(tester);
    expect(arrows.length, 3);
    for (final Rect arrow in arrows) {
      expect(arrow.right, closeTo(arrows.first.right, 0.01));
    }
    expect(arrows.first.right, closeTo(_windowSize.width - 20 - 16, 0.01));

    final Rect title = tester.getRect(
      find.descendant(of: find.byType(AppBar), matching: find.byType(Text)),
    );
    expect(title.center.dx, closeTo(_windowSize.width / 2, 0.5));
  });
}
