// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show PlaceholderAlignment;

import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

class EmojiSpan extends ExtendedWidgetSpan {
  EmojiSpan(
    Image image, {
    Key? key,
    required double imageWidth,
    required double imageHeight,
    EdgeInsets? margin,
    int start = 0,
    ui.PlaceholderAlignment alignment = ui.PlaceholderAlignment.middle,
    String? actualText,
    TextBaseline? baseline,
    BoxFit fit = BoxFit.scaleDown,
    ImageLoadingBuilder? loadingBuilder,
    ImageFrameBuilder? frameBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    Color? color,
    BlendMode? colorBlendMode,
    AlignmentGeometry imageAlignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    FilterQuality filterQuality = FilterQuality.low,
    GestureTapCallback? onTap,
    HitTestBehavior behavior = HitTestBehavior.deferToChild,
  })  : width = imageWidth + (margin == null ? 0 : margin.horizontal),
        height = imageHeight + (margin == null ? 0 : margin.vertical),
        super(
          child: Container(
            padding: margin,
            child: GestureDetector(
              onTap: onTap,
              behavior: behavior,
              child: image,
            ),
          ),
          baseline: baseline,
          alignment: alignment,
          start: start,
          deleteAll: true,
          actualText: actualText,
        );
  final double width;
  final double height;
}
