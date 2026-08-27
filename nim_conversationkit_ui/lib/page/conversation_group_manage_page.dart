// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/router/imkit_router_constants.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:provider/provider.dart';

import '../conversation_kit_client.dart';
import '../l10n/S.dart';
import '../model/conversation_group_ui_model.dart';
import '../view_model/conversation_group_view_model.dart';

class ConversationGroupManagePage extends StatelessWidget {
  const ConversationGroupManagePage({
    Key? key,
    required this.model,
  }) : super(key: key);

  final ConversationGroupViewModel model;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ConversationGroupViewModel>.value(
      value: model,
      child: TransparentScaffold(
        title: S.of(context).conversationGroupTitle,
        backgroundColor: Colors.white,
        appBarBackgroundColor: Colors.white,
        elevation: 0.5,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Consumer<ConversationGroupViewModel>(
                  builder: (context, model, child) {
                    return ListView(
                      children: [
                        _SectionTitle(S.of(context).conversationGroupVisible),
                        _GroupReorderList(
                          groups: model.visibleGroups,
                          visibleSection: true,
                        ),
                        _SectionTitle(S.of(context).conversationGroupHidden),
                        if (model.hiddenGroups.isEmpty)
                          const SizedBox(height: 72)
                        else
                          _GroupReorderList(
                            groups: model.hiddenGroups,
                            visibleSection: false,
                          ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _showCreateDialog(context),
                    child: Text(S.of(context).conversationGroupCreate),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CreateGroupSheet(model: model),
    );
  }
}

class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet({required this.model});

  final ConversationGroupViewModel model;

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends BaseState<_CreateGroupSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final sheetHeight =
        (mediaQuery.size.height - keyboardHeight - 82).clamp(300.0, 520.0);
    final canCreate = _controller.text.trim().isNotEmpty;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: ChangeNotifierProvider<ConversationGroupViewModel>.value(
        value: widget.model,
        child: SafeArea(
          top: false,
          child: Container(
            height: sheetHeight,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6FA),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 88,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: CommonColors.color_666666,
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          child: Text(S.of(context).cancelTitle),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            S.of(context).conversationGroupCreate,
                            style: const TextStyle(
                              color: CommonColors.color_333333,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 96,
                        child: TextButton(
                          onPressed: canCreate ? _createGroup : null,
                          style: TextButton.styleFrom(
                            foregroundColor: CommonColors.color_337eff,
                            disabledForegroundColor: CommonColors.color_cccccc,
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          child: Text(S.of(context).sureTitle),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 19),
                  child: _CreateGroupNameInput(
                    controller: _controller,
                    onChanged: () => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createGroup() async {
    final name = _controller.text.trim();
    if (name.isEmpty ||
        !await haveConnectivity(
          gravity: defaultTargetPlatform == TargetPlatform.iOS
              ? ToastGravity.TOP
              : null,
        )) {
      return;
    }
    final result = await widget.model.createGroup(name);
    if (!mounted) {
      return;
    }
    if (result.isSuccess) {
      Navigator.pop(context);
    } else if (result.code ==
        ConversationGroupViewModel.conversationGroupLimit) {
      ChatUIToast.show(
        S.of(context).conversationGroupLimit,
        context: context,
        gravity: defaultTargetPlatform == TargetPlatform.iOS
            ? ToastGravity.TOP
            : null,
      );
    } else {
      ChatUIToast.show(
        result.errorDetails ?? S.of(context).conversationGroupOperationFailed,
        context: context,
      );
    }
  }
}

class _CreateGroupNameInput extends StatelessWidget {
  const _CreateGroupNameInput({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final length = controller.text.characters.length;
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            right: 58,
            bottom: 34,
            child: TextField(
              controller: controller,
              autofocus: true,
              inputFormatters: [
                LengthLimitingTextInputFormatter(
                  ConversationGroupViewModel.maxGroupNameLength,
                ),
              ],
              onChanged: (_) => onChanged(),
              maxLines: 1,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: S.of(context).conversationGroupNameHint,
                contentPadding: const EdgeInsets.fromLTRB(34, 30, 0, 0),
                counterText: '',
              ),
              style: const TextStyle(
                color: CommonColors.color_333333,
                fontSize: 16,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            Positioned(
              top: 32,
              right: 28,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  controller.clear();
                  onChanged();
                },
                child: const Icon(
                  Icons.cancel,
                  size: 20,
                  color: Color(0xFFB7BBC3),
                ),
              ),
            ),
          Positioned(
            right: 33,
            bottom: 15,
            child: Text(
              '$length/${ConversationGroupViewModel.maxGroupNameLength}',
              style: const TextStyle(
                color: Color(0xFFA8ADB6),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFFF7F8FA),
      child: Text(
        title,
        style: const TextStyle(
          color: CommonColors.color_666666,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _GroupReorderList extends StatelessWidget {
  const _GroupReorderList({
    required this.groups,
    required this.visibleSection,
  });

  final List<ConversationGroupUiModel> groups;
  final bool visibleSection;

  @override
  Widget build(BuildContext context) {
    final model = context.read<ConversationGroupViewModel>();
    if (!visibleSection) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return _GroupRow(
            key: ValueKey('hidden_${group.id}'),
            group: group,
            index: index,
            visibleSection: visibleSection,
          );
        },
      );
    }
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: groups.length,
      onReorder: model.reorderVisible,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _GroupRow(
          key: ValueKey('visible_${group.id}'),
          group: group,
          index: index,
          visibleSection:
              visibleSection && group.id != ConversationGroupUiModel.allId,
        );
      },
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
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
    final isVisibleGroup = visibleSection || group.fixedFirst;
    return Container(
      height: 54,
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: isVisibleGroup
                ? SvgPicture.asset(
                    group.canHide
                        ? 'images/ic_group_item_hide.svg'
                        : 'images/ic_group_item_hide_disable.svg',
                    package: kPackage,
                  )
                : SvgPicture.asset(
                    'images/ic_group_item_show.svg',
                    package: kPackage,
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
              style: const TextStyle(fontSize: 16),
            ),
          ),
          if (group.canSetting)
            IconButton(
              icon: SvgPicture.asset(
                'images/ic_group_item_setting.svg',
                package: kPackage,
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  RouterConstants.PATH_CONVERSATION_GROUP_SETTING_PAGE,
                  arguments: {
                    'model': model,
                    'group': group,
                  },
                );
              },
            ),
          if (visibleSection)
            ReorderableDragStartListener(
              index: index,
              enabled: !group.fixedFirst,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SvgPicture.asset(
                  'images/ic_group_item_move.svg',
                  package: kPackage,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
