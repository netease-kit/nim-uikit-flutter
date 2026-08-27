// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/manager/ai_robot_manager.dart';
import 'package:nim_chatkit/model/bot_subsession_models.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/repo/chat_service_observer_repo.dart';
import 'package:nim_chatkit/repo/topic_repo.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/helper/chat_message_helper.dart';
import 'package:nim_chatkit_ui/helper/topic_message_helper.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/view_model/chat_view_model.dart';
import 'package:nim_core_v2/nim_core.dart';

class TopicChatViewModel extends ChatViewModel {
  final BotSubsessionTopicContext topicContext;
  final void Function(BotSubsessionTopicContext context)? onTopicResolved;

  V2NIMTopic? _currentTopic;
  bool _isPlaceholder = false;
  bool _isDisposed = false;
  StreamSubscription<V2NIMTopic>? _topicUpdatedSub;
  StreamSubscription<List<V2NIMTopicRefer>>? _topicRemovedSub;
  final Set<String> _pendingTopicMessageClientIds = <String>{};
  String topicTitle = '';

  TopicChatViewModel(
    String conversationId, {
    required this.topicContext,
    this.onTopicResolved,
    ChatUIConfig? chatUIConfig,
  })  : _currentTopic = topicContext.topic,
        _isPlaceholder =
            topicContext.isPlaceholder || topicContext.topic == null,
        super(
          conversationId,
          NIMConversationType.p2p,
          chatUIConfig: chatUIConfig,
        ) {
    chatTitle = rootSessionTitle;
    topicTitle = _resolveTitle();
    mute = false;
    _bindTopicEvents();
  }

  bool get isPlaceholder => _currentTopic == null || _isPlaceholder;

  V2NIMTopic? get currentTopic => _currentTopic;
  V2NIMUserAIBot? get currentRobot => AIRobotManager.instance.getRobotById(
        ChatKitUtils.getConversationTargetId(conversationId),
      );
  String get rootSessionTitle => currentRobot?.name?.isNotEmpty == true
      ? currentRobot!.name!
      : ChatKitUtils.getConversationTargetId(conversationId);
  @override
  String get routePendingNewMessageKey =>
      '$conversationId|topic:${topicContext.topicKey}';
  bool _topicDeleted = false;
  bool get topicDeleted => _topicDeleted;
  String get _placeholderTitle => topicContext.placeholderTitle.isNotEmpty
      ? topicContext.placeholderTitle
      : S.of().botSubsessionNewSession;

  @override
  initData({NIMMessage? anchorMessage}) async {
    await initBaseData(updateTitle: false);
    chatTitle = rootSessionTitle;
    topicTitle = _resolveTitle();
    notifyListeners();
    if (anchorMessage != null) {
      loadMessageWithAnchor(anchorMessage);
    } else if (findAnchorDate != null) {
      loadMessageWithAnchorDate(findAnchorDate!);
    } else {
      _initTopicFetch();
    }
    subscriptions.add(
      ChatServiceObserverRepo.observeMessageReceipt().listen((event) {
        updateP2PReceipt(event);
      }),
    );
  }

  void _bindTopicEvents() {
    _topicUpdatedSub = TopicRepo.instance.onTopicUpdated.listen((topic) {
      if (_currentTopic?.topicId == topic.topicId &&
          topic.conversationId == conversationId) {
        _currentTopic = topic;
        topicTitle = _resolveTitle();
        notifyListeners();
      }
    });
    _topicRemovedSub = TopicRepo.instance.onTopicsRemoved.listen((topics) {
      final removed = topics.any((topic) =>
          topic.conversationId == conversationId &&
          topic.topicId == _currentTopic?.topicId);
      if (removed) {
        _currentTopic = null;
        _topicDeleted = true;
        topicTitle = _placeholderTitle;
        notifyListeners();
      }
    });
  }

  String _resolveTitle() {
    return TopicMessageHelper.resolveTopicTitle(
      _currentTopic,
      fallback: _placeholderTitle,
    );
  }

  void _initTopicFetch() {
    clearRoutePendingNewMessages();
    if (isPlaceholder) {
      hasMoreForwardMessages = false;
      hasMoreNewerMessages = false;
      isLoading = false;
      if (messageList.isEmpty) {
        messageList = [];
      } else {
        notifyListeners();
      }
      return;
    }
    hasMoreForwardMessages = true;
    hasMoreNewerMessages = false;
    _fetchTopicMessages(
        limit: ChatViewModel.messageLimit, anchor: null, init: true);
  }

  @override
  void loadMessageWithAnchor(NIMMessage anchor) {
    prepareForAnchorLoading();
    hasMoreForwardMessages = true;
    hasMoreNewerMessages = false;
    _fetchTopicMessages(
        limit: ChatViewModel.messageLimit, anchor: anchor, init: true);
  }

  @override
  Future<NIMResult<NIMMessage>> getMessageByRefer(
    NIMMessageRefer messageRefer,
  ) async {
    final localResult = await super.getMessageByRefer(messageRefer);
    if (localResult.isSuccess && localResult.data != null) {
      return localResult;
    }

    final topic = _currentTopic;
    final createTime = messageRefer.createTime;
    if (topic == null || createTime == null || createTime <= 0) {
      return localResult;
    }

    final result = await TopicRepo.instance.getTopicMessageList(
      V2NIMTopicMessageListOption(
        topic: topic,
        beginTime: createTime,
        endTime: createTime,
        limit: 100,
        direction: NIMQueryDirection.desc,
      ),
    );
    if (!result.isSuccess) {
      Alog.e(
        tag: 'TopicChatViewModel',
        moduleName: 'getTopicMessageList',
        content: 'getTopicMessageList error code: ${result.code}',
      );
      return NIMResult.failure(
        message: result.errorDetails,
        code: result.code,
      );
    }

    final candidates = <NIMMessage>[
      ...?result.data?.replyList,
      if (result.data?.anchorMessage != null) result.data!.anchorMessage!,
    ];
    for (final message in candidates) {
      if (TopicMessageHelper.matchesMessageRefer(message, messageRefer)) {
        return NIMResult.success(data: message);
      }
    }
    return NIMResult.failure(message: 'message not found');
  }

  @override
  void loadMessageWithAnchorDate(int date) {
    findAnchorDate = date;
    prepareForAnchorLoading();
    hasMoreForwardMessages = true;
    hasMoreNewerMessages = false;
    _fetchTopicMessages(
        limit: ChatViewModel.messageLimit, anchor: null, init: true);
  }

  @override
  fetchMoreMessage(NIMQueryDirection direction) {
    if (direction != NIMQueryDirection.desc) {
      return;
    }
    final anchor = messageList.isNotEmpty ? messageList.last.nimMessage : null;
    _fetchTopicMessages(limit: ChatViewModel.messageLimit, anchor: anchor);
  }

  Future<void> _fetchTopicMessages({
    required int limit,
    NIMMessage? anchor,
    bool init = false,
  }) async {
    final topic = _currentTopic;
    if (topic == null) {
      if (init) {
        messageList = [];
        isLoading = false;
      }
      return;
    }
    if (isLoading) {
      return;
    }
    isLoading = true;
    final result = await TopicRepo.instance.getTopicMessageList(
      V2NIMTopicMessageListOption(
        topic: topic,
        anchorMessage: anchor,
        limit: limit,
        direction: NIMQueryDirection.desc,
      ),
    );
    if (!result.isSuccess) {
      Alog.e(
        tag: 'TopicChatViewModel',
        moduleName: 'getTopicMessageList 2',
        content: 'getTopicMessageList error code: ${result.code}',
      );
      isLoading = false;
      notifyListeners();
      return;
    }
    final fetchedMessages = <NIMMessage>[
      ...?result.data?.replyList,
    ];
    final resolvedAnchor = result.data?.anchorMessage ?? anchor;
    if (resolvedAnchor != null &&
        !fetchedMessages.any(
          (message) =>
              TopicMessageHelper.matchesMessageRefer(message, resolvedAnchor),
        )) {
      fetchedMessages.add(resolvedAnchor);
    }
    final filled = await ChatMessageRepo.fillUserInfo(fetchedMessages);
    final sorted = List<ChatMessage>.from(filled)
      ..sort((a, b) =>
          (b.nimMessage.createTime ?? 0) - (a.nimMessage.createTime ?? 0));
    hasMoreForwardMessages = result.data?.hasMore == true;
    if (anchor == null) {
      messageList = sorted;
    } else {
      final merged = List<ChatMessage>.from(messageList)..addAll(sorted);
      final unique = <String, ChatMessage>{};
      for (final item in merged) {
        unique[item.nimMessage.messageClientId ?? ''] = item;
      }
      messageList = unique.values.toList()
        ..sort((a, b) =>
            (b.nimMessage.createTime ?? 0) - (a.nimMessage.createTime ?? 0));
    }
    isLoading = false;
    notifyListeners();
  }

  @override
  bool shouldHandleCurrentMessage(NIMMessage message) {
    if (message.conversationId != conversationId) {
      return false;
    }
    if (_shouldHandlePendingTopicMessage(message)) {
      return true;
    }
    if (_currentTopic == null) {
      return false;
    }
    final refer = message.topicRefer;
    return refer?.topicId == _currentTopic?.topicId &&
        refer?.conversationId == conversationId;
  }

  bool _shouldHandlePendingTopicMessage(NIMMessage message) {
    final messageClientId = message.messageClientId;
    return messageClientId != null &&
        _pendingTopicMessageClientIds.contains(messageClientId);
  }

  @override
  bool shouldHandleMessageRefer(NIMMessageRefer? messageRefer) {
    return messageRefer?.conversationId == conversationId;
  }

  @override
  void sendMessage(
    NIMMessage message, {
    NIMMessage? replyMsg,
    NIMMessagePushConfig? pushConfig,
  }) async {
    final messageClientId = message.messageClientId;
    if (messageClientId != null) {
      _pendingTopicMessageClientIds.add(messageClientId);
    }
    final params = await ChatMessageHelper.getSenderParams(
      message,
      conversationId,
      pushConfig: pushConfig,
    );

    if (isPlaceholder) {
      final result = await TopicRepo.instance.sendTopicMessage(
        message: message,
        conversationId: conversationId,
        params: V2NIMSendTopicMessageParams(sendMessageParams: params),
      );
      _handleTopicSendResult(result, message, isFirstMessage: true);
      return;
    }

    if (replyMsg != null) {
      final result = await TopicRepo.instance.replyTopicMessage(
        message: message,
        replyMessage: replyMsg,
        topic: _currentTopic!,
        params: params,
      );
      _handleTopicSendResult(result, message);
      return;
    }

    final result = await TopicRepo.instance.sendTopicMessage(
      message: message,
      conversationId: conversationId,
      topic: _currentTopic,
      params: V2NIMSendTopicMessageParams(sendMessageParams: params),
    );
    _handleTopicSendResult(result, message);
  }

  Future<void> _handleTopicSendResult(
    NIMResult<NIMSendMessageResult> result,
    NIMMessage originalMessage, {
    bool isFirstMessage = false,
  }) async {
    BotSubsessionTopicContext? resolvedContext;
    if (result.isSuccess && result.data?.message != null) {
      final sent = result.data!.message!;
      if (isFirstMessage) {
        final autoTitle = TopicMessageHelper.buildAutoTitleFromMessage(
          originalMessage,
          fallbackMessage: sent,
        );
        topicTitle = autoTitle;
        notifyListeners();

        final topicRefer = sent.topicRefer;
        if (topicRefer != null) {
          final topicResult =
              await TopicRepo.instance.getTopicByRefer(topicRefer);
          if (_isDisposed) {
            return;
          }
          if (topicResult.isSuccess && topicResult.data != null) {
            _currentTopic = topicResult.data;
            _isPlaceholder = false;
            topicTitle = autoTitle;
            notifyListeners();
            final topic = _currentTopic!;
            final updateResult = await TopicRepo.instance.updateTopic(
              V2NIMUpdateTopicParams(
                topic: topic,
                topicName: autoTitle,
                serverExtension: TopicRepo.instance.buildTitleServerExtension(
                  title: autoTitle,
                  userRenamed: false,
                  originalServerExtension: topic.serverExtension,
                ),
              ),
            );
            if (_isDisposed) {
              return;
            }
            if (updateResult.isSuccess && updateResult.data != null) {
              _currentTopic = updateResult.data;
              topicTitle = _resolveTitle();
            }
            resolvedContext = BotSubsessionTopicContext(
              conversationId: conversationId,
              topic: _currentTopic,
              localKey: topicContext.localKey,
            );
          }
        }
      }
      if (shouldHandleCurrentMessage(sent) || isFirstMessage) {
        final filled = await ChatMessageRepo.fillUserInfo([sent]);
        if (_isDisposed) {
          return;
        }
        final current = List<ChatMessage>.from(messageList);
        final index = current.indexWhere(
          (item) =>
              item.nimMessage.messageClientId == sent.messageClientId &&
              sent.messageClientId?.isNotEmpty == true,
        );
        if (index >= 0) {
          current[index] = filled.first;
        } else {
          current.insert(0, filled.first);
        }
        messageList = current
          ..sort((a, b) =>
              (b.nimMessage.createTime ?? 0) - (a.nimMessage.createTime ?? 0));
      }
    }
    await handleSendMessageResult(result);
    if (_isDisposed) {
      return;
    }
    if (resolvedContext != null) {
      onTopicResolved?.call(resolvedContext);
    }
  }

  Future<NIMResult<void>> deleteCurrentTopic() async {
    if (_currentTopic == null) {
      return NIMResult.failure(message: 'topic not found');
    }
    final result = await TopicRepo.instance.removeTopics(
      V2NIMRemoveTopicsParams(topicList: [_currentTopic!]),
    );
    if (result.isSuccess) {
      _topicDeleted = true;
      _currentTopic = null;
      notifyListeners();
    }
    return result;
  }

  Future<NIMResult<V2NIMTopic>> renameCurrentTopic(String title) async {
    final topic = _currentTopic;
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
      _currentTopic = result.data;
      _isPlaceholder = false;
      topicTitle = _resolveTitle();
      notifyListeners();
    }
    return result;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _topicUpdatedSub?.cancel();
    _topicRemovedSub?.cancel();
    super.dispose();
  }
}
