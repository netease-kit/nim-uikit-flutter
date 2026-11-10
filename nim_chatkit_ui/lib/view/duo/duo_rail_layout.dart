// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// 折叠单屏工具栏卡片的默认内容宽度。
const double kDuoRailWidth = 72;

/// 双屏右侧工具栏的宽度（与设计稿一致，贴屏幕右侧）。
const double kDuoRailDualWidth = 76;

/// 折叠单屏工具栏卡片与屏幕边缘的间距。
const double kDuoRailOuterMargin = 8;

/// iPhone Duo 右侧工具栏的统一容器。
///
/// - [floating] 为 true：折叠单屏使用的悬浮圆角卡片；
/// - [floating] 为 false：双屏使用的贴边工具栏（76px、浅灰底、左侧分隔线）。
class DuoRailLayout extends StatelessWidget {
  const DuoRailLayout({
    Key? key,
    this.header,
    this.footer,
    this.floating = true,
    this.width,
    this.headerTop,
  }) : super(key: key);

  /// 工具栏顶部内容（聊天操作按钮等）。
  final Widget? header;

  /// 工具栏底部内容（一级导航）。
  final Widget? footer;

  /// 是否使用悬浮圆角卡片样式。
  final bool floating;

  /// 工具栏内容宽度，默认折叠 72 / 双屏 76。
  final double? width;

  /// 覆盖 header 顶部留白（折叠单屏返回按钮位置）。
  final double? headerTop;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double topInset = mediaQuery.padding.top;
    final double rightInset = mediaQuery.padding.right;
    final double railWidth =
        width ?? (floating ? kDuoRailWidth : kDuoRailDualWidth);
    // 双屏内屏的状态栏/摄像头位于顶部或右侧，操作按钮需要下移，
    // 避免被系统时间、Wi-Fi 图标遮挡。
    final double headerTop = this.headerTop ??
        (floating
            ? topInset + 16 + (rightInset > 0 ? rightInset + 40 : 0)
            : (rightInset > 0 ? 140 : topInset + 48));
    final Widget content = SafeArea(
      top: true,
      bottom: true,
      left: false,
      right: false,
      child: Column(
        children: [
          if (header != null)
            Padding(
              padding: EdgeInsets.only(top: headerTop),
              child: SizedBox(width: railWidth, child: header),
            ),
          const Spacer(),
          if (footer != null) footer!,
        ],
      ),
    );
    if (!floating) {
      return Container(
        width: railWidth,
        decoration: const BoxDecoration(
          color: Color(0xFFF6F8FA),
          border: Border(
            left: BorderSide(color: Color(0xFFE9EFF5), width: 1),
          ),
        ),
        child: content,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(
        top: kDuoRailOuterMargin,
        right: kDuoRailOuterMargin,
        bottom: kDuoRailOuterMargin,
      ),
      child: Container(
        width: railWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: content,
        ),
      ),
    );
  }
}
