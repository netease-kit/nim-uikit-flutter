// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/base/default_language.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/repo/config_repo.dart';

import '../../l10n/S.dart';
import '../home/splash_page.dart';
import 'desktop_settings_dialog.dart';

/// 桌面端 Sidebar 底部"更多"按钮 + 自定义浮层菜单
/// hover 到按钮时自动弹出菜单，语言项 hover 时展开语言子菜单
class DesktopMoreMenu extends StatefulWidget {
  const DesktopMoreMenu({Key? key}) : super(key: key);

  @override
  State<DesktopMoreMenu> createState() => _DesktopMoreMenuState();
}

class _DesktopMoreMenuState extends State<DesktopMoreMenu> {
  bool _isHovered = false;
  bool _menuOpen = false;

  OverlayEntry? _overlayEntry;

  /// 鼠标移入时触发
  void _onHoverEnter(BuildContext context) {
    setState(() => _isHovered = true);
    if (_menuOpen) return;
    _menuOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showOverlayMenu(context);
    });
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _menuOpen = false;
        _isHovered = false;
      });
    } else {
      // dispose 阶段已 unmounted，只清理引用，不能 setState
      _menuOpen = false;
      _isHovered = false;
    }
  }

  /// 弹出自定义 Overlay 菜单
  void _showOverlayMenu(BuildContext context) {
    final RenderBox? buttonBox = context.findRenderObject() as RenderBox?;
    if (buttonBox == null) return;
    final overlay = Overlay.of(context);

    final Offset pos = buttonBox.localToGlobal(Offset.zero);
    final Size size = buttonBox.size;

    // 菜单左上角位置：按钮右侧 4px，底部与按钮底部对齐
    final double menuLeft = pos.dx + size.width + 4;
    final double menuBottom =
        MediaQuery.of(context).size.height - pos.dy - size.height;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => _MoreMenuOverlay(
        menuLeft: menuLeft,
        menuBottom: menuBottom,
        onClose: _closeMenu,
        onSettingTap: () {
          _closeMenu();
          showDialog(
            context: context,
            builder: (_) => const DesktopSettingsDialog(),
          );
        },
        onLogoutTap: () {
          _closeMenu();
          _showLogoutConfirm(context);
        },
        // 语言切换：先关闭菜单，再由父级 context 执行导航，避免 Overlay context 失效
        onLanguageSwitch: (lang) {
          _closeMenu();
          _doSwitchLanguage(context, lang);
        },
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  /// 由父级稳定 context 执行语言切换导航（语言数据已由子菜单提前写入）。
  ///
  /// 重建路由栈时必须以 [SplashPage] 为根，而非直接跳到 [HomePage]。
  /// 原因：[SplashPage] 内的 Consumer<LoginModel> 是登录/登出状态路由的
  /// 唯一枢纽。若以 [HomePage] 为根，后续登出时 [SplashPage] 不在栈中，
  /// LoginModel 状态变化无人响应，导致无法跳转到登录页。
  void _doSwitchLanguage(BuildContext context, String lang) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashPage(deviceToken: null)),
      (route) => false,
    );
  }

  /// 退出登录二次确认弹框
  void _showLogoutConfirm(BuildContext context) {
    showCommonDialog(
      context: context,
      title: S.of(context).mineLogout,
      content: S.of(context).logoutDialogContent,
      navigateContent: S.of(context).logoutDialogDisagree,
      positiveContent: S.of(context).logoutDialogAgree,
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        IMKitClient.logoutIM().then((success) {

        });
      }
    });
  }

  @override
  void dispose() {
    // dispose 阶段不能调用 setState，直接移除 Overlay Entry
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverEnter(context),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: (_isHovered || _menuOpen)
              ? const Color(0xFF3D4150)
              : Colors.transparent,
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/ic_more_nav.svg',
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(
              (_isHovered || _menuOpen)
                  ? Colors.white
                  : const Color(0xFF8B8FA3),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 主菜单 Overlay Widget
// ──────────────────────────────────────────────

class _MoreMenuOverlay extends StatefulWidget {
  final double menuLeft;
  final double menuBottom;
  final VoidCallback onClose;
  final VoidCallback onSettingTap;
  final VoidCallback onLogoutTap;

  /// 语言切换回调，由父级（DesktopMoreMenu）持有稳定的 context 执行导航
  final void Function(String lang) onLanguageSwitch;

  const _MoreMenuOverlay({
    required this.menuLeft,
    required this.menuBottom,
    required this.onClose,
    required this.onSettingTap,
    required this.onLogoutTap,
    required this.onLanguageSwitch,
  });

  @override
  State<_MoreMenuOverlay> createState() => _MoreMenuOverlayState();
}

class _MoreMenuOverlayState extends State<_MoreMenuOverlay> {
  bool _langHovered = false;
  bool _subMenuOpen = false;

  String _currentLanguage = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    String lang;
    if (CommonUIDefaultLanguage.commonDefaultLanguage?.isNotEmpty == true) {
      lang = CommonUIDefaultLanguage.commonDefaultLanguage!;
    } else {
      lang = await ConfigRepo.getLanguage() ??
          PlatformDispatcher.instance.locale.languageCode;
    }
    if (mounted) setState(() => _currentLanguage = lang);
  }

  void _switchLanguage(String lang) {
    CommonUIDefaultLanguage.commonDefaultLanguage = lang;
    ConfigRepo.updateLanguage(lang);
    // 通过父级回调执行关闭菜单 + 导航，避免使用 Overlay 内部的 context（可能已 unmounted）
    widget.onLanguageSwitch(lang);
  }

  @override
  Widget build(BuildContext context) {
    // 点击菜单外部关闭
    return Stack(
      children: [
        // 透明遮罩，点击关闭
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),

        // 主菜单
        Positioned(
          left: widget.menuLeft,
          bottom: widget.menuBottom,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            child: SizedBox(
              width: 160,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── 语言切换项（hover 展开子菜单）
                  MouseRegion(
                    onEnter: (_) => setState(() {
                      _langHovered = true;
                      _subMenuOpen = true;
                    }),
                    onExit: (_) => setState(() => _langHovered = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      decoration: BoxDecoration(
                        color: _langHovered
                            ? const Color(0xFFF0F2F5)
                            : Colors.transparent,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/ic_lan_nav.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF333333),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              S.of(context).language,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Color(0xFF8B8FA3),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── 设置项
                  _MainMenuItem(
                    svgPath: 'assets/ic_setting_nav.svg',
                    label: S.of(context).mineSetting,
                    onTap: widget.onSettingTap,
                  ),

                  // ── 退出登录
                  _MainMenuItem(
                    svgPath: 'assets/ic_logout_nav.svg',
                    label: S.of(context).mineLogout,
                    labelColor: const Color(0xFFE6605C),
                    onTap: widget.onLogoutTap,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
        ),

        // 语言子菜单（语言行 hover 时显示）
        if (_subMenuOpen)
          Positioned(
            left: widget.menuLeft + 164, // 主菜单宽度 160 + 4px 间距
            bottom: widget.menuBottom + 72, // 与语言行对齐（设置+退出行高度约 72）
            child: MouseRegion(
              onEnter: (_) => setState(() => _subMenuOpen = true),
              onExit: (_) => setState(() => _subMenuOpen = false),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                child: SizedBox(
                  width: 120,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LangMenuItem(
                        label: S.of(context).languageChinese,
                        langCode: languageZh,
                        currentLang: _currentLanguage,
                        onTap: () => _switchLanguage(languageZh),
                        isFirst: true,
                      ),
                      const Divider(
                          height: 1, thickness: 1, color: Color(0xFFF0F2F5)),
                      _LangMenuItem(
                        label: S.of(context).languageEnglish,
                        langCode: languageEn,
                        currentLang: _currentLanguage,
                        onTap: () => _switchLanguage(languageEn),
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// 主菜单普通项
// ──────────────────────────────────────────────

class _MainMenuItem extends StatefulWidget {
  final String svgPath;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;
  final bool isLast;

  const _MainMenuItem({
    required this.svgPath,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.isLast = false,
  });

  @override
  State<_MainMenuItem> createState() => _MainMenuItemState();
}

class _MainMenuItemState extends State<_MainMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF0F2F5) : Colors.transparent,
            borderRadius: widget.isLast
                ? const BorderRadius.vertical(bottom: Radius.circular(8))
                : BorderRadius.zero,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SvgPicture.asset(
                widget.svgPath,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  widget.labelColor ?? const Color(0xFF333333),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.labelColor ?? const Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 语言子菜单项
// ──────────────────────────────────────────────

class _LangMenuItem extends StatefulWidget {
  final String label;
  final String langCode;
  final String currentLang;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _LangMenuItem({
    required this.label,
    required this.langCode,
    required this.currentLang,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  State<_LangMenuItem> createState() => _LangMenuItemState();
}

class _LangMenuItemState extends State<_LangMenuItem> {
  bool _isHovered = false;

  bool get _isSelected => widget.currentLang.startsWith(widget.langCode);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF0F2F5) : Colors.transparent,
            borderRadius: BorderRadius.vertical(
              top: widget.isFirst ? const Radius.circular(8) : Radius.zero,
              bottom: widget.isLast ? const Radius.circular(8) : Radius.zero,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        _isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: _isSelected
                        ? const Color(0xFF337EFF)
                        : const Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
