// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit_ui/helper/ait_member_search_helper.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/view/ait/ait_manager.dart';
import 'package:nim_chatkit_ui/view/ait/ait_model.dart';

class _TestAitManager extends AitManager {
  _TestAitManager() : super('team-ai-search');

  @override
  Future<void> loadAllMembers() async {}
}

void main() {
  setUpAll(setupLocator);

  test('only AI users in the current team are searchable', () {
    final teamAssistant = AitBean(
      aiUser: NIMAIUser(name: '个人助理', accountId: 'Assistant_01'),
      isAIUserTeamMember: true,
    );
    final outsideAssistant = AitBean(
      aiUser: NIMAIUser(name: '个人助理', accountId: 'Assistant_02'),
    );
    expect(matchesAitMemberFields(teamAssistant.searchableFields, '个'), isTrue);
    expect(
        matchesAitMemberFields(teamAssistant.searchableFields, '助理'), isTrue);
    expect(
        matchesAitMemberFields(teamAssistant.searchableFields, 'assistant_01'),
        isTrue);
    expect(
        matchesAitMemberFields(teamAssistant.searchableFields, '不存在'), isFalse);
    expect(matchesAitMemberFields(outsideAssistant.searchableFields, '个'),
        isFalse);
    expect(teamAssistant.displayName, '个人助理');
    expect(outsideAssistant.displayName, '个人助理');
    expect(
        findAitMemberSubtitles(
            teamAssistant.searchableFields, teamAssistant.displayName, '01'),
        ['Assistant_01']);
    expect(AitBean(aiUser: NIMAIUser(accountId: 'assistant')).displayName,
        'assistant');
  });

  testWidgets('group mention picker searches and selects an AI member',
      (tester) async {
    final manager = _TestAitManager();
    addTearDown(manager.dispose);
    final outsideAssistant =
        AitBean(aiUser: NIMAIUser(name: '个人助理', accountId: 'outside'));
    final teamAssistant = AitBean(
      aiUser: NIMAIUser(name: '群内个人助理', accountId: 'assistant'),
      isAIUserTeamMember: true,
    );
    manager.aitMemberList.value = [outsideAssistant, teamAssistant];
    AitBean? selected;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh')],
      home: Scaffold(
          body: Builder(
              builder: (context) => TextButton(
                    onPressed: () async {
                      selected =
                          await manager.selectMember(context) as AitBean?;
                    },
                    child: const Text('open'),
                  ))),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('个人助理'), findsOneWidget);
    expect(find.text('群内个人助理'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '个');
    await tester.pumpAndSettle();
    expect(find.text('个人助理', findRichText: true), findsNothing);
    expect(find.text('群内个人助理', findRichText: true), findsOneWidget);
    await tester.enterText(find.byType(TextField), '不存在');
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('ait-member-empty-image')),
      findsOneWidget,
    );
    expect(find.text('未找到匹配的成员'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '个');
    await tester.pumpAndSettle();
    await tester.tap(find.text('群内个人助理', findRichText: true));
    await tester.pumpAndSettle();
    expect(selected, same(teamAssistant));
    expect(selected?.displayName, '群内个人助理');
  });

  testWidgets('mention picker stays fixed while source keyboard closes',
      (tester) async {
    final manager = _TestAitManager();
    addTearDown(manager.dispose);
    manager.aitMemberList.value = [
      AitBean(
        aiUser: NIMAIUser(name: '群内个人助理', accountId: 'assistant'),
        isAIUserTeamMember: true,
      ),
    ];
    final viewInsets = ValueNotifier<EdgeInsets>(
      const EdgeInsets.only(bottom: 300),
    );
    addTearDown(viewInsets.dispose);

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh')],
      builder: (context, child) => ValueListenableBuilder<EdgeInsets>(
        valueListenable: viewInsets,
        builder: (context, insets, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(viewInsets: insets),
          child: child!,
        ),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => manager.selectMember(context),
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final title = find.text('选择提醒');
    final initialTop = tester.getTopLeft(title).dy;

    viewInsets.value = EdgeInsets.zero;
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(title).dy, initialTop);
  });

  testWidgets('mention empty state keeps its size when keyboard opens',
      (tester) async {
    final manager = _TestAitManager();
    addTearDown(manager.dispose);
    manager.aitMemberList.value = [
      AitBean(
        aiUser: NIMAIUser(name: '群内个人助理', accountId: 'assistant'),
        isAIUserTeamMember: true,
      ),
    ];
    final viewInsets = ValueNotifier<EdgeInsets>(EdgeInsets.zero);
    addTearDown(viewInsets.dispose);

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh')],
      builder: (context, child) => ValueListenableBuilder<EdgeInsets>(
        valueListenable: viewInsets,
        builder: (context, insets, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(viewInsets: insets),
          child: child!,
        ),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => manager.selectMember(context),
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '不存在');
    await tester.pumpAndSettle();
    final emptyImage =
        find.byKey(const ValueKey<String>('ait-member-empty-image'));
    expect(tester.getSize(emptyImage).height, 73);

    viewInsets.value = const EdgeInsets.only(bottom: 300);
    await tester.pumpAndSettle();

    expect(tester.getSize(emptyImage).height, 73);
    expect(find.text('未找到匹配的成员'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
