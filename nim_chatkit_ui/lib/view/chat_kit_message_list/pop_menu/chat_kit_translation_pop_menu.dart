// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';

import 'chat_kit_menu_helper.dart';
import 'chat_kit_super_tooltip.dart';

class ChatKitTranslationPopMenu {
  static ChatKitTranslationPopMenu? _currentDesktopInstance;

  final BuildContext context;
  final ChatMessage message;
  final Offset globalPosition;
  final VoidCallback onCopy;
  final VoidCallback onForward;
  final VoidCallback onHide;

  SuperTooltip? _tooltip;
  OverlayEntry? _backgroundEntry;
  OverlayEntry? _menuEntry;
  bool _isDesktopMenuOpen = false;

  ChatKitTranslationPopMenu({
    required this.context,
    required this.message,
    required this.globalPosition,
    required this.onCopy,
    required this.onForward,
    required this.onHide,
  }) {
    if (!ChatKitUtils.isDesktopOrWeb) {
      _tooltip = SuperTooltip(
        popupDirection: _getPopupDirection(),
        minimumOutSidePadding: 0,
        arrowTipDistance: 2,
        arrowBaseWidth: 10,
        arrowLength: 10,
        right: ChatKitMenuHelper.isSelf(message.nimMessage) ? 60 : null,
        left: ChatKitMenuHelper.isSelf(message.nimMessage) ? null : 60,
        borderColor: Colors.white,
        backgroundColor: Colors.white,
        shadowColor: Colors.black26,
        hasShadow: true,
        borderWidth: 1,
        showCloseButton: ShowCloseButton.none,
        touchThroughAreaShape: ClipAreaShape.rectangle,
        targetGlobalPosition: globalPosition,
        content: _buildMobileActions(),
      );
    }
  }

  TooltipDirection _getPopupDirection() {
    final mediaQuery = MediaQuery.of(context);
    final top = mediaQuery.padding.top + kToolbarHeight;
    final bottom = mediaQuery.size.height - mediaQuery.padding.bottom;
    final spaceAbove = globalPosition.dy - top;
    final spaceBelow = bottom - globalPosition.dy;
    return spaceAbove < 120 && spaceBelow > spaceAbove
        ? TooltipDirection.down
        : TooltipDirection.up;
  }

  Widget _buildMobileActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSvgAction(
            label: S.of(context).chatMessageActionCopy,
            asset: 'images/ic_chat_copy.svg',
            onTap: onCopy,
          ),
          _buildSvgAction(
            label: S.of(context).chatMessageActionForward,
            asset: 'images/ic_chat_forward.svg',
            onTap: onForward,
          ),
          _buildHideAction(),
        ],
      ),
    );
  }

  Widget _buildSvgAction({
    required String label,
    required String asset,
    required VoidCallback onTap,
  }) {
    return _buildAction(
      label: label,
      icon: SvgPicture.asset(
        asset,
        package: kPackage,
        width: 18,
        height: 18,
      ),
      onTap: onTap,
    );
  }

  Widget _buildHideAction() {
    return _buildSvgAction(
      label: S.of(context).messageTranslationHide,
      asset: 'images/ic_chat_translation_hide.svg',
      onTap: onHide,
    );
  }

  Widget _buildAction({
    required String label,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 60,
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: () {
            _tooltip?.close();
            onTap();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 14,
                  color: '#333333'.toColor(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void show() {
    if (ChatKitUtils.isDesktopOrWeb) {
      _showDesktopMenu();
    } else {
      _tooltip?.show(context);
    }
  }

  void clean() {
    _closeDesktopMenu();
    if (_tooltip?.isOpen == true) {
      _tooltip?.close();
    }
  }

  void _showDesktopMenu() {
    _currentDesktopInstance?.clean();
    _currentDesktopInstance = this;

    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final position =
        overlayBox?.globalToLocal(globalPosition) ?? globalPosition;
    final overlaySize = overlayBox?.size ?? MediaQuery.of(context).size;
    final actions = [
      _TranslationAction(
        label: S.of(context).chatMessageActionCopy,
        asset: 'images/ic_chat_copy.svg',
        onTap: onCopy,
      ),
      _TranslationAction(
        label: S.of(context).chatMessageActionForward,
        asset: 'images/ic_chat_forward.svg',
        onTap: onForward,
      ),
      _TranslationAction(
        label: S.of(context).messageTranslationHide,
        asset: 'images/ic_chat_translation_hide.svg',
        onTap: onHide,
      ),
    ];

    const menuWidth = 122.0;
    const itemHeight = 32.0;
    const itemGap = 16.0;
    const padding = 16.0;
    const borderWidth = 1.0;
    const pointerGap = 8.0;
    final menuHeight = padding * 2 +
        borderWidth * 2 +
        actions.length * itemHeight +
        (actions.length - 1) * itemGap;

    var left = position.dx + pointerGap;
    var top = position.dy;
    if (left + menuWidth > overlaySize.width) {
      left = position.dx - menuWidth - pointerGap;
    }
    if (top + menuHeight > overlaySize.height) {
      top = overlaySize.height - menuHeight;
    }
    left = left.clamp(0, overlaySize.width - menuWidth).toDouble();
    top = top.clamp(0, overlaySize.height - menuHeight).toDouble();

    _backgroundEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeDesktopMenu,
          onSecondaryTap: _closeDesktopMenu,
          child: const ColoredBox(color: Colors.transparent),
        ),
      ),
    );
    _menuEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        child: Material(
          color: Colors.transparent,
          child: _DesktopTranslationMenuContent(
            actions: actions,
            onItemTap: (action) {
              _closeDesktopMenu();
              action.onTap();
            },
          ),
        ),
      ),
    );

    overlay.insert(_backgroundEntry!);
    overlay.insert(_menuEntry!);
    _isDesktopMenuOpen = true;
  }

  void _closeDesktopMenu() {
    if (!_isDesktopMenuOpen) {
      return;
    }
    _backgroundEntry?.remove();
    _menuEntry?.remove();
    _backgroundEntry = null;
    _menuEntry = null;
    _isDesktopMenuOpen = false;
    if (_currentDesktopInstance == this) {
      _currentDesktopInstance = null;
    }
  }
}

class _TranslationAction {
  const _TranslationAction({
    required this.label,
    required this.asset,
    required this.onTap,
  });

  final String label;
  final String asset;
  final VoidCallback onTap;
}

class _DesktopTranslationMenuContent extends StatefulWidget {
  const _DesktopTranslationMenuContent({
    required this.actions,
    required this.onItemTap,
  });

  final List<_TranslationAction> actions;
  final ValueChanged<_TranslationAction> onItemTap;

  @override
  State<_DesktopTranslationMenuContent> createState() =>
      _DesktopTranslationMenuContentState();
}

class _DesktopTranslationMenuContentState
    extends State<_DesktopTranslationMenuContent> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 122,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6E6E6)),
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
        children: List.generate(widget.actions.length, (index) {
          final action = widget.actions[index];
          final isHovered = _hoveredIndex == index;
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 16),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hoveredIndex = index),
              onExit: (_) => setState(() => _hoveredIndex = -1),
              child: GestureDetector(
                onTap: () => widget.onItemTap(action),
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
                        action.asset,
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
                        action.label,
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
