// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/model/message_reaction.dart';

import 'message_reaction_emoji.dart';

enum MessageReactionPickerMode {
  quickBarExpanded,
  messageBar,
}

///七列完整快捷回复面板
class MessageReactionPicker extends StatelessWidget {
  const MessageReactionPicker({
    Key? key,
    required this.mode,
    required this.onSelected,
    this.onCollapse,
    this.selectedIndexes = const <int>{},
    this.emojiBuilder,
    this.showSurface = true,
  }) : super(key: key);

  static const double width = 312;

  /// Returns the full panel height within the chat viewport's safe area.
  static double heightFor(MediaQueryData mediaQuery) {
    final usableHeight = math.max(
      0.0,
      mediaQuery.size.height -
          mediaQuery.padding.vertical -
          kToolbarHeight -
          16,
    );
    return math.min(
      math.min(180.0, mediaQuery.size.height * 0.28),
      usableHeight,
    );
  }

  final MessageReactionPickerMode mode;
  final ValueChanged<int> onSelected;
  final VoidCallback? onCollapse;
  final Set<int> selectedIndexes;
  final MessageReactionEmojiBuilder? emojiBuilder;
  final bool showSurface;

  static const int _columnCount = 7;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: showSurface
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE6E6E6)),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(133, 136, 140, 0.25),
                    offset: Offset(0, 4),
                    blurRadius: 7,
                  ),
                ],
              )
            : null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slotWidth = constraints.maxWidth / _columnCount;
            final emojiSize = math.min(26.0, math.max(16.0, slotWidth - 8));
            final quickItems =
                mode == MessageReactionPickerMode.quickBarExpanded
                    ? <int?>[
                        ...MessageReactionConfig.quickIndexes.take(6),
                        null,
                      ]
                    : MessageReactionConfig.quickIndexes.cast<int?>();
            return Column(
              children: [
                SizedBox(
                  height: 40,
                  child: Row(
                    children: quickItems
                        .map(
                          (index) => Expanded(
                            child: _buildItem(context, index, emojiSize),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: _buildGrid(
                    context,
                    MessageReactionConfig.allIndexes,
                    emojiSize,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    List<int> indexes,
    double emojiSize,
  ) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columnCount,
        mainAxisExtent: 40,
        mainAxisSpacing: 4,
      ),
      itemCount: indexes.length,
      itemBuilder: (context, itemIndex) =>
          _buildItem(context, indexes[itemIndex], emojiSize),
    );
  }

  Widget _buildItem(BuildContext context, int? index, double emojiSize) {
    if (index == null) {
      return Semantics(
        button: true,
        label: S.of(context).chatMessageReactionCollapse,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onCollapse,
          child: Icon(
            Icons.keyboard_arrow_up,
            size: emojiSize,
            color: const Color(0xFF656A72),
          ),
        ),
      );
    }
    final selected = selectedIndexes.contains(index);
    return Semantics(
      button: true,
      selected: selected,
      label: S.of(context).chatMessageReactionEmoji(index),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => onSelected(index),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF2FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: MessageReactionEmoji(
            index: index,
            size: emojiSize,
            builder: emojiBuilder,
          ),
        ),
      ),
    );
  }
}
