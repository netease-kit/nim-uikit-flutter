// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netease_common_ui/base/default_language.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/view/page/message_translation_language_page.dart';

void main() {
  tearDown(() {
    CommonUIDefaultLanguage.commonDefaultLanguage = null;
  });

  testWidgets('uses app English language when system locale is Chinese', (
    tester,
  ) async {
    CommonUIDefaultLanguage.commonDefaultLanguage = languageEn;

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('zh')],
        home: MessageTranslationLanguagePage(selectedLanguage: 'en'),
      ),
    );

    expect(find.text('Simplified Chinese'), findsOneWidget);
    expect(find.text('Traditional Chinese'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('简体中文'), findsNothing);

    final selectedText = tester.widget<Text>(find.text('English'));
    final unselectedText = tester.widget<Text>(find.text('Simplified Chinese'));
    expect(selectedText.style?.color, const Color(0xFF337EFF));
    expect(unselectedText.style?.color, const Color(0xFF333333));
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byType(Radio<String>), findsNothing);

    await tester.tap(find.text('Simplified Chinese'));
    await tester.pump();

    final newlySelectedText =
        tester.widget<Text>(find.text('Simplified Chinese'));
    final previouslySelectedText = tester.widget<Text>(find.text('English'));
    expect(newlySelectedText.style?.color, const Color(0xFF337EFF));
    expect(previouslySelectedText.style?.color, const Color(0xFF333333));
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
