// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:netease_common/netease_common.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/neListView/size_cache_widget.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/extension.dart';
import 'package:nim_chatkit/message/message_helper.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/router/imkit_router.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_desktop_context_menu.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_pop_actions.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../chat_kit_client.dart';
import '../../helper/chat_message_helper.dart';
import '../../model/history_read_position_tracker.dart';
import '../../model/history_read_position_viewport.dart';
import '../../view_model/chat_view_model.dart';
import 'history_read_position_entry.dart';
import 'item/chat_kit_message_item.dart';

class ChatKitMessageList extends StatefulWidget {
  final AutoScrollController scrollController;

  final ChatKitMessageBuilder? messageBuilder;

  final bool Function(ChatMessage message)? onMessageItemClick;

  final bool Function(ChatMessage message)? onMessageItemLongClick;

  final bool Function(String? userID, {bool isSelf})? onTapAvatar;

  final bool Function(String? userID, {bool isSelf})? onAvatarLongPress;

  final PopMenuAction? popMenuAction;

  final NIMTeam? teamInfo;

  final NIMMessage? anchor;

  final ChatUIConfig? chatUIConfig;

  final int? anchorDate;

  /// Whether replies to the current topic root should be hidden.
  final bool hideThreadRootReply;

  ChatKitMessageList({
    Key? key,
    required this.scrollController,
    this.anchor,
    this.anchorDate,
    this.messageBuilder,
    this.popMenuAction,
    this.onTapAvatar,
    this.teamInfo,
    this.chatUIConfig,
    this.onMessageItemClick,
    this.onAvatarLongPress,
    this.onMessageItemLongClick,
    this.hideThreadRootReply = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageListState();
}

class ChatKitMessageListState extends State<ChatKitMessageList>
    with RouteAware {
  NIMMessage? findAnchor;

  int? findAnchorDate;

  //是否在当前页面
  bool isInCurrentPage = true;

  bool _wasAtLatestMessageBeforePush = false;

  bool _showScrollToBottom = false;

  final GlobalKey _firstItemKey = GlobalKey();
  final GlobalKey _messageViewportKey = GlobalKey();
  double _firstItemHeight = 0;
  bool _historyPositionEvaluationScheduled = false;

  final Key _centerKey = GlobalKey();
  String? _pivotMessageId;

  //需要修正的消息索引
  int? _pivotMessageIndex;

  // 是否正在执行"滚动到锚点"的动画。动画过程中 pixels 会短暂触达
  // minScrollExtent（reverse+center 布局下的最新消息端），若此时
  // hasMoreNewerMessages == true，scroll 监听会误判为"用户滑到底部"
  // 而拉取 asc 方向新消息，造成列表重建 + pivot 飘移，最终定位失败。
  // 在 _scrollToIndex 触发时置 true，动画结束后再置 false。
  bool _scrollingToAnchor = false;

  // 正在执行“回到底部”的程序化滚动。用于避免滚动监听在动画过程中再次
  // 修改按钮状态或触发额外逻辑，导致滚动回弹甚至出现列表卡住的现象。
  bool _scrollingToBottom = false;

  Timer? _scrollToBottomGuardTimer;

  DateTime? _lastScrollToBottomFinishedAt;
  bool _forceNextScrollToBottom = false;
  int _scrollToBottomSessionId = 0;

  // 用户点击"查看更下方消息/回到底部"后，忽略路由入参自带的初始 anchor，
  // 避免重新拉取最新消息后 build 又根据 widget.anchorDate/widget.anchor
  // 回写 pivot，导致列表重新围绕历史锚点布局，进而出现"按钮点了但没到底"。
  bool _ignoreRouteAnchor = false;

  void _logI(String content) {
    Alog.i(tag: 'ChatKit', moduleName: 'message list', content: content);
  }

  bool _onMessageCopy(ChatMessage message) {
    var customActions = widget.popMenuAction;
    if (customActions?.onMessageCopy != null &&
        customActions!.onMessageCopy!(message)) {
      return true;
    }
    if (message.nimMessage.messageType == NIMMessageType.text &&
        message.nimMessage.text?.isNotEmpty == true) {
      Clipboard.setData(ClipboardData(text: message.nimMessage.text!));
      ChatUIToast.show(S.of().chatMessageCopySuccess);
      return true;
    }
    var multiLineMap = MessageHelper.parseMultiLineMessage(message.nimMessage);
    if (multiLineMap != null) {
      var title = multiLineMap[ChatMessage.keyMultiLineTitle] as String;
      var content = multiLineMap[ChatMessage.keyMultiLineBody];
      Clipboard.setData(ClipboardData(text: content ?? title));
      ChatUIToast.show(S.of().chatMessageCopySuccess);
      return true;
    }
    return false;
  }

  _scrollToMessageByRefer(NIMMessageRefer messageRefer) async {
    final viewModel = context.read<ChatViewModel>();
    var index = viewModel.messageList.indexWhere(
      (element) =>
          element.nimMessage.messageClientId == messageRefer.messageClientId,
    );
    if (index >= 0) {
      _scrollToIndex(index);
    } else {
      var anchor = (await viewModel.getMessageByRefer(messageRefer)).data;

      if (!mounted) {
        return;
      }
      if (anchor != null) {
        setState(() {
          findAnchor = anchor;
          viewModel.showNewMessage = false;
          _showScrollToBottom = true;
        });
        _findAnchorRemote(anchor);
      }
    }
  }

  _scrollToMessageByTime(int anchorDate) {
    if (context.read<ChatViewModel>().isLoading || _scrollingToAnchor) return;
    var list = context.read<ChatViewModel>().messageList;
    var newAnchorDate = context.read<ChatViewModel>().findAnchorDate;
    if (list.isEmpty) {
      _logI('scrollToAnchor: messageList is empty');
      return;
    }
    if (newAnchorDate != null) {
      anchorDate = newAnchorDate;
    }

    int index = list.firstIndexOf((e) {
      return e.nimMessage.createTime! <= anchorDate;
    });
    if (index >= 0) {
      // Update the pivot during this build so CustomScrollView lays out with
      // the final center before scrollToIndex reads its coordinates.
      findAnchorDate = null;
      _pivotMessageIndex = null;
      _pivotMessageId = index < list.length - 1
          ? list[index].nimMessage.messageClientId
          : list.first.nimMessage.messageClientId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        // Clear the ViewModel anchor before scrolling to avoid another pass.
        context.read<ChatViewModel>().clearFindAnchorDate();
        _scrollToIndex(index);
      });
    } else {
      _logI(
        'scrollToAnchor: not found in ${list.length} items, _findAnchorDateRemote -->> ',
      );
      if (!context.read<ChatViewModel>().isLoading) {
        _findAnchorDateRemote(anchorDate);
      }
    }
  }

  _scrollToAnchor(NIMMessage anchor) {
    final viewModel = context.read<ChatViewModel>();
    // Wait for the anchor-centered fetch to finish. Other ViewModel updates
    // (team info, contact state, etc.) can rebuild this widget while loading;
    // scrolling the temporary anchor-only list would clear findAnchor too
    // early and skip the final positioning pass.
    if (viewModel.isLoading) {
      return;
    }
    var list = viewModel.messageList;
    if (list.isEmpty) {
      _logI('scrollToAnchor: messageList is empty');
      return;
    }
    int index = list.indexWhere(
      (element) => element.nimMessage.isSameMessage(anchor),
    );
    if (index >= 0) {
      // Update the pivot during this build so CustomScrollView lays out with
      // the final center before scrollToIndex reads its coordinates. Changing
      // the center and scrolling in the same post-frame callback can leave the
      // controller at an offset outside the new extents and show a blank list.
      findAnchor = null;
      _pivotMessageIndex = null;
      _pivotMessageId = index < list.length - 1
          ? list[index].nimMessage.messageClientId
          : list.first.nimMessage.messageClientId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _scrollToIndex(index);
      });
    } else {
      _logI(
        'scrollToAnchor: not found in ${list.length} items, _findAnchorRemote -->> ',
      );
      if (!viewModel.isLoading) {
        _findAnchorRemote(anchor);
      }
    }
  }

  //滚动到具体的index
  Future<bool> _scrollToIndex(int index) async {
    if (!mounted) {
      return false;
    }
    final vm = context.read<ChatViewModel>();
    final msgLen = vm.messageList.length;
    // 如果键盘弹出则滚动到begin,否则滚动到middle
    var bottom = MediaQuery.of(context).viewInsets.bottom;
    var position =
        bottom > 0 ? AutoScrollPosition.begin : AutoScrollPosition.middle;
    // 如果是最后一条消息（列表里最老的那条），使用 begin：在 reverse 布局
    // 下对应视口底部，与 pivot=anchor 时 center sliver 的初始位置一致，避免
    // AutoScrollPosition.end 在 reverse+center 场景下语义歧义导致动画落点
    // 不可预期（曾引发"看起来像滑到了消息最底部"的表现）。
    if (index == msgLen - 1) {
      position = AutoScrollPosition.begin;
    }
    // 标记进入锚点动画，保证动画过程中 scroll 监听到 minScrollExtent
    // 不会误判为"用户滑到底部"而触发 asc 拉取（导致定位失败）。
    _scrollingToAnchor = true;
    final scrollDuration = const Duration(milliseconds: 500);
    try {
      await widget.scrollController.scrollToIndex(
        index,
        preferPosition: position,
        duration: scrollDuration,
      );
      // 保留一点安全余量，等待动画稳定后再放行，避免 scroll_to_index 内
      // 部偶发的额外 jump / 位置修正再次触发监听。
      await Future<void>.delayed(
        scrollDuration + const Duration(milliseconds: 200),
      );
      if (!mounted) return false;
      _scrollingToAnchor = false;
      final targetMessage = index >= 0 && index < vm.messageList.length
          ? vm.messageList[index].nimMessage
          : null;
      if (targetMessage != null &&
          vm.historyReadPositionState == HistoryReadPositionState.locating &&
          vm.isHistoryReadPositionTarget(targetMessage)) {
        vm.completeHistoryReadPositionLocation(success: true);
      }
      _refreshScrollToBottomVisibility();
      _scheduleHistoryPositionEvaluation();
      return true;
    } catch (_) {
      _scrollingToAnchor = false;
      if (mounted &&
          vm.historyReadPositionState == HistoryReadPositionState.locating) {
        final targetMessage = index >= 0 && index < vm.messageList.length
            ? vm.messageList[index].nimMessage
            : null;
        if (targetMessage != null &&
            vm.isHistoryReadPositionTarget(targetMessage)) {
          vm.completeHistoryReadPositionLocation(success: false);
        }
      }
      return false;
    }
  }

  bool _computeShouldShowScrollToBottom(ChatViewModel vm) {
    if (_scrollingToBottom) {
      return false;
    }
    if (vm.isMultiSelected) {
      return false;
    }
    if (vm.hasMoreNewerMessages || vm.newMessages.isNotEmpty) {
      return true;
    }
    if (!widget.scrollController.hasClients) {
      return _showScrollToBottom;
    }
    final threshold = _firstItemHeight > 0 ? _firstItemHeight + 10 : 100;
    return widget.scrollController.offset >
        widget.scrollController.position.minScrollExtent + threshold;
  }

  void _refreshScrollToBottomVisibility() {
    if (!mounted) return;
    final vm = context.read<ChatViewModel>();
    final shouldShow = _computeShouldShowScrollToBottom(vm);
    if (_showScrollToBottom != shouldShow) {
      setState(() {
        if (shouldShow) {
          vm.showNewMessage = false;
        }
        _showScrollToBottom = shouldShow;
      });
    }
  }

  void _scheduleHistoryPositionEvaluation() {
    if (_historyPositionEvaluationScheduled || !mounted) return;
    _historyPositionEvaluationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _historyPositionEvaluationScheduled = false;
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent == false) return;
      final vm = context.read<ChatViewModel>();
      final state = vm.historyReadPositionState;
      if (state != HistoryReadPositionState.evaluating &&
          state != HistoryReadPositionState.ready) {
        return;
      }
      if (vm.isLoading ||
          findAnchor != null ||
          findAnchorDate != null ||
          vm.findAnchorDate != null ||
          _scrollingToAnchor) {
        return;
      }
      final viewport =
          _messageViewportKey.currentContext?.findRenderObject() as RenderBox?;
      if (viewport == null || !viewport.hasSize) return;
      final viewportRect = viewport.localToGlobal(Offset.zero) & viewport.size;
      final visibleMessageRects = <int, Rect>{};
      for (final entry in widget.scrollController.tagMap.entries) {
        final index = entry.key;
        if (index < 0 || index >= vm.messageList.length) continue;
        final box = entry.value.context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) continue;
        final rect = box.localToGlobal(Offset.zero) & box.size;
        visibleMessageRects[index] = rect;
      }
      final topIndex = findTopVisibleHistoryMessageIndex(
        viewportRect,
        visibleMessageRects,
      );
      if (topIndex != null) {
        final createTime = vm.messageList[topIndex].nimMessage.createTime;
        if (createTime != null && createTime > 0) {
          vm.evaluateHistoryReadPositionTop(
            createTime,
            hasReachedHistoryStart: isHistoryStartVisible(
              viewportRect,
              visibleMessageRects[vm.messageList.length - 1],
              hasMoreOlderMessages: vm.hasMoreForwardMessages,
            ),
          );
        }
      }
    });
  }

  Future<void> _locateHistoryReadPosition(ChatViewModel viewModel) async {
    final loadedTarget = viewModel.beginLoadedHistoryReadPositionLocation();
    if (loadedTarget != null) {
      await _scrollToHistoryReadPositionTarget(viewModel, loadedTarget);
      return;
    }

    final result = await viewModel.beginHistoryReadPositionLocation();
    final target = result?.data;
    if (!mounted || target == null) return;

    final loaded = await viewModel.loadHistoryReadPositionAnchor(target);
    if (!mounted) return;
    if (!loaded) {
      viewModel.completeHistoryReadPositionLocation(success: false);
      return;
    }

    await _scrollToHistoryReadPositionTarget(viewModel, target);
  }

  Future<void> _scrollToHistoryReadPositionTarget(
    ChatViewModel viewModel,
    NIMMessage target,
  ) async {
    final index = viewModel.messageList.indexWhere(
      (message) => message.nimMessage.isSameMessage(target),
    );
    if (index < 0) {
      viewModel.completeHistoryReadPositionLocation(success: false);
      return;
    }
    setState(() {
      findAnchor = null;
      findAnchorDate = null;
      _pivotMessageIndex = null;
      _pivotMessageId = viewModel.messageList[index].nimMessage.messageClientId;
    });
    viewModel.finishHistoryReadPositionLoading();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final success = await _scrollToIndex(index);
    if (!success && mounted) {
      viewModel.completeHistoryReadPositionLocation(success: false);
    } else if (success && mounted) {
      // _scrollToIndex also completes the state when it can match a stable
      // message ID. Complete here as the authoritative fallback for legacy
      // messages that do not carry a usable server/client ID.
      viewModel.completeHistoryReadPositionLocation(success: true);
    }
  }

  void _cancelScrollToBottomByUserGesture() {
    if (!_scrollingToBottom) {
      return;
    }
    _finishScrollToBottom();
  }

  void _finishScrollToBottom() {
    if (!_scrollingToBottom && _scrollToBottomGuardTimer == null) {
      return;
    }
    _scrollToBottomSessionId++;
    _scrollToBottomGuardTimer?.cancel();
    _scrollToBottomGuardTimer = null;
    _scrollingToBottom = false;
    _lastScrollToBottomFinishedAt = DateTime.now();
    if (!mounted) {
      return;
    }
    _refreshScrollToBottomVisibility();
  }

  void _settleScrollToBottom({required int sessionId, int attempt = 0}) {
    if (sessionId != _scrollToBottomSessionId || !_scrollingToBottom) {
      return;
    }
    if (!mounted || !widget.scrollController.hasClients) {
      _finishScrollToBottom();
      return;
    }
    final position = widget.scrollController.position;
    final target = position.minScrollExtent;
    final current = position.pixels;
    final delta = (current - target).abs();
    if (delta < 0.5) {
      if (mounted) {
        setState(() {
          _showScrollToBottom = false;
        });
      }
      _finishScrollToBottom();
      return;
    }

    if (attempt >= 3) {
      widget.scrollController.jumpTo(target);
      if (mounted) {
        setState(() {
          _showScrollToBottom = false;
        });
      }
      _finishScrollToBottom();
      return;
    }

    widget.scrollController.jumpTo(target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _settleScrollToBottom(
          sessionId: sessionId,
          attempt: attempt + 1,
        );
      });
    });
  }

  bool _onMessageCollect(ChatMessage message) {
    var customActions = widget.popMenuAction;
    if (customActions?.onMessageCollect != null &&
        customActions!.onMessageCollect!(message)) {
      return true;
    }
    context.read<ChatViewModel>().collectMessage(message);
    return true;
  }

  bool _onMessageReply(ChatMessage message) {
    var customActions = widget.popMenuAction;
    if (customActions?.onMessageReply != null &&
        customActions!.onMessageReply!(message)) {
      return true;
    }
    context.read<ChatViewModel>().replyMessage = message;
    return true;
  }

  bool _onMessageForward(ChatMessage message) {
    var customActions = widget.popMenuAction;
    if (customActions?.onMessageForward != null &&
        customActions!.onMessageForward!(message)) {
      return true;
    }
    // 转发
    var sessionName = context.read<ChatViewModel>().chatTitle;
    ChatMessageHelper.showForwardSelector(context, (
      conversationId, {
      String? postScript,
      bool? isLastUser,
    }) {
      context.read<ChatViewModel>().forwardMessage(
            message.nimMessage,
            conversationId,
            postScript: postScript,
          );
    }, sessionName: sessionName);

    return true;
  }

  bool _onMessageTranslate(ChatMessage message) {
    var customActions = widget.popMenuAction;
    if (customActions?.onMessageTranslate != null &&
        customActions!.onMessageTranslate!(message)) {
      return true;
    }
    context.read<ChatViewModel>().translateMessage(message);
    return true;
  }

  bool _onMessageVoiceToText(ChatMessage message) {
    var customActions = widget.popMenuAction;
    if (customActions?.onMessageVoiceToText != null &&
        customActions!.onMessageVoiceToText!(message)) {
      return true;
    }
    context.read<ChatViewModel>().voiceToTextMessage(message);
    return true;
  }

  bool _onMessagePin(ChatMessage message, bool isCancel) {
    var customActions = widget.popMenuAction;
    if (customActions?.onMessagePin != null &&
        customActions!.onMessagePin!(message, isCancel)) {
      return true;
    }
    if (isCancel) {
      context.read<ChatViewModel>().removeMessagePin(message.nimMessage);
    } else {
      context.read<ChatViewModel>().addMessagePin(message.nimMessage).then((
        result,
      ) {
        if (result.code == ChatMessageRepo.errorPINLimited) {
          ChatUIToast.show(S.of(context).chatMessagePinLimitTips,
              context: context);
        }
      });
    }
    return true;
  }

  bool _onMessageMultiSelect(ChatMessage message) {
    context.read<ChatViewModel>().isMultiSelected = true;
    context.read<ChatViewModel>().addSelectedMessage(message.nimMessage);
    hideKeyboard();
    return true;
  }

  bool _onMessageDelete(ChatMessage message) {
    var customActions = widget.popMenuAction;
    if (customActions?.onMessageDelete != null &&
        customActions!.onMessageDelete!(message)) {
      return true;
    }
    showCommonDialog(
      context: context,
      title: S.of().chatMessageActionDelete,
      content: S.of().chatMessageDeleteConfirm,
    ).then(
      (value) => {
        if (value ?? false)
          context.read<ChatViewModel>().deleteMessage(message),
      },
    );
    return true;
  }

  void _resendMessage(ChatMessage message) {
    context.read<ChatViewModel>().sendMessage(
          message.nimMessage,
          replyMsg: message.replyMsg,
        );
  }

  bool _onVoicePlayModelChange(bool isVoiceFromSpeaker) {
    var customActions = widget.popMenuAction;
    if (customActions?.onVoiceSpeakerSwitch != null &&
        customActions!.onVoiceSpeakerSwitch!(isVoiceFromSpeaker)) {
      return true;
    }
    if (isVoiceFromSpeaker) {
      ChatUIToast.show(S.of().chatVoiceFromSpeakerTips);
    } else {
      ChatUIToast.show(S.of().chatVoiceFromEarSpeakerTips);
    }
    context.read<ChatViewModel>().updateVoicePlayModel(isVoiceFromSpeaker);
    return true;
  }

  bool _onMessageRevoke(ChatMessage message) {
    var customActions = widget.popMenuAction;
    if (customActions?.onMessageRevoke != null &&
        customActions!.onMessageRevoke!(message)) {
      return true;
    }
    showCommonDialog(
      context: context,
      title: S.of().chatMessageActionRevoke,
      content: S.of().chatMessageRevokeConfirm,
    ).then(
      (value) => {
        if (value ?? false)
          context.read<ChatViewModel>().revokeMessage(message).then((value) {
            if (!value.isSuccess) {
              if (value.code == ChatMessageRepo.errorRevokeTimeout) {
                ChatUIToast.show(S.of().chatMessageRevokeOverTime);
              } else {
                ChatUIToast.show(S.of().chatMessageRevokeFailed);
              }
            }
          }),
      },
    );
    return true;
  }

  _findAnchorDateRemote(int anchorDate) {
    context.read<ChatViewModel>().loadMessageWithAnchorDate(anchorDate);
  }

  _findAnchorRemote(NIMMessage anchor) {
    context.read<ChatViewModel>().loadMessageWithAnchor(anchor);
  }

  bool _loadMore() {
    // load old
    if (context.read<ChatViewModel>().messageList.isNotEmpty &&
        context.read<ChatViewModel>().hasMoreForwardMessages &&
        !context.read<ChatViewModel>().isLoading) {
      Alog.d(
        tag: 'ChatKit',
        moduleName: 'ChatKitMessageList',
        content: '_loadMore -->>',
      );
      context.read<ChatViewModel>().fetchMoreMessage(NIMQueryDirection.desc);
      return true;
    }
    return false;
  }

  PopMenuAction getDefaultPopMenuActions(PopMenuAction? customActions) {
    PopMenuAction actions = PopMenuAction();
    actions.onMessageCopy = _onMessageCopy;
    actions.onMessageReply = _onMessageReply;
    actions.onMessageCollect = _onMessageCollect;
    actions.onMessageForward = _onMessageForward;
    actions.onMessageTranslate = _onMessageTranslate;
    actions.onMessageVoiceToText = _onMessageVoiceToText;
    actions.onMessagePin = _onMessagePin;
    actions.onMessageMultiSelect = _onMessageMultiSelect;
    actions.onMessageDelete = _onMessageDelete;
    actions.onMessageRevoke = _onMessageRevoke;
    actions.onVoiceSpeakerSwitch = _onVoicePlayModelChange;
    return actions;
  }

  @override
  void didPushNext() {
    final viewModel = context.read<ChatViewModel>();
    _wasAtLatestMessageBeforePush = !viewModel.hasMoreNewerMessages &&
        viewModel.newMessages.isEmpty &&
        findAnchor == null &&
        findAnchorDate == null &&
        viewModel.findAnchorDate == null &&
        (!widget.scrollController.hasClients ||
            widget.scrollController.offset <=
                widget.scrollController.position.minScrollExtent + 1);
    isInCurrentPage = false;
    viewModel.setChatRouteVisible(false);
    super.didPushNext();
  }

  @override
  void didPopNext() {
    if (mounted) {
      final viewModel = context.read<ChatViewModel>();
      viewModel.setChatRouteVisible(true);
      final shouldMergePendingMessages = _wasAtLatestMessageBeforePush &&
          !viewModel.hasMoreNewerMessages &&
          findAnchor == null &&
          findAnchorDate == null &&
          viewModel.findAnchorDate == null &&
          viewModel.newMessages.isNotEmpty;
      if (shouldMergePendingMessages) {
        viewModel.srollToNewMessage();
      }
      _wasAtLatestMessageBeforePush = false;
      setState(() {
        isInCurrentPage = true;
        if (shouldMergePendingMessages) {
          _showScrollToBottom = false;
        } else if (viewModel.newMessages.isNotEmpty) {
          _showScrollToBottom = true;
        }
      });
    }
    super.didPopNext();
  }

  @override
  void initState() {
    super.initState();
    findAnchor = widget.anchor;
    findAnchorDate = widget.anchorDate;
    Future.delayed(Duration.zero, () {
      if (!mounted) {
        return;
      }
      IMKitRouter.instance.routeObserver.subscribe(
        this,
        ModalRoute.of(context)!,
      );
    });
    _initScrollController();
  }

  @override
  void dispose() {
    _scrollToBottomGuardTimer?.cancel();
    IMKitRouter.instance.routeObserver.unsubscribe(this);
    super.dispose();
  }

  //收到新消息后滑动到底部，对齐原生端交互
  _scrollToBottom() {
    final forceScroll = _forceNextScrollToBottom;
    _forceNextScrollToBottom = false;
    final now = DateTime.now();
    if (!forceScroll && _lastScrollToBottomFinishedAt != null) {
      final gap = now.difference(_lastScrollToBottomFinishedAt!);
      if (gap < const Duration(milliseconds: 1200)) {
        return;
      }
    }
    if (_scrollingToBottom) {
      return;
    }
    _logI('_scrollToBottom');
    if (!widget.scrollController.hasClients) {
      return;
    }
    _scrollToBottomSessionId++;
    final sessionId = _scrollToBottomSessionId;
    _scrollingToBottom = true;
    _scrollToBottomGuardTimer?.cancel();
    _scrollToBottomGuardTimer = Timer(const Duration(seconds: 2), () {
      _finishScrollToBottom();
    });
    if (_showScrollToBottom) {
      setState(() {
        _showScrollToBottom = false;
      });
    }
    // 使用双 postFrame：第一帧让 _insertMessages 触发的 rebuild 完成，
    // 第二帧让新内容布局稳定后再读取 minScrollExtent，避免在拉取最新
    // 消息后基于 stale 布局滚动导致 "差一点没到底" / "完全没动" 的问题。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.scrollController.hasClients) {
        _finishScrollToBottom();
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.scrollController.hasClients) {
          _finishScrollToBottom();
          return;
        }
        _settleScrollToBottom(sessionId: sessionId);
      });
    });
  }

  _initScrollController() {
    widget.scrollController.addListener(() {
      _scheduleHistoryPositionEvaluation();
      // 滚动时关闭桌面端右键菜单
      ChatKitDesktopContextMenu.currentInstance?.close();

      if (_scrollingToBottom) {
        if (widget.scrollController.hasClients) {
          final position = widget.scrollController.position;
          if (position.userScrollDirection != ScrollDirection.idle) {
            _cancelScrollToBottomByUserGesture();
          }
          if (_scrollingToBottom == false) {
            _refreshScrollToBottomVisibility();
          } else {
            return;
          }
        }
      }

      if (widget.scrollController.position.pixels >=
          widget.scrollController.position.maxScrollExtent) {
        // 锚点动画期间不触发 load more(desc)，避免破坏定位结果
        if (_scrollingToAnchor) {
          return;
        }
        if (_loadMore()) {
          return;
        }
      } else if (widget.scrollController.position.pixels <=
          widget.scrollController.position.minScrollExtent) {
        // 锚点定位未完成时，不触发向下拉取更新消息，避免破坏定位结果。
        // 触发场景：_scrollToIndex 的 animateTo 动画进行中，pixels 会短暂
        // 触达 minScrollExtent，若此时 hasMoreNewerMessages==true 会被误判
        // 为"到底"并拉取 asc 方向消息，导致新消息插入到列表头部，pivot
        // 位置偏移，最终定位失败。
        //
        // 除了 _scrollingToAnchor 动画标志之外，还额外检查 State 与
        // ViewModel 上的 findAnchor* 字段作为双保险（例如调用方未走
        // _scrollToIndex 的边缘场景）。
        final vm = context.read<ChatViewModel>();
        if (_scrollingToAnchor ||
            findAnchor != null ||
            findAnchorDate != null ||
            vm.findAnchorDate != null) {
          return;
        }
        if (vm.messageList.isNotEmpty &&
            vm.hasMoreNewerMessages &&
            !vm.isLoading) {
          vm.fetchMoreMessage(NIMQueryDirection.asc);
          return;
        }
      }

      if (_firstItemKey.currentContext != null) {
        RenderBox? box =
            _firstItemKey.currentContext!.findRenderObject() as RenderBox?;
        if (box != null) {
          _firstItemHeight = box.size.height;
        }
      }

      double threshold = _firstItemHeight > 0 ? _firstItemHeight + 10 : 100;

      if (widget.scrollController.offset >
              widget.scrollController.position.minScrollExtent + threshold &&
          !_showScrollToBottom) {
        setState(() {
          context.read<ChatViewModel>().showNewMessage = false;
          _showScrollToBottom = true;
        });
      } else if (widget.scrollController.offset <=
              widget.scrollController.position.minScrollExtent + threshold &&
          _showScrollToBottom) {
        final vm = context.read<ChatViewModel>();
        if (!vm.hasMoreNewerMessages) {
          if (vm.newMessages.isNotEmpty) {
            final isAtLatestMessage = widget.scrollController.offset <=
                widget.scrollController.position.minScrollExtent + 1;
            if (!isAtLatestMessage) {
              return;
            }
            // 手动滑到最新消息端：把缓存的 newMessages 插入列表并清空，
            // 否则新消息不显示，且提示（依赖 newMessages.isNotEmpty）不消失。
            vm.srollToNewMessage(scrollToEnd: false);
          } else {
            setState(() {
              vm.showNewMessage = true;
              _showScrollToBottom = false;
            });
          }
        }
      }
    });
    context.read<ChatViewModel>().scrollToEnd = _scrollToBottom;
  }

  Widget _buildMessageItem(ChatViewModel chatViewModel, int index) {
    if (index < 0 || index >= chatViewModel.messageList.length) {
      return const SizedBox.shrink();
    }
    ChatMessage message = chatViewModel.messageList[index];
    ChatMessage? lastMessage = index < chatViewModel.messageList.length - 1
        ? chatViewModel.messageList[index + 1]
        : null;
    Widget item = AutoScrollTag(
      controller: widget.scrollController,
      index: index,
      key: ValueKey(message.nimMessage.messageClientId),
      highlightColor: Colors.black.withAlpha(25),
      child: ChatKitMessageItem(
        key: ValueKey(message.nimMessage.messageClientId),
        chatMessage: message,
        messageBuilder: widget.messageBuilder,
        lastMessage: lastMessage,
        popMenuAction: getDefaultPopMenuActions(widget.popMenuAction),
        scrollToIndex: _scrollToMessageByRefer,
        onTapFailedMessage: _resendMessage,
        onTapAvatar: widget.onTapAvatar,
        onAvatarLongPress: widget.onAvatarLongPress,
        chatUIConfig: widget.chatUIConfig,
        hideThreadRootReply: widget.hideThreadRootReply,
        teamInfo: widget.teamInfo,
        onMessageItemClick: widget.onMessageItemClick,
        onMessageItemLongClick: widget.onMessageItemLongClick,
      ),
    );
    if (index == 0) {
      return KeyedSubtree(key: _firstItemKey, child: item);
    }
    return item;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (cnt, chatViewModel, child) {
        // 动态定位：当 ViewModel.findAnchorDate 更新时（如从历史搜索定位），
        // 同步到 state 的 findAnchorDate，确保 build 重绘时触发滚动
        if (chatViewModel.findAnchorDate != null && findAnchorDate == null) {
          findAnchorDate = chatViewModel.findAnchorDate;
        }
        if (findAnchor != null) {
          _logI('build, try scroll to anchor:${findAnchor?.text}');
          _scrollToAnchor(findAnchor!);
        } else if (findAnchorDate != null) {
          _logI('build, try scroll to anchorDate:${findAnchorDate}');
          _scrollToMessageByTime(findAnchorDate!);
        }
        final messageList = chatViewModel.messageList;
        if (messageList.isEmpty) {
          _pivotMessageId = null;
        } else if (_pivotMessageId == null) {
          if (!_ignoreRouteAnchor && widget.anchor != null) {
            _pivotMessageId = widget.anchor!.messageClientId;
          } else if (!_ignoreRouteAnchor && widget.anchorDate != null) {
            _pivotMessageId = messageList
                .firstWhereOrNull(
                  (m) => m.nimMessage.createTime! <= widget.anchorDate!,
                )
                ?.nimMessage
                .messageClientId;
          }
        }

        int pivotIndex = 0;
        if (messageList.isNotEmpty) {
          if (_pivotMessageId != null) {
            pivotIndex = messageList.indexWhere(
              (m) => m.nimMessage.messageClientId == _pivotMessageId,
            );
            if (pivotIndex == -1) {
              pivotIndex = 0;
              _pivotMessageId = messageList.first.nimMessage.messageClientId;
            }
          }
        }

        ///先初步判断是否需要shrinkWrap
        bool enableShrinkWrap = pivotIndex == 0 && messageList.length < 15;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !widget.scrollController.hasClients) {
            return;
          }
          if (_scrollingToBottom) {
            return;
          }
          // maxScrollExtent < 1.0 表示上方内容未填满视口
          bool topNotFilled =
              widget.scrollController.position.maxScrollExtent < 1.0;
          // minScrollExtent < -1.0 表示下方有内容超出视口（即下方有隐藏内容）
          bool bottomHasContent =
              widget.scrollController.position.minScrollExtent < -1.0;
          // 只有当上方有空白，且下方有足够内容来填充时，才调整锚点
          bool shouldShrinkWrap = topNotFilled && bottomHasContent;

          //具体判断
          if (shouldShrinkWrap) {
            int indexPivotMessage = messageList.indexWhere(
              (m) => m.nimMessage.messageClientId == _pivotMessageId,
            );
            if (_pivotMessageIndex == null && indexPivotMessage != -1) {
              _pivotMessageIndex = indexPivotMessage;
            }
            if (indexPivotMessage > 0) {
              setState(() {
                _pivotMessageId = messageList[indexPivotMessage - 1]
                    .nimMessage
                    .messageClientId;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                //添加大于1的逻辑，避免重复滚动
                if (_pivotMessageIndex != null &&
                    (_pivotMessageIndex! - indexPivotMessage) > 1) {
                  // 锚点定位动画进行中，不要触发 shrinkWrap 的二次 _scrollToIndex，
                  // 否则会覆盖锚点滚动目标，导致最终停在 pivot 附近而不是锚点。
                  if (_scrollingToAnchor) {
                    return;
                  }
                  _scrollToIndex(_pivotMessageIndex!);
                }
              });
            }
          }
          _refreshScrollToBottomVisibility();
          _scheduleHistoryPositionEvaluation();
        });

        ///message list
        return Container(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                key: _messageViewportKey,
                alignment: Alignment.topCenter,
                child: SizeCacheWidget(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      final hasUserDrag =
                          (notification is ScrollStartNotification &&
                                  notification.dragDetails != null) ||
                              (notification is ScrollUpdateNotification &&
                                  notification.dragDetails != null) ||
                              (notification is OverscrollNotification &&
                                  notification.dragDetails != null);
                      if (_scrollingToBottom && hasUserDrag) {
                        _cancelScrollToBottomByUserGesture();
                      }
                      return false;
                    },
                    child: CustomScrollView(
                      controller: widget.scrollController,
                      center: (!enableShrinkWrap && pivotIndex > 0)
                          ? _centerKey
                          : null,
                      reverse: true,
                      shrinkWrap: enableShrinkWrap,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.only(bottom: 10),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              int globalIndex = pivotIndex - 1 - index;
                              if (globalIndex < 0) return null;
                              return _buildMessageItem(
                                chatViewModel,
                                globalIndex,
                              );
                            }, childCount: pivotIndex > 0 ? pivotIndex : 0),
                          ),
                        ),
                        SliverPadding(
                          key: _centerKey,
                          padding: const EdgeInsets.only(top: 10),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                int globalIndex = pivotIndex + index;
                                if (globalIndex >=
                                    chatViewModel.messageList.length) {
                                  return null;
                                }
                                return _buildMessageItem(
                                  chatViewModel,
                                  globalIndex,
                                );
                              },
                              childCount: messageList.length - pivotIndex > 0
                                  ? messageList.length - pivotIndex
                                  : 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (shouldShowHistoryReadPositionEntry(
                state: chatViewModel.historyReadPositionState,
                count: chatViewModel.historyReadPositionCount ?? 0,
                isMultiSelected: chatViewModel.isMultiSelected,
              ))
                Positioned(
                  top: ChatKitUtils.isDesktopOrWeb ? 16 : 20,
                  right: ChatKitUtils.isDesktopOrWeb ? 16 : 20,
                  child: HistoryReadPositionEntry(
                    label: S.of(context).chatNewMessage(
                          chatViewModel.historyReadPositionDisplayCount,
                        ),
                    locating: chatViewModel.historyReadPositionState ==
                        HistoryReadPositionState.locating,
                    loading: chatViewModel.historyReadPositionLoading,
                    isDesktopOrWeb: ChatKitUtils.isDesktopOrWeb,
                    onTap: () => _locateHistoryReadPosition(chatViewModel),
                  ),
                ),
              if (_showScrollToBottom &&
                  context.read<ChatViewModel>().isMultiSelected != true)
                Positioned(
                  bottom: 20,
                  right: chatViewModel.newMessages.isEmpty ? 20 : 0,
                  child: GestureDetector(
                    key: const Key('chat-new-message-entry'),
                    onTap: () {
                      // 1. 清理来自历史搜索定位的锚点 / pivot 缓存。这里不调用
                      //    setState，避免触发一次 "中间空列表 + shrinkWrap 切换"
                      //    的 rebuild；State 字段直接赋值即可，下次 fetch 完成
                      //    notifyListeners 触发 rebuild 时会读取到最新值。
                      findAnchor = null;
                      findAnchorDate = null;
                      _ignoreRouteAnchor = true;
                      _forceNextScrollToBottom = true;
                      _pivotMessageId = null;
                      _pivotMessageIndex = null;
                      chatViewModel.clearFindAnchorDate();
                      // 2. 触发 ChatViewModel 滑动到底部 / 拉取最新消息：
                      //    - hasMoreNewerMessages == true：清空列表并重新拉取最新
                      //      100 条，拉取完成后回调 _scrollToBottom 进行滚动；
                      //    - hasMoreNewerMessages == false：插入缓存的 newMessages
                      //      并直接调用 _scrollToBottom。
                      chatViewModel.srollToNewMessage();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: chatViewModel.newMessages.isEmpty
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                        borderRadius: chatViewModel.newMessages.isEmpty
                            ? null
                            : BorderRadius.only(
                                topLeft: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'images/ic_new_message_icon.svg',
                            width: 16,
                            height: 16,
                            package: kPackage,
                          ),
                          if (chatViewModel.newMessages
                              .any((m) => m.nimMessage.isSelf != true))
                            Text(
                              S.of(context).chatNewMessage(
                                    '${chatViewModel.newMessages.where((m) => m.nimMessage.isSelf != true).length}',
                                  ),
                              style: TextStyle(
                                fontSize: 14,
                                color: '#1861DF'.toColor(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
    // List messageList = widget.messageList;
  }
}
