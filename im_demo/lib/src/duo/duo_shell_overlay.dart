// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:im_demo/l10n/S.dart';
import 'package:netease_common_ui/duo/duo_shell_controller.dart';

import 'duo_rail.dart';

/// 把 Duo 右侧工具栏放到 Navigator 之上，保证左侧首页/工具栏始终可点击。
class DuoShellOverlay extends StatelessWidget {
  const DuoShellOverlay({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shell = DuoShellController.instance;
    return ListenableBuilder(
      listenable: shell,
      builder: (context, _) {
        if (!shell.enabled) return child;
        // Duo 的右侧安全区（内屏摄像头/状态栏）比右侧工具栏更宽，页面已经由
        // 路由让出了工具栏宽度，AppBar/SafeArea 再按安全区内缩一次会让标题不
        // 居中、右侧按钮与内容离屏幕右边一截。Duo 路径统一去掉右侧安全区，
        // 工具栏自身仍使用外层 MediaQuery，位置不受影响。
        final Widget scopedChild = MediaQuery.removePadding(
          context: context,
          removeRight: true,
          child: child,
        );
        if (shell.fullScreenActive) return scopedChild;
        final Widget rail = Material(
          type: MaterialType.transparency,
          child: DuoRail(
            currentIndex: shell.currentTab,
            onTabSelected: shell.requestTab,
            items: _buildItems(context, shell),
            floating: false,
            // 折叠单屏：首页显示底部一级导航；详情页切换为返回/设置按钮。
            showNavigation: shell.dual || !shell.detailActive,
            headerTop: shell.dual ? null : 160,
          ),
        );
        // 弹框遮罩画在 Navigator 内部，工具栏在 Navigator 之上，需要一并遮住
        // 并禁止点击，才能和原生“蒙层覆盖整屏”保持一致。
        // 遮罩颜色取当前弹框自身的 barrierColor：弹框不遮挡内容（如仅靠点击
        // 外部关闭的弹出菜单）时，工具栏只需要不可点击，不需要额外变暗。
        final Color? barrierColor = shell.modalBarrierColor;
        // 弹框把取消/确定注册到工具栏时（DuoDialogChrome），工具栏本身就是
        // 弹框的操作区，需要保持可见、可点击；普通弹框才跟随遮罩一起禁用。
        final bool dialogChromeActive = shell.dialogChromeActive;
        final bool modalActive = shell.modalActive && !dialogChromeActive;
        final bool coverRail =
            modalActive && barrierColor != null && barrierColor.a > 0;
        final double railWidth =
            shell.toolbarWidth > 0 ? shell.toolbarWidth : 76;
        return Stack(
          fit: StackFit.expand,
          children: [
            scopedChild,
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: modalActive,
                child: rail,
              ),
            ),
            if (coverRail)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: railWidth,
                child: IgnorePointer(
                  child: ColoredBox(color: barrierColor),
                ),
              ),
          ],
        );
      },
    );
  }

  List<DuoRailItem> _buildItems(
    BuildContext context,
    DuoShellController shell,
  ) {
    const Color unselected = Color(0xFFC5C9D2);
    return [
      DuoRailItem(
        icon: SvgPicture.asset(
          'assets/icon_session_selected.svg',
          width: 28,
          height: 28,
          colorFilter: const ColorFilter.mode(unselected, BlendMode.srcIn),
        ),
        selectedIcon: SvgPicture.asset(
          'assets/icon_session_selected.svg',
          width: 28,
          height: 28,
        ),
        label: S.of(context).message,
        showRedDot: shell.chatUnreadCount > 0,
      ),
      DuoRailItem(
        icon: SvgPicture.asset(
          'assets/icon_contact_unselected.svg',
          width: 28,
          height: 28,
          colorFilter: const ColorFilter.mode(unselected, BlendMode.srcIn),
        ),
        selectedIcon: SvgPicture.asset(
          'assets/icon_contact_selected.svg',
          width: 28,
          height: 28,
        ),
        label: S.of(context).contact,
        showRedDot: shell.contactUnreadCount + shell.teamUnreadCount > 0,
      ),
      DuoRailItem(
        icon: SvgPicture.asset(
          'assets/icon_my_selected.svg',
          width: 28,
          height: 28,
          colorFilter: const ColorFilter.mode(unselected, BlendMode.srcIn),
        ),
        selectedIcon: SvgPicture.asset(
          'assets/icon_my_selected.svg',
          width: 28,
          height: 28,
        ),
        label: S.of(context).mine,
      ),
    ];
  }
}
