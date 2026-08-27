// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:provider/provider.dart';

import '../l10n/S.dart';
import '../model/conversation_group_ui_model.dart';
import '../view_model/conversation_group_view_model.dart';
import 'conversation_group_desktop_dialogs.dart';

class ConversationGroupDesktopPanel extends StatelessWidget {
  const ConversationGroupDesktopPanel({
    Key? key,
    this.onCollapse,
  }) : super(key: key);

  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context) {
    if (!IMKitConfigCenter.enableConversationGroup) {
      return const SizedBox.shrink();
    }
    final model = context.watch<ConversationGroupViewModel>();
    return _DesktopGroupList(
      model: model,
      onCollapse: onCollapse ?? () {},
    );
  }
}

class _DesktopGroupList extends StatelessWidget {
  const _DesktopGroupList({
    required this.model,
    required this.onCollapse,
  });

  final ConversationGroupViewModel model;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final groups = model.visibleGroups;
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE9EFF5), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                IconButton(
                  tooltip: S.of(context).closeTitle,
                  icon: const Icon(Icons.segment, size: 22),
                  color: CommonColors.color_666666,
                  onPressed: onCollapse,
                ),
                Expanded(
                  child: Text(
                    S.of(context).conversationGroupTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CommonColors.color_333333,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: S.of(context).conversationGroupSetting,
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  color: CommonColors.color_666666,
                  onPressed: () {
                    showConversationGroupManageDialog(context, model);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return _DesktopGroupRow(
                  group: group,
                  selected: group.id == model.selectedGroup.id,
                  onTap: () {
                    model.selectGroup(group);
                    onCollapse();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopGroupRow extends StatelessWidget {
  const _DesktopGroupRow({
    required this.group,
    required this.selected,
    required this.onTap,
  });

  final ConversationGroupUiModel group;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = _unreadCount(context);
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              _iconData(),
              size: 16,
              color: selected
                  ? CommonColors.color_337eff
                  : CommonColors.color_999999,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                group.name,
                softWrap: true,
                style: TextStyle(
                  color: selected
                      ? CommonColors.color_337eff
                      : CommonColors.color_333333,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (unread > 0)
              Text(
                "(${unread > 99 ? '99+' : unread})",
                softWrap: true,
                style: TextStyle(
                  color: selected
                      ? CommonColors.color_337eff
                      : CommonColors.color_333333,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconData() {
    switch (group.kind) {
      case ConversationGroupKind.all:
        return Icons.chat_bubble_outline;
      case ConversationGroupKind.aitMe:
        return Icons.alternate_email;
      case ConversationGroupKind.unread:
        return Icons.mark_chat_unread_outlined;
      case ConversationGroupKind.custom:
        return Icons.forum_outlined;
    }
  }

  int _unreadCount(BuildContext context) {
    final model = context.read<ConversationGroupViewModel>();
    return model.unreadCountForGroup(group);
  }
}
