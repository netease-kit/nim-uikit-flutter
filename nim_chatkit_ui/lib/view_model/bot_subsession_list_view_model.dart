// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/manager/ai_robot_manager.dart';
import 'package:nim_chatkit/model/bot_subsession_models.dart';
import 'package:nim_chatkit/repo/chat_service_observer_repo.dart';
import 'package:nim_chatkit/repo/conversation_repo.dart';
import 'package:nim_chatkit/repo/text_search.dart';
import 'package:nim_chatkit/repo/topic_repo.dart';
import 'package:nim_chatkit_ui/helper/topic_message_helper.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_core_v2/nim_core.dart';

/// Whether the platform supports querying Topic messages from local storage.
@visibleForTesting
bool shouldLoadLatestTopicMessageFromLocal({
  required bool isWeb,
}) {
  return !isWeb;
}

class BotSubsessionListViewModel extends ChangeNotifier {
  static const int pageSize = 50;

  final String conversationId;

  BotSubsessionListViewModel(this.conversationId) {
    _init();
  }

  final List<StreamSubscription> _subscriptions = [];
  final List<BotSubsessionListItem> _allItems = [];
  int _unreadStateRevision = 0;

  List<BotSubsessionListItem> _items = [];

  List<BotSubsessionListItem> get items => _items;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;

  bool get isLoadingMore => _isLoadingMore;

  bool _loadFailed = false;

  bool get loadFailed => _loadFailed;

  bool _hasMore = false;

  bool get hasMore => _hasMore;

  bool _fallbackToLinearChat = false;
  bool _isDisposed = false;

  bool get fallbackToLinearChat => _fallbackToLinearChat;

  String _keyword = '';

  String get keyword => _keyword;

  String? _nextToken;
  BotSubsessionTopicContext? _draftContext;
  final Map<int, NIMMessage> _pendingTopicMessages = {};

  String get targetId => ChatKitUtils.getConversationTargetId(conversationId);

  V2NIMUserAIBot? get robot => AIRobotManager.instance.getRobotById(targetId);

  String get pageTitle {
    if (robot?.name?.isNotEmpty == true) {
      return robot!.name!;
    }
    return targetId;
  }

  BotSubsessionTopicContext? get draftContext => _draftContext;

  Future<void> _init() async {
    _bindTopicEvents();
    await reload();
  }

  Future<void> markConversationRead() async {
    await ConversationRepo.clearSessionUnreadCount(conversationId);
    // 更新会话已读时间戳，子会话列表红点基于 latestMessageTime > readTime 判定，
    // 仅清未读数不会更新 readTime，重新进入列表时红点会复现。
    await ConversationRepo.markConversationRead(conversationId);
    _clearUnreadDots();
  }

  void _bindTopicEvents() {
    _subscriptions.add(
      ConversationRepo.onConversationReadTimeUpdated().listen((event) {
        if (event.conversationId != conversationId) {
          return;
        }
        _clearUnreadDots();
      }),
    );
    _subscriptions.add(
      ConversationRepo.onConversationChanged().listen((conversations) {
        if (conversations.any(
          (conversation) =>
              conversation.conversationId == conversationId &&
              (conversation.unreadCount ?? 0) <= 0,
        )) {
          _clearUnreadDots();
        }
      }),
    );
    _subscriptions.add(
      TopicRepo.instance.onTopicAdded.listen((topic) {
        if (topic.conversationId == conversationId) {
          _upsertTopic(topic);
        }
      }),
    );
    _subscriptions.add(
      TopicRepo.instance.onTopicUpdated.listen((topic) {
        if (topic.conversationId == conversationId) {
          _upsertTopic(topic);
        }
      }),
    );
    _subscriptions.add(
      TopicRepo.instance.onTopicsRemoved.listen((topics) {
        final removedIds = topics
            .where((element) => element.conversationId == conversationId)
            .map((e) => e.topicId)
            .nonNulls
            .toSet();
        if (removedIds.isEmpty) {
          return;
        }
        _allItems.removeWhere(
          (item) => removedIds.contains(item.context.topic?.topicId),
        );
        _applyFilter();
      }),
    );
    _subscriptions.add(
      ChatServiceObserverRepo.observeSendMessage().listen(_handleTopicMessage),
    );
    _subscriptions.add(
      NimCore.instance.messageService.onReceiveMessages.listen((messages) {
        for (final message in messages) {
          _handleTopicMessage(message);
        }
      }),
    );
    _subscriptions.add(
      ChatServiceObserverRepo.observeMessageDelete().listen(
        _handleTopicMessageDeleted,
      ),
    );
  }

  Future<void> reload() async {
    _isLoading = true;
    _loadFailed = false;
    _fallbackToLinearChat = false;
    _nextToken = null;
    notifyListeners();

    final result = await TopicRepo.instance.getTopicListByOption(
      V2NIMTopicListOption(
        conversationId: conversationId,
        nextToken: '',
        limit: pageSize,
        direction: NIMQueryDirection.desc,
      ),
    );
    _isLoading = false;
    if (!result.isSuccess) {
      _loadFailed = true;
      notifyListeners();
      return;
    }

    _hasMore = result.data?.hasMore == true;
    _nextToken = result.data?.nextToken;
    _allItems
      ..clear()
      ..addAll(await _buildItems(result.data?.topicList ?? const []));
    if (_allItems.isEmpty) {
      _fallbackToLinearChat = true;
    }
    _applyFilter();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || (_nextToken?.isEmpty ?? true)) {
      return;
    }
    _isLoadingMore = true;
    notifyListeners();
    final result = await TopicRepo.instance.getTopicListByOption(
      V2NIMTopicListOption(
        conversationId: conversationId,
        nextToken: _nextToken,
        limit: pageSize,
        direction: NIMQueryDirection.desc,
      ),
    );
    _isLoadingMore = false;
    if (result.isSuccess) {
      _hasMore = result.data?.hasMore == true;
      _nextToken = result.data?.nextToken;
      _allItems.addAll(await _buildItems(result.data?.topicList ?? const []));
      _applyFilter();
    } else {
      notifyListeners();
    }
  }

  void updateKeyword(String value) {
    _keyword = value;
    _applyFilter();
  }

  void consumeFallbackNavigation() {
    _fallbackToLinearChat = false;
  }

  void createPlaceholder(String title) {
    _draftContext = BotSubsessionTopicContext(
      conversationId: conversationId,
      isPlaceholder: true,
      placeholderTitle: title,
      localKey:
          'placeholder_${conversationId}_${DateTime.now().microsecondsSinceEpoch}',
    );
    final existingIndex = _allItems.indexWhere((item) => item.isPlaceholder);
    final placeholderItem = BotSubsessionListItem(
      context: _draftContext!,
      title: _draftContext!.placeholderTitle,
      summary: '',
      latestTime: DateTime.now().millisecondsSinceEpoch,
      sortTime: DateTime.now().millisecondsSinceEpoch,
      showUnreadDot: false,
    );
    if (existingIndex >= 0) {
      _allItems[existingIndex] = placeholderItem;
    } else {
      _allItems.insert(0, placeholderItem);
    }
    _applyFilter();
  }

  void replacePlaceholderWithTopic(
    BotSubsessionTopicContext placeholderContext,
    V2NIMTopic topic, {
    bool notify = true,
  }) {
    if (_draftContext?.topicKey != placeholderContext.topicKey) {
      _upsertTopic(topic);
      return;
    }
    final pendingMessage = topic.topicId == null
        ? null
        : _pendingTopicMessages.remove(topic.topicId);
    final latestTime = pendingMessage?.createTime ??
        topic.updateTime ??
        topic.messageTime ??
        topic.createTime ??
        DateTime.now().millisecondsSinceEpoch;
    final item = BotSubsessionListItem(
      context: BotSubsessionTopicContext(
        conversationId: conversationId,
        topic: topic,
        localKey: placeholderContext.localKey,
      ),
      title: TopicMessageHelper.resolveTopicTitle(topic),
      summary: pendingMessage == null
          ? ''
          : TopicMessageHelper.buildSummaryText(pendingMessage),
      latestTime: latestTime,
      sortTime: latestTime,
      showUnreadDot: false,
    );
    final placeholderIndex =
        _allItems.indexWhere((element) => element.isPlaceholder);
    final topicIndex = _allItems.indexWhere(
      (element) => element.context.topic?.topicId == topic.topicId,
    );
    if (placeholderIndex >= 0) {
      _allItems[placeholderIndex] = item;
      if (topicIndex >= 0 && topicIndex != placeholderIndex) {
        _allItems.removeAt(topicIndex);
      }
    } else if (topicIndex >= 0) {
      _allItems[topicIndex] = item;
    } else {
      _allItems.insert(0, item);
    }
    _draftContext = null;
    _applyFilter(notify: notify);
    if (pendingMessage == null) {
      _upsertTopic(topic);
    }
  }

  void discardPlaceholder({
    BotSubsessionTopicContext? expectedContext,
    bool notify = true,
  }) {
    if (expectedContext != null &&
        _draftContext?.topicKey != expectedContext.topicKey) {
      return;
    }
    _draftContext = null;
    _allItems.removeWhere((item) => item.isPlaceholder);
    if (notify) {
      _applyFilter();
    }
  }

  Future<NIMResult<V2NIMTopic>> renameTopic(
    BotSubsessionListItem item,
    String title,
  ) async {
    final topic = item.context.topic;
    if (topic == null) {
      return NIMResult.failure(message: 'topic not found');
    }
    final trimmed = title.trim();
    final result = await TopicRepo.instance.updateTopic(
      V2NIMUpdateTopicParams(
        topic: topic,
        topicName: trimmed,
        serverExtension: TopicRepo.instance.buildTitleServerExtension(
          title: trimmed,
          userRenamed: true,
          originalServerExtension: topic.serverExtension,
        ),
      ),
    );
    if (result.isSuccess && result.data != null) {
      _upsertTopic(result.data!);
    }
    return result;
  }

  Future<NIMResult<void>> deleteTopic(BotSubsessionListItem item) async {
    final topic = item.context.topic;
    if (topic == null) {
      return NIMResult.failure(message: 'topic not found');
    }
    final result = await TopicRepo.instance.removeTopics(
      V2NIMRemoveTopicsParams(topicList: [topic]),
    );
    if (result.isSuccess) {
      _allItems.removeWhere(
        (element) => element.context.topic?.topicId == topic.topicId,
      );
      _applyFilter();
    }
    return result;
  }

  Future<List<BotSubsessionListItem>> _buildItems(
      List<V2NIMTopic> topics) async {
    int readTime = 0;
    final readTimeRes = await TopicRepo.instance.getConversationReadTime(
      conversationId,
    );
    if (readTimeRes.isSuccess && readTimeRes.data != null) {
      readTime = readTimeRes.data!;
    }

    final conversationType = !kIsWeb
        ? (await NimCore.instance.conversationIdUtil.conversationType(
              conversationId,
            ))
                .data ??
            NIMConversationType.p2p
        : null;

    return Future.wait(topics.map((topic) async {
      final title = TopicMessageHelper.resolveTopicTitle(topic);
      final latestMessageInfo = await _loadLatestMessageInfo(
        topic,
        readTime,
        conversationType,
      );
      return BotSubsessionListItem(
        context: BotSubsessionTopicContext(
          conversationId: conversationId,
          topic: topic,
        ),
        title: title,
        summary: latestMessageInfo.summary,
        latestTime: latestMessageInfo.latestMessageTime,
        sortTime: latestMessageInfo.sortTime,
        showUnreadDot: latestMessageInfo.showUnreadDot,
      );
    }));
  }

  Future<_TopicLatestMessageInfo> _loadLatestMessageInfo(
    V2NIMTopic topic,
    int readTime,
    NIMConversationType? conversationType,
  ) async {
    final topicTime =
        topic.updateTime ?? topic.messageTime ?? topic.createTime ?? 0;
    final fallbackMessageTime = topic.messageTime ?? topic.createTime ?? 0;
    if (shouldLoadLatestTopicMessageFromLocal(
      isWeb: kIsWeb,
    )) {
      final localLatestMessageInfo = await _queryLatestMessageInfoFromLocal(
        topic,
        readTime,
        topicTime,
        fallbackMessageTime,
        conversationType,
      );
      if (localLatestMessageInfo != null) {
        return localLatestMessageInfo;
      }
    }

    final cloudLatestMessageInfo = await _queryLatestMessageInfoFromCloud(
      topic,
      readTime,
      topicTime,
      fallbackMessageTime,
    );
    return cloudLatestMessageInfo ??
        _buildFallbackLatestMessageInfo(
          fallbackMessageTime,
          topicTime,
        );
  }

  Future<_TopicLatestMessageInfo?> _queryLatestMessageInfoFromLocal(
    V2NIMTopic topic,
    int readTime,
    int topicTime,
    int fallbackMessageTime,
    NIMConversationType? conversationType,
  ) async {
    final messageClientId = topic.messageClientId;
    final messageServerId = topic.messageServerId;
    if (messageClientId?.isEmpty != false &&
        messageServerId?.isEmpty != false) {
      return null;
    }

    final result =
        await NimCore.instance.messageService.getLocalThreadMessageList(
      messageRefer: NIMMessageRefer(
        conversationId: topic.conversationId ?? conversationId,
        conversationType: conversationType,
        messageClientId: messageClientId,
        messageServerId: messageServerId,
        createTime: topic.messageTime ?? topic.createTime,
      ),
    );
    if (!result.isSuccess) {
      return null;
    }

    final latestMessage = TopicMessageHelper.findLatestMessage(
      <NIMMessage?>[
        result.data?.message,
        ...?result.data?.replyList,
      ],
    );
    if (latestMessage == null) {
      return null;
    }

    final latestMessageTime = latestMessage.createTime ?? fallbackMessageTime;
    final sortTime =
        latestMessageTime > topicTime ? latestMessageTime : topicTime;
    return _TopicLatestMessageInfo(
      summary: TopicMessageHelper.buildSummaryText(latestMessage),
      latestMessageTime: latestMessageTime,
      sortTime: sortTime,
      showUnreadDot:
          _isReceivedMessage(latestMessage) && latestMessageTime > readTime,
    );
  }

  Future<_TopicLatestMessageInfo?> _queryLatestMessageInfoFromCloud(
    V2NIMTopic topic,
    int readTime,
    int topicTime,
    int fallbackMessageTime,
  ) async {
    final result = await TopicRepo.instance.getTopicMessageList(
      V2NIMTopicMessageListOption(
        topic: topic,
        limit: 1,
        direction: NIMQueryDirection.desc,
      ),
    );
    if (!result.isSuccess) {
      return null;
    }
    final messages = result.data?.replyList;
    if (messages == null || messages.isEmpty) {
      return null;
    }
    final latestMessage = TopicMessageHelper.findLatestMessage(messages);
    if (latestMessage == null) {
      return null;
    }
    final latestMessageTime = latestMessage.createTime ?? fallbackMessageTime;
    final sortTime =
        latestMessageTime > topicTime ? latestMessageTime : topicTime;
    return _TopicLatestMessageInfo(
      summary: TopicMessageHelper.buildSummaryText(latestMessage),
      latestMessageTime: latestMessageTime,
      sortTime: sortTime,
      showUnreadDot:
          _isReceivedMessage(latestMessage) && latestMessageTime > readTime,
    );
  }

  _TopicLatestMessageInfo _buildFallbackLatestMessageInfo(
    int fallbackMessageTime,
    int topicTime,
  ) {
    return _TopicLatestMessageInfo(
      summary: '',
      latestMessageTime: fallbackMessageTime,
      sortTime:
          topicTime > fallbackMessageTime ? topicTime : fallbackMessageTime,
      showUnreadDot: false,
    );
  }

  void _upsertTopic(V2NIMTopic topic) async {
    final unreadStateRevision = _unreadStateRevision;
    final items = await _buildItems([topic]);
    if (_isDisposed || items.isEmpty) {
      return;
    }
    final item = items.first;
    final index = _allItems.indexWhere(
      (element) => element.context.topic?.topicId == topic.topicId,
    );
    if (index >= 0) {
      final existing = _allItems[index];
      _allItems[index] = item.copyWith(
        title: item.title == S.of().botSubsessionNewSession
            ? existing.title
            : item.title,
        summary: item.summary.isEmpty ? existing.summary : item.summary,
        latestTime: item.latestTime > existing.latestTime
            ? item.latestTime
            : existing.latestTime,
        sortTime: item.sortTime > existing.sortTime
            ? item.sortTime
            : existing.sortTime,
        showUnreadDot: existing.showUnreadDot ||
            (unreadStateRevision == _unreadStateRevision && item.showUnreadDot),
      );
    } else {
      _allItems.insert(0, item);
    }
    _applyFilter();
  }

  void _handleTopicMessage(NIMMessage message) {
    if (message.conversationId != conversationId) {
      return;
    }
    final topicRefer = message.topicRefer;
    final topicId = topicRefer?.topicId;
    if (topicRefer == null ||
        topicRefer.conversationId != conversationId ||
        topicId == null) {
      return;
    }
    final index = _allItems.indexWhere(
      (item) => item.context.topic?.topicId == topicId,
    );
    if (index < 0) {
      _pendingTopicMessages[topicId] = message;
      _refreshTopicByRefer(topicRefer);
      return;
    }

    final item = _allItems[index];
    final latestTime =
        message.createTime ?? DateTime.now().millisecondsSinceEpoch;
    final topicTime = item.context.topic?.updateTime ??
        item.context.topic?.messageTime ??
        item.context.topic?.createTime ??
        0;
    _allItems[index] = item.copyWith(
      summary: TopicMessageHelper.buildSummaryText(message),
      latestTime: latestTime,
      sortTime: latestTime > topicTime ? latestTime : topicTime,
      showUnreadDot: item.showUnreadDot || _isReceivedMessage(message),
    );
    _applyFilter();
  }

  void _handleTopicMessageDeleted(
    List<NIMMessageDeletedNotification> notifications,
  ) {
    final hasDeletedMessageInConversation = notifications.any(
      (notification) =>
          notification.messageRefer?.conversationId == conversationId,
    );
    if (!hasDeletedMessageInConversation) {
      return;
    }
    _refreshLoadedTopicItems();
  }

  Future<void> _refreshLoadedTopicItems() async {
    final topics = _allItems
        .map((item) => item.context.topic)
        .whereType<V2NIMTopic>()
        .toList();
    if (topics.isEmpty) {
      return;
    }

    final refreshedItems = await _buildItems(topics);
    if (_isDisposed) {
      return;
    }
    final refreshedItemsByTopicId = <int, BotSubsessionListItem>{
      for (final item in refreshedItems)
        if (item.context.topic?.topicId != null)
          item.context.topic!.topicId!: item,
    };
    var hasUpdatedItem = false;
    for (var index = 0; index < _allItems.length; index++) {
      final topicId = _allItems[index].context.topic?.topicId;
      final refreshedItem =
          topicId == null ? null : refreshedItemsByTopicId[topicId];
      if (refreshedItem != null) {
        _allItems[index] = refreshedItem;
        hasUpdatedItem = true;
      }
    }
    if (hasUpdatedItem) {
      _applyFilter();
    }
  }

  Future<void> _refreshTopicByRefer(V2NIMTopicRefer topicRefer) async {
    final result = await TopicRepo.instance.getTopicByRefer(topicRefer);
    if (!_isDisposed && result.isSuccess && result.data != null) {
      _upsertTopic(result.data!);
    }
  }

  bool _isReceivedMessage(NIMMessage message) {
    if (message.isSelf != null) {
      return message.isSelf != true;
    }
    if (message.senderId == null) {
      return false;
    }
    return message.senderId != IMKitClient.account();
  }

  void _clearUnreadDots() {
    _unreadStateRevision++;
    var changed = false;
    for (var i = 0; i < _allItems.length; i++) {
      if (_allItems[i].showUnreadDot) {
        _allItems[i] = _allItems[i].copyWith(showUnreadDot: false);
        changed = true;
      }
    }
    if (changed) {
      _applyFilter();
    }
  }

  void _applyFilter({bool notify = true}) {
    if (_keyword.isEmpty) {
      _items = List.of(_allItems);
    } else {
      _items = _allItems
          .map((item) {
            final hit = TextSearcher.search(item.title, _keyword);
            if (hit == null) {
              return null;
            }
            return item.copyWith(
              highlightStart: hit.start,
              highlightEnd: hit.end,
            );
          })
          .nonNulls
          .toList();
    }
    _items.sort((a, b) {
      if (a.isPlaceholder != b.isPlaceholder) {
        return a.isPlaceholder ? -1 : 1;
      }
      return b.sortTime.compareTo(a.sortTime);
    });
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pendingTopicMessages.clear();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

class _TopicLatestMessageInfo {
  final String summary;
  final int latestMessageTime;
  final int sortTime;
  final bool showUnreadDot;

  const _TopicLatestMessageInfo({
    required this.summary,
    required this.latestMessageTime,
    required this.sortTime,
    required this.showUnreadDot,
  });
}
