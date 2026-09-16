// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/helper/message_popup_coordinator.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/model/message_reaction.dart';

import 'message_reaction_emoji.dart';
import 'message_reaction_picker.dart';

///消息气泡下方的快捷回复聚合区域
class MessageReactionBar extends StatefulWidget {
  const MessageReactionBar({
    Key? key,
    required this.state,
    required this.currentAccountId,
    required this.onSelected,
    this.emojiBuilder,
    this.messageTargetKey,
  }) : super(key: key);

  final MessageReactionState state;
  final String? currentAccountId;
  final ValueChanged<int> onSelected;
  final MessageReactionEmojiBuilder? emojiBuilder;

  /// 用于定位表情弹框的完整消息区域，未设置时使用当前 Reaction 区域。
  final GlobalKey? messageTargetKey;

  @override
  State<MessageReactionBar> createState() => _MessageReactionBarState();
}

class _MessageReactionBarState extends State<MessageReactionBar> {
  final GlobalKey _addKey = GlobalKey();
  OverlayEntry? _dismissEntry;
  OverlayEntry? _pickerEntry;
  LocalHistoryEntry? _localHistoryEntry;

  @override
  void initState() {
    super.initState();
    MessagePopupCoordinator.registerReactionTarget(_addKey, _showPicker);
  }

  @override
  void dispose() {
    MessagePopupCoordinator.unregisterReactionTarget(_addKey);
    _closePicker();
    super.dispose();
  }

  void _closePicker() {
    final historyEntry = _localHistoryEntry;
    if (historyEntry != null) {
      _localHistoryEntry = null;
      historyEntry.remove();
      return;
    }
    _removePickerEntries();
  }

  void _removePickerEntries() {
    MessagePopupCoordinator.release(this);
    _dismissEntry?.remove();
    _pickerEntry?.remove();
    _dismissEntry = null;
    _pickerEntry = null;
  }

  void _showPicker() {
    _closePicker();
    final overlay = Overlay.of(context);
    final box = _addKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final keyedTargetBox = widget.messageTargetKey?.currentContext
        ?.findRenderObject() as RenderBox?;
    final targetBox =
        keyedTargetBox ?? context.findRenderObject() as RenderBox?;
    if (targetBox == null || !targetBox.hasSize) {
      return;
    }
    final mediaQuery = MediaQuery.of(context);
    final origin = box.localToGlobal(Offset.zero);
    final targetOrigin = targetBox.localToGlobal(Offset.zero);
    final targetRect = targetOrigin & targetBox.size;
    final panelWidth = math.min(
      MessageReactionPicker.width,
      math.max(0.0, mediaQuery.size.width - 16),
    );
    if (panelWidth <= 0) {
      return;
    }
    final viewportTop = mediaQuery.padding.top + kToolbarHeight + 8;
    final viewportBottom =
        mediaQuery.size.height - mediaQuery.padding.bottom - 8;
    final height = MessageReactionPicker.heightFor(mediaQuery);
    if (height <= 0) {
      return;
    }
    final left = origin.dx
        .clamp(
          8.0,
          math.max(8.0, mediaQuery.size.width - panelWidth - 8),
        )
        .toDouble();
    const targetGap = 6.0;
    final availableAbove = targetRect.top - viewportTop - targetGap;
    final availableBelow = viewportBottom - targetRect.bottom - targetGap;
    late final double top;
    if (availableAbove >= height) {
      top = targetRect.top - height - targetGap;
    } else if (availableBelow >= height) {
      top = targetRect.bottom + targetGap;
    } else {
      final visibleTop = math.max(targetRect.top, viewportTop);
      final visibleBottom = math.min(targetRect.bottom, viewportBottom);
      final centerY = visibleTop <= visibleBottom
          ? (visibleTop + visibleBottom) / 2
          : targetRect.center.dy.clamp(viewportTop, viewportBottom).toDouble();
      top = (centerY - height / 2)
          .clamp(viewportTop, viewportBottom - height)
          .toDouble();
    }

    MessagePopupCoordinator.activate(this, _closePicker);
    _dismissEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closePicker,
          onSecondaryTap: _closePicker,
          child: const SizedBox.expand(),
        ),
      ),
    );
    _pickerEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        width: panelWidth,
        height: height,
        child: Material(
          color: Colors.transparent,
          child: MessageReactionPicker(
            mode: MessageReactionPickerMode.messageBar,
            selectedIndexes: widget.state.summaries.values
                .where((summary) => summary.contains(widget.currentAccountId))
                .map((summary) => summary.index)
                .toSet(),
            emojiBuilder: widget.emojiBuilder,
            onSelected: (index) {
              _closePicker();
              widget.onSelected(index);
            },
          ),
        ),
      ),
    );
    overlay.insert(_dismissEntry!);
    overlay.insert(_pickerEntry!);
    final route = ModalRoute.of(context);
    if (route != null) {
      late final LocalHistoryEntry historyEntry;
      historyEntry = LocalHistoryEntry(
        onRemove: () {
          if (identical(_localHistoryEntry, historyEntry)) {
            _localHistoryEntry = null;
          }
          _removePickerEntries();
        },
      );
      _localHistoryEntry = historyEntry;
      route.addLocalHistoryEntry(historyEntry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaries = widget.state.summaries.values
        .where((summary) =>
            MessageReactionConfig.supportedIndexes.contains(summary.index))
        .toList()
      ..sort((a, b) {
        final aTime = a.createTime;
        final bTime = b.createTime;
        if (aTime == null && bTime != null) return 1;
        if (aTime != null && bTime == null) return -1;
        final timeOrder = (aTime ?? 0).compareTo(bTime ?? 0);
        return timeOrder != 0 ? timeOrder : a.index.compareTo(b.index);
      });
    if (summaries.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            Semantics(
              button: true,
              label: S.of(context).chatMessageReactionAdd,
              child: InkWell(
                key: _addKey,
                borderRadius: BorderRadius.circular(13),
                onTap: _showPicker,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'images/ic_message_reaction_add.svg',
                    key: const ValueKey<String>('message-reaction-add'),
                    package: kPackage,
                    width: 26,
                    height: 26,
                  ),
                ),
              ),
            ),
            for (final summary in summaries)
              _ReactionChip(
                key: ValueKey<int>(summary.index),
                summary: summary,
                selected: summary.contains(widget.currentAccountId),
                emojiBuilder: widget.emojiBuilder,
                onTap: () => widget.onSelected(summary.index),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    Key? key,
    required this.summary,
    required this.selected,
    required this.onTap,
    this.emojiBuilder,
  }) : super(key: key);

  final MessageReactionSummary summary;
  final bool selected;
  final VoidCallback onTap;
  final MessageReactionEmojiBuilder? emojiBuilder;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: S.of(context).chatMessageReactionCount(
            summary.index,
            summary.count,
          ),
      child: Opacity(
        opacity: summary.pending ? 0.65 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(
              minWidth: 56,
              minHeight: 26,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFE5E5E5), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MessageReactionEmoji(
                  index: summary.index,
                  size: 16,
                  builder: emojiBuilder,
                ),
                ...[
                  const SizedBox(width: 4),
                  Text(
                    '${summary.count}',
                    style: TextStyle(
                      fontSize: 10,
                      color: selected
                          ? const Color(0xFF337EFF)
                          : const Color(0xFF666666),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
