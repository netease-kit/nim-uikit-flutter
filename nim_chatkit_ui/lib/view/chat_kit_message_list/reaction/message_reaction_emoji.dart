// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/model/message_reaction.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

///固定尺寸的快捷回复表情
class MessageReactionEmoji extends StatelessWidget {
  const MessageReactionEmoji({
    Key? key,
    required this.index,
    required this.size,
    this.builder,
  }) : super(key: key);

  final int index;
  final double size;
  final MessageReactionEmojiBuilder? builder;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: ClipRect(
          child: builder?.call(context, index, size) ??
              Image.asset(
                MessageReactionConfig.assetPath(index),
                package: kPackage,
                width: size,
                height: size,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  Alog.e(
                    tag: 'ChatKit',
                    moduleName: 'MessageReactionEmoji',
                    content: 'load reaction emoji $index failed: $error',
                  );
                  return SizedBox.square(dimension: size);
                },
              ),
        ),
      ),
    );
  }
}
