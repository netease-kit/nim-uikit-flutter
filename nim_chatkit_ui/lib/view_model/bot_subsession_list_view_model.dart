// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/manager/ai_robot_manager.dart';
import 'package:nim_chatkit/model/bot_subsession_models.dart';
import 'package:nim_chatkit/repo/chat_service_observer_repo.dart';
import 'package:nim_chatkit/repo/conversation_repo.dart';
import 'package:nim_chatkit/repo/text_search.dart';
import 'package:nim_chatkit/repo/topic_repo.dart';
import 'package:nim_chatkit_ui/helper/topic_message_helper.dart';
import 'package:nim_core_v2/nim_core.dart';

class BotSubsessionListViewModel extends ChangeNotifier {
  static const int pageSize = 50;

  final String conversationId;

  BotSubsessionListViewModel(this.conversationId) {
    _init();
  }

  final List<StreamSubscription> _subscriptions = [];
  final List<BotSubsessionListItem> _allItems = [];

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
  bool get fallbackToLinearChat => _fallbackToLinearChat;

  String _keyword = '';
  String get keyword => _keyword;

  String? _nextToken;
  BotSubsessionTopicContext? _draftContext;

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
    for (var i = 0; i < _allItems.length; i++) {
      if (_allItems[i].showUnreadDot) {
        _allItems[i] = _allItems[i].copyWith(showUnreadDot: false);
      }
    }
    _applyFilter();
  }

  void _bindTopicEvents() {
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
    final latestTime = DateTime.now().millisecondsSinceEpoch;
    final item = BotSubsessionListItem(
      context: BotSubsessionTopicContext(
        conversationId: conversationId,
        topic: topic,
      ),
      title: TopicMessageHelper.resolveTopicTitle(topic),
      summary: '',
      latestTime: latestTime,
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

    return Future.wait(topics.map((topic) async {
      final title = TopicMessageHelper.resolveTopicTitle(topic);
      final latestMessageInfo = await _loadLatestMessageInfo(topic, readTime);
      return BotSubsessionListItem(
        context: BotSubsessionTopicContext(
          conversationId: conversationId,
          topic: topic,
        ),
        title: title,
        summary: latestMessageInfo.summary,
        latestTime: latestMessageInfo.latestTime,
        showUnreadDot: latestMessageInfo.showUnreadDot,
      );
    }));
  }

  Future<_TopicLatestMessageInfo> _loadLatestMessageInfo(
    V2NIMTopic topic,
    int readTime,
  ) async {
    final topicTime =
        topic.updateTime ?? topic.messageTime ?? topic.createTime ?? 0;
    final result = await TopicRepo.instance.getTopicMessageList(
      V2NIMTopicMessageListOption(
        topic: topic,
        limit: 1,
        direction: NIMQueryDirection.desc,
      ),
    );
    if (!result.isSuccess) {
      return _TopicLatestMessageInfo(
        summary: '',
        latestTime: topicTime,
        showUnreadDot: false,
      );
    }
    final messages = result.data?.replyList;
    if (messages == null || messages.isEmpty) {
      return _TopicLatestMessageInfo(
        summary: '',
        latestTime: topicTime,
        showUnreadDot: false,
      );
    }
    final latestMessage = messages.first;
    final latestTime = latestMessage.createTime ?? topicTime;
    return _TopicLatestMessageInfo(
      summary: TopicMessageHelper.buildSummaryText(latestMessage),
      latestTime: latestTime,
      showUnreadDot: _isReceivedMessage(latestMessage) && latestTime > readTime,
    );
  }

  void _upsertTopic(V2NIMTopic topic) async {
    final items = await _buildItems([topic]);
    if (items.isEmpty) {
      return;
    }
    final item = items.first;
    final index = _allItems.indexWhere(
      (element) => element.context.topic?.topicId == topic.topicId,
    );
    if (index >= 0) {
      _allItems[index] = item.copyWith(
        showUnreadDot: _allItems[index].showUnreadDot || item.showUnreadDot,
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
    if (topicRefer?.conversationId != conversationId || topicId == null) {
      return;
    }
    final index = _allItems.indexWhere(
      (item) => item.context.topic?.topicId == topicId,
    );
    if (index < 0) {
      _refreshTopicByRefer(topicRefer!);
      return;
    }

    final item = _allItems[index];
    final latestTime =
        message.createTime ?? DateTime.now().millisecondsSinceEpoch;
    _allItems[index] = item.copyWith(
      summary: TopicMessageHelper.buildSummaryText(message),
      latestTime: latestTime,
      showUnreadDot: item.showUnreadDot || _isReceivedMessage(message),
    );
    _applyFilter();
  }

  Future<void> _refreshTopicByRefer(V2NIMTopicRefer topicRefer) async {
    final result = await TopicRepo.instance.getTopicByRefer(topicRefer);
    if (result.isSuccess && result.data != null) {
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
      return b.latestTime.compareTo(a.latestTime);
    });
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

class _TopicLatestMessageInfo {
  final String summary;
  final int latestTime;
  final bool showUnreadDot;

  const _TopicLatestMessageInfo({
    required this.summary,
    required this.latestTime,
    required this.showUnreadDot,
  });
}
