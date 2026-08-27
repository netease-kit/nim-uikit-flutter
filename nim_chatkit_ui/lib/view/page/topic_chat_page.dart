// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/message/merge_message.dart';
import 'package:nim_chatkit/model/bot_subsession_models.dart';
import 'package:nim_chatkit/repo/conversation_repo.dart';
import 'package:nim_chatkit/router/imkit_router.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit/services/message/nim_chat_cache.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/helper/bot_subsession_action_helper.dart';
import 'package:nim_chatkit_ui/helper/chat_message_helper.dart';
import 'package:nim_chatkit_ui/helper/merge_message_helper.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_item.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/media/audio_player.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/chat_kit_message_list.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_pop_actions.dart';
import 'package:nim_chatkit_ui/view/input/bottom_input_field.dart';
import 'package:nim_chatkit_ui/view/page/chat_page.dart' show BottomOption;
import 'package:nim_chatkit_ui/view_model/chat_view_model.dart';
import 'package:nim_chatkit_ui/view_model/topic_chat_view_model.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class TopicChatPage extends StatefulWidget {
  final String conversationId;
  final BotSubsessionTopicContext topicContext;
  final ChatUIConfig? chatUIConfig;
  final ChatKitMessageBuilder? messageBuilder;
  final VoidCallback? onBackToList;
  final ValueChanged<BotSubsessionTopicContext>? onTopicResolved;

  const TopicChatPage({
    Key? key,
    required this.conversationId,
    required this.topicContext,
    this.chatUIConfig,
    this.messageBuilder,
    this.onBackToList,
    this.onTopicResolved,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TopicChatPageState();
}

class _TopicChatPageState extends BaseState<TopicChatPage> with RouteAware {
  late AutoScrollController autoController;
  final GlobalKey<dynamic> _inputField = GlobalKey();
  ChatUIConfig? chatUIConfig;
  bool _handledTopicDeleted = false;

  static const int mergedMessageLimit = 100;
  static const int forwardMessageLimit = 10;

  Future<void> _setChattingAccount() async {
    NIMChatCache.instance.setCurrentChatSession(
      ChatSession(
        ChatKitUtils.getConversationTargetId(widget.conversationId),
        NIMConversationType.p2p,
        widget.conversationId,
      ),
    );
    // 进入子会话聊天页即视为已读：更新会话已读时间戳，
    // 否则返回子会话列表时未读红点（latestMessageTime > readTime）不消失。
    await _markConversationRead();
  }

  Future<void> _markConversationRead() async {
    await ConversationRepo.clearSessionUnreadCount(widget.conversationId);
    await ConversationRepo.markConversationRead(widget.conversationId);
  }

  void _clearChattingAccount() {
    NIMChatCache.instance.clearCurrentChatSession(
      ChatKitUtils.getConversationTargetId(widget.conversationId),
      NIMConversationType.p2p,
      widget.conversationId,
    );
  }

  @override
  void initState() {
    super.initState();
    chatUIConfig = widget.chatUIConfig ?? ChatKitClient.instance.chatUIConfig;
    autoController = AutoScrollController(
      viewportBoundaryGetter: () =>
          Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
      axis: Axis.vertical,
    );
    ChatKitClient.instance.registerRevokedMessage();

    unawaited(_setChattingAccount());

    Future.delayed(Duration.zero, () {
      IMKitRouter.instance.routeObserver
          .subscribe(this, ModalRoute.of(context)!);
    });
  }

  @override
  void dispose() {
    ChatAudioPlayer.instance.stopAll();
    unawaited(_markConversationRead());
    _clearChattingAccount();
    IMKitRouter.instance.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (NIMChatCache.instance.currentChatSession?.conversationId !=
        widget.conversationId) {
      unawaited(_setChattingAccount());
    }
    super.didPopNext();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TopicChatViewModel>(
      create: (_) => TopicChatViewModel(
        widget.conversationId,
        topicContext: widget.topicContext,
        onTopicResolved: widget.onTopicResolved,
        chatUIConfig: chatUIConfig,
      ),
      builder: (context, _) {
        final model = context.watch<TopicChatViewModel>();
        final title = model.topicTitle.isNotEmpty
            ? model.topicTitle
            : S.of(context).botSubsessionNewSession;
        final inputHint = model.rootSessionTitle;
        final haveSelectedMessage = model.selectedMessages.isNotEmpty;

        if (model.topicDeleted && !_handledTopicDeleted) {
          _handledTopicDeleted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            unawaited(_leaveTopicPage(context));
          });
        }
        return ListenableProvider<ChatViewModel>.value(
          value: model,
          child: PopScope(
            canPop: model.isMultiSelected != true,
            onPopInvokedWithResult: (bool didPop, result) async {
              if (context.read<TopicChatViewModel>().isMultiSelected) {
                context.read<TopicChatViewModel>().isMultiSelected = false;
              }
              if (didPop) {
                unawaited(_markConversationRead());
              }
            },
            child: ChatKitUtils.isDesktopOrWeb
                ? Scaffold(
                    backgroundColor: Colors.white,
                    body: Column(
                      children: [
                        _buildDesktopHeader(context, title),
                        Expanded(
                          child: _buildChatBody(
                            context,
                            inputHint,
                            haveSelectedMessage,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildMobilePage(
                    context,
                    title,
                    inputHint,
                    haveSelectedMessage,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildMobilePage(
    BuildContext context,
    String title,
    String inputHint,
    bool haveSelectedMessage,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: TransparentScaffold.defaultLeadingIcon ??
              const Icon(
                Icons.arrow_back_ios_rounded,
                size: 26,
              ),
          onPressed: () {
            unawaited(_leaveTopicPage(context));
          },
        ),
        title: _buildMobileTitle(context, title),
        actions: [_buildMobileAction(context)],
      ),
      body: _buildChatBody(
        context,
        inputHint,
        haveSelectedMessage,
      ),
    );
  }

  Future<void> _leaveTopicPage(BuildContext context) async {
    await _markConversationRead();
    if (!mounted) {
      return;
    }
    if (widget.onBackToList != null) {
      widget.onBackToList!.call();
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Widget _buildDesktopHeader(BuildContext context, String title) {
    final model = context.watch<TopicChatViewModel>();
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: '#E8E8E8'.toColor(), width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          if (model.isMultiSelected)
            TextButton(
              onPressed: () {
                context.read<TopicChatViewModel>().isMultiSelected = false;
              },
              child: Text(
                S.of(context).messageCancel,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  color: '#333333'.toColor(),
                ),
              ),
            )
          else if (!model.isPlaceholder)
            Builder(
              builder: (buttonContext) {
                return IconButton(
                  onPressed: () => _showDesktopTopicActions(buttonContext),
                  icon: const Icon(
                    Icons.more_vert,
                    size: 22,
                    color: Color(0xFF666666),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMobileTitle(BuildContext context, String title) {
    final model = context.watch<TopicChatViewModel>();
    final rootTitle =
        model.chatTitle.isNotEmpty ? model.chatTitle : model.rootSessionTitle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF262626),
          ),
        ),
        if (rootTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              rootTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: '#8C8C8C'.toColor(),
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showMobileTopicActions(BuildContext context) async {
    final viewModel = context.read<TopicChatViewModel>();
    await BotSubsessionActionHelper.showTopicActions(
      context: context,
      currentTitle: viewModel.topicTitle,
      onRename: viewModel.renameCurrentTopic,
      onDelete: viewModel.deleteCurrentTopic,
      checkNetwork: checkNetwork,
    );
  }

  Future<void> _showDesktopTopicActions(BuildContext context) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    final globalPosition = renderBox == null
        ? Offset.zero
        : renderBox.localToGlobal(
            Offset(renderBox.size.width, renderBox.size.height),
          );
    final viewModel = context.read<TopicChatViewModel>();
    await BotSubsessionActionHelper.showDesktopTopicActions(
      context: context,
      globalPosition: globalPosition,
      currentTitle: viewModel.topicTitle,
      onRename: viewModel.renameCurrentTopic,
      onDelete: viewModel.deleteCurrentTopic,
      checkNetwork: checkNetwork,
    );
  }

  Widget _buildMobileAction(BuildContext context) {
    return context.watch<TopicChatViewModel>().isMultiSelected
        ? TextButton(
            onPressed: () {
              context.read<TopicChatViewModel>().isMultiSelected = false;
            },
            child: Text(
              S.of(context).messageCancel,
              maxLines: 1,
              style: TextStyle(
                fontSize: 16,
                color: '#333333'.toColor(),
              ),
            ),
          )
        : IconButton(
            onPressed: () => _showMobileTopicActions(context),
            icon: SvgPicture.asset(
              'images/ic_setting.svg',
              width: 26,
              height: 26,
              package: kPackage,
            ),
          );
  }

  void _mergedForward(BuildContext context) {
    if (!checkNetwork()) {
      return;
    }
    final selectedMessages =
        context.read<TopicChatViewModel>().selectedMessages;
    if (selectedMessages.length > mergedMessageLimit) {
      ChatUIToast.show(
        S
            .of(context)
            .chatMessageMergedForwardLimitOut(mergedMessageLimit.toString()),
        context: context,
      );
      return;
    }
    final cannotMergeMessage = selectedMessages.where((message) {
      if (MergeMessageHelper.getMergedMessageDepth(message) >=
          MergedMessage.defaultMaxDepth) {
        return true;
      }
      return message.sendingState == NIMMessageSendingState.failed ||
          message.messageType == NIMMessageType.call ||
          message.sendingState == NIMMessageSendingState.sending;
    }).toList();
    if (cannotMergeMessage.isNotEmpty) {
      showCommonDialog(
        context: context,
        content: S.of(context).chatMessageHaveCannotForwardMessages,
      ).then((value) {
        if (value == true) {
          context.read<TopicChatViewModel>().removeSelectedMessages(
                cannotMergeMessage,
              );
        }
      });
      return;
    }
    if (context.read<TopicChatViewModel>().selectedMessages.isEmpty) {
      return;
    }

    final sessionName = _forwardSessionName(context);
    ChatMessageHelper.showForwardSelector(
      context,
      (conversationId, {String? postScript, bool? isLastUser}) {
        context.read<TopicChatViewModel>().mergedMessageForward(
              conversationId,
              postScript: postScript,
              errorToast: S.of(context).chatMessageMergeMessageError,
              exitMultiMode: isLastUser == true,
            );
      },
      sessionName: sessionName,
      type: ForwardType.merge,
    );
  }

  void _forwardOneByOne(BuildContext context) {
    if (!checkNetwork()) {
      return;
    }
    final selectedMessages =
        context.read<TopicChatViewModel>().selectedMessages;
    if (selectedMessages.length > forwardMessageLimit) {
      ChatUIToast.show(
        S
            .of(context)
            .chatMessageForwardOneByOneLimitOut(forwardMessageLimit.toString()),
        context: context,
      );
      return;
    }

    final cannotForwardMessage = selectedMessages.where((message) {
      return message.sendingState == NIMMessageSendingState.failed ||
          message.sendingState == NIMMessageSendingState.sending ||
          message.messageType == NIMMessageType.call ||
          message.messageType == NIMMessageType.audio;
    }).toList();
    if (cannotForwardMessage.isNotEmpty) {
      showCommonDialog(
        context: context,
        content: S.of(context).chatMessageHaveCannotForwardMessages,
      ).then((value) {
        if (value == true) {
          context.read<TopicChatViewModel>().removeSelectedMessages(
                cannotForwardMessage,
              );
        }
      });
      return;
    }
    if (context.read<TopicChatViewModel>().selectedMessages.isEmpty) {
      return;
    }
    final sessionName = _forwardSessionName(context);
    ChatMessageHelper.showForwardSelector(
      context,
      (conversationId, {String? postScript, bool? isLastUser}) {
        context.read<TopicChatViewModel>().forwardMessageOneByOne(
              conversationId,
              postScript: postScript,
              exitMultiMode: isLastUser == true,
            );
      },
      sessionName: sessionName,
      type: ForwardType.oneByOne,
    );
  }

  void _deleteMessageOneByOne(BuildContext context) {
    if (!checkNetwork()) {
      return;
    }
    showCommonDialog(
      context: context,
      title: S.of().chatMessageActionDelete,
      content: S.of().chatMessageDeleteConfirm,
    ).then(
      (value) => {
        if (value ?? false)
          context.read<TopicChatViewModel>().deleteMessageOneByOne(),
      },
    );
  }

  PopMenuAction _buildTopicPopActions(BuildContext context) {
    final actions =
        chatUIConfig?.messageClickListener?.customPopActions ?? PopMenuAction();
    actions.onMessageForward = (message) {
      final sessionName = _forwardSessionName(context);
      ChatMessageHelper.showForwardSelector(context, (
        conversationId, {
        String? postScript,
        bool? isLastUser,
      }) {
        context.read<TopicChatViewModel>().forwardMessage(
              message.nimMessage,
              conversationId,
              postScript: postScript,
            );
      }, sessionName: sessionName);
      return true;
    };
    return actions;
  }

  String _forwardSessionName(BuildContext context) {
    return context.read<TopicChatViewModel>().rootSessionTitle;
  }

  Widget _buildChatBody(
    BuildContext context,
    String inputHint,
    bool haveSelectedMessage,
  ) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!context.read<TopicChatViewModel>().isMultiSelected) {
                    _inputField.currentState.hideAllPanel();
                  }
                },
                child: Stack(
                  children: [
                    ChatKitMessageList(
                      scrollController: autoController,
                      hideThreadRootReply: true,
                      popMenuAction: _buildTopicPopActions(context),
                      messageBuilder:
                          widget.messageBuilder ?? chatUIConfig?.messageBuilder,
                      onTapAvatar: (String? userId, {bool isSelf = false}) {
                        if (context
                            .read<TopicChatViewModel>()
                            .isMultiSelected) {
                          return true;
                        }
                        final customAvatarTap =
                            chatUIConfig?.messageClickListener?.onTapAvatar;
                        if (customAvatarTap != null &&
                            customAvatarTap(userId, isSelf: isSelf)) {
                          return true;
                        }
                        final robot =
                            context.read<TopicChatViewModel>().currentRobot;
                        if (!isSelf && robot != null) {
                          ChatAudioPlayer.instance.stopAll();
                          goToRobotProfile(context, robot);
                        }
                        return true;
                      },
                      onAvatarLongPress: (userId, {isSelf = false}) => true,
                      chatUIConfig: chatUIConfig,
                      teamInfo: null,
                      onMessageItemClick: chatUIConfig
                          ?.messageClickListener?.onMessageItemClick,
                      onMessageItemLongClick: chatUIConfig
                          ?.messageClickListener?.onMessageItemLongClick,
                    ),
                    if (_showEmptyState(context)) _buildEmptyState(context),
                  ],
                ),
              ),
            ),
            if (context.watch<TopicChatViewModel>().isMultiSelected)
              Container(
                color: '#EFF1F3'.toColor(),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    BottomOption(
                      icon: haveSelectedMessage
                          ? 'images/ic_chat_merge_forward.svg'
                          : 'images/ic_chat_merge_forward_disable.svg',
                      label: S.of(context).chatMessageMergeForward,
                      onTap: () {
                        _mergedForward(context);
                      },
                      enable: haveSelectedMessage,
                    ),
                    BottomOption(
                      icon: haveSelectedMessage
                          ? 'images/ic_chat_item_forward.svg'
                          : 'images/ic_chat_item_forward_disable.svg',
                      label: S.of(context).chatMessageItemsForward,
                      onTap: () {
                        _forwardOneByOne(context);
                      },
                      enable: haveSelectedMessage,
                    ),
                    BottomOption(
                      icon: haveSelectedMessage
                          ? 'images/ic_chat_delete_round.svg'
                          : 'images/ic_chat_delete_round_disable.svg',
                      label: S.of(context).chatMessageActionDelete,
                      onTap: () {
                        _deleteMessageOneByOne(context);
                      },
                      enable: haveSelectedMessage,
                    ),
                  ],
                ),
              ),
            if (!context.watch<TopicChatViewModel>().isMultiSelected)
              BottomInputField(
                scrollController: autoController,
                conversationType: NIMConversationType.p2p,
                conversationId: widget.conversationId,
                hint: S.of(context).chatMessageSendHint(inputHint),
                chatUIConfig: chatUIConfig,
                key: _inputField,
              ),
          ],
        ),
      ],
    );
  }

  bool _showEmptyState(BuildContext context) {
    final model = context.watch<TopicChatViewModel>();
    return !model.isLoading && model.messageList.isEmpty;
  }

  Widget _buildEmptyState(BuildContext context) {
    final model = context.watch<TopicChatViewModel>();
    final chatTitle =
        model.chatTitle.isNotEmpty ? model.chatTitle : model.rootSessionTitle;
    return IgnorePointer(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 72),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'images/ic_list_empty.svg',
                package: kPackage,
              ),
              const SizedBox(height: 12),
              Text(
                S.of(context).botSubsessionChatEmptyTips(chatTitle),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: '#999999'.toColor(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
