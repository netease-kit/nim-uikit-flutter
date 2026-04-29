// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';

import '../../../chat_kit_client.dart';
import 'chat_kit_menu_helper.dart';
import 'chat_kit_pop_actions.dart';

/// 桌面端/Web 端消息右键上下文菜单。
///
/// 通过 Overlay 实现，在鼠标右键点击位置弹出列表式菜单。
/// 菜单项逻辑与移动端完全一致，通过 [ChatKitMenuHelper] 共享。
class ChatKitDesktopContextMenu {
  /// 当前打开的菜单实例，用于滚动时关闭
  static ChatKitDesktopContextMenu? currentInstance;

  OverlayEntry? _backgroundEntry;
  OverlayEntry? _menuEntry;
  bool _isOpen = false;

  final BuildContext context;
  final ChatMessage message;
  final PopMenuAction? popMenuAction;
  final ChatUIConfig? chatUIConfig;
  final bool isVoiceFromSpeaker;
  final Offset globalPosition;

  ChatKitDesktopContextMenu({
    required this.context,
    required this.message,
    required this.globalPosition,
    this.popMenuAction,
    this.chatUIConfig,
    this.isVoiceFromSpeaker = true,
  });

  void show() {
    // 关闭已有的菜单实例
    currentInstance?.close();
    currentInstance = this;

    final overlay = Overlay.of(context);

    final menuItems = ChatKitMenuHelper.buildMenuItems(
      context,
      message,
      chatUIConfig,
      isVoiceFromSpeaker,
    );

    if (menuItems.isEmpty) return;

    // 计算菜单尺寸
    const double menuWidth = 122.0;
    const double itemHeight = 32.0; // 菜单项高度
    const double itemGap = 16.0;
    const double padding = 16.0;
    const double borderWidth = 1.0;
    final double menuHeight = padding * 2 +
        borderWidth * 2 +
        menuItems.length * itemHeight +
        (menuItems.length - 1) * itemGap;

    // 计算菜单位置（边界检测）
    final screenSize = MediaQuery.of(context).size;
    double left = globalPosition.dx;
    double top = globalPosition.dy;

    if (left + menuWidth > screenSize.width) {
      left = globalPosition.dx - menuWidth;
    }
    if (top + menuHeight > screenSize.height) {
      top = globalPosition.dy - menuHeight;
    }
    // 防止负数
    if (left < 0) left = 0;
    if (top < 0) top = 0;

    // 背景蒙层 — 点击关闭菜单
    _backgroundEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: close,
          onSecondaryTap: close,
          child: Container(color: Colors.transparent),
        ),
      ),
    );

    // 菜单内容
    _menuEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        child: Material(
          color: Colors.transparent,
          child: _MenuContent(
            menuItems: menuItems,
            onItemTap: (actionId) {
              close();
              ChatKitMenuHelper.handleAction(
                message,
                actionId,
                popMenuAction,
                isVoiceFromSpeaker,
              );
            },
          ),
        ),
      ),
    );

    overlay.insert(_backgroundEntry!);
    overlay.insert(_menuEntry!);
    _isOpen = true;
  }

  void close() {
    if (!_isOpen) return;
    _backgroundEntry?.remove();
    _menuEntry?.remove();
    _backgroundEntry = null;
    _menuEntry = null;
    _isOpen = false;
    if (currentInstance == this) {
      currentInstance = null;
    }
  }

  void clean() {
    close();
  }
}

/// 菜单内容组件（StatefulWidget 用于管理 hover 状态）
class _MenuContent extends StatefulWidget {
  final List<Map<String, String>> menuItems;
  final void Function(String actionId) onItemTap;

  const _MenuContent({
    required this.menuItems,
    required this.onItemTap,
  });

  @override
  State<_MenuContent> createState() => _MenuContentState();
}

class _MenuContentState extends State<_MenuContent> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 122,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6E6E6), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(133, 136, 140, 0.25),
            offset: Offset(0, 4),
            blurRadius: 7,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.menuItems.length, (index) {
          final item = widget.menuItems[index];
          final isHovered = _hoveredIndex == index;
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 16),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hoveredIndex = index),
              onExit: (_) => setState(() => _hoveredIndex = -1),
              child: GestureDetector(
                onTap: () => widget.onItemTap(item['id']!),
                child: Container(
                  width: 114,
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isHovered
                        ? const Color(0xFFECEEEF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        item['icon']!,
                        package: kPackage,
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF656A72),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item['label']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF333333),
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
