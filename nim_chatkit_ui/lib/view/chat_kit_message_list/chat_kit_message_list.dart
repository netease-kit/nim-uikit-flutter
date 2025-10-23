// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common/netease_common.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/widgets/neListView/size_cache_widget.dart';
import 'package:nim_chatkit/router/imkit_router.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit/message/message_helper.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_pop_actions.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../chat_kit_client.dart';
import '../../helper/chat_message_helper.dart';
import '../../view_model/chat_view_model.dart';
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

  ChatKitMessageList(
      {Key? key,
      required this.scrollController,
      this.anchor,
      this.messageBuilder,
      this.popMenuAction,
      this.onTapAvatar,
      this.teamInfo,
      this.chatUIConfig,
      this.onMessageItemClick,
      this.onAvatarLongPress,
      this.onMessageItemLongClick})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageListState();
}

class ChatKitMessageListState extends State<ChatKitMessageList>
    with RouteAware {
  NIMMessage? findAnchor;

  //是否在当前页面
  bool isInCurrentPage = true;

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
      Fluttertoast.showToast(msg: S.of().chatMessageCopySuccess);
      return true;
    }
    var multiLineMap = MessageHelper.parseMultiLineMessage(message.nimMessage);
    if (multiLineMap != null) {
      var title = multiLineMap[ChatMessage.keyMultiLineTitle] as String;
      var content = multiLineMap[ChatMessage.keyMultiLineBody];
      Clipboard.setData(ClipboardData(text: content ?? title));
      Fluttertoast.showToast(msg: S.of().chatMessageCopySuccess);
      return true;
    }
    return false;
  }

  _scrollToMessageByUUID(String messageClientId) {
    var index = context.read<ChatViewModel>().messageList.indexWhere(
        (element) => element.nimMessage.messageClientId == messageClientId);
    if (index >= 0) {
      widget.scrollController.scrollToIndex(index);
    }
  }

  _scrollToAnchor(NIMMessage anchor) {
    var list = context.read<ChatViewModel>().messageList;
    if (list.isEmpty) {
      _logI('scrollToAnchor: messageList is empty');
      return;
    }
    int index = context.read<ChatViewModel>().messageList.indexWhere(
        (element) =>
            element.nimMessage.messageClientId == anchor.messageClientId!);
    if (index >= 0) {
      // in range
      findAnchor = null;

      _logI('scrollToAnchor: found anchor index found:$index');
      widget.scrollController
          .scrollToIndex(index, duration: Duration(milliseconds: 500))
          .then((value) {
        widget.scrollController
            .scrollToIndex(index, preferPosition: AutoScrollPosition.middle);
      });
    } else {
      _logI(
          'scrollToAnchor: not found in ${list.length} items, _findAnchorRemote -->> ');
      _findAnchorRemote(anchor);
    }
  }

  bool _onMessageCollect(ChatMessage message) {
    var customActions = widget.popMenuAction;
    if (customActions?.onMessageCollect != null &&
        customActions!.onMessageCollect!(message)) {
      return true;
    }
    context.read<ChatViewModel>().collectMessage(message.nimMessage);
    Fluttertoast.showToast(msg: S.of().chatMessageCollectSuccess);
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
    ChatMessageHelper.showForwardSelector(context, (conversationId,
        {String? postScript, bool? isLastUser}) {
      context.read<ChatViewModel>().forwardMessage(
          message.nimMessage, conversationId,
          postScript: postScript);
    }, sessionName: sessionName);

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
      context
          .read<ChatViewModel>()
          .addMessagePin(message.nimMessage)
          .then((result) {
        if (result.code == ChatMessageRepo.errorPINLimited) {
          Fluttertoast.showToast(msg: S.of(context).chatMessagePinLimitTips);
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
            content: S.of().chatMessageDeleteConfirm)
        .then((value) => {
              if (value ?? false)
                context.read<ChatViewModel>().deleteMessage(message)
            });
    return true;
  }

  void _resendMessage(ChatMessage message) {
    context
        .read<ChatViewModel>()
        .sendMessage(message.nimMessage, replyMsg: message.replyMsg);
  }

  bool _onVoicePlayModelChange(bool isVoiceFromSpeaker) {
    var customActions = widget.popMenuAction;
    if (customActions?.onVoiceSpeakerSwitch != null &&
        customActions!.onVoiceSpeakerSwitch!(isVoiceFromSpeaker)) {
      return true;
    }
    if (isVoiceFromSpeaker) {
      Fluttertoast.showToast(msg: S.of().chatVoiceFromSpeakerTips);
    } else {
      Fluttertoast.showToast(msg: S.of().chatVoiceFromEarSpeakerTips);
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
            content: S.of().chatMessageRevokeConfirm)
        .then((value) => {
              if (value ?? false)
                context
                    .read<ChatViewModel>()
                    .revokeMessage(message)
                    .then((value) {
                  if (!value.isSuccess) {
                    if (value.code == ChatMessageRepo.errorRevokeTimeout) {
                      Fluttertoast.showToast(
                          msg: S.of().chatMessageRevokeOverTime);
                    } else {
                      Fluttertoast.showToast(
                          msg: S.of().chatMessageRevokeFailed);
                    }
                  }
                })
            });
    return true;
  }

  _findAnchorRemote(NIMMessage anchor) {
    context.read<ChatViewModel>().loadMessageWithAnchor(anchor);
  }

  _loadMore() async {
    // load old
    if (context.read<ChatViewModel>().messageList.isNotEmpty &&
        context.read<ChatViewModel>().hasMoreForwardMessages &&
        !context.read<ChatViewModel>().isLoading) {
      Alog.d(
          tag: 'ChatKit',
          moduleName: 'ChatKitMessageList',
          content: '_loadMore -->>');
      context.read<ChatViewModel>().fetchMoreMessage(NIMQueryDirection.desc);
    }
  }

  _loadNewer() {
    // load old
    if (context.read<ChatViewModel>().messageList.isNotEmpty &&
        context.read<ChatViewModel>().hasMoreNewerMessages &&
        !context.read<ChatViewModel>().isLoading) {
      Alog.d(
          tag: 'ChatKit',
          moduleName: 'ChatKitMessageList',
          content: '_loadNewer -->>');
      context.read<ChatViewModel>().fetchMoreMessage(NIMQueryDirection.asc);
    }
  }

  PopMenuAction getDefaultPopMenuActions(PopMenuAction? customActions) {
    PopMenuAction actions = PopMenuAction();
    actions.onMessageCopy = _onMessageCopy;
    actions.onMessageReply = _onMessageReply;
    actions.onMessageCollect = _onMessageCollect;
    actions.onMessageForward = _onMessageForward;
    actions.onMessagePin = _onMessagePin;
    actions.onMessageMultiSelect = _onMessageMultiSelect;
    actions.onMessageDelete = _onMessageDelete;
    actions.onMessageRevoke = _onMessageRevoke;
    actions.onVoiceSpeakerSwitch = _onVoicePlayModelChange;
    return actions;
  }

  @override
  void didPushNext() {
    isInCurrentPage = false;
    super.didPushNext();
  }

  @override
  void didPopNext() {
    setState(() {
      isInCurrentPage = true;
    });
    super.didPopNext();
  }

  @override
  void initState() {
    super.initState();
    findAnchor = widget.anchor;
    Future.delayed(Duration.zero, () {
      IMKitRouter.instance.routeObserver
          .subscribe(this, ModalRoute.of(context)!);
    });
    _initScrollController();
  }

  //收到新消息后滑动到底部，对齐原生端交互
  _scrollToBottom() {
    _logI('_scrollToBottom');
    if (widget.scrollController.hasClients) {
      widget.scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  _initScrollController() {
    widget.scrollController.addListener(() {
      if (widget.scrollController.position.pixels >=
          widget.scrollController.position.maxScrollExtent) {
        _logI('scrollController -->> load more');
        _loadMore();
      } else if (widget.scrollController.position.pixels <= 0) {
        _loadNewer();
      }
    });
    context.read<ChatViewModel>().scrollToEnd = _scrollToBottom;
  }

  @override
  void dispose() {
    IMKitRouter.instance.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (findAnchor != null) {
      _logI('build, try scroll to anchor:${findAnchor?.text}');
      _scrollToAnchor(findAnchor!);
    }

    return Consumer<ChatViewModel>(builder: (cnt, chatViewModel, child) {
      ///message list
      return Container(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SizeCacheWidget(
                child: ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  addAutomaticKeepAlives: false,
                  shrinkWrap: true,
                  reverse: true,
                  itemCount: chatViewModel.messageList.length,
                  itemBuilder: (context, index) {
                    ChatMessage message = chatViewModel.messageList[index];
                    ChatMessage? lastMessage =
                        index < chatViewModel.messageList.length - 1
                            ? chatViewModel.messageList[index + 1]
                            : null;
                    return AutoScrollTag(
                      controller: widget.scrollController,
                      index: index,
                      key: ValueKey(message.nimMessage.messageClientId),
                      highlightColor: Colors.black.withOpacity(0.1),
                      child: ChatKitMessageItem(
                        key: ValueKey(message.nimMessage.messageClientId),
                        chatMessage: message,
                        messageBuilder: widget.messageBuilder,
                        lastMessage: lastMessage,
                        popMenuAction:
                            getDefaultPopMenuActions(widget.popMenuAction),
                        scrollToIndex: _scrollToMessageByUUID,
                        onTapFailedMessage: _resendMessage,
                        onTapAvatar: widget.onTapAvatar,
                        onAvatarLongPress: widget.onAvatarLongPress,
                        chatUIConfig: widget.chatUIConfig,
                        teamInfo: widget.teamInfo,
                        onMessageItemClick: widget.onMessageItemClick,
                        onMessageItemLongClick: widget.onMessageItemLongClick,
                      ),
                    );
                  },
                ),
              ),
            )
          ],
        ),
      );
    });
    // List messageList = widget.messageList;
  }
}
