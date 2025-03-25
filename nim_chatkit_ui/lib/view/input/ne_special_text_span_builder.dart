// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/cupertino.dart';

import 'emoji/emoji_text.dart';

class NeSpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  NeSpecialTextSpanBuilder({this.showAtBackground = false});

  /// whether show background for @somebody
  final bool showAtBackground;

  @override
  SpecialText? createSpecialText(String flag,
      {TextStyle? textStyle,
      SpecialTextGestureTapCallback? onTap,
      int? index}) {
    if (flag == '') {
      return null;
    }

    ///index is end index of start flag, so text start index should be index-(flag.length-1)
    if (isStart(flag, EmojiText.flag)) {
      return EmojiText(textStyle, start: index! - (EmojiText.flag.length - 1));
    }
    // if (isStart(flag, AtText.flag)) {
    //   return AtText(
    //     textStyle,
    //     onTap,
    //     start: index! - (AtText.flag.length - 1),
    //     showAtBackground: showAtBackground,
    //   );
    // }
    return null;
  }
}
