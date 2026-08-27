// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:netease_common_ui/widgets/update_text_info_page.dart';
import 'package:nim_chatkit/router/imkit_router_constants.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:provider/provider.dart';

import '../conversation_kit_client.dart';
import '../l10n/S.dart';
import '../model/conversation_group_ui_model.dart';
import '../model/conversation_info.dart';
import '../view_model/conversation_group_view_model.dart';

class ConversationGroupSettingPage extends StatefulWidget {
  const ConversationGroupSettingPage({
    Key? key,
    required this.model,
    required this.group,
  }) : super(key: key);

  final ConversationGroupViewModel model;
  final ConversationGroupUiModel group;

  @override
  State<ConversationGroupSettingPage> createState() =>
      _ConversationGroupSettingPageState();
}

class _ConversationGroupSettingPageState
    extends BaseState<ConversationGroupSettingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.model.loadAllConversationsForGroup(widget.group);
      }
    });
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

  void _onBackPressed() {
    _selectAllIfCurrentGroupIsHidden();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ConversationGroupViewModel>.value(
      value: widget.model,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: _onPopInvoked,
        child: TransparentScaffold(
          title: S.of(context).conversationGroupSetting,
          leading: IconButton(
            icon: TransparentScaffold.defaultLeadingIcon ??
                const Icon(Icons.arrow_back_ios_rounded, size: 26),
            onPressed: _onBackPressed,
          ),
          actions: [
            TextButton(
              onPressed: () => _confirmDelete(context),
              child: Text(
                S.of(context).deleteTitle,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
          body: Consumer<ConversationGroupViewModel>(
            builder: (context, model, child) {
              final currentGroup = model.groups.firstWhere(
                (item) => item.id == widget.group.id,
                orElse: () => widget.group,
              );
              final conversations = model.selectedGroup.id == currentGroup.id
                  ? model.displayConversations
                  : <ConversationInfo>[];
              return ListView(
                children: [
                  ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            S.of(context).conversationGroupName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Text(
                            currentGroup.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: CommonColors.color_999999,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => _editName(context, currentGroup),
                  ),
                  _ConversationCountHeader(count: conversations.length),
                  ListTile(
                    leading: SvgPicture.asset(
                      'images/ic_group_add_conversation.svg',
                      package: kPackage,
                    ),
                    title: Text(
                      S.of(context).conversationGroupAddConversation,
                    ),
                    onTap: () async {
                      await model.loadAllConversationsForGroup(currentGroup);
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.pushNamed(
                        context,
                        RouterConstants
                            .PATH_CONVERSATION_GROUP_ADD_CONVERSATION_PAGE,
                        arguments: {
                          'model': model,
                          'group': currentGroup,
                        },
                      );
                    },
                  ),
                  if (conversations.isEmpty)
                    _EmptyView()
                  else
                    ...conversations.map(
                      (conversation) => _ConversationRow(
                        key: ValueKey(conversation.getConversationId()),
                        conversation: conversation,
                        onDelete: () => _deleteConversation(
                          currentGroup,
                          conversation,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  void _editName(BuildContext context, ConversationGroupUiModel group) {
    Future<bool> updateName(String name) async {
      final result = await widget.model.updateGroupName(group, name);
      if (!result.isSuccess && context.mounted) {
        ChatUIToast.show(
          result.errorDetails ?? S.of(context).conversationGroupOperationFailed,
          context: context,
        );
      }
      return result.isSuccess;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateTextInfoPage(
          title: S.of(context).conversationGroupName,
          content: group.name,
          maxLength: ConversationGroupViewModel.maxGroupNameLength,
          maxLines: 1,
          privilege: true,
          onSave: updateName,
          leading: Text(
            S.of(context).cancelTitle,
            style: const TextStyle(
              fontSize: 16,
              color: CommonColors.color_666666,
            ),
          ),
          sureStr: S.of(context).sureTitle,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: Text(S.of(context).conversationGroupDeleteConfirmTitle),
          content: Text(S.of(context).conversationGroupDeleteConfirmContent),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(S.of(context).cancelTitle),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                if (!checkNetwork()) {
                  return;
                }
                final result = await widget.model.deleteGroup(widget.group);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
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

  Future<void> _deleteConversation(
    ConversationGroupUiModel group,
    ConversationInfo conversation,
  ) async {
    if (!checkNetwork()) {
      return;
    }
    final result = await widget.model.removeConversationsFromGroup(
      group,
      [conversation.getConversationId()],
    );
    if (!result.isSuccess && mounted) {
      ChatUIToast.show(
        result.errorDetails ?? S.of(context).conversationGroupOperationFailed,
        context: context,
      );
    }
  }
}

class _ConversationCountHeader extends StatelessWidget {
  const _ConversationCountHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFFF7F8FA),
      child: Text(
        S.of(context).conversationGroupConversationCount(count),
        style: const TextStyle(
          color: CommonColors.color_666666,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    Key? key,
    required this.conversation,
    required this.onDelete,
  }) : super(key: key);

  final ConversationInfo conversation;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Avatar(
        avatar: conversation.getAvatar() ?? '',
        name: conversation.getName(),
        width: 40,
        height: 40,
        radius: 20,
      ),
      title: Text(
        conversation.getName(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: SizedBox(
        width: 60,
        height: 32,
        child: OutlinedButton(
          onPressed: onDelete,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: CommonColors.color_337eff,
            side: const BorderSide(
              color: CommonColors.color_337eff,
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
            ),
          ),
          child: Text(S.of(context).deleteTitle),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
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
