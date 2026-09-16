// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/model/message_reaction.dart';

import 'message_reaction_emoji.dart';

///长按/右键菜单顶部的六个快捷表情与展开按钮
class MessageReactionQuickBar extends StatelessWidget {
  const MessageReactionQuickBar({
    Key? key,
    required this.onSelected,
    required this.onExpand,
    this.selectedIndexes = const <int>{},
    this.emojiBuilder,
    this.popupStyle = false,
  }) : super(key: key);

  final ValueChanged<int> onSelected;
  final VoidCallback onExpand;
  final Set<int> selectedIndexes;
  final MessageReactionEmojiBuilder? emojiBuilder;
  final bool popupStyle;

  @override
  Widget build(BuildContext context) {
    final indexes = MessageReactionConfig.quickIndexes.take(6).toList();
    return SizedBox(
      height: popupStyle ? 30 : 44,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 7 * 40.0;
          final slotExtent = popupStyle
              ? math.min(30.0, math.max(16.0, (availableWidth - 108) / 7))
              : math.min(40.0, availableWidth / 7);
          final emojiSize = popupStyle
              ? math.min(26.0, slotExtent)
              : math.min(26.0, math.max(16.0, slotExtent - 8));
          final slotSpacing = popupStyle
              ? math.min(
                  18.0,
                  math.max(2.0, (availableWidth - slotExtent * 7) / 6),
                )
              : 0.0;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < indexes.length; i++) ...[
                if (i > 0 && popupStyle) SizedBox(width: slotSpacing),
                _ReactionSlot(
                  key: ValueKey<int>(indexes[i]),
                  extent: slotExtent,
                  selected: selectedIndexes.contains(indexes[i]),
                  semanticLabel:
                      S.of(context).chatMessageReactionEmoji(indexes[i]),
                  onTap: () => onSelected(indexes[i]),
                  child: MessageReactionEmoji(
                    index: indexes[i],
                    size: emojiSize,
                    builder: emojiBuilder,
                  ),
                ),
              ],
              if (popupStyle) SizedBox(width: slotSpacing),
              _ReactionSlot(
                extent: slotExtent,
                semanticLabel: S.of(context).chatMessageReactionExpand,
                onTap: onExpand,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: emojiSize,
                  color: const Color(0xFF656A72),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReactionSlot extends StatelessWidget {
  const _ReactionSlot({
    Key? key,
    required this.child,
    required this.semanticLabel,
    required this.onTap,
    required this.extent,
    this.selected = false,
  }) : super(key: key);

  final Widget child;
  final String semanticLabel;
  final VoidCallback onTap;
  final double extent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            width: extent,
            height: extent,
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}
