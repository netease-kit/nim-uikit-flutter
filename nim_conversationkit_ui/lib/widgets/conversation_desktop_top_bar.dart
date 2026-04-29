// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/utils/color_utils.dart';

import '../l10n/S.dart';
import 'conversation_pop_menu_button.dart';

/// 桌面/Web 端会话列表顶部工具栏
///
/// 包含：
/// - 左侧搜索框（只读，点击触发 [onSearchTap] 回调）
/// - 右侧 "+" 按钮（弹出 [ConversationPopMenuButton] 下拉菜单，以桌面弹框方式打开子页面）
///
/// 使用方式：
/// ```dart
/// ConversationPage(
///   config: ConversationUIConfig(
///     titleBarConfig: const ConversationTitleBarConfig(showTitleBar: false),
///   ),
///   topWidget: ConversationDesktopTopBar(
///     onSearchTap: () {
///       showDesktopDialog(context, const SearchKitGlobalSearchPage());
///     },
///   ),
/// )
/// ```
class ConversationDesktopTopBar extends StatefulWidget {
  const ConversationDesktopTopBar({
    Key? key,
    this.onSearchTap,
  }) : super(key: key);

  /// 点击搜索框时的回调，由调用方决定如何打开搜索页（通常为 showDesktopDialog）
  final VoidCallback? onSearchTap;

  @override
  State<ConversationDesktopTopBar> createState() =>
      _ConversationDesktopTopBarState();
}

class _ConversationDesktopTopBarState extends State<ConversationDesktopTopBar> {
  // GlobalKey 用于定位 "+" 按钮，供 PopupMenuButton 计算偏移
  final GlobalKey _menuButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // 搜索框（只读触发区）
              Expanded(
                child: GestureDetector(
                  onTap: widget.onSearchTap,
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'images/ic_search.svg',
                          width: 16,
                          height: 16,
                          package: 'nim_conversationkit_ui',
                          colorFilter: const ColorFilter.mode(
                            Color(0xFFB3B7BC),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          S.of(context).conversationSearchHint,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFB3B7BC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // "+" 弹出菜单按钮（桌面模式：子页面以弹框打开）
              SizedBox(
                width: 36,
                height: 36,
                child: ConversationPopMenuButton(
                  key: _menuButtonKey,
                  isDesktopMode: true,
                ),
              ),
            ],
          ),
        ),
        // 底部分隔线
        Divider(
          height: 1,
          thickness: 1,
          color: '#DBE0E8'.toColor(),
        ),
      ],
    );
  }
}
