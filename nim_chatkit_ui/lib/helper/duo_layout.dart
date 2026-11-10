// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:foldable/foldable.dart';
import 'package:flutter/widgets.dart';
import 'package:netease_common_ui/duo/duo_dialog.dart';
import 'package:netease_common_ui/duo/duo_shell_controller.dart';

/// 可折叠设备（iPhone Duo）的布局判定。
///
/// 只有在设备真正展开为双屏、且窗口宽度足够时才启用双栏布局；
/// 普通 iPhone、Android 设备以及折叠状态都返回 false，保持原有单栏交互。
class DuoLayout {
  const DuoLayout._();

  /// 模拟器无法折叠时，可用 `--dart-define=DUO_PREVIEW_EXPANDED=true`
  /// 在宽度足够的模拟器（如 iPad）上预览双屏布局。
  ///
  /// FIXME(duo-simulator): 仅用于开发预览，发布前确认是否移除该调试开关。
  static const bool previewExpanded =
      bool.fromEnvironment('DUO_PREVIEW_EXPANDED');

  /// 模拟器无法折叠时，可用 `--dart-define=DUO_PREVIEW_FOLDED=true`
  /// 在普通 iPhone 模拟器上预览折叠态的右侧导航栏。
  ///
  /// FIXME(duo-simulator): 仅用于开发预览，发布前确认是否移除该调试开关。
  static const bool previewFolded = bool.fromEnvironment('DUO_PREVIEW_FOLDED');

  /// 当前设备是否带铰链（iPhone Duo 等可折叠设备）。
  static bool isFoldableDevice(BuildContext context) {
    // 两个预览开关都用于在非折叠模拟器上验证布局。
    return previewFolded ||
        previewExpanded ||
        DuoMediaQuery.of(context).isFoldable;
  }

  /// 是否使用双栏（桌面化）布局。
  ///
  /// 依赖 [DuoMediaQuery] 与窗口尺寸，折叠状态或窗口尺寸变化时会触发重建。
  static bool isExpanded(BuildContext context) {
    if (previewFolded) {
      return false;
    }
    final foldData = DuoMediaQuery.of(context);
    final windowSize = MediaQuery.sizeOf(context);
    if (previewExpanded) {
      // iPhone Duo 模拟器封面屏约 466pt 宽，门槛放宽到 400 便于在模拟器预览双栏布局。
      return windowSize.width >= 400;
    }
    return shouldUseTwoPane(
      isFoldable: foldData.isFoldable,
      status: foldData.status,
      horizontalSizeClass: foldData.horizontalSizeClass,
      windowSize: windowSize,
    );
  }

  /// Duo 聊天页面在窗口中的区域。
  ///
  /// 长按消息等浮层仍挂在窗口级 Overlay 上，位置计算必须以聊天页面为边界，
  /// 否则会落到左侧会话列表或右侧工具栏。
  ///
  /// - 双屏展开：返回右侧内容区（不含最右侧工具栏）；
  /// - 折叠单屏：聊天页铺满窗口，但右侧同样被工具栏占用，返回“窗口宽 - 工具栏”，
  ///   否则长按弹窗会伸到工具栏下方被遮挡；
  /// - 非 Duo 设备、全屏页面返回 null，调用方继续按整个窗口计算，
  ///   普通 iPhone、Android、桌面端行为保持不变。
  static Rect? chatPaneBounds(BuildContext context) {
    final DuoShellController shell = DuoShellController.instance;
    if (shell.enabled && !shell.dual && !shell.fullScreenActive) {
      final Size windowSize = MediaQuery.sizeOf(context);
      final double toolbarWidth =
          shell.toolbarWidth > 0 ? shell.toolbarWidth : 76;
      final double width = windowSize.width - toolbarWidth;
      if (windowSize.width <= 0 || windowSize.height <= 0 || width <= 0) {
        return null;
      }
      return Rect.fromLTWH(0, 0, width, windowSize.height);
    }
    return duoPaneBounds(context, side: DuoPaneSide.right);
  }

  /// 双栏布局的纯函数判定，便于单元测试。
  ///
  /// - 非折叠设备始终返回 false（不影响普通 iPhone / Android）；
  /// - 窗口过窄（封面屏）返回 false；
  /// - 内屏展开（fullyOpen / partiallyOpen）或 iOS 报告 regular 宽度时返回 true。
  static bool shouldUseTwoPane({
    required bool isFoldable,
    required HingeStatus status,
    required SizeClass horizontalSizeClass,
    required Size windowSize,
  }) {
    if (!isFoldable) {
      return false;
    }
    if (windowSize.width < 600) {
      return false;
    }
    final bool isOpen =
        status == HingeStatus.fullyOpen || status == HingeStatus.partiallyOpen;
    final bool isRegularWidth = horizontalSizeClass == SizeClass.regular;
    return isOpen || isRegularWidth;
  }
}
