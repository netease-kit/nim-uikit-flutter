// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/repo/conversation_group_repo.dart';
import 'package:nim_chatkit/repo/conversation_repo.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../l10n/S.dart';
import '../model/conversation_group_ui_model.dart';
import '../model/conversation_info.dart';
import '../service/ait/ait_server.dart';
import 'conversation_view_model.dart';

class ConversationGroupViewModel extends ChangeNotifier {
  static const int maxCustomGroupCount = 10;
  static const int maxGroupNameLength = 20;
  static const int maxGroupConversationCount = 100;
  static const int maxConversationGroupCount = 5;

  static const int conversationGroupLimit = 116435;
  static const int conversationGroupConversationCountLimit = 116437;
  static const int conversationNotExist = 110404;
  static const int conversationJoinGroupLimit = 110304;

  static bool isConversationJoinGroupLimit(int? code) {
    return code == conversationJoinGroupLimit;
  }

  final ConversationViewModel conversationViewModel;
  final BuildContext context;

  ConversationGroupViewModel({
    required this.conversationViewModel,
    required this.context,
  }) {
    _init();
  }

  List<ConversationGroupUiModel> _groups = [];
  String _selectedGroupId = ConversationGroupUiModel.allId;
  bool _loading = false;
  bool _saving = false;

  final List<StreamSubscription?> _subscriptions = [];
  final Map<String, _GroupConversationPage> _customPages = {};
  final Map<String, int> _customGroupUnreadCounts = {};
  final Set<String> _subscribedUnreadGroupIds = {};
  final Set<String> _refreshingCustomGroupUnreadIds = {};
  final Set<String> _pendingCustomGroupUnreadIds = {};
  bool _refreshingUnreadIgnoreMutedCount = false;
  bool _pendingUnreadIgnoreMutedCountRefresh = false;
  int _unreadIgnoreMutedCount = 0;
  bool _subscribedUnreadIgnoreMuted = false;

  List<ConversationGroupUiModel> get groups => _groups;

  List<ConversationGroupUiModel> get visibleGroups =>
      _groups.where((group) => group.visible).toList();

  List<ConversationGroupUiModel> get hiddenGroups =>
      _groups.where((group) => !group.visible).toList();

  ConversationGroupUiModel get selectedGroup {
    return _groups.firstWhere(
      (group) => group.id == _selectedGroupId,
      orElse: () => _defaultGroups().first,
    );
  }

  bool get loading => _loading;

  bool get saving => _saving;

  List<ConversationInfo> get displayConversations {
    final selected = selectedGroup;
    switch (selected.kind) {
      case ConversationGroupKind.all:
        return conversationViewModel.conversationList;
      case ConversationGroupKind.aitMe:
        return conversationViewModel.conversationList
            .where(_isAitMeConversation)
            .toList();
      case ConversationGroupKind.unread:
        return conversationViewModel.conversationList
            .where(_isUnreadConversation)
            .toList();
      case ConversationGroupKind.custom:
        return _customPages[selected.id]?.conversations ?? [];
    }
  }

  int unreadCountForGroup(ConversationGroupUiModel group) {
    switch (group.kind) {
      case ConversationGroupKind.all:
        return _unreadIgnoreMutedCount;
      case ConversationGroupKind.aitMe:
        return conversationViewModel.conversationList
            .where(_isAitMeConversation)
            .length;
      case ConversationGroupKind.unread:
        return _unreadIgnoreMutedCount;
      case ConversationGroupKind.custom:
        return _customGroupUnreadCounts[group.id] ?? 0;
    }
  }

  bool _isAitMeConversation(ConversationInfo conversation) {
    final type = conversation.getConversationType();
    return (type == NIMConversationType.team ||
            type == NIMConversationType.superTeam) &&
        conversation.haveBeenAit;
  }

  bool _isUnreadConversation(ConversationInfo conversation) {
    return conversation.getUnreadCount() > 0 && !conversation.isMute();
  }

  Future<void> _init() async {
    if (!IMKitConfigCenter.enableConversationGroup) {
      return;
    }
    await reloadGroups();
    _subscriptions.add(
      ConversationGroupRepo.onUnreadCountChangedByFilter().listen((event) {
        final groupId = event.conversationFilter?.conversationGroupId;
        final ignoreMuted = event.conversationFilter?.ignoreMuted;
        final unreadCount = event.unreadCount;
        if (unreadCount == null) {
          return;
        }
        if (groupId == null && ignoreMuted == true) {
          _unreadIgnoreMutedCount = unreadCount;
          notifyListeners();
          return;
        }
        if (groupId == null) {
          return;
        }
        _customGroupUnreadCounts[groupId] = unreadCount;
        notifyListeners();
      }),
    );
    // 某些桌面端 SDK 版本只回调会话变更，不回调分组未读 Filter 变更。
    // 使用变更会话携带的 groupIds 定向刷新，保证自定义分组未读数同步。
    _subscriptions.add(
      ConversationRepo.onConversationChanged().listen(
        _refreshCustomGroupUnreadForConversations,
      ),
    );
    _subscriptions.add(
      AitServer.instance.onSessionAitUpdated.listen(
        _updateCustomGroupAitState,
      ),
    );
    _subscriptions.add(
      ConversationGroupRepo.onConversationGroupCreated().listen((_) {
        reloadGroups();
      }),
    );
    _subscriptions.add(
      ConversationGroupRepo.onConversationGroupChanged().listen((_) {
        reloadGroups();
      }),
    );
    _subscriptions.add(
      ConversationGroupRepo.onConversationGroupDeleted()
          .listen((groupId) async {
        _customPages.remove(groupId);
        _customGroupUnreadCounts.remove(groupId);
        await _unsubscribeCustomGroupUnread(groupId);
        if (_selectedGroupId == groupId) {
          _selectedGroupId = ConversationGroupUiModel.allId;
        }
        reloadGroups();
      }),
    );
    _subscriptions.add(
      ConversationGroupRepo.onConversationsAddedToGroup().listen((event) {
        _refreshCustomGroupUnreadCount(event.groupId);
        if (event.groupId == _selectedGroupId) {
          _loadCustomConversations(event.groupId, refresh: true);
        }
      }),
    );
    _subscriptions.add(
      ConversationGroupRepo.onConversationsRemovedFromGroup().listen((event) {
        _refreshCustomGroupUnreadCount(event.groupId);
        if (_removeConversationsFromCustomCache(
          event.groupId,
          event.conversationIds,
        )) {
          notifyListeners();
        }
      }),
    );
    conversationViewModel.addListener(_onConversationChanged);
  }

  void _onConversationChanged() {
    _syncCustomConversationCache();
    final selected = selectedGroup;
    if (selected.kind == ConversationGroupKind.custom) {
      _loadCustomConversations(selected.id, refresh: true);
    } else {
      notifyListeners();
    }
  }

  void _syncCustomConversationCache() {
    if (_customPages.isEmpty) {
      return;
    }
    final conversationMap = {
      for (final conversation in conversationViewModel.conversationList)
        conversation.getConversationId(): conversation
    };
    for (final page in _customPages.values) {
      for (var i = 0; i < page.conversations.length; i++) {
        final existing = page.conversations[i];
        final latest = conversationMap[existing.getConversationId()];
        if (latest != null) {
          latest.haveBeenAit = latest.haveBeenAit || existing.haveBeenAit;
          page.conversations[i] = latest;
        }
      }
    }
  }

  void _updateCustomGroupAitState(AitSession? aitSession) {
    if (aitSession == null) {
      return;
    }
    var hasUpdated = false;
    for (final page in _customPages.values) {
      final index = page.conversations.indexWhere(
        (conversation) =>
            conversation.getConversationId() == aitSession.sessionId,
      );
      if (index >= 0) {
        page.conversations[index].haveBeenAit = aitSession.isAit;
        hasUpdated = true;
      }
    }
    if (hasUpdated) {
      notifyListeners();
    }
  }

  Future<void> reloadGroups() async {
    if (!IMKitConfigCenter.enableConversationGroup) {
      return;
    }
    _loading = true;
    notifyListeners();
    final result = await ConversationGroupRepo.getConversationGroupList();
    final configMap = await ConversationGroupRepo.getLocalConfigMap();
    final visibleOrder = await ConversationGroupRepo.getDefaultGroupOrder();
    if (!result.isSuccess) {
      _applyLocalConfigsToCachedGroups(configMap, visibleOrder);
      _loading = false;
      notifyListeners();
      return;
    }

    final sdkGroups = result.data ?? [];
    final defaults = await _orderedDefaultGroups(configMap);
    final customGroups = <ConversationGroupUiModel>[];
    var hiddenIndex = 100000;
    for (final sdkGroup in sdkGroups) {
      final config = configMap[sdkGroup.groupId];
      final visible = config?.visible ?? false;
      final sortOrder = config?.sortOrder ?? hiddenIndex++;
      customGroups.add(
        ConversationGroupUiModel(
          id: sdkGroup.groupId,
          kind: ConversationGroupKind.custom,
          name: sdkGroup.name ?? '',
          visible: visible,
          sortOrder: sortOrder,
          sdkGroup: sdkGroup,
        ),
      );
    }
    customGroups.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _groups = _sortGroups([...defaults, ...customGroups], visibleOrder);
    if (!_groups.any((group) => group.id == _selectedGroupId)) {
      _selectedGroupId = ConversationGroupUiModel.allId;
    }
    await _refreshDefaultGroupCounts();
    await _syncCustomUnreadSubscriptions();
    _loading = false;
    notifyListeners();
  }

  void _applyLocalConfigsToCachedGroups(
    Map<String, ConversationGroupLocalConfig> configMap,
    List<String> visibleOrder,
  ) {
    final source = _groups.isEmpty ? _defaultGroups() : _groups;
    _groups = _sortGroups(
      source
          .map(
            (group) => group.copyWith(
              visible: group.id == ConversationGroupUiModel.allId
                  ? true
                  : configMap[group.id]?.visible ?? group.visible,
              sortOrder: configMap[group.id]?.sortOrder ?? group.sortOrder,
            ),
          )
          .toList(),
      visibleOrder,
    );
    if (!_groups.any((group) => group.id == _selectedGroupId)) {
      _selectedGroupId = ConversationGroupUiModel.allId;
    }
  }

  Future<void> selectGroup(
    ConversationGroupUiModel group, {
    bool forceRefresh = false,
  }) async {
    final groupChanged = _selectedGroupId != group.id;
    _selectedGroupId = group.id;
    notifyListeners();
    if (group.kind == ConversationGroupKind.custom &&
        (groupChanged || forceRefresh)) {
      await _loadCustomConversations(group.id, refresh: true);
    }
  }

  /// Selects a custom group and loads all of its conversations into the cache.
  Future<void> loadAllConversationsForGroup(
    ConversationGroupUiModel group,
  ) async {
    if (!group.isCustom) {
      return;
    }
    await selectGroup(group, forceRefresh: true);
    while (true) {
      final page = _customPages[group.id];
      if (page == null ||
          page.finished ||
          page.conversations.length >= maxGroupConversationCount) {
        return;
      }
      final previousOffset = page.offset;
      final previousCount = page.conversations.length;
      await _loadCustomConversations(group.id);
      final nextPage = _customPages[group.id];
      if (nextPage == null ||
          (nextPage.offset == previousOffset &&
              nextPage.conversations.length == previousCount)) {
        return;
      }
    }
  }

  void selectAllGroup() {
    if (_selectedGroupId == ConversationGroupUiModel.allId) {
      return;
    }
    _selectedGroupId = ConversationGroupUiModel.allId;
    notifyListeners();
  }

  Future<void> loadMoreForSelectedGroup() async {
    final selected = selectedGroup;
    if (selected.kind == ConversationGroupKind.custom) {
      await _loadCustomConversations(selected.id);
    } else {
      conversationViewModel.queryConversationNextList();
    }
  }

  Future<void> hideGroup(ConversationGroupUiModel group) async {
    if (!group.canHide) {
      return;
    }
    await _updateCustomVisibility(group, false);
  }

  Future<void> showGroup(ConversationGroupUiModel group) async {
    if (!group.canHide) {
      return;
    }
    await _updateCustomVisibility(group, true);
  }

  Future<void> reorderVisible(int oldIndex, int newIndex) async {
    final list = visibleGroups;
    if (oldIndex <= 0 || oldIndex >= list.length) {
      return;
    }
    if (newIndex <= 0) {
      newIndex = 1;
    }
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final moving = list.removeAt(oldIndex);
    list.insert(newIndex, moving);
    await _saveVisibleOrder(list);
  }

  Future<void> reorderHidden(int oldIndex, int newIndex) async {
    final list = hiddenGroups;
    if (oldIndex < 0 || oldIndex >= list.length) {
      return;
    }
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final moving = list.removeAt(oldIndex);
    list.insert(newIndex, moving);
    await _saveHiddenOrder(list);
  }

  Future<NIMResult<V2NIMConversationGroupResult>> createGroup(
    String name, {
    List<String> conversationIds = const [],
  }) async {
    final trimmedName = name.trim();
    if (conversationIds.length > maxGroupConversationCount) {
      return NIMResult.failure(message: 'conversation count limit');
    }
    final result = await ConversationGroupRepo.createConversationGroup(
      trimmedName,
      conversationIds,
    );
    if (result.isSuccess && result.data?.group != null) {
      final groupId = result.data!.group!.groupId;
      final configMap = await ConversationGroupRepo.getLocalConfigMap();
      configMap[groupId] = ConversationGroupLocalConfig(
        groupId: groupId,
        visible: true,
        sortOrder: _nextVisibleSortOrder(),
      );
      await ConversationGroupRepo.saveLocalConfigs(configMap.values);
      if (conversationIds.isEmpty) {
        _customPages[groupId] = _GroupConversationPage()..finished = true;
      }
      await reloadGroups();
    }
    return result;
  }

  Future<NIMResult<void>> updateGroupName(
    ConversationGroupUiModel group,
    String name,
  ) async {
    final trimmedName = name.trim();
    if (!group.isCustom ||
        trimmedName.isEmpty ||
        trimmedName.length > maxGroupNameLength) {
      return NIMResult.failure(message: 'invalid name');
    }
    final result = await ConversationGroupRepo.updateConversationGroup(
      group.id,
      trimmedName,
      serverExtension: group.sdkGroup?.serverExtension,
    );
    if (result.isSuccess) {
      await reloadGroups();
    }
    return result;
  }

  Future<NIMResult<void>> deleteGroup(ConversationGroupUiModel group) async {
    if (!group.canDelete) {
      return NIMResult.failure(message: 'not support');
    }
    final result =
        await ConversationGroupRepo.deleteConversationGroup(group.id);
    if (result.isSuccess) {
      final configMap = await ConversationGroupRepo.getLocalConfigMap();
      configMap.remove(group.id);
      await ConversationGroupRepo.saveLocalConfigs(configMap.values);
      _customPages.remove(group.id);
      _customGroupUnreadCounts.remove(group.id);
      await _unsubscribeCustomGroupUnread(group.id);
      if (_selectedGroupId == group.id) {
        _selectedGroupId = ConversationGroupUiModel.allId;
      }
      await reloadGroups();
    }
    return result;
  }

  Future<NIMResult<List<V2NIMConversationOperationResult>>>
      addConversationsToGroup(
    ConversationGroupUiModel group,
    List<String> conversationIds,
  ) async {
    if (!group.isCustom) {
      return NIMResult.failure(message: 'not support');
    }
    final requestIds = conversationIds.toSet().toList();
    if (requestIds.length > maxGroupConversationCount) {
      return NIMResult.failure(
        code: conversationGroupConversationCountLimit,
        message: 'conversation count limit',
      );
    }
    await loadAllConversationsForGroup(group);
    final page = _customPages[group.id];
    if (page?.finished == true) {
      final existingIds = page!.conversations
          .map((conversation) => conversation.getConversationId())
          .toSet();
      final newCount = requestIds
          .where((conversationId) => !existingIds.contains(conversationId))
          .length;
      if (existingIds.length + newCount > maxGroupConversationCount) {
        return NIMResult.failure(
          code: conversationGroupConversationCountLimit,
          message: 'conversation count limit',
        );
      }
    }
    final result = await ConversationGroupRepo.addConversationsToGroup(
      group.id,
      requestIds,
    );
    if (result.isSuccess) {
      await loadAllConversationsForGroup(group);
    }
    return result;
  }

  Future<NIMResult<List<V2NIMConversationOperationResult>>>
      removeConversationsFromGroup(
    ConversationGroupUiModel group,
    List<String> conversationIds,
  ) async {
    if (!group.isCustom) {
      return NIMResult.failure(message: 'not support');
    }
    final result = await ConversationGroupRepo.removeConversationsFromGroup(
      group.id,
      conversationIds,
    );
    if (result.isSuccess) {
      if (_removeConversationsFromCustomCache(group.id, conversationIds)) {
        notifyListeners();
      }
    }
    return result;
  }

  bool _removeConversationsFromCustomCache(
    String groupId,
    Iterable<String> conversationIds,
  ) {
    final page = _customPages[groupId];
    if (page == null) {
      return false;
    }
    final removeIds = conversationIds.toSet();
    final oldLength = page.conversations.length;
    page.conversations.removeWhere(
      (conversation) => removeIds.contains(conversation.getConversationId()),
    );
    return page.conversations.length != oldLength;
  }

  Future<void> _loadCustomConversations(
    String groupId, {
    bool refresh = false,
  }) async {
    final page = _customPages[groupId] ?? _GroupConversationPage();
    if (page.loading) {
      final loadingCompleter = page.loadingCompleter;
      if (loadingCompleter != null) {
        await loadingCompleter.future;
      }
      if (refresh) {
        await _loadCustomConversations(groupId, refresh: true);
      }
      return;
    }
    if (!refresh && page.finished) {
      return;
    }
    final loadingCompleter = Completer<void>();
    page.loading = true;
    page.loadingCompleter = loadingCompleter;
    if (refresh) {
      page.offset = 0;
      page.finished = false;
      page.conversations.clear();
    }
    _customPages[groupId] = page;
    try {
      final result = await ConversationGroupRepo.getConversationListByGroupId(
        groupId,
        page.offset,
        maxGroupConversationCount,
      );
      if (result.isSuccess && result.data != null) {
        page.offset = result.data!.offset;
        page.finished = result.data!.finished ||
            page.conversations.length >= maxGroupConversationCount;
        final conversations = (conversationViewModel.convertConversationInfo(
                  result.data!.conversationList,
                ) ??
                [])
            .toList();
        final conversationsWithAitState =
            await _applyAitStateToCustomConversations(conversations);
        final conversationIds = page.conversations
            .map((conversation) => conversation.getConversationId())
            .toSet();
        for (final conversation in conversationsWithAitState) {
          if (conversationIds.add(conversation.getConversationId())) {
            page.conversations.add(conversation);
          }
        }
        page.finished = page.finished ||
            page.conversations.length >= maxGroupConversationCount;
      }
    } finally {
      page.loading = false;
      page.loadingCompleter = null;
      notifyListeners();
      loadingCompleter.complete();
    }
  }

  Future<List<ConversationInfo>> _applyAitStateToCustomConversations(
    List<ConversationInfo> conversations,
  ) async {
    final mainConversationMap = {
      for (final conversation in conversationViewModel.conversationList)
        conversation.getConversationId(): conversation,
    };
    final accountId = IMKitClient.account();
    final aitConversationIds = IMKitClient.enableAit && accountId != null
        ? (await AitServer.instance.getAllAitSession(accountId)).toSet()
        : const <String>{};

    return conversations.map((conversation) {
      final conversationId = conversation.getConversationId();
      final hasUnreadAit = aitConversationIds.contains(conversationId) &&
          conversation.getUnreadCount() > 0;
      final latestConversation = mainConversationMap[conversationId];
      if (latestConversation != null) {
        latestConversation.haveBeenAit =
            latestConversation.haveBeenAit || hasUnreadAit;
        return latestConversation;
      }
      conversation.haveBeenAit = hasUnreadAit;
      return conversation;
    }).toList();
  }

  Future<void> _refreshDefaultGroupCounts() async {
    await _refreshUnreadIgnoreMutedCount();
    await _subscribeUnreadIgnoreMutedCount();
  }

  Future<void> _refreshUnreadIgnoreMutedCount() async {
    if (_refreshingUnreadIgnoreMutedCount) {
      _pendingUnreadIgnoreMutedCountRefresh = true;
      return;
    }
    _refreshingUnreadIgnoreMutedCount = true;
    try {
      do {
        _pendingUnreadIgnoreMutedCountRefresh = false;
        final result = await ConversationGroupRepo.getUnreadCountIgnoreMuted();
        if (result.isSuccess &&
            result.data != null &&
            _unreadIgnoreMutedCount != result.data!) {
          _unreadIgnoreMutedCount = result.data!;
          notifyListeners();
        }
      } while (_pendingUnreadIgnoreMutedCountRefresh);
    } finally {
      _refreshingUnreadIgnoreMutedCount = false;
    }
  }

  Future<void> _subscribeUnreadIgnoreMutedCount() async {
    if (_subscribedUnreadIgnoreMuted) {
      return;
    }
    final result =
        await ConversationGroupRepo.subscribeUnreadCountIgnoreMuted();
    if (result.isSuccess) {
      _subscribedUnreadIgnoreMuted = true;
    }
  }

  Future<void> _refreshCustomGroupUnreadCount(String groupId) async {
    if (!_refreshingCustomGroupUnreadIds.add(groupId)) {
      _pendingCustomGroupUnreadIds.add(groupId);
      return;
    }
    try {
      do {
        _pendingCustomGroupUnreadIds.remove(groupId);
        final result =
            await ConversationGroupRepo.getUnreadCountByGroupId(groupId);
        if (result.isSuccess && result.data != null) {
          _customGroupUnreadCounts[groupId] = result.data!;
          notifyListeners();
        }
      } while (_pendingCustomGroupUnreadIds.contains(groupId));
    } finally {
      _refreshingCustomGroupUnreadIds.remove(groupId);
    }
  }

  void _refreshCustomGroupUnreadForConversations(
    List<NIMConversation> conversations,
  ) {
    if (ChatKitUtils.isDesktopOrWeb && conversations.isNotEmpty) {
      _refreshUnreadIgnoreMutedCount();
    }
    final changedGroupIds = <String>{};
    for (final conversation in conversations) {
      changedGroupIds.addAll(conversation.groupIds ?? const <String>[]);
    }
    for (final groupId in changedGroupIds) {
      if (_subscribedUnreadGroupIds.contains(groupId)) {
        _refreshCustomGroupUnreadCount(groupId);
      }
    }
  }

  Future<void> _syncCustomUnreadSubscriptions() async {
    final customGroupIds = _groups
        .where((group) => group.isCustom)
        .map((group) => group.id)
        .toSet();
    final staleGroupIds = _subscribedUnreadGroupIds
        .where((groupId) => !customGroupIds.contains(groupId))
        .toList();
    for (final groupId in staleGroupIds) {
      await _unsubscribeCustomGroupUnread(groupId);
      _customGroupUnreadCounts.remove(groupId);
    }
    for (final groupId in customGroupIds) {
      await _refreshCustomGroupUnreadCount(groupId);
      if (_subscribedUnreadGroupIds.add(groupId)) {
        await ConversationGroupRepo.subscribeUnreadCountByGroupId(groupId);
      }
    }
  }

  Future<void> _unsubscribeCustomGroupUnread(String groupId) async {
    if (_subscribedUnreadGroupIds.remove(groupId)) {
      await ConversationGroupRepo.unsubscribeUnreadCountByGroupId(groupId);
    }
  }

  Future<void> _updateCustomVisibility(
    ConversationGroupUiModel group,
    bool visible,
  ) async {
    _saving = true;
    notifyListeners();
    final configMap = await ConversationGroupRepo.getLocalConfigMap();
    configMap[group.id] = ConversationGroupLocalConfig(
      groupId: group.id,
      visible: visible,
      sortOrder: visible ? _nextVisibleSortOrder() : _nextHiddenSortOrder(),
    );
    final visibleIds = _groups
        .where((item) => item.visible && item.id != group.id)
        .map((item) => item.id)
        .toList();
    final hiddenIds = _groups
        .where((item) => !item.visible && item.id != group.id)
        .map((item) => item.id)
        .toList();
    final orderIds = <String>[...visibleIds];
    if (visible) {
      orderIds.add(group.id);
      orderIds.addAll(hiddenIds);
    } else {
      orderIds.addAll(hiddenIds);
      orderIds.add(group.id);
    }
    await ConversationGroupRepo.saveDefaultGroupOrder(orderIds);
    await ConversationGroupRepo.saveLocalConfigs(configMap.values);
    if (!visible && _selectedGroupId == group.id) {
      _selectedGroupId = ConversationGroupUiModel.allId;
    }
    await reloadGroups();
    _saving = false;
    notifyListeners();
  }

  Future<void> _saveVisibleOrder(List<ConversationGroupUiModel> list) async {
    final configMap = await ConversationGroupRepo.getLocalConfigMap();
    final hiddenGroups = this.hiddenGroups;
    final orderIds = <String>[];
    for (var i = 0; i < list.length; i++) {
      final group = list[i];
      orderIds.add(group.id);
      if (group.canHide) {
        configMap[group.id] = ConversationGroupLocalConfig(
          groupId: group.id,
          visible: true,
          sortOrder: i,
        );
      }
    }
    for (var i = 0; i < hiddenGroups.length; i++) {
      final group = hiddenGroups[i];
      if (!orderIds.contains(group.id)) {
        orderIds.add(group.id);
      }
      if (group.canHide) {
        configMap[group.id] = ConversationGroupLocalConfig(
          groupId: group.id,
          visible: false,
          sortOrder: 100000 + i,
        );
      }
    }
    await ConversationGroupRepo.saveDefaultGroupOrder(orderIds);
    await ConversationGroupRepo.saveLocalConfigs(configMap.values);
    await reloadGroups();
  }

  Future<void> _saveHiddenOrder(List<ConversationGroupUiModel> list) async {
    final configMap = await ConversationGroupRepo.getLocalConfigMap();
    final orderIds = <String>[
      ...visibleGroups.map((group) => group.id),
      ...list.map((group) => group.id),
    ];
    for (var i = 0; i < list.length; i++) {
      final group = list[i];
      if (group.canHide) {
        configMap[group.id] = ConversationGroupLocalConfig(
          groupId: group.id,
          visible: false,
          sortOrder: 100000 + i,
        );
      }
    }
    await ConversationGroupRepo.saveDefaultGroupOrder(orderIds);
    await ConversationGroupRepo.saveLocalConfigs(configMap.values);
    await reloadGroups();
  }

  int _nextVisibleSortOrder() {
    final visibleCustom =
        _groups.where((group) => group.isCustom && group.visible);
    if (visibleCustom.isEmpty) {
      return 1000;
    }
    return visibleCustom
            .map((group) => group.sortOrder)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  int _nextHiddenSortOrder() {
    final hiddenCustom =
        _groups.where((group) => group.isCustom && !group.visible);
    if (hiddenCustom.isEmpty) {
      return 100000;
    }
    return hiddenCustom
            .map((group) => group.sortOrder)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  Future<List<ConversationGroupUiModel>> _orderedDefaultGroups(
    Map<String, ConversationGroupLocalConfig> configMap,
  ) async {
    final defaults = _defaultGroups();
    final order = await ConversationGroupRepo.getDefaultGroupOrder();
    if (order.isEmpty) {
      return defaults
          .map(
            (group) => group.copyWith(
              visible: group.id == ConversationGroupUiModel.allId
                  ? true
                  : configMap[group.id]?.visible ?? group.visible,
              sortOrder: configMap[group.id]?.sortOrder ?? group.sortOrder,
            ),
          )
          .toList();
    }
    final map = {for (final group in defaults) group.id: group};
    final result = <ConversationGroupUiModel>[];
    for (var index = 0; index < order.length; index++) {
      final id = order[index];
      final group = map[id];
      if (group != null) {
        final config = configMap[id];
        result.add(
          group.copyWith(
            visible: id == ConversationGroupUiModel.allId
                ? true
                : config?.visible ?? true,
            sortOrder: config?.sortOrder ?? index,
          ),
        );
      }
    }
    for (final group in defaults) {
      if (!result.any((item) => item.id == group.id)) {
        result.add(group);
      }
    }
    return result;
  }

  List<ConversationGroupUiModel> _defaultGroups() {
    return [
      ConversationGroupUiModel(
        id: ConversationGroupUiModel.allId,
        kind: ConversationGroupKind.all,
        name: S.of(context).conversationGroupAll,
        visible: true,
        sortOrder: 0,
      ),
      ConversationGroupUiModel(
        id: ConversationGroupUiModel.aitMeId,
        kind: ConversationGroupKind.aitMe,
        name: S.of(context).conversationGroupAitMe,
        visible: true,
        sortOrder: 1,
      ),
      ConversationGroupUiModel(
        id: ConversationGroupUiModel.unreadId,
        kind: ConversationGroupKind.unread,
        name: S.of(context).conversationGroupUnread,
        visible: true,
        sortOrder: 2,
      ),
    ];
  }

  List<ConversationGroupUiModel> _sortGroups(
    List<ConversationGroupUiModel> source,
    List<String> visibleOrder,
  ) {
    final visible = source.where((group) => group.visible).toList()
      ..sort((a, b) {
        final orderA = visibleOrder.indexOf(a.id);
        final orderB = visibleOrder.indexOf(b.id);
        if (orderA >= 0 && orderB >= 0) {
          return orderA.compareTo(orderB);
        }
        if (orderA >= 0) {
          return -1;
        }
        if (orderB >= 0) {
          return 1;
        }
        return a.sortOrder.compareTo(b.sortOrder);
      });
    final hidden = source.where((group) => !group.visible).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    visible.removeWhere((group) => group.id == ConversationGroupUiModel.allId);
    return [_defaultGroups().first, ...visible, ...hidden];
  }

  @override
  void dispose() {
    conversationViewModel.removeListener(_onConversationChanged);
    for (final subscription in _subscriptions) {
      subscription?.cancel();
    }
    for (final groupId in _subscribedUnreadGroupIds.toList()) {
      ConversationGroupRepo.unsubscribeUnreadCountByGroupId(groupId);
    }
    if (_subscribedUnreadIgnoreMuted) {
      ConversationGroupRepo.unsubscribeUnreadCountIgnoreMuted();
    }
    _subscribedUnreadGroupIds.clear();
    _refreshingCustomGroupUnreadIds.clear();
    _pendingCustomGroupUnreadIds.clear();
    _pendingUnreadIgnoreMutedCountRefresh = false;
    super.dispose();
  }
}

class _GroupConversationPage {
  int offset = 0;
  bool finished = false;
  bool loading = false;
  Completer<void>? loadingCompleter;
  List<ConversationInfo> conversations = [];
}
