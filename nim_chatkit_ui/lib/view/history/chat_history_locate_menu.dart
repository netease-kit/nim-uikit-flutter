// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';

/// 历史消息页面桌面/Web 端右键"定位到原始消息"Overlay 菜单。
///
/// 复用 [ChatKitDesktopContextMenu] 的 Overlay 定位模式，
/// 使用鼠标右键点击的全局坐标直接计算 left/top，并做屏幕边界检测。
class ChatHistoryLocateMenu {
  static ChatHistoryLocateMenu? _currentInstance;

  OverlayEntry? _backgroundEntry;
  OverlayEntry? _menuEntry;
  bool _isOpen = false;

  final BuildContext context;
  final Offset globalPosition;
  final VoidCallback onLocate;

  ChatHistoryLocateMenu({
    required this.context,
    required this.globalPosition,
    required this.onLocate,
  });

  void show() {
    // 确保先关掉上一个
    _currentInstance?.close();
    _currentInstance = this;

    const double menuWidth = 148.0;
    const double menuHeight = 64.0; // padding*2 + 1 item(32)

    // rootOverlay: true 确保始终插入到 app 最顶层的 Overlay，
    // 避免在嵌入式子树里取到局部 Overlay 导致菜单不可见
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final screenSize =
        overlayBox != null ? overlayBox.size : MediaQuery.of(context).size;

    double left = globalPosition.dx;
    double top = globalPosition.dy;

    if (left + menuWidth > screenSize.width) {
      left = globalPosition.dx - menuWidth;
    }
    if (top + menuHeight > screenSize.height) {
      top = globalPosition.dy - menuHeight;
    }
    if (left < 0) left = 0;
    if (top < 0) top = 0;

    _backgroundEntry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: close,
          onSecondaryTap: close,
          child: Container(color: Colors.transparent),
        ),
      ),
    );

    _menuEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: left,
        top: top,
        child: Material(
          color: Colors.transparent,
          child: _LocateMenuContent(
            label: S.of(context).chatSearchLocateMessage,
            onTap: () {
              close();
              onLocate();
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
    if (_currentInstance == this) _currentInstance = null;
  }
}

class _LocateMenuContent extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _LocateMenuContent({required this.label, required this.onTap});

  @override
  State<_LocateMenuContent> createState() => _LocateMenuContentState();
}

class _LocateMenuContentState extends State<_LocateMenuContent> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 116,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: _hovered ? const Color(0xFFECEEEF) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
