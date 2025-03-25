// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';

import 'emoji.dart';
import 'emoji_span.dart';

///emoji/image text
class EmojiText extends SpecialText {
  EmojiText(TextStyle? textStyle, {this.start})
      : super(EmojiText.flag, ']', textStyle);
  static const String flag = '[';
  final int? start;
  @override
  InlineSpan finishText() {
    final String key = toString();

    if (EmojiUitl.instance.emojiMap.containsKey(key)) {
      double size = 18;

      if (textStyle?.fontSize != null) {
        size = textStyle!.fontSize! * 1.15;
      }

      return EmojiSpan(
          Image.asset(
            EmojiUitl.instance.emojiMap[key]!.source,
            package: kPackage,
            height: 30,
            width: 30,
          ),
          actualText: key,
          imageWidth: size,
          imageHeight: size,
          start: start!,
          //fit: BoxFit.fill,
          margin: const EdgeInsets.all(2));
    }

    return TextSpan(text: toString(), style: textStyle);
  }
}

class EmojiUitl {
  EmojiUitl._() {
    emojiData.forEach((emojiMap) {
      _emojiMap[(emojiMap['tag'] as String)] = NeEmoji.fromMap(emojiMap);
    });
  }

  final Map<String, NeEmoji> _emojiMap = <String, NeEmoji>{};

  Map<String, NeEmoji> get emojiMap => _emojiMap;

  static EmojiUitl? _instance;
  static EmojiUitl get instance => _instance ??= EmojiUitl._();
}
