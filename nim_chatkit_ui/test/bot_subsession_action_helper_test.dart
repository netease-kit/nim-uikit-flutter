// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netease_common_ui/base/default_language.dart';
import 'package:nim_chatkit_ui/helper/bot_subsession_action_helper.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_core_v2/nim_core.dart';

void main() {
  tearDown(() {
    CommonUIDefaultLanguage.commonDefaultLanguage = null;
  });

  testWidgets('network check blocks subsession deletion', (tester) async {
    CommonUIDefaultLanguage.commonDefaultLanguage = languageZh;
    var networkCheckCount = 0;
    var deleteCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('zh')],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                BotSubsessionActionHelper.showTopicActions(
                  context: context,
                  currentTitle: 'topic',
                  onRename: (_) async => NIMResult.success(),
                  onDelete: () async {
                    deleteCount++;
                    return NIMResult.success();
                  },
                  checkNetwork: () {
                    networkCheckCount++;
                    return false;
                  },
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(networkCheckCount, 1);
    expect(deleteCount, 0);
  });
}
