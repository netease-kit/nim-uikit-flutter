// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit_ui/view/input/ne_special_text_span_builder.dart';

Widget _app(String text) {
  const style = TextStyle(fontSize: 16, height: 1.25);
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: RichText(
          text: NeSpecialTextSpanBuilder().build(
            text,
            textStyle: style,
          ),
        ),
      ),
    ),
  );
}

Future<Size> _layout(WidgetTester tester, String text) async {
  await tester.pumpWidget(_app(text));
  await tester.pump();
  return tester.getSize(find.byType(RichText));
}

void main() {
  testWidgets('image emoji keeps the normal single-line height',
      (tester) async {
    final plainSize = await _layout(tester, 'A');
    final unicodeEmojiSize = await _layout(tester, '😀');
    final imageEmojiSize = await _layout(tester, '[大笑]');
    final mixedSize = await _layout(tester, 'A[大笑]B');
    final multilineSize = await _layout(tester, 'A\n[大笑]');

    expect(unicodeEmojiSize.height, plainSize.height);
    expect(imageEmojiSize.height, lessThanOrEqualTo(plainSize.height));
    expect(mixedSize.height, plainSize.height);
    expect(mixedSize.width, greaterThan(imageEmojiSize.width));
    expect(multilineSize.height, greaterThan(plainSize.height));
  });
}
