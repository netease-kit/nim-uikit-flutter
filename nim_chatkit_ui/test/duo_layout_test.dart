// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:foldable/foldable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit_ui/helper/duo_layout.dart';

void main() {
  group('DuoLayout.shouldUseTwoPane', () {
    test('普通 iPad/iPhone（非折叠设备）始终使用单栏', () {
      expect(
        DuoLayout.shouldUseTwoPane(
          isFoldable: false,
          status: HingeStatus.fullyOpen,
          horizontalSizeClass: SizeClass.regular,
          windowSize: const Size(1024, 768),
        ),
        isFalse,
      );
    });

    test('iPhone Duo 折叠态（封面屏）使用单栏', () {
      expect(
        DuoLayout.shouldUseTwoPane(
          isFoldable: true,
          status: HingeStatus.closed,
          horizontalSizeClass: SizeClass.compact,
          windowSize: const Size(466, 678),
        ),
        isFalse,
      );
    });

    test('iPhone Duo 完全展开（内屏）使用双栏', () {
      expect(
        DuoLayout.shouldUseTwoPane(
          isFoldable: true,
          status: HingeStatus.fullyOpen,
          horizontalSizeClass: SizeClass.regular,
          windowSize: const Size(951, 669),
        ),
        isTrue,
      );
    });

    test('iPhone Duo 半开状态也使用双栏', () {
      expect(
        DuoLayout.shouldUseTwoPane(
          isFoldable: true,
          status: HingeStatus.partiallyOpen,
          horizontalSizeClass: SizeClass.compact,
          windowSize: const Size(700, 800),
        ),
        isTrue,
      );
    });

    test('窗口过窄时即使展开也保持单栏', () {
      expect(
        DuoLayout.shouldUseTwoPane(
          isFoldable: true,
          status: HingeStatus.fullyOpen,
          horizontalSizeClass: SizeClass.regular,
          windowSize: const Size(480, 800),
        ),
        isFalse,
      );
    });

    test('iOS 报告 regular 宽度时使用双栏（如分屏）', () {
      expect(
        DuoLayout.shouldUseTwoPane(
          isFoldable: true,
          status: HingeStatus.unknown,
          horizontalSizeClass: SizeClass.regular,
          windowSize: const Size(900, 700),
        ),
        isTrue,
      );
    });
  });
}
