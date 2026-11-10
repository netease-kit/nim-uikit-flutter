// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_conversationkit_ui/model/conversation_info.dart';
import 'package:nim_conversationkit_ui/view_model/conversation_view_model.dart';
import 'package:nim_conversationkit_ui/widgets/conversation_list.dart';
import 'package:provider/provider.dart';

// Keep real profile loading while disabling unrelated initial queries.
class _TestViewModel extends ConversationViewModel {
  _TestViewModel() : super(null, null);

  @override
  Future<void> queryConversationList() async {}

  @override
  Future<void> doUnreadCallback() async {}

  @override
  void queryConversationNextList() {}

  @override
  void subscribeUserStatusByIds(List<String> userAccountIds) {}
}

ConversationInfo _conversation(
  String id, {
  NIMConversationType type = NIMConversationType.p2p,
  String? name,
  String? avatar,
}) {
  return ConversationInfo(NIMConversation(
    conversationId: id,
    type: type,
    name: name ?? id,
    avatar: avatar,
    mute: false,
    stickTop: false,
    createTime: 0,
    updateTime: 0,
  ));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.yunxin.163.com/nim_core');
  late _TestViewModel model;
  late List<List<String>> requests;
  Future<Map<String, dynamic>> Function(List<String>)? load;

  setUpAll(() {
    setupLocator();
    IMKitClient.enableAi = false;
    IMKitClient.enableRobot = false;
  });

  setUp(() {
    requests = [];
    load = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getUserList') {
        final ids = List<String>.from(call.arguments['userIdList'] as List);
        requests.add(ids);
        if (load != null) return load!(ids);
        return {
          'code': 0,
          'data': {
            'userInfoList': [
              for (final id in ids)
                {'accountId': id, 'name': 'Name $id', 'avatar': 'avatar-$id'},
            ],
          },
        };
      }
      return {'code': 0};
    });
    model = _TestViewModel();
  });

  tearDown(() {
    model.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('loads only placeholders, batches and deduplicates target IDs',
      () async {
    final first = _conversation('first', avatar: '');
    final duplicate = _conversation('first');
    first.setNickName('Alias');
    final items = [
      first,
      duplicate,
      _conversation('second'),
      _conversation('named', name: 'Already known'),
      _conversation('pictured', avatar: 'existing'),
      _conversation('team', type: NIMConversationType.team),
    ];
    model.conversationList = items;

    await model.refreshVisibleUserInfo(items);
    await model.refreshVisibleUserInfo(items);

    expect(requests, [
      ['first', 'second']
    ]);
    expect(first.conversation.name, 'Name first');
    expect(first.conversation.avatar, 'avatar-first');
    expect(duplicate.conversation.name, 'Name first');
    expect(first.getName(), 'Alias');
  });

  test('guards concurrent loads and preserves newer conversation details',
      () async {
    final completer = Completer<Map<String, dynamic>>();
    load = (_) => completer.future;
    final first = _conversation('first');
    final second = _conversation('second');
    final pending = model.refreshVisibleUserInfo([first]);
    await model.refreshVisibleUserInfo([second]);
    first.conversation.name = 'Newer name';
    completer.complete({
      'code': 0,
      'data': {
        'userInfoList': [
          {'accountId': 'first', 'name': 'Old name', 'avatar': 'old-avatar'},
        ],
      },
    });
    await pending;
    expect(requests, [
      ['first']
    ]);
    expect(first.conversation.name, 'Newer name');
    load = null;
    await model.refreshVisibleUserInfo([second]);
    expect(requests.last, ['second']);
  });

  test('does not repeatedly request failed profiles', () async {
    load = (_) async => {'code': 500};
    final item = _conversation('failed');
    await model.refreshVisibleUserInfo([item]);
    await model.refreshVisibleUserInfo([item]);
    expect(requests, hasLength(1));
  });

  test('requests once even when a user still has placeholder details',
      () async {
    load = (_) async => {
          'code': 0,
          'data': {
            'userInfoList': [
              {'accountId': 'first', 'name': 'first', 'avatar': ''},
            ],
          },
        };
    final item = _conversation('first');
    await model.refreshVisibleUserInfo([item]);
    await model.refreshVisibleUserInfo([item]);
    expect(requests, hasLength(1));
  });

  test('ignores completion after disposal', () async {
    final completer = Completer<Map<String, dynamic>>();
    load = (_) => completer.future;
    final item = _conversation('first');
    final pending = model.refreshVisibleUserInfo([item]);
    model.dispose();
    // Replace the disposed instance for the common teardown.
    model = _TestViewModel();
    completer.complete({
      'code': 0,
      'data': {
        'userInfoList': [
          {'accountId': 'first', 'name': 'Updated'}
        ],
      },
    });
    await pending;
    expect(item.conversation.name, 'first');
  });

  Future<void> showList(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ConversationViewModel>.value(
        value: model,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 124,
              child: ConversationList(
                onUnreadCountChanged: null,
                config: ConversationItemConfig(
                  customItemBuilder: (info, index) => Text(info.getName()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('first frame loads visible rows, not prefetched offscreen rows',
      (tester) async {
    model.conversationList =
        List.generate(20, (index) => _conversation('user-$index'));
    await showList(tester);
    await tester.pump(const Duration(milliseconds: 101));
    await tester.pump();
    expect(requests, [
      ['user-0', 'user-1']
    ]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('rechecks visible rows when conversation data changes',
      (tester) async {
    model.conversationList = [_conversation('first', name: 'Already known')];
    await showList(tester);
    await tester.pump(const Duration(milliseconds: 101));
    expect(requests, isEmpty);
    model.conversationList = [_conversation('first')];
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 101));
    await tester.pump();
    expect(requests, [
      ['first'],
    ]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'waits for scrolling to stop and cancels pending first-frame load',
      (tester) async {
    model.conversationList =
        List.generate(20, (index) => _conversation('user-$index'));
    await showList(tester);
    final gesture = await tester.startGesture(const Offset(100, 100));
    await gesture.moveBy(const Offset(0, -62));
    await tester.pump(const Duration(milliseconds: 200));
    expect(requests, isEmpty);
    await gesture.moveBy(const Offset(0, -62));
    await tester.pump(const Duration(milliseconds: 200));
    expect(requests, isEmpty);
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 101));
    await tester.pump();
    expect(requests, hasLength(1));
    expect(requests.single, isNot(contains('user-0')));
    expect(requests.single.length, lessThanOrEqualTo(3));
    await tester.pumpWidget(const SizedBox());
  });
}
