// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit_ui/helper/monotonic_scroll_behavior.dart';

void main() {
  testWidgets('iOS 速度跟踪器忽略时间戳倒序的重采样点', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext buildContext) {
            context = buildContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final GestureVelocityTrackerBuilder builder =
        const MonotonicScrollBehavior().velocityTrackerBuilder(context);
    final VelocityTracker tracker = builder(
      const PointerDownEvent(kind: PointerDeviceKind.touch),
    );
    expect(tracker, isA<IOSScrollViewFlingVelocityTracker>());

    tracker.addPosition(
      const Duration(milliseconds: 20),
      const Offset(0, 20),
    );
    // 开启重采样后可能出现时间戳略早的合成事件，默认实现会触发断言。
    expect(
      () => tracker.addPosition(
        const Duration(milliseconds: 19),
        const Offset(0, 10),
      ),
      returnsNormally,
    );
    // 正常递增的采样仍会写入，不影响速度估计。
    expect(
      () => tracker.addPosition(
        const Duration(milliseconds: 21),
        const Offset(0, 30),
      ),
      returnsNormally,
    );

    // flutter_test 会在测试体结束后立刻校验 foundation 调试变量，
    // 必须在测试体里恢复，不能只依赖 tearDown。
    debugDefaultTargetPlatformOverride = null;
  });
}
