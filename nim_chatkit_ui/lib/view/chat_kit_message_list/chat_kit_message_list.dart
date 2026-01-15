// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common/netease_common.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/neListView/size_cache_widget.dart';
import 'package:nim_chatkit/message/message_helper.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/router/imkit_router.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
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

  final int? anchorDate;

  ChatKitMessageList(
      {Key? key,
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
      this.onMessageItemLongClick})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageListState();
}

class ChatKitMessageListState extends State<ChatKitMessageList>
    with RouteAware {
  NIMMessage? findAnchor;

  int? findAnchorDate;

  //是否在当前页面
  bool isInCurrentPage = true;

  bool _showScrollToBottom = false;

  bool? _enableShrinkWrap;

  final GlobalKey _firstItemKey = GlobalKey();
  double _firstItemHeight = 0;

  final Key _centerKey = GlobalKey();
  String? _pivotMessageId;

  //需要修正的消息索引
  int? _pivotMessageIndex;

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

  _scrollToMessageByRefer(NIMMessageRefer messageRefer) async {
    var index = context.read<ChatViewModel>().messageList.indexWhere(
        (element) =>
            element.nimMessage.messageClientId == messageRefer.messageClientId);
    if (index >= 0) {
      _scrollToIndex(index);
    } else {
      var anchor = (await ChatMessageRepo.getMessageByRefer(messageRefer)).data;

      if (anchor != null) {
        setState(() {
          findAnchor = anchor;
          context.read<ChatViewModel>().showNewMessage = false;
          _showScrollToBottom = true;
        });
        _findAnchorRemote(anchor);
      }
    }
  }

  _scrollToMessageByTime(int anchorDate) {
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
      // in range
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        findAnchorDate = null;
        if (index < list.length - 1) {
          setState(() {
            _pivotMessageId = list[index].nimMessage.messageClientId;
          });
        } else {
          setState(() {
            _pivotMessageId = list[0].nimMessage.messageClientId;
          });
        }
        _scrollToIndex(index);
      });
    } else {
      _logI(
          'scrollToAnchor: not found in ${list.length} items, _findAnchorDateRemote -->> ');
      if (!context.read<ChatViewModel>().isLoading) {
        _findAnchorDateRemote(anchorDate);
      }
    }
  }

  _scrollToAnchor(NIMMessage anchor) {
    var list = context.read<ChatViewModel>().messageList;
    if (list.isEmpty) {
      _logI('scrollToAnchor: messageList is empty');
      return;
    }
    int index = list.indexWhere((element) =>
        element.nimMessage.messageClientId == anchor.messageClientId!);
    if (index >= 0) {
      // in range
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        findAnchor = null;
        if (index < list.length - 1) {
          setState(() {
            _pivotMessageId = list[index].nimMessage.messageClientId;
          });
        }

        _scrollToIndex(index);
      });
    } else {
      _logI(
          'scrollToAnchor: not found in ${list.length} items, _findAnchorRemote -->> ');
      if (!context.read<ChatViewModel>().isLoading) {
        _findAnchorRemote(anchor);
      }
    }
  }

  //滚动到具体的index
  _scrollToIndex(int index) {
    _logI('scrollToIndex: found anchor index found:$index');
    if (!mounted) {
      return;
    }
    // 如果键盘弹出则滚动到begin,否则滚动到middle
    var bottom = MediaQuery.of(context).viewInsets.bottom;
    var position =
        bottom > 0 ? AutoScrollPosition.begin : AutoScrollPosition.middle;
    // 如果是最后一条消息，滚动到begin
    if (index == context.read<ChatViewModel>().messageList.length - 1) {
      position = AutoScrollPosition.end;
    }
    widget.scrollController.scrollToIndex(index,
        preferPosition: position, duration: Duration(milliseconds: 500));
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
          content: '_loadMore -->>');
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
    findAnchorDate = widget.anchorDate;
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.scrollController.hasClients) {
          double target = widget.scrollController.position.minScrollExtent;
          _logI('scrolling to bottom target: $target');
          widget.scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );

          setState(() {
            _showScrollToBottom = false;
          });
        }
      });
    }
  }

  _initScrollController() {
    widget.scrollController.addListener(() {
      if (widget.scrollController.position.pixels >=
          widget.scrollController.position.maxScrollExtent) {
        _logI('scrollController -->> load more');
        if (_loadMore()) {
          return;
        }
      } else if (widget.scrollController.position.pixels <=
          widget.scrollController.position.minScrollExtent) {
        if (context.read<ChatViewModel>().messageList.isNotEmpty &&
            context.read<ChatViewModel>().hasMoreNewerMessages) {
          context.read<ChatViewModel>().fetchMoreMessage(NIMQueryDirection.asc);
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
        setState(() {
          if (!context.read<ChatViewModel>().hasMoreNewerMessages) {
            context.read<ChatViewModel>().srollToNewMessage(scrollToEnd: false);
            _showScrollToBottom = false;
          }
        });
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
        teamInfo: widget.teamInfo,
        onMessageItemClick: widget.onMessageItemClick,
        onMessageItemLongClick: widget.onMessageItemLongClick,
      ),
    );
    if (index == 0) {
      return KeyedSubtree(
        key: _firstItemKey,
        child: item,
      );
    }
    return item;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(builder: (cnt, chatViewModel, child) {
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
        if (widget.anchor != null) {
          _pivotMessageId = widget.anchor!.messageClientId;
        } else if (widget.anchorDate != null) {
          _pivotMessageId = messageList
              .firstWhereOrNull(
                  (m) => m.nimMessage.createTime! <= widget.anchorDate!)
              ?.nimMessage
              .messageClientId;
        }
      }

      int pivotIndex = 0;
      if (messageList.isNotEmpty) {
        if (_pivotMessageId != null) {
          pivotIndex = messageList.indexWhere(
              (m) => m.nimMessage.messageClientId == _pivotMessageId);
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
              (m) => m.nimMessage.messageClientId == _pivotMessageId);
          if (_pivotMessageIndex == null && indexPivotMessage != -1) {
            _pivotMessageIndex = indexPivotMessage;
          }
          if (indexPivotMessage > 0) {
            setState(() {
              _pivotMessageId =
                  messageList[indexPivotMessage - 1].nimMessage.messageClientId;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              //添加大于1的逻辑，避免重复滚动
              if (_pivotMessageIndex != null &&
                  (_pivotMessageIndex! - indexPivotMessage) > 1) {
                _scrollToIndex(_pivotMessageIndex!);
              }
            });
          }
        }
      });

      ///message list
      return Container(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SizeCacheWidget(
                child: CustomScrollView(
                  controller: widget.scrollController,
                  center:
                      (!enableShrinkWrap && pivotIndex > 0) ? _centerKey : null,
                  reverse: true,
                  shrinkWrap: enableShrinkWrap,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 10),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            int globalIndex = pivotIndex - 1 - index;
                            if (globalIndex < 0) return null;
                            return _buildMessageItem(
                                chatViewModel, globalIndex);
                          },
                          childCount: pivotIndex > 0 ? pivotIndex : 0,
                        ),
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
                                chatViewModel, globalIndex);
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
            if (_showScrollToBottom &&
                context.read<ChatViewModel>().isMultiSelected != true)
              Positioned(
                bottom: 20,
                right: chatViewModel.newMessages.isEmpty ? 20 : 0,
                child: GestureDetector(
                  onTap: chatViewModel.srollToNewMessage,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                        if (chatViewModel.newMessages.isNotEmpty)
                          Text(
                            S.of(context).chatNewMessage(
                                '${chatViewModel.newMessages.length}'),
                            style: TextStyle(
                                fontSize: 14, color: '#1861DF'.toColor()),
                          )
                      ],
                    ),
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
