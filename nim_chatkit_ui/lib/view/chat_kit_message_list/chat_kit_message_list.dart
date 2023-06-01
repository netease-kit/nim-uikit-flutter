// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_corekit_im/router/imkit_router.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_pop_actions.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/widgets/chat_forward_dialog.dart';
import 'package:collection/collection.dart';
import 'package:netease_corekit_im/router/imkit_router_factory.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_corekit_im/model/contact_info.dart';
import 'package:netease_corekit_im/services/message/chat_message.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nim_core/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../../chat_kit_client.dart';
import '../../view_model/chat_view_model.dart';
import 'item/chat_kit_message_item.dart';

class ChatKitMessageList extends StatefulWidget {
  final AutoScrollController scrollController;

  final ChatKitMessageBuilder? messageBuilder;

  final bool Function(ChatMessage message)? onMessageItemClick;

  final bool Function(ChatMessage message)? onMessageItemLongClick;

  final bool Function(String? userID, {bool isSelf})? onTapAvatar;

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
    Clipboard.setData(ClipboardData(text: message.nimMessage.content));
    Fluttertoast.showToast(msg: S.of().chatMessageCopySuccess);
    return true;
  }

  _scrollToIndex(String uuid) {
    var index = context
        .read<ChatViewModel>()
        .messageList
        .indexWhere((element) => element.nimMessage.uuid == uuid);
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
    final lastTimestamp = context
        .read<ChatViewModel>()
        .getAnchor(QueryDirection.QUERY_OLD)
        .timestamp;
    if (anchor.timestamp >= lastTimestamp) {
      // in range
      findAnchor = null;
      int index = context
          .read<ChatViewModel>()
          .messageList
          .indexWhere((element) => element.nimMessage.uuid == anchor.uuid!);
      _logI(
          'scrollToAnchor: found time:${anchor.timestamp} >= $lastTimestamp, index found:$index');
      if (index >= 0) {
        widget.scrollController
            .scrollToIndex(index, duration: Duration(milliseconds: 500))
            .then((value) {
          widget.scrollController
              .scrollToIndex(index, preferPosition: AutoScrollPosition.middle);
        });
      }
    } else {
      _logI(
          'scrollToAnchor: not found in ${list.length} items, load more -->> ');
      widget.scrollController
          .scrollToIndex(list.length, duration: Duration(milliseconds: 1));
      if (context.read<ChatViewModel>().hasMoreForwardMessages) {
        _loadMore();
      }
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

  void _goContactSelector(ChatMessage message) {
    var filterUser =
        context.read<ChatViewModel>().sessionType == NIMSessionType.p2p
            ? [context.read<ChatViewModel>().sessionId]
            : null;
    var sessionName = context.read<ChatViewModel>().chatTitle;
    String forwardStr = S.of(context).messageForwardMessageTips(sessionName);
    goToContactSelector(context, filter: filterUser, returnContact: true)
        .then((selectedUsers) {
      if (selectedUsers is List<ContactInfo>) {
        showChatForwardDialog(
                context: context,
                contentStr: forwardStr,
                contacts: selectedUsers)
            .then((result) {
          if (result == true) {
            for (var user in selectedUsers) {
              context.read<ChatViewModel>().forwardMessage(
                  message.nimMessage, user.user.userId!, NIMSessionType.p2p);
            }
          }
        });
      }
    });
  }

  void _goTeamSelector(ChatMessage message) {
    var sessionName = context.read<ChatViewModel>().chatTitle;
    String forwardStr = S.of(context).messageForwardMessageTips(sessionName);
    goTeamListPage(context, selectorModel: true).then((result) {
      if (result is NIMTeam) {
        showChatForwardDialog(
                context: context, contentStr: forwardStr, team: result)
            .then((forward) {
          if (forward == true) {
            context.read<ChatViewModel>().forwardMessage(
                message.nimMessage, result.id!, NIMSessionType.team);
          }
        });
      }
    });
  }

  bool _onMessageForward(ChatMessage message) {
    var customActions = widget.popMenuAction;
    if (customActions?.onMessageForward != null &&
        customActions!.onMessageForward!(message)) {
      return true;
    }
    // 转发
    var style = const TextStyle(fontSize: 16, color: CommonColors.color_333333);
    showBottomChoose<int>(context: context, actions: [
      CupertinoActionSheetAction(
        onPressed: () {
          Navigator.pop(context, 2);
        },
        child: Text(
          S.of(context).messageForwardToTeam,
          style: style,
        ),
      ),
      CupertinoActionSheetAction(
        onPressed: () {
          Navigator.pop(context, 1);
        },
        child: Text(
          S.of(context).messageForwardToP2p,
          style: style,
        ),
      )
    ]).then((value) {
      if (value == 1) {
        _goContactSelector(message);
      } else if (value == 2) {
        _goTeamSelector(message);
      }
    });
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
      context.read<ChatViewModel>().addMessagePin(message.nimMessage);
    }
    return true;
  }

  bool _onMessageMultiSelect(ChatMessage message) {
    ///todo implement
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
    context.read<ChatViewModel>().sendMessage(message.nimMessage,
        replyMsg: message.replyMsg, resend: true);
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
                    if (value.code == 508) {
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

  _loadMore() async {
    // load old
    if (context.read<ChatViewModel>().messageList.isNotEmpty) {
      Alog.d(
          tag: 'ChatKit',
          moduleName: 'ChatKitMessageList',
          content: '_loadMore -->>');
      context.read<ChatViewModel>().fetchMoreMessage(QueryDirection.QUERY_OLD);
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
  }

  @override
  void dispose() {
    IMKitRouter.instance.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (findAnchor != null) {
      _logI('build, try scroll to anchor:${findAnchor?.content}');
      _scrollToAnchor(findAnchor!);
    }

    return Consumer<ChatViewModel>(builder: (cnt, chatViewModel, child) {
      if (chatViewModel.sessionType == NIMSessionType.p2p &&
          chatViewModel.messageList.isNotEmpty) {
        NIMMessage? firstMessage = chatViewModel.messageList
            .firstWhereOrNull((element) =>
                element.nimMessage.messageDirection ==
                NIMMessageDirection.received)
            ?.nimMessage;
        if (firstMessage?.messageAck == true &&
            firstMessage?.hasSendAck == false &&
            isInCurrentPage) {
          chatViewModel.sendMessageP2PReceipt(firstMessage!);
        }
      }

      ///message list
      return Container(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.topCenter,
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
                  if (index == chatViewModel.messageList.length - 1 &&
                      chatViewModel.hasMoreForwardMessages) {
                    _loadMore();
                  }
                  return AutoScrollTag(
                    controller: widget.scrollController,
                    index: index,
                    key: ValueKey(message.nimMessage.uuid),
                    highlightColor: Colors.black.withOpacity(0.1),
                    child: ChatKitMessageItem(
                      key: ValueKey(message.nimMessage.uuid),
                      chatMessage: message,
                      messageBuilder: widget.messageBuilder,
                      lastMessage: lastMessage,
                      popMenuAction:
                          getDefaultPopMenuActions(widget.popMenuAction),
                      scrollToIndex: _scrollToIndex,
                      onTapFailedMessage: _resendMessage,
                      onTapAvatar: widget.onTapAvatar,
                      chatUIConfig: widget.chatUIConfig,
                      teamInfo: widget.teamInfo,
                      onMessageItemClick: widget.onMessageItemClick,
                      onMessageItemLongClick: widget.onMessageItemLongClick,
                    ),
                  );
                },
              ),
            )
          ],
        ),
      );
    });
    // List messageList = widget.messageList;
  }
}
