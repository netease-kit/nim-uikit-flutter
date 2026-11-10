// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:foldable/foldable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit/window_adaptation.dart';
import 'package:nim_chatkit_ui/helper/foldable_window_adaptation.dart';

void main() {
  testWidgets('maps injected foldable snapshots to the shared scope', (
    tester,
  ) async {
    final snapshots = StreamController<FoldableData>.broadcast();
    WindowAdaptationState? observed;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(951, 669)),
        child: FoldableWindowAdaptation(
          debugData: snapshots.stream,
          child: Builder(
            builder: (context) {
              observed = WindowAdaptationScope.maybeOf(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();

    snapshots.add(
      const FoldableData(
        capabilities: FoldableCapabilities(
          supportLevel: FoldableSupportLevel.available,
          isFoldable: true,
          hingeApiPresent: true,
          regionApiPresent: true,
          angleUnitVerified: false,
          strategy: 'simulated',
        ),
        status: HingeStatus.partiallyOpen,
        angleDegrees: 90,
        regions: <ReservedRegion>[],
        displayFeatures: <DisplayFeature>[],
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(observed?.isIPhoneDuoPath, isTrue);
    expect(observed?.foldState, WindowFoldState.expanded);
    expect(observed?.windowSize, const Size(951, 669));

    await snapshots.close();
  });
}
