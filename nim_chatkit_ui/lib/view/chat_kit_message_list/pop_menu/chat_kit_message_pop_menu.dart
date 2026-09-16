// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:nim_chatkit_ui/helper/message_reaction_helper.dart';
import 'package:nim_chatkit_ui/helper/message_popup_coordinator.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/reaction/message_reaction_picker.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/reaction/message_reaction_quick_bar.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_pop_actions.dart';
import 'package:provider/provider.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../../../chat_kit_client.dart';
import '../../../view_model/chat_view_model.dart';
import 'chat_kit_menu_helper.dart';
import 'chat_kit_super_tooltip.dart';

class ChatKitMessagePopMenu {
  SuperTooltip? _tooltip;

  BuildContext context;

  ChatMessage message;

  PopMenuAction? popMenuAction;

  ChatUIConfig? chatUIConfig;

  Offset? globalPosition;

  bool isVoiceFromSpeaker = true;

  ChatKitMessagePopMenu(
    this.message,
    this.isVoiceFromSpeaker,
    this.context, {
    this.popMenuAction,
    this.chatUIConfig,
    this.globalPosition,
  }) {
    final estimatedPopupHeight = _estimatedCollapsedPopupHeight(context);
    final placement = _getPopupPlacement(context, estimatedPopupHeight);

    _tooltip = SuperTooltip(
      onClose: () => MessagePopupCoordinator.release(this),
      onTapOutside: (position) => MessagePopupCoordinator.openReactionAt(
        position,
        Overlay.of(context),
      ),
      tooltipContainerKey:
          const ValueKey<String>('chat-message-pop-menu-surface'),
      popupDirection: placement.direction,
      minimumOutSidePadding: 0,
      arrowTipDistance: 2,
      arrowBaseWidth: 10.0,
      arrowLength: 10.0,
      right: ChatKitMenuHelper.isSelf(message.nimMessage) ? 60 : null,
      left: ChatKitMenuHelper.isSelf(message.nimMessage) ? null : 60,
      borderColor: Colors.white,
      backgroundColor: Colors.white,
      shadowColor: Colors.black26,
      hasShadow: true,
      borderWidth: 1.0,
      contentPadding: IMKitConfigCenter.enableMessageReaction &&
              MessageReactionHelper.isSupported(message)
          ? EdgeInsets.zero
          : null,
      showCloseButton: ShowCloseButton.none,
      showArrow: !placement.centered,
      centerVerticallyOnTarget: placement.centered,
      touchThroughAreaShape: ClipAreaShape.rectangle,
      targetGlobalPosition: placement.anchor,
      content: _getTooltipAction(context, chatUIConfig, message),
    );
  }

  double _estimatedCollapsedPopupHeight(BuildContext context) {
    final reactionEnabled = IMKitConfigCenter.enableMessageReaction &&
        MessageReactionHelper.isSupported(message);
    final viewModel = context.read<ChatViewModel>();
    final actionCount = ChatKitMenuHelper.buildMenuItems(
      context,
      message,
      chatUIConfig,
      isVoiceFromSpeaker,
      viewModel.getVoiceToTextState(message.nimMessage)?.voiceToText?.isValid ==
          true,
    ).length;
    final columnCount = reactionEnabled ? 5 : 4;
    final rowCount = actionCount == 0 ? 0 : (actionCount / columnCount).ceil();
    final actionHeight = rowCount * 44.0 + math.max(0, rowCount - 1) * 12.0;
    final contentPadding = reactionEnabled ? 32.0 : 12.0;
    final reactionSectionHeight = reactionEnabled ? 48.0 : 0.0;
    const tooltipInsetsAndArrow = 32.0;
    return contentPadding +
        reactionSectionHeight +
        actionHeight +
        tooltipInsetsAndArrow;
  }

  _MessagePopupPlacement _getPopupPlacement(
    BuildContext context,
    double popupHeight,
  ) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return _MessagePopupPlacement(
        direction: TooltipDirection.up,
        anchor: globalPosition,
      );
    }
    final origin = box.localToGlobal(Offset.zero);
    final mediaQuery = MediaQuery.of(context);
    final safeTop = mediaQuery.padding.top + kToolbarHeight;
    final safeBottom = mediaQuery.size.height - mediaQuery.padding.bottom;
    final targetRect = origin & box.size;
    final anchorX = (globalPosition?.dx ?? targetRect.center.dx)
        .clamp(targetRect.left, targetRect.right)
        .toDouble();
    final spaceAbove = targetRect.top - safeTop;
    final spaceBelow = safeBottom - targetRect.bottom;
    const verticalClearance = 8.0;
    final requiredSpace = popupHeight + verticalClearance;
    if (spaceAbove >= requiredSpace) {
      return _MessagePopupPlacement(
        direction: TooltipDirection.up,
        anchor: Offset(anchorX, targetRect.top),
      );
    }
    if (spaceBelow >= requiredSpace) {
      return _MessagePopupPlacement(
        direction: TooltipDirection.down,
        anchor: Offset(anchorX, targetRect.bottom),
      );
    }
    final visibleTop = math.max(targetRect.top, safeTop);
    final visibleBottom = math.min(targetRect.bottom, safeBottom);
    final centerY = visibleTop <= visibleBottom
        ? (visibleTop + visibleBottom) / 2
        : targetRect.center.dy.clamp(safeTop, safeBottom).toDouble();
    return _MessagePopupPlacement(
      direction: TooltipDirection.up,
      anchor: Offset(anchorX, centerY),
      centered: true,
    );
  }

  Widget _getTooltipAction(
    BuildContext context,
    ChatUIConfig? config,
    ChatMessage message,
  ) {
    final viewModel = context.read<ChatViewModel>();
    final reactionEnabled = IMKitConfigCenter.enableMessageReaction &&
        MessageReactionHelper.isSupported(message);
    Alog.i(
      tag: 'ChatKit',
      moduleName: 'MessageReactionPopMenu',
      content: 'long press reaction check: enabled=$reactionEnabled, '
          'messageServerId=${message.nimMessage.messageServerId}, '
          'messageClientId=${message.nimMessage.messageClientId}, '
          'messageType=${message.nimMessage.messageType}, '
          'isSelf=${message.nimMessage.isSelf}, '
          'sendingState=${message.nimMessage.sendingState}, '
          'statusErrorCode=${message.nimMessage.messageStatus?.errorCode}, '
          'isRevoke=${message.isRevoke}',
    );
    return _MobileMenuContent(
      message: message,
      config: config,
      isVoiceFromSpeaker: isVoiceFromSpeaker,
      hasValidVoiceToText: viewModel
              .getVoiceToTextState(message.nimMessage)
              ?.voiceToText
              ?.isValid ==
          true,
      reactionEnabled: reactionEnabled,
      selectedReactionIndexes: viewModel
          .getMessageReactionState(message.nimMessage)
          .summaries
          .values
          .where((summary) => summary.contains(viewModel.currentAccountId))
          .map((summary) => summary.index)
          .toSet(),
      onReactionSelected: _onReactionSelected,
      onActionSelected: (actionId) {
        _tooltip?.close();
        ChatKitMenuHelper.handleAction(
          message,
          actionId,
          popMenuAction,
          isVoiceFromSpeaker,
        );
      },
    );
  }

  void _onReactionSelected(int index) {
    final viewModel = context.read<ChatViewModel>();
    final errorText = S.of(context).chatMessageReactionFailed;
    final limitErrorText = S.of(context).chatMessageReactionLimit;
    _tooltip?.close();
    viewModel.toggleMessageReaction(message, index).then((result) {
      if (!result.isSuccess &&
          result.code != ChatViewModel.messageReactionNetworkUnavailableCode) {
        ChatUIToast.show(
          result.code == ChatMessageRepo.errorQuickCommentLimited
              ? limitErrorText
              : errorText,
        );
      }
    });
  }

  void close() {
    if (_tooltip?.isOpen == true) {
      _tooltip?.close();
    }
  }

  void clean() {
    close();
  }

  void show() {
    MessagePopupCoordinator.activate(this, close);
    _tooltip?.show(context);
  }

  Widget itemInkWell({Widget? child, GestureTapCallback? onTap}) {
    return SizedBox(
      width: 60,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: child,
        ),
      ),
    );
  }
}

class _MessagePopupPlacement {
  const _MessagePopupPlacement({
    required this.direction,
    required this.anchor,
    this.centered = false,
  });

  final TooltipDirection direction;
  final Offset? anchor;
  final bool centered;
}

class _MobileMenuContent extends StatefulWidget {
  const _MobileMenuContent({
    required this.message,
    required this.config,
    required this.isVoiceFromSpeaker,
    required this.hasValidVoiceToText,
    required this.reactionEnabled,
    required this.selectedReactionIndexes,
    required this.onReactionSelected,
    required this.onActionSelected,
  });

  final ChatMessage message;
  final ChatUIConfig? config;
  final bool isVoiceFromSpeaker;
  final bool hasValidVoiceToText;
  final bool reactionEnabled;
  final Set<int> selectedReactionIndexes;
  final ValueChanged<int> onReactionSelected;
  final ValueChanged<String> onActionSelected;

  @override
  State<_MobileMenuContent> createState() => _MobileMenuContentState();
}

class _MobileMenuContentState extends State<_MobileMenuContent> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final actions = _orderedActions(
      ChatKitMenuHelper.buildMenuItems(
        context,
        widget.message,
        widget.config,
        widget.isVoiceFromSpeaker,
        widget.hasValidVoiceToText,
      ),
    );
    final maxPickerHeight =
        MessageReactionPicker.heightFor(MediaQuery.of(context));
    Alog.i(
      tag: 'ChatKit',
      moduleName: 'MessageReactionPopMenu',
      content: 'mobile menu build: reactionEnabled=${widget.reactionEnabled}, '
          'actionCount=${actions.length}',
    );
    final availableMenuWidth =
        math.max(0.0, MediaQuery.sizeOf(context).width - 16);
    final menuWidth = math.min(
      _expanded
          ? MessageReactionPicker.width
          : widget.reactionEnabled
              ? MessageReactionPicker.width
              : 276.0,
      availableMenuWidth,
    );
    return Container(
      width: menuWidth,
      padding: _expanded
          ? EdgeInsets.zero
          : widget.reactionEnabled
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 16)
              : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      constraints: BoxConstraints(
        maxWidth: menuWidth,
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.reactionEnabled) ...[
              if (_expanded)
                SizedBox(
                  height: maxPickerHeight,
                  child: MessageReactionPicker(
                    mode: MessageReactionPickerMode.quickBarExpanded,
                    showSurface: false,
                    selectedIndexes: widget.selectedReactionIndexes,
                    emojiBuilder: widget.config?.messageReactionEmojiBuilder,
                    onCollapse: () => setState(() => _expanded = false),
                    onSelected: widget.onReactionSelected,
                  ),
                )
              else
                MessageReactionQuickBar(
                  popupStyle: true,
                  emojiBuilder: widget.config?.messageReactionEmojiBuilder,
                  onExpand: () => setState(() => _expanded = true),
                  onSelected: widget.onReactionSelected,
                ),
              if (!_expanded)
                const Divider(height: 18, color: Color(0xFFE6E8EB)),
            ],
            if (!_expanded) _buildActionGrid(actions),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _orderedActions(
    List<Map<String, String>> actions,
  ) {
    if (!widget.reactionEnabled) {
      return actions;
    }
    const preferredOrder = <String>[
      ChatKitMenuHelper.copyMessageId,
      ChatKitMenuHelper.forwardMessageId,
      ChatKitMenuHelper.replyMessageId,
      ChatKitMenuHelper.revokeMessageId,
      ChatKitMenuHelper.deleteMessageId,
    ];
    final remaining = <String, Map<String, String>>{
      for (final action in actions) action['id']!: action,
    };
    final ordered = <Map<String, String>>[];
    for (final id in preferredOrder) {
      final action = remaining.remove(id);
      if (action != null) {
        ordered.add(action);
      }
    }
    ordered.addAll(remaining.values);
    return ordered;
  }

  Widget _buildActionGrid(List<Map<String, String>> actions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const enabledItemWidth = 40.0;
        final rowItemCount = math.min(actions.length, 5);
        final spacing = widget.reactionEnabled && rowItemCount > 1
            ? math.max(
                0.0,
                (constraints.maxWidth - enabledItemWidth * rowItemCount) /
                    (rowItemCount - 1),
              )
            : 4.0;
        return Wrap(
          direction: Axis.horizontal,
          alignment: WrapAlignment.start,
          spacing: spacing,
          runSpacing: widget.reactionEnabled ? 12 : 24,
          children: actions
              .map(
                (item) => Material(
                  color: Colors.white,
                  child: SizedBox(
                    key: ValueKey<String>(
                      'chat-message-action-${item['id']}',
                    ),
                    width: widget.reactionEnabled ? enabledItemWidth : 60,
                    child: InkWell(
                      onTap: () => widget.onActionSelected(item['id']!),
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            item['icon']!,
                            package: kPackage,
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['label']!,
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
                ),
              )
              .toList(),
        );
      },
    );
  }
}
