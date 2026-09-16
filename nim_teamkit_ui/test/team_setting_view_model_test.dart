// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit/model/team_models.dart';
import 'package:nim_chatkit/repo/team_member_search_repository.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/message/nim_chat_cache.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:nim_teamkit_ui/view_model/team_setting_view_model.dart';

class _MemberCache implements NIMChatCache {
  final controller =
      StreamController<List<UserInfoWithTeam>>.broadcast(sync: true);
  List<UserInfoWithTeam> members = <UserInfoWithTeam>[];
  int fetchCalls = 0;

  @override
  List<UserInfoWithTeam> get teamMembers => members;

  @override
  Future<void> fetchTeamMember(String teamId,
      {bool loadMore = false, int? limit}) async {
    fetchCalls++;
  }

  @override
  Stream<List<UserInfoWithTeam>> get teamMembersNotifier => controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SearchRepository extends TeamMemberSearchRepository {
  int calls = 0;
  final List<NIMTeamMemberRoleQueryType> roleQueries = [];
  Future<List<UserInfoWithTeam>> result = Future.value([]);

  @override
  Future<List<UserInfoWithTeam>> loadAll(
    String teamId,
    NIMTeamType teamType, {
    NIMTeamMemberRoleQueryType roleQueryType =
        NIMTeamMemberRoleQueryType.memberRoleQueryTypeAll,
  }) {
    calls++;
    roleQueries.add(roleQueryType);
    return result;
  }
}

UserInfoWithTeam _member(
  String accountId, {
  NIMTeamMemberRole role = NIMTeamMemberRole.memberRoleNormal,
}) =>
    UserInfoWithTeam(
      null,
      NIMTeamMember(
        teamId: 'team',
        teamType: NIMTeamType.typeNormal,
        accountId: accountId,
        memberRole: role,
        joinTime: 1,
        inTeam: true,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.yunxin.163.com/nim_core');
  late NIMChatCache originalCache;
  late _MemberCache cache;
  late _SearchRepository repository;
  late TeamSettingViewModel model;
  late Completer<Map<String, dynamic>> removal;
  final first = _member('match-first');
  final second = _member('match-second');
  final laterPage = _member('match-later-page');

  setUp(() {
    originalCache = NIMChatCache.instance;
    cache = _MemberCache();
    NIMChatCache.instance = cache;
    repository = _SearchRepository();
    repository.result = Future.value([first, second, laterPage]);
    getIt.registerSingleton<TeamMemberSearchRepository>(repository);
    removal = Completer<Map<String, dynamic>>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'kickMember');
      return removal.future;
    });
    model = TeamSettingViewModel(configuredTeamId: 'team');
    model.userInfoData = [first, second];
    model.addTeamSubscribe();
  });

  tearDown(() async {
    model.dispose();
    await cache.controller.close();
    NIMChatCache.instance = originalCache;
    await getIt.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  for (final eventFirst in [true, false]) {
    test('removes only the member without loading (event first: $eventFirst)',
        () async {
      model.filterByText('match');
      await Future<void>.delayed(Duration.zero);
      final loadingStates = <bool>[];
      model.addListener(() {
        loadingStates.add(model.isFilterLoading);
        expect(model.filterList, isNotNull);
      });

      final result = model.removeTeamMember('team', first.teamInfo.accountId);
      if (eventFirst) cache.controller.add([second]);
      removal.complete({'code': 0});
      expect((await result).isSuccess, isTrue);
      if (!eventFirst) cache.controller.add([second]);

      expect(model.filterList, [second, laterPage]);
      expect(model.searchKey, 'match');
      expect(loadingStates, isNotEmpty);
      expect(loadingStates, everyElement(isFalse));
      expect(repository.calls, 1);
    });
  }

  test('failed removal preserves the search results', () async {
    model.filterByText('match');
    await Future<void>.delayed(Duration.zero);
    final result = model.removeTeamMember('team', first.teamInfo.accountId);
    removal.complete({'code': 403});

    expect((await result).isSuccess, isFalse);
    expect(model.filterList, [first, second, laterPage]);
    expect(repository.calls, 1);
    expect(model.isFilterLoading, isFalse);
  });

  test('initial member request merges owner and managers before pagination',
      () async {
    final normal = _member('normal');
    final owner = _member(
      'owner',
      role: NIMTeamMemberRole.memberRoleOwner,
    );
    final manager = _member(
      'manager',
      role: NIMTeamMemberRole.memberRoleManager,
    );
    cache.members = [normal];
    repository.result = Future.value([manager, owner]);

    model.requestTeamMembers('team');
    await Future<void>.delayed(Duration.zero);

    expect(repository.roleQueries, [
      NIMTeamMemberRoleQueryType.memberRoleQueryTypeManager,
    ]);
    expect(
      model.userInfoData?.map((member) => member.teamInfo.accountId),
      ['owner', 'manager', 'normal'],
    );
    expect(cache.fetchCalls, 0);
  });

  test('an in-flight search cannot restore a removed member', () async {
    final search = Completer<List<UserInfoWithTeam>>();
    repository.result = search.future;
    model.filterByText('match');
    final result = model.removeTeamMember('team', first.teamInfo.accountId);
    removal.complete({'code': 0});
    await result;
    search.complete([first, second, laterPage]);
    await Future<void>.delayed(Duration.zero);

    expect(model.filterList, [second, laterPage]);
    expect(model.isFilterLoading, isFalse);
    expect(repository.calls, 1);
  });
}
