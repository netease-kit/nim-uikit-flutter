// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:netease_common_ui/duo/duo_page_chrome.dart';
import 'package:netease_common_ui/duo/duo_shell_controller.dart';
import 'package:nim_chatkit_ui/view/duo/duo_rail_layout.dart';
import 'package:nim_chatkit/router/imkit_router_constants.dart';

/// 右侧导航栏的一项，复用首页底部导航的图标与文案。
class DuoRailItem {
  const DuoRailItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.showRedDot = false,
  });

  final Widget icon;
  final Widget selectedIcon;
  final String label;
  final bool showRedDot;
}

/// 底部对齐的一级导航项，可单独嵌入聊天页右侧工具栏。
class DuoRailNav extends StatelessWidget {
  const DuoRailNav({
    Key? key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.items,
    this.bottomPadding = 24,
  }) : super(key: key);

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final List<DuoRailItem> items;

  /// 导航底部的留白；双屏贴边工具栏使用 0，由 SafeArea 保留 Home 指示条空间。
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < items.length; i++) _buildItem(i),
        SizedBox(height: bottomPadding),
      ],
    );
  }

  Widget _buildItem(int index) {
    final item = items[index];
    final bool selected = currentIndex == index;
    return SizedBox(
      width: 72,
      child: InkWell(
        onTap: () => onTabSelected(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child: selected ? item.selectedIcon : item.icon,
                    ),
                  ),
                  if (item.showRedDot)
                    Positioned(
                      top: -2,
                      right: -3,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: selected
                      ? const Color(0xFF337EFF)
                      : const Color(0xFFC5C9D2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// iPhone Duo 的单屏/双屏共用的右侧一级导航栏。
///
/// 折叠态替代底部 BottomNavigationBar，展开态位于双栏最右侧；
/// 图标整体靠下对齐，与设计稿一致。仅由 Duo 布局使用，普通单屏 iPhone 不涉及。
class DuoRail extends StatelessWidget {
  const DuoRail({
    Key? key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.items,
    this.floating = true,
    this.showNavigation = true,
    this.headerTop,
  }) : super(key: key);

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final List<DuoRailItem> items;

  /// 是否使用折叠单屏的悬浮圆角卡片样式；双屏使用贴边工具栏。
  final bool floating;

  /// 折叠单屏详情页只显示返回/页面按钮，不显示底部一级导航。
  final bool showNavigation;

  /// 折叠单屏返回按钮的顶部位置。
  final double? headerTop;

  @override
  Widget build(BuildContext context) {
    final shell = DuoShellController.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([shell, shell.chrome]),
      builder: (context, _) {
        return DuoRailLayout(
          floating: floating,
          headerTop: headerTop,
          header: _buildChrome(context),
          footer: showNavigation
              ? DuoRailNav(
                  currentIndex: currentIndex,
                  onTabSelected: onTabSelected,
                  items: items,
                  bottomPadding: floating ? 24 : 0,
                )
              : null,
        );
      },
    );
  }

  /// 二级页面的返回/右侧按钮，取自当前页面注册到 chrome 的内容。
  Widget? _buildChrome(BuildContext context) {
    final shell = DuoShellController.instance;
    if (!shell.detailActive) return null;
    final data = shell.chrome.current;
    // 双屏首层抽屉页面（从首页 Tab 打开）不需要返回按钮；
    // 折叠单屏时首层依然需要返回；下级页面在两种形态下都展示返回。
    // 双屏首层抽屉默认不展示返回按钮；页面内部存在子页面状态时，
    // 页面会显式注册 leading（例如个人信息页的昵称/性别编辑），此时仍需展示。
    // 双屏下聊天页是右侧一级抽屉。折叠单屏从“我的群聊/联系人详情”进入
    // 聊天时可能残留了下方抽屉路由，detailDepth 仍大于 1；这里以当前栈顶
    // 路由为准，聊天页在双屏下始终不展示返回按钮。
    final bool isChatRootInDual = shell.dual &&
        shell.activeDetailRouteKey == RouterConstants.PATH_CHAT_PAGE;
    final bool hideBack = isChatRootInDual || (data?.hideBack ?? false);
    final bool showBack = !hideBack &&
        (shell.detailDepth > 1 || !shell.dual || data?.leading != null);
    final Widget? leading = showBack
        ? (data?.leading ??
            buildDuoBackButton(
              onPressed: () {
                // 工具栏绘制在 Navigator 之上，直接用它自己的 context 取
                // Navigator 会失败；默认返回回调由首页注入（首页位于路由内）。
                final VoidCallback? onBack = shell.onBack;
                if (onBack != null) {
                  onBack();
                  return;
                }
                Navigator.of(context, rootNavigator: true).maybePop();
              },
            ))
        : null;
    final actions = data?.actions ?? const <Widget>[];
    if (leading == null && actions.isEmpty) return null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) _DuoRailChromeButton(child: leading),
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _DuoRailChromeButton(child: action),
          ),
      ],
    );
  }
}

/// Duo 右侧工具栏的圆形按钮。
///
/// 设计稿中返回、取消、确定、保存等按钮统一为圆形描边按钮：
/// 白色底、1px 浅灰边框，内容居中。这里在渲染层统一包装，页面仍然可以
/// 按原方式注册 [IconButton] / [TextButton] / [DuoCountBadge]。
class _DuoRailChromeButton extends StatelessWidget {
  const _DuoRailChromeButton({required this.child});

  static const double _size = 45;
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _badgeColor = Color(0xFF337EFF);

  /// 页面注册的原始工具栏按钮。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget content = _unwrap(child);
    int badgeCount = 0;
    Color badgeColor = _badgeColor;
    if (content is DuoCountBadge) {
      badgeCount = content.showDuoBadge ? content.count : 0;
      badgeColor = content.badgeColor;
      content = _unwrap(content.duoChild ?? content.child);
    }

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            key: const ValueKey('duo-rail-chrome-circle'),
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _borderColor),
            ),
          ),
          _buildContent(content),
          if (badgeCount > 0)
            Positioned(
              top: -5,
              right: -7,
              child: IgnorePointer(
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 去掉页面为了普通标题栏添加的 [Padding]，圆形按钮内由自身居中控制。
  Widget _unwrap(Widget widget) {
    Widget current = widget;
    while (current is Padding) {
      final Widget? child = current.child;
      if (child == null) {
        break;
      }
      current = child;
    }
    return current;
  }

  Widget _buildContent(Widget content) {
    if (content is TextButton) {
      return _buildTextButton(content);
    }
    if (content is IconButton) {
      // IconButton 默认 48×48 点击区，缩放到 40 的圆内，图标也同步略缩小，
      // 与设计稿（约 20pt 图标）一致，同时保留 tooltip、禁用态等行为。
      return FittedBox(
        fit: BoxFit.contain,
        child: content,
      );
    }
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: content,
      ),
    );
  }

  /// 文字按钮（取消/确定/保存）重建为圆形按钮，去掉 TextButton 默认的
  /// 64×48 最小尺寸和内边距；长文案用 FittedBox 等比缩小，避免溢出圆形。
  Widget _buildTextButton(TextButton button) {
    final ButtonStyle baseStyle = button.style ?? const ButtonStyle();
    return SizedBox(
      width: _size,
      height: _size,
      child: TextButton(
        onPressed: button.onPressed,
        onLongPress: button.onLongPress,
        focusNode: button.focusNode,
        autofocus: button.autofocus,
        clipBehavior: button.clipBehavior,
        statesController: button.statesController,
        style: baseStyle.copyWith(
          minimumSize: const WidgetStatePropertyAll<Size?>(Size.zero),
          maximumSize: const WidgetStatePropertyAll<Size?>(Size(_size, _size)),
          fixedSize: const WidgetStatePropertyAll<Size?>(Size(_size, _size)),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
            EdgeInsets.zero,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const WidgetStatePropertyAll<OutlinedBorder?>(
            CircleBorder(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: button.child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
