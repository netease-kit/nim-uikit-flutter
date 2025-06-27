// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

Widget getSingleMiddleEllipsisText(String? data, {TextStyle? style}) {
  return LayoutBuilder(builder: (context, constrain) {
    String info = data ?? "";
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: info, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    final exceedWidth = (textPainter.size.width - constrain.maxWidth).toInt();
    if (exceedWidth > 0) {
      final exceedLength =
          (exceedWidth / textPainter.size.width * info.length).toInt();
      final index = (info.length - exceedLength) ~/ 2;
      info =
          "${info.substring(0, index)}...${info.substring(index + exceedLength + 4)}";
    }
    return Text(
      info,
      maxLines: 1,
      style: style,
    );
  });
}
