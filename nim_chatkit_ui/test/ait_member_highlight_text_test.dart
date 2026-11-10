// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit_ui/widget/ait_member_highlight_text.dart';

void main() {
  testWidgets('highlights the literal matching keyword in blue',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AitMemberHighlightText(
          displayName: '哈利波特',
          query: '利波',
          style: TextStyle(color: Color(0xFF333333)),
        ),
      ),
    );

    final richText = tester.widget<RichText>(find.byType(RichText));
    final children = (richText.text as TextSpan).children!;

    expect((children[0] as TextSpan).text, '哈');
    expect((children[1] as TextSpan).text, '利波');
    expect(
      (children[1] as TextSpan).style!.color,
      CommonColors.color_337eff,
    );
    expect((children[2] as TextSpan).text, '特');
  });

  testWidgets('does not expand pinyin initials', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AitMemberHighlightText(
          displayName: '小云',
          query: 'y',
          style: TextStyle(color: Color(0xFF333333)),
        ),
      ),
    );

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.textSpan, isNull);
  });
}
