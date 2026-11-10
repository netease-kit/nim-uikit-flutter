// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/duo/duo_dialog.dart';
import 'package:netease_common_ui/duo/duo_dialog_chrome.dart';
import 'package:netease_common_ui/duo/duo_shell_controller.dart';
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
    final page = ChangeNotifierProvider<ConversationGroupViewModel>.value(
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
    // Duo 折叠/双屏下，路由已经为右侧工具栏预留了宽度，但系统上报的右侧
    // 安全区（内屏摄像头/状态栏）比工具栏更宽。页面里的 AppBar 和 SafeArea
    // 会再按安全区内缩一次，导致列表、标题栏右侧空出一条空白。
    // 这里仅在 Duo 路径去掉右侧安全区，让内容贴齐内容区右边缘；
    // 普通 iPhone、Android、桌面端行为保持不变。
    if (!DuoShellController.instance.enabled) {
      return page;
    }
    return MediaQuery.removePadding(
      context: context,
      removeRight: true,
      child: page,
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDuoModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        // Duo 弹框路由已经按可见内容区（折叠单屏扣除右侧工具栏）布局，
        // 标题行和输入框不会被工具栏遮挡，这里不再额外让位。
        return _CreateGroupSheet(model: model);
      },
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
    // 折叠单屏高度较矮，键盘弹起后按 300 的最小高度会把弹框顶部顶出屏幕；
    // Duo 上放宽最小高度，保证标题和输入框完整展示。其他设备保持原值。
    final double minSheetHeight =
        DuoShellController.instance.enabled ? 220.0 : 300.0;
    final sheetHeight = (mediaQuery.size.height - keyboardHeight - 82).clamp(
      minSheetHeight,
      520.0,
    );
    final canCreate = _controller.text.trim().isNotEmpty;
    // Duo 上弹框的取消/确定统一放到右侧工具栏，弹框内只保留标题和输入框。
    final bool duo = DuoShellController.instance.enabled;
    final Widget sheet = AnimatedPadding(
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Duo 上取消/确定已经放到右侧工具栏，弹框内不再为按钮
                      // 预留宽度；折叠/展开过渡帧里弹框可能被压到很窄，普通
                      // 设备也按可用宽度收缩两侧占位，避免标题行溢出。
                      final double sideWidth;
                      if (duo) {
                        sideWidth = 0;
                      } else if (!constraints.maxWidth.isFinite ||
                          constraints.maxWidth >= 192) {
                        sideWidth = 96;
                      } else {
                        sideWidth = constraints.maxWidth * 0.28;
                      }
                      return Row(
                        children: [
                          if (sideWidth > 0)
                            SizedBox(
                              width: sideWidth,
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: CommonColors.color_333333,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (sideWidth > 0)
                            SizedBox(
                              width: sideWidth,
                              child: TextButton(
                                onPressed: canCreate ? _createGroup : null,
                                style: TextButton.styleFrom(
                                  foregroundColor: CommonColors.color_337eff,
                                  disabledForegroundColor:
                                      CommonColors.color_cccccc,
                                  textStyle: const TextStyle(fontSize: 16),
                                ),
                                child: Text(S.of(context).sureTitle),
                              ),
                            ),
                        ],
                      );
                    },
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
    if (!duo) {
      return sheet;
    }
    return DuoDialogChrome(
      // Duo 工具栏上是“取消/确定”，不是返回按钮；外层 Padding 避免
      // normalizeDuoLeading 把 TextButton 统一替换成返回图标。
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          style: TextButton.styleFrom(
            foregroundColor: CommonColors.color_666666,
            textStyle: const TextStyle(fontSize: 16),
          ),
          child: Text(S.of(context).cancelTitle),
        ),
      ),
      actions: [
        TextButton(
          onPressed: canCreate ? _createGroup : null,
          style: TextButton.styleFrom(
            foregroundColor: CommonColors.color_337eff,
            disabledForegroundColor: CommonColors.color_cccccc,
            textStyle: const TextStyle(fontSize: 16),
          ),
          child: Text(S.of(context).sureTitle),
        ),
      ],
      child: sheet,
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
