// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:foldable/foldable.dart';
import 'package:flutter/widgets.dart';
import 'package:netease_common_ui/duo/duo_shell_controller.dart';
import 'package:nim_chatkit/window_adaptation.dart';

/// Adds foldable iOS capabilities to the shared UIKit window adaptation scope.
///
/// The provider deliberately keeps [DisplayFeatureBridgeMode.none], so adding
/// the plugin does not change the width or anchoring of existing dialogs and
/// bottom sheets on ordinary iPhones. Consumers opt into fold-aware layouts by
/// reading [WindowAdaptationScope] below this widget.
class FoldableWindowAdaptation extends StatelessWidget {
  const FoldableWindowAdaptation({
    Key? key,
    required this.child,
    this.debugData,
  }) : super(key: key);

  /// The UIKit subtree that consumes window adaptation state.
  final Widget child;

  /// Optional fold snapshots for simulator and widget tests.
  final Stream<FoldableData>? debugData;

  @override
  Widget build(BuildContext context) {
    return FoldableProvider(
      bridgeMode: DisplayFeatureBridgeMode.none,
      debugData: debugData,
      child: Builder(
        builder: (context) {
          final mediaQuery = MediaQuery.of(context);
          final foldData = DuoMediaQuery.maybeOf(context);
          // DuoShellController 是 Demo 首页已经确认的设备能力来源。
          // 模拟器上 foldable 插件不一定能返回铰链快照，但 Duo shell 仍然
          // 会正确进入 Duo 布局；输入栏等子组件也必须沿用同一条路径。
          final bool isIPhoneDuoPath = DuoShellController.instance.enabled ||
              foldData?.isFoldable == true;
          final state = WindowAdaptationConfig.resolver != null
              ? WindowAdaptationConfig.resolve(mediaQuery).copyWith(
                  isIPhoneDuoPath: isIPhoneDuoPath,
                )
              : WindowAdaptationState.fromMediaQuery(
                  mediaQuery,
                  isIPhoneDuoPath: isIPhoneDuoPath,
                  foldState: _foldStateOf(foldData?.status),
                );
          return WindowAdaptationScope(
            state: state,
            child: child,
          );
        },
      ),
    );
  }

  static WindowFoldState _foldStateOf(HingeStatus? status) {
    switch (status) {
      case HingeStatus.closed:
        return WindowFoldState.folded;
      case HingeStatus.partiallyOpen:
      case HingeStatus.fullyOpen:
        return WindowFoldState.expanded;
      case HingeStatus.unknown:
      case null:
        return WindowFoldState.unknown;
    }
  }
}
