// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/text_search.dart';
import 'package:nim_chatkit/repo/conversation_repo.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:provider/provider.dart';

import '../conversation_kit_client.dart';
import '../l10n/S.dart';
import '../model/conversation_group_ui_model.dart';
import '../model/conversation_info.dart';
import '../view_model/conversation_group_view_model.dart';

Future<void> showConversationGroupManageDialog(
  BuildContext context,
  ConversationGroupViewModel model,
) {
  return _showDesktopDialog<void>(
    context,
    width: 620,
    height: 580,
    child: ChangeNotifierProvider<ConversationGroupViewModel>.value(
      value: model,
      child: _ManageDialog(model: model),
    ),
  );
}

Future<void> _showSettingDialog(
  BuildContext context,
  ConversationGroupViewModel model,
  ConversationGroupUiModel group,
) {
  return _showDesktopDialog<void>(
    context,
    width: 520,
    height: 680,
    child: ChangeNotifierProvider<ConversationGroupViewModel>.value(
      value: model,
      child: _SettingDialog(model: model, group: group),
    ),
  );
}

Future<void> _showCreateDialog(
  BuildContext context,
  ConversationGroupViewModel model,
) {
  return _showDesktopDialog<void>(
    context,
    width: 520,
    height: 680,
    child: ChangeNotifierProvider<ConversationGroupViewModel>.value(
      value: model,
      child: _CreateDialog(model: model),
    ),
  );
}

Future<T?> _showDesktopDialog<T>(
  BuildContext context, {
  required double width,
  required double height,
  required Widget child,
}) {
  final size = MediaQuery.of(context).size;
  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: size.width - 48,
            maxHeight: size.height - 48,
          ),
          child: SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Material(
                color: Colors.white,
                child: child,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.title,
    this.onClose,
  });

  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.only(left: 24, right: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9EFF5), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: CommonColors.color_333333,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: CommonColors.color_666666,
            onPressed: onClose ?? () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _ManageDialog extends StatelessWidget {
  const _ManageDialog({required this.model});

  final ConversationGroupViewModel model;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DialogHeader(title: S.of(context).conversationGroupTitle),
        Expanded(
          child: Consumer<ConversationGroupViewModel>(
            builder: (context, model, child) {
              return Row(
                children: [
                  Expanded(
                    child: _DialogGroupColumn(
                      title: S.of(context).conversationGroupVisible,
                      groups: model.visibleGroups,
                      visibleSection: true,
                    ),
                  ),
                  Container(width: 1, color: const Color(0xFFE9EFF5)),
                  Expanded(
                    child: _DialogGroupColumn(
                      title: S.of(context).conversationGroupHidden,
                      groups: model.hiddenGroups,
                      visibleSection: false,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFE9EFF5), width: 1),
            ),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showCreateDialog(context, model),
                icon: const Icon(Icons.add, size: 18),
                label: Text(S.of(context).conversationGroupCreate),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(S.of(context).sureTitle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DialogGroupColumn extends StatelessWidget {
  const _DialogGroupColumn({
    required this.title,
    required this.groups,
    required this.visibleSection,
  });

  final String title;
  final List<ConversationGroupUiModel> groups;
  final bool visibleSection;

  @override
  Widget build(BuildContext context) {
    final model = context.read<ConversationGroupViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          child: Text(
            title,
            style: const TextStyle(
              color: CommonColors.color_333333,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: visibleSection
              ? ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  buildDefaultDragHandles: false,
                  itemCount: groups.length,
                  onReorder: model.reorderVisible,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return _DialogGroupRow(
                      key: ValueKey('visible_${group.id}'),
                      group: group,
                      index: index,
                      visibleSection: visibleSection,
                    );
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return _DialogGroupRow(
                      key: ValueKey('hidden_${group.id}'),
                      group: group,
                      index: index,
                      visibleSection: visibleSection,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DialogGroupRow extends StatelessWidget {
  const _DialogGroupRow({
    Key? key,
    required this.group,
    required this.index,
    required this.visibleSection,
  }) : super(key: key);

  final ConversationGroupUiModel group;
  final int index;
  final bool visibleSection;

  @override
  Widget build(BuildContext context) {
    final model = context.read<ConversationGroupViewModel>();
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F2F5), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              visibleSection ? Icons.remove_circle : Icons.add_circle,
              size: 20,
              color: group.canHide
                  ? (visibleSection
                      ? const Color(0xFFF24957)
                      : const Color(0xFF36B39B))
                  : CommonColors.color_cccccc,
            ),
            onPressed: group.canHide
                ? () {
                    if (visibleSection) {
                      model.hideGroup(group);
                    } else {
                      model.showGroup(group);
                    }
                  }
                : null,
          ),
          Expanded(
            child: Text(
              group.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CommonColors.color_333333,
                fontSize: 15,
              ),
            ),
          ),
          if (group.canSetting)
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 20),
              color: CommonColors.color_999999,
              onPressed: () => _showSettingDialog(context, model, group),
            ),
          if (visibleSection)
            ReorderableDragStartListener(
              index: index,
              enabled: !group.fixedFirst,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child:
                    Icon(Icons.drag_handle, color: CommonColors.color_cccccc),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingDialog extends StatefulWidget {
  const _SettingDialog({
    required this.model,
    required this.group,
  });

  final ConversationGroupViewModel model;
  final ConversationGroupUiModel group;

  @override
  State<_SettingDialog> createState() => _SettingDialogState();
}

class _SettingDialogState extends State<_SettingDialog> {
  late final TextEditingController _nameController;
  Timer? _nameSaveTimer;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.model.loadAllConversationsForGroup(widget.group);
      }
    });
  }

  @override
  void dispose() {
    _nameSaveTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _selectAllIfCurrentGroupIsHidden() {
    final group = widget.model.groups.firstWhere(
      (item) => item.id == widget.group.id,
      orElse: () => widget.group,
    );
    if (!group.visible) {
      widget.model.selectAllGroup();
    }
  }

  void _onPopInvoked(bool didPop, Object? result) {
    if (didPop) {
      return;
    }
    _selectAllIfCurrentGroupIsHidden();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: Consumer<ConversationGroupViewModel>(
        builder: (context, model, child) {
          final group = model.groups.firstWhere(
            (item) => item.id == widget.group.id,
            orElse: () => widget.group,
          );
          final conversations = model.selectedGroup.id == group.id
              ? model.displayConversations
              : <ConversationInfo>[];
          return Column(
            children: [
              _DialogHeader(
                title: S.of(context).conversationGroupSetting,
                onClose: () async {
                  await _flushName(group);
                  if (mounted) {
                    _selectAllIfCurrentGroupIsHidden();
                    Navigator.pop(context);
                  }
                },
              ),
              Expanded(
                child: _GroupEditBody(
                  nameController: _nameController,
                  conversations: conversations,
                  onNameChanged: () => _scheduleUpdateName(group),
                  onAddConversation: () async {
                    await model.loadAllConversationsForGroup(group);
                    if (!context.mounted) {
                      return;
                    }
                    await _showAddConversationDialog(
                      context,
                      model: model,
                      group: group,
                      initialIds: model.displayConversations
                          .map((conversation) =>
                              conversation.getConversationId())
                          .toSet(),
                      saveToGroup: true,
                    );
                  },
                  onRemoveConversation: (conversation) {
                    model.removeConversationsFromGroup(
                      group,
                      [conversation.getConversationId()],
                    );
                  },
                ),
              ),
              _SettingFooter(
                onDelete: () => _confirmDelete(group),
                onConfirm: () async {
                  await _flushName(group);
                  if (mounted) {
                    _selectAllIfCurrentGroupIsHidden();
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _scheduleUpdateName(ConversationGroupUiModel group) {
    setState(() {});
    _nameSaveTimer?.cancel();
    _nameSaveTimer = Timer(const Duration(milliseconds: 500), () {
      _updateName(group);
    });
  }

  Future<void> _flushName(ConversationGroupUiModel group) async {
    _nameSaveTimer?.cancel();
    await _updateName(group);
  }

  Future<void> _updateName(ConversationGroupUiModel group) async {
    final name = _nameController.text.trim();
    if (name.isEmpty ||
        name == group.name ||
        name.length > ConversationGroupViewModel.maxGroupNameLength) {
      return;
    }
    final result =
        await widget.model.updateGroupName(group, _nameController.text);
    if (!result.isSuccess && mounted) {
      ChatUIToast.show(
        result.errorDetails ?? S.of(context).conversationGroupOperationFailed,
        context: context,
      );
    }
  }

  void _confirmDelete(ConversationGroupUiModel group) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(S.of(context).conversationGroupDeleteConfirmTitle),
          content: Text(S.of(context).conversationGroupDeleteConfirmContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(S.of(context).cancelTitle),
            ),
            TextButton(
              onPressed: () async {
                final result = await widget.model.deleteGroup(group);
                Navigator.pop(dialogContext);
                if (result.isSuccess) {
                  if (mounted) {
                    Navigator.pop(context);
                  }
                } else if (mounted) {
                  ChatUIToast.show(
                    result.errorDetails ??
                        S.of(context).conversationGroupOperationFailed,
                    context: context,
                  );
                }
              },
              child: Text(S.of(context).deleteTitle),
            ),
          ],
        );
      },
    );
  }
}

class _CreateDialog extends StatefulWidget {
  const _CreateDialog({required this.model});

  final ConversationGroupViewModel model;

  @override
  State<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends BaseState<_CreateDialog> {
  final TextEditingController _nameController = TextEditingController();
  final List<ConversationInfo> _selectedConversations = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = _nameController.text.trim().isNotEmpty;
    return Column(
      children: [
        _DialogHeader(title: S.of(context).conversationGroupCreate),
        Expanded(
          child: _GroupEditBody(
            nameController: _nameController,
            conversations: _selectedConversations,
            onNameChanged: () => setState(() {}),
            onAddConversation: _selectConversations,
            onRemoveConversation: (conversation) {
              setState(() {
                _selectedConversations.removeWhere(
                  (item) =>
                      item.getConversationId() ==
                      conversation.getConversationId(),
                );
              });
            },
          ),
        ),
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFE9EFF5), width: 1),
            ),
          ),
          child: Row(
            children: [
              const Spacer(),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(S.of(context).cancelTitle),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: canCreate ? _createGroup : null,
                child: Text(S.of(context).sureTitle),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectConversations() async {
    final result = await _showAddConversationDialog(
      context,
      model: widget.model,
      initialIds: _selectedConversations
          .map((conversation) => conversation.getConversationId())
          .toSet(),
      saveToGroup: false,
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _selectedConversations
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || !checkNetwork()) {
      return;
    }
    final result = await widget.model.createGroup(
      name,
      conversationIds: _selectedConversations
          .map((conversation) => conversation.getConversationId())
          .toList(),
    );
    if (result.isSuccess) {
      if (mounted) {
        Navigator.pop(context);
      }
    } else if (mounted) {
      if (result.code == ConversationGroupViewModel.conversationGroupLimit) {
        ChatUIToast.show(
          S.of(context).conversationGroupLimit,
          context: context,
        );
      } else {
        ChatUIToast.show(
          result.errorDetails ?? S.of(context).conversationGroupOperationFailed,
          context: context,
        );
      }
    }
  }
}

class _GroupEditBody extends StatelessWidget {
  const _GroupEditBody({
    required this.nameController,
    required this.conversations,
    required this.onNameChanged,
    required this.onAddConversation,
    required this.onRemoveConversation,
  });

  final TextEditingController nameController;
  final List<ConversationInfo> conversations;
  final VoidCallback onNameChanged;
  final VoidCallback onAddConversation;
  final ValueChanged<ConversationInfo> onRemoveConversation;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      children: [
        Text(
          S.of(context).conversationGroupName,
          style: const TextStyle(
            color: CommonColors.color_333333,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: nameController,
          maxLength: ConversationGroupViewModel.maxGroupNameLength,
          onChanged: (_) => onNameChanged(),
          decoration: InputDecoration(
            hintText: S.of(context).conversationGroupNameHint,
            suffixIcon: IconButton(
              icon: const Icon(Icons.cancel, size: 18),
              onPressed: () {
                nameController.clear();
                onNameChanged();
              },
            ),
            border: const OutlineInputBorder(),
            counterText:
                '${nameController.text.length}/${ConversationGroupViewModel.maxGroupNameLength}',
          ),
        ),
        const SizedBox(height: 20),
        Text(
          S.of(context).conversationGroupConversationList,
          style: const TextStyle(
            color: CommonColors.color_333333,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: onAddConversation,
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: CommonColors.color_cccccc),
                  ),
                  child:
                      const Icon(Icons.add, color: CommonColors.color_999999),
                ),
                const SizedBox(width: 12),
                Text(
                  S.of(context).conversationGroupAddConversation,
                  style: const TextStyle(
                    color: CommonColors.color_333333,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (conversations.isEmpty)
          const _DialogEmptyView()
        else
          ...conversations.map(
            (conversation) => _ConversationEditRow(
              conversation: conversation,
              onRemove: () => onRemoveConversation(conversation),
            ),
          ),
      ],
    );
  }
}

class _SettingFooter extends StatelessWidget {
  const _SettingFooter({
    required this.onDelete,
    required this.onConfirm,
  });

  final VoidCallback onDelete;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE9EFF5), width: 1),
        ),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(S.of(context).conversationGroupDeleteConfirmTitle),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF24957),
              side: const BorderSide(color: Color(0xFFF24957)),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onConfirm,
            child: Text(S.of(context).sureTitle),
          ),
        ],
      ),
    );
  }
}

class _ConversationEditRow extends StatelessWidget {
  const _ConversationEditRow({
    required this.conversation,
    required this.onRemove,
  });

  final ConversationInfo conversation;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F2F5), width: 1),
        ),
      ),
      child: Row(
        children: [
          Avatar(
            avatar: conversation.getAvatar() ?? '',
            name: conversation.getName(),
            width: 40,
            height: 40,
            radius: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              conversation.getName(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CommonColors.color_333333,
                fontSize: 15,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: onRemove,
            child: Text(S.of(context).deleteTitle),
          ),
        ],
      ),
    );
  }
}

Future<List<ConversationInfo>?> _showAddConversationDialog(
  BuildContext context, {
  required ConversationGroupViewModel model,
  ConversationGroupUiModel? group,
  required Set<String> initialIds,
  required bool saveToGroup,
}) {
  return _showDesktopDialog<List<ConversationInfo>>(
    context,
    width: 520,
    height: 680,
    child: ChangeNotifierProvider<ConversationGroupViewModel>.value(
      value: model,
      child: _AddConversationDialog(
        model: model,
        group: group,
        initialIds: initialIds,
        saveToGroup: saveToGroup,
      ),
    ),
  );
}

class _AddConversationDialog extends StatefulWidget {
  const _AddConversationDialog({
    required this.model,
    required this.initialIds,
    required this.saveToGroup,
    this.group,
  });

  final ConversationGroupViewModel model;
  final ConversationGroupUiModel? group;
  final Set<String> initialIds;
  final bool saveToGroup;

  @override
  State<_AddConversationDialog> createState() => _AddConversationDialogState();
}

class _AddConversationDialogState extends BaseState<_AddConversationDialog> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _initialConversationIds = {};
  final Set<String> _selectedIds = {};
  final List<ConversationInfo> _allConversations = [];
  final List<ConversationInfo> _showConversations = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _finished = false;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _initialConversationIds.addAll(widget.initialIds);
    if (!widget.saveToGroup) {
      _selectedIds.addAll(widget.initialIds);
    }
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_filterConversations);
    _loadConversations(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  bool _isInTargetGroup(ConversationInfo conversation) {
    if (!widget.saveToGroup) {
      return false;
    }
    final conversationId = conversation.getConversationId();
    return _initialConversationIds.contains(conversationId) ||
        conversation.conversation.groupIds?.contains(widget.group?.id) == true;
  }

  void _onScroll() {
    if (_isSearching || _loading || _loadingMore || _finished) {
      return;
    }
    if (!_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 48) {
      _loadConversations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AddConversationHeader(
          selectedCount: _selectedIds.length,
          onCancel: () => Navigator.pop(context),
          onConfirm: _submit,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: S.of(context).conversationGroupSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: _searchController.clear,
                    ),
              filled: true,
              fillColor: const Color(0xFFF2F3F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _showConversations.isEmpty
                  ? const _DialogEmptyView()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _showConversations.length +
                          (!_isSearching && _loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _showConversations.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        }
                        final conversation = _showConversations[index];
                        return _ConversationSelectRow(
                          conversation: conversation,
                          keyword: _searchController.text.trim(),
                          selected: _selectedIds
                              .contains(conversation.getConversationId()),
                          onChanged: (selected) =>
                              _toggleConversation(conversation, selected),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Future<void> _loadConversations({bool refresh = false}) async {
    if (_isSearching && !refresh) {
      return;
    }
    if (refresh) {
      _offset = 0;
      _finished = false;
      _allConversations.clear();
    }
    if (_loading || _loadingMore || _finished) {
      return;
    }
    if (mounted) {
      setState(() {
        if (refresh) {
          _loading = true;
        } else {
          _loadingMore = true;
        }
      });
    }
    final result = await ConversationRepo.getConversationList(
      _offset,
      widget.model.conversationViewModel.pageLimit,
    );
    if (!mounted) {
      return;
    }
    final conversations =
        widget.model.conversationViewModel.convertConversationInfo(
              result?.conversationList,
            ) ??
            [];
    if (result != null) {
      _offset = result.offset;
      _finished = result.finished;
    } else {
      _finished = true;
    }
    final existingIds = _allConversations
        .map((conversation) => conversation.getConversationId())
        .toSet();
    _allConversations.addAll(
      conversations.where(
        (conversation) =>
            !existingIds.contains(conversation.getConversationId()),
      ),
    );
    _filterConversations();
    if (!_isSearching &&
        _showConversations.length <
            widget.model.conversationViewModel.pageLimit &&
        !_finished) {
      _loading = false;
      _loadingMore = false;
      await _loadConversations();
      return;
    }
    setState(() {
      _loading = false;
      _loadingMore = false;
    });
  }

  void _filterConversations() {
    final keyword = _searchController.text.trim();
    _showConversations
      ..clear()
      ..addAll(
        keyword.isEmpty
            ? _allConversations.where(
                (conversation) => !_isInTargetGroup(conversation),
              )
            : _allConversations.where((conversation) {
                return !_isInTargetGroup(conversation) &&
                    conversation.getName().contains(keyword);
              }),
      );
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleConversation(ConversationInfo conversation, bool selected) {
    final conversationId = conversation.getConversationId();
    if (selected) {
      final selectionLimit = widget.saveToGroup
          ? ConversationGroupViewModel.maxGroupConversationCount -
              _initialConversationIds.length
          : ConversationGroupViewModel.maxGroupConversationCount;
      if (_selectedIds.length >= selectionLimit) {
        ChatUIToast.show(
          S.of(context).conversationGroupConversationLimit,
          context: context,
        );
        return;
      }
      if ((conversation.conversation.groupIds?.length ?? 0) >=
              ConversationGroupViewModel.maxConversationGroupCount &&
          !_selectedIds.contains(conversationId)) {
        ChatUIToast.show(
          S.of(context).conversationGroupJoinedLimit,
          context: context,
        );
        return;
      }
      _selectedIds.add(conversationId);
    } else {
      _selectedIds.remove(conversationId);
    }
    setState(() {});
  }

  Future<void> _submit() async {
    final selectedConversations = _allConversations
        .where(
          (conversation) =>
              _selectedIds.contains(conversation.getConversationId()),
        )
        .toList();
    if (widget.saveToGroup && widget.group != null) {
      if (!checkNetwork()) {
        return;
      }
      final addIds = _selectedIds.toList();
      if (addIds.isNotEmpty) {
        final result = await widget.model.addConversationsToGroup(
          widget.group!,
          addIds,
        );
        if (!result.isSuccess) {
          final joinGroupLimit =
              ConversationGroupViewModel.isConversationJoinGroupLimit(
            result.code,
          );
          await _refreshConversationsAfterAddFailure(
            clearSelection: !joinGroupLimit,
          );
          if (mounted) {
            if (joinGroupLimit) {
              ChatUIToast.show(
                S.of(context).conversationGroupJoinedLimit,
                context: context,
              );
            } else if (result.code ==
                ConversationGroupViewModel
                    .conversationGroupConversationCountLimit) {
              ChatUIToast.show(
                S.of(context).conversationGroupConversationCountLimit,
                context: context,
              );
            } else if (result.code ==
                ConversationGroupViewModel.conversationNotExist) {
              ChatUIToast.show(
                S.of(context).conversationGroupConversationNotExist,
                context: context,
              );
            } else {
              ChatUIToast.show(
                result.errorDetails ??
                    S.of(context).conversationGroupOperationFailed,
                context: context,
              );
            }
          }
          return;
        }
        if (result.data?.isNotEmpty == true && mounted) {
          final hasJoinGroupLimit = result.data!.any(
            (operation) =>
                ConversationGroupViewModel.isConversationJoinGroupLimit(
              operation.error?.code,
            ),
          );
          final allConversationsFailed = addIds.every(
            (conversationId) => result.data!.any(
              (operation) => operation.conversationId == conversationId,
            ),
          );
          await _refreshConversationsAfterAddFailure(
            clearSelection: !(allConversationsFailed && hasJoinGroupLimit),
          );
          if (!mounted) {
            return;
          }
          if (!allConversationsFailed) {
            ChatUIToast.show(
              S.of(context).conversationGroupPartialAddFailed,
              context: context,
            );
            Navigator.pop(context, selectedConversations);
            return;
          }
          ChatUIToast.show(
            hasJoinGroupLimit
                ? S.of(context).conversationGroupJoinedLimit
                : result.data!.any(
                    (operation) =>
                        operation.error?.code ==
                        ConversationGroupViewModel.conversationNotExist,
                  )
                    ? S.of(context).conversationGroupConversationNotExist
                    : S.of(context).conversationGroupPartialAddFailed,
            context: context,
          );
          return;
        }
      }
    }
    if (mounted) {
      Navigator.pop(context, selectedConversations);
    }
  }

  Future<void> _refreshConversationsAfterAddFailure({
    bool clearSelection = true,
  }) async {
    await widget.model.conversationViewModel.queryConversationList();
    if (!mounted) {
      return;
    }
    _initialConversationIds
      ..clear()
      ..addAll(
        widget.model.displayConversations.map(
          (conversation) => conversation.getConversationId(),
        ),
      );
    if (clearSelection) {
      _selectedIds.clear();
    }
    await _loadConversations(refresh: true);
  }
}

class _AddConversationHeader extends StatelessWidget {
  const _AddConversationHeader({
    required this.selectedCount,
    required this.onCancel,
    required this.onConfirm,
  });

  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9EFF5), width: 1),
        ),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: onCancel,
            child: Text(S.of(context).cancelTitle),
          ),
          Expanded(
            child: Center(
              child: Text(
                S.of(context).conversationGroupAddTitle(
                      selectedCount,
                      ConversationGroupViewModel.maxGroupConversationCount,
                    ),
                style: const TextStyle(
                  color: CommonColors.color_333333,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: onConfirm,
            child: Text(S.of(context).sureTitle),
          ),
        ],
      ),
    );
  }
}

class _ConversationSelectRow extends StatelessWidget {
  const _ConversationSelectRow({
    required this.conversation,
    required this.keyword,
    required this.selected,
    required this.onChanged,
  });

  final ConversationInfo conversation;
  final String keyword;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: selected,
        onChanged: (value) => onChanged(value ?? false),
      ),
      title: Row(
        children: [
          Avatar(
            avatar: conversation.getAvatar() ?? '',
            name: conversation.getName(),
            width: 40,
            height: 40,
            radius: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: keyword.isEmpty
                ? Text(
                    conversation.getName(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : TextSearcher.hitWidget(
                    conversation.getName(),
                    keyword,
                    const TextStyle(
                      color: CommonColors.color_333333,
                      fontSize: 16,
                    ),
                    const TextStyle(
                      color: CommonColors.color_337eff,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      onTap: () => onChanged(!selected),
    );
  }
}

class _DialogEmptyView extends StatelessWidget {
  const _DialogEmptyView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 72),
      child: Column(
        children: [
          SvgPicture.asset(
            'images/ic_search_empty.svg',
            package: kPackage,
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).conversationEmpty,
            style: const TextStyle(
              color: CommonColors.color_b3b7bc,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
