// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final ScrollController _groupScrollController = ScrollController();
  final Map<String, GlobalKey> _groupKeys = {};
  String? _lastSelectedGroupId;
  bool _lastSelectedGroupAlignRight = false;

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
    final selectedIndex =
        groups.indexWhere((group) => group.id == model.selectedGroup.id);
    _scheduleSelectedGroupScroll(
      model.selectedGroup.id,
      alignRight: selectedIndex == groups.length - 1,
    );
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
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              // 移动端不绑定控制器，避免 ensureVisible 级联影响外层会话列表滚动；
              // 分组 tab 横向滚动到选中项仅在桌面端需要（与 10.9.6 行为一致）。
              controller: widget.isDesktop ? _groupScrollController : null,
              padding: EdgeInsets.symmetric(
                horizontal: widget.isDesktop ? 4 : 12,
                vertical: 8,
              ),
              itemCount: groups.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final group = groups[index];
                return KeyedSubtree(
                  key: _keyForGroup(group.id),
                  child: _GroupChip(
                    group: group,
                    selected: group.id == model.selectedGroup.id,
                    count: model.unreadCountForGroup(group),
                    onTap: () {
                      model.selectGroup(group);
                      widget.onGroupSelected?.call();
                    },
                  ),
                );
              },
            ),
          ),
          if (!widget.isDesktop)
            IconButton(
              icon: SvgPicture.asset(
                'images/ic_group_setting.svg',
                package: kPackage,
              ),
              color: CommonColors.color_666666,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  RouterConstants.PATH_CONVERSATION_GROUP_MANAGE_PAGE,
                  arguments: {'model': model},
                );
              },
            ),
        ],
      ),
    );
  }

  GlobalKey _keyForGroup(String groupId) {
    return _groupKeys.putIfAbsent(groupId, GlobalKey.new);
  }

  void _scheduleSelectedGroupScroll(
    String groupId, {
    required bool alignRight,
  }) {
    if (!widget.isDesktop ||
        (_lastSelectedGroupId == groupId &&
            _lastSelectedGroupAlignRight == alignRight)) {
      return;
    }
    _lastSelectedGroupId = groupId;
    _lastSelectedGroupAlignRight = alignRight;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final groupContext = _groupKeys[groupId]?.currentContext;
      if (groupContext == null) {
        return;
      }
      Scrollable.ensureVisible(
        groupContext,
        alignment: alignRight ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
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
