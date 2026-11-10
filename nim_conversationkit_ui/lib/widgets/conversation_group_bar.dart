// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:netease_common_ui/duo/duo_drawer_navigation.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/router/imkit_router_constants.dart';
import 'package:provider/provider.dart';

import '../conversation_kit_client.dart';
import '../l10n/S.dart';
import '../model/conversation_group_ui_model.dart';
import '../view_model/conversation_group_view_model.dart';

class ConversationGroupBar extends StatefulWidget {
  const ConversationGroupBar({
    Key? key,
    this.isDesktop = false,
    this.isPanelExpanded = false,
    this.onPanelToggle,
    this.onGroupSelected,
    this.panelTapRegionGroupId,
    this.onPanelTapOutside,
  }) : super(key: key);

  final bool isDesktop;
  final bool isPanelExpanded;
  final VoidCallback? onPanelToggle;
  final VoidCallback? onGroupSelected;
  final Object? panelTapRegionGroupId;
  final ValueChanged<PointerDownEvent>? onPanelTapOutside;

  @override
  State<ConversationGroupBar> createState() => _ConversationGroupBarState();
}

class _ConversationGroupBarState extends State<ConversationGroupBar> {
  /// 分组栏横向滚动位置的存储 key。
  ///
  /// 选中自定义分组时，会话列表会先短暂进入空数据态再切回列表态，
  /// 分组栏因此被整体重建。没有存储 key 时横向滚动位置会复位到最左侧，
  /// 导致选中的右侧分组不可见，这里用 PageStorage 保住滚动位置。
  static const String _scrollOffsetStorageKey =
      'conversation_group_bar_scroll_offset';

  /// 分组列表页面是否已经由分组栏入口打开。
  ///
  /// Duo 双屏下左侧会话列表常驻可点，重复点击最右侧入口不应该重复打开、
  /// 重复加载右侧的分组列表页面。使用 State 级静态标记，避免分组栏重建后
  /// 丢失保护；页面出栈（含被替换）后自动复位。
  static bool _managePageOpened = false;

  final ScrollController _groupScrollController = ScrollController();
  final Map<String, GlobalKey> _groupKeys = {};
  String? _lastSelectedGroupId;

  @override
  void dispose() {
    _groupScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!IMKitConfigCenter.enableConversationGroup) {
      return const SizedBox.shrink();
    }
    final model = context.watch<ConversationGroupViewModel>();
    final groups = model.visibleGroups;
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }
    _scheduleSelectedGroupScroll(model.selectedGroup.id);
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          if (widget.isDesktop)
            TapRegion(
              groupId: widget.panelTapRegionGroupId,
              onTapOutside: widget.onPanelTapOutside,
              child: SizedBox(
                width: 44,
                child: Tooltip(
                  message: widget.isPanelExpanded
                      ? S.of(context).closeTitle
                      : S.of(context).conversationGroupTitle,
                  child: IconButton(
                    icon: const Icon(Icons.segment, size: 22),
                    color: CommonColors.color_666666,
                    onPressed: widget.onPanelToggle,
                  ),
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              key: const PageStorageKey<String>(_scrollOffsetStorageKey),
              scrollDirection: Axis.horizontal,
              // 全端统一绑定控制器：选中分组时只调整分组栏自身的滚动位置，
              // 不使用 Scrollable.ensureVisible，避免级联滚动外层会话列表。
              controller: _groupScrollController,
              padding: EdgeInsets.symmetric(
                horizontal: widget.isDesktop ? 4 : 12,
                vertical: 8,
              ),
              // 分组数量有限（默认分组 + 最多 10 个自定义分组），一次性布局
              // 全部 tab，才能在选中项尚未展示时准确计算滚动位置。
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int index = 0; index < groups.length; index++) ...[
                    if (index > 0) const SizedBox(width: 8),
                    KeyedSubtree(
                      key: _keyForGroup(groups[index].id),
                      child: _GroupChip(
                        group: groups[index],
                        selected: groups[index].id == model.selectedGroup.id,
                        count: model.unreadCountForGroup(groups[index]),
                        onTap: () {
                          model.selectGroup(groups[index]);
                          widget.onGroupSelected?.call();
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!widget.isDesktop)
            IconButton(
              icon: SvgPicture.asset(
                'images/ic_group_setting.svg',
                package: kPackage,
              ),
              color: CommonColors.color_666666,
              onPressed: () => _openGroupManagePage(model),
            ),
        ],
      ),
    );
  }

  /// 打开会话分组列表页面，同一时间只允许存在一个入口打开的页面。
  ///
  /// Duo 双屏下分组入口属于左侧常驻列表，右侧已有聊天等抽屉页面时应替换
  /// 当前抽屉而不是叠加路由；否则折叠单屏后返回会先回到上一个抽屉页面，
  /// 而不是回到左侧会话列表。其他形态保持普通 push。
  Future<void> _openGroupManagePage(ConversationGroupViewModel model) async {
    if (_managePageOpened) {
      return;
    }
    _managePageOpened = true;
    try {
      await pushDuoDrawerNamed(
        context,
        RouterConstants.PATH_CONVERSATION_GROUP_MANAGE_PAGE,
        arguments: {'model': model},
      );
    } finally {
      _managePageOpened = false;
    }
  }

  GlobalKey _keyForGroup(String groupId) {
    return _groupKeys.putIfAbsent(groupId, GlobalKey.new);
  }

  void _scheduleSelectedGroupScroll(String groupId) {
    if (_lastSelectedGroupId == groupId) {
      return;
    }
    _lastSelectedGroupId = groupId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (!_revealSelectedGroup(groupId)) {
        // 分组栏尚未完成布局（例如页面暂时离屏），下次构建时重新尝试。
        _lastSelectedGroupId = null;
      }
    });
  }

  /// 保证选中的分组 tab 完整展示在分组栏可视区域内。
  ///
  /// 只在分组栏自身的横向滚动视图内计算偏移量，不调用
  /// [Scrollable.ensureVisible]，避免把滚动级联到外层会话列表。
  ///
  /// 返回 false 表示当前布局信息还不完整，需要后续重试。
  bool _revealSelectedGroup(String groupId) {
    if (!_groupScrollController.hasClients) {
      return false;
    }
    final RenderObject? groupObject =
        _groupKeys[groupId]?.currentContext?.findRenderObject();
    if (groupObject is! RenderBox ||
        !groupObject.attached ||
        !groupObject.hasSize) {
      return false;
    }
    final RenderObject? viewport = RenderAbstractViewport.maybeOf(groupObject);
    if (viewport is! RenderBox) {
      return false;
    }
    final ScrollPosition position = _groupScrollController.position;
    if (!position.hasPixels || !position.hasContentDimensions) {
      return false;
    }
    final double groupStart =
        groupObject.localToGlobal(Offset.zero, ancestor: viewport).dx;
    final double groupEnd = groupStart + groupObject.size.width;
    final double viewportWidth = viewport.size.width;
    double target = position.pixels;
    if (groupStart < 0) {
      target += groupStart;
    } else if (groupEnd > viewportWidth) {
      target += groupEnd - viewportWidth;
    }
    target = target
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((target - position.pixels).abs() < 0.5) {
      return true;
    }
    _groupScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
    return true;
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.group,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  final ConversationGroupUiModel group;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor =
        selected ? CommonColors.color_337eff : CommonColors.color_333333;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 32,
        constraints: const BoxConstraints(minWidth: 52),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? CommonColors.color_337eff.withValues(alpha: 0.1)
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              group.name,
              maxLines: 1,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (count > 0)
              Text(
                "(${count > 99 ? '99+' : count})",
                maxLines: 1,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
