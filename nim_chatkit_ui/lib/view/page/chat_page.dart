// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/no_network_tip.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/router/imkit_router.dart';
import 'package:nim_chatkit/router/imkit_router_constants.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit/services/message/nim_chat_cache.dart';
import 'package:nim_chatkit/message/merge_message.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit_ui/helper/merge_message_helper.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/chat_kit_message_list.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_pop_actions.dart';
import 'package:nim_chatkit_ui/view/page/chat_setting_page.dart';
import 'package:nim_chatkit_ui/view_model/chat_view_model.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../chat_kit_client.dart';
import '../../helper/chat_message_helper.dart';
import '../../l10n/S.dart';
import '../../media/audio_player.dart';
import '../input/bottom_input_field.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;

  final NIMConversationType conversationType;

  final NIMMessage? anchor;

  final PopMenuAction? customPopActions;

  final bool Function(ChatMessage message)? onMessageItemClick;

  final bool Function(ChatMessage message)? onMessageItemLongClick;

  final bool Function(String? userID, {bool isSelf})? onTapAvatar;

  final ChatUIConfig? chatUIConfig;

  final ChatKitMessageBuilder? messageBuilder;

  ChatPage(
      {Key? key,
      required this.conversationId,
      required this.conversationType,
      this.anchor,
      this.customPopActions,
      this.onTapAvatar,
      this.chatUIConfig,
      this.messageBuilder,
      this.onMessageItemClick,
      this.onMessageItemLongClick})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatPageState();
}

class ChatPageState extends BaseState<ChatPage> with RouteAware {
  late AutoScrollController autoController;
  final GlobalKey<dynamic> _inputField = GlobalKey();

  //合并转发限制的消息数
  static const int mergedMessageLimit = 100;

  //逐条转发限制的消息数
  static const int forwardMessageLimit = 10;

  Timer? _typingTimer;

  int _remainTime = 5;

  StreamSubscription? _teamDismissSub;

  ChatUIConfig? chatUIConfig;

  void _setTyping(BuildContext context) {
    _typingTimer?.cancel();
    _remainTime = 5;
    _typingTimer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (_remainTime <= 0) {
        _remainTime = 5;
        _typingTimer?.cancel();
        context.read<ChatViewModel>().resetTyping();
      } else {
        _remainTime--;
      }
    });
  }

  void _defaultAvatarTap(String? userId, {bool isSelf = false}) {
    if (isSelf) {
      gotoMineInfoPage(context);
    } else {
      goToContactDetail(context, userId!);
    }
  }

  bool _defaultAvatarLongPress(String? userID, {bool isSelf = false}) {
    if (!isSelf) {
      _inputField.currentState.addMention(userID!);
      return true;
    }
    return false;
  }

  ///设置正在聊天的账号
  void _setChattingAccount() {
    ChatMessageRepo.setChattingAccount(
        null, widget.conversationType, widget.conversationId);
  }

  Future<String> getSessionId(String conversationId) async {
    return (await NimCore.instance.conversationIdUtil
            .conversationTargetId(conversationId))
        .data!;
  }

  ///清除正在聊天的账号
  void _clearChattingAccount() async {
    ChatMessageRepo.clearChattingAccountWithId(
        null, widget.conversationType, widget.conversationId);
  }

  bool hasShowTeamDismissDialog = false;

  @override
  void initState() {
    super.initState();
    chatUIConfig = widget.chatUIConfig ?? ChatKitClient.instance.chatUIConfig;
    autoController = AutoScrollController(
      viewportBoundaryGetter: () =>
          Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
      axis: Axis.vertical,
    );
    //初始化语音播放器
    ChatAudioPlayer.instance.initAudioPlayer();
    ChatKitClient.instance.registerRevokedMessage();
    if (widget.conversationType == NIMConversationType.team) {
      _teamDismissSub =
          NimCore.instance.messageService.onReceiveMessages.listen((event) {
        for (var msg in event) {
          if (_isTeamDisMessageNotify(msg)) {
            _showTeamDismissDialog();
            break;
          } else if (_isTeamKickedMessageNotify(msg)) {
            _showTeamKickedDialog();
            break;
          }
        }
      });
    }
    _setChattingAccount();
    Future.delayed(Duration.zero, () {
      IMKitRouter.instance.routeObserver
          .subscribe(this, ModalRoute.of(context)!);
    });
  }

  bool _isTeamDisMessageNotify(NIMMessage msg) {
    if (msg.conversationId == widget.conversationId &&
        msg.messageType == NIMMessageType.notification) {
      NIMMessageNotificationAttachment attachment =
          msg.attachment as NIMMessageNotificationAttachment;
      if (attachment.type == NIMMessageNotificationType.teamDismiss &&
          msg.senderId != getIt<IMLoginService>().userInfo?.accountId) {
        return true;
      }
    }
    return false;
  }

  ///是否是被踢出群的通知
  bool _isTeamKickedMessageNotify(NIMMessage msg) {
    if (msg.conversationId == widget.conversationId &&
        msg.messageType == NIMMessageType.notification) {
      NIMMessageNotificationAttachment attachment =
          msg.attachment as NIMMessageNotificationAttachment;
      if (attachment.type == NIMMessageNotificationType.teamKick) {
        if (attachment.targetIds
                ?.contains(getIt<IMLoginService>().userInfo?.accountId) ==
            true) {
          return true;
        }
      }
    }
    return false;
  }

  void _showTeamDismissDialog() {
    showCommonDialog(
            context: GlobalKey().currentContext ?? context,
            title: S.of().chatTeamBeRemovedTitle,
            content: S.of().chatTeamBeRemovedContent,
            showNavigate: false)
        .then((value) {
      if (value == true) {
        _onTeamDismissOrKicked();
      }
    });
  }

  ///显示被踢的确认弹框
  void _showTeamKickedDialog() {
    showCommonDialog(
            context: GlobalKey().currentContext ?? context,
            title: S.of().chatTeamBeRemovedTitle,
            content: S.of().chatTeamHaveBeenKick,
            showNavigate: false)
        .then((value) {
      if (value == true) {
        _onTeamDismissOrKicked();
      }
    });
  }

  ///踢出群后的处理逻辑
  void _onTeamDismissOrKicked() {
    if (widget.chatUIConfig?.onTeamDismissOrLeave?.call() == true) {
      return;
    }
    Navigator.popUntil(context, ModalRoute.withName('/'));
  }

  @override
  void onAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
    super.onAppLifecycleState(state);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    ChatAudioPlayer.instance.release();
    _teamDismissSub?.cancel();
    _clearChattingAccount();
    IMKitRouter.instance.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (NIMChatCache.instance.currentChatSession?.conversationId !=
            widget.conversationId ||
        NIMChatCache.instance.currentChatSession?.conversationType !=
            widget.conversationType) {
      _setChattingAccount();
    }
    super.didPopNext();
  }

  void _mergedForward(BuildContext context) {
    //判断网络
    if (!checkNetwork()) {
      return;
    }
    var selectedMessages = context.read<ChatViewModel>().selectedMessages;
    //判断选择消息的数量
    if (selectedMessages.length > mergedMessageLimit) {
      Fluttertoast.showToast(
          msg: S
              .of(context)
              .chatMessageMergedForwardLimitOut(mergedMessageLimit.toString()));
      return;
    }
    //判断不能合并转发的
    // 1. 消息深度超过最大深度
    // 2. 消息发送失败
    // 3. 消息正在发送
    var cannotMergeMessage = selectedMessages.where((e) {
      if (MergeMessageHelper.getMergedMessageDepth(e) >=
          MergedMessage.defaultMaxDepth) {
        return true;
      }
      return e.sendingState == NIMMessageSendingState.failed ||
          e.messageType == NIMMessageType.avChat ||
          e.sendingState == NIMMessageSendingState.sending;
    }).toList();
    if (cannotMergeMessage.isNotEmpty) {
      showCommonDialog(
              context: context,
              content: S.of(context).chatMessageHaveCannotForwardMessages)
          .then((value) {
        if (value == true) {
          context
              .read<ChatViewModel>()
              .removeSelectedMessages(cannotMergeMessage);
        }
      });
      return;
    }
    if (context.read<ChatViewModel>().selectedMessages.isEmpty) {
      return;
    }

    // 处理合并转发
    var sessionName = context.read<ChatViewModel>().chatTitle;
    ChatMessageHelper.showForwardSelector(context, (conversationId,
        {String? postScript, bool? isLastUser}) {
      context.read<ChatViewModel>().mergedMessageForward(conversationId,
          postScript: postScript,
          errorToast: S.of(context).chatMessageMergeMessageError,
          exitMultiMode: isLastUser == true);
    }, sessionName: sessionName, type: ForwardType.merge);
  }

  void _forwardOneByOne(BuildContext context) {
    //判断网络
    if (!checkNetwork()) {
      return;
    }
    var selectedMessages = context.read<ChatViewModel>().selectedMessages;
    if (selectedMessages.length > forwardMessageLimit) {
      Fluttertoast.showToast(
          msg: S.of(context).chatMessageForwardOneByOneLimitOut(
              forwardMessageLimit.toString()));
      return;
    }

    //判断有不能转发的消息
    // 1. 消息发送失败
    // 2. 消息正在发送
    // 3. 消息是语音消息
    var cannotMergeMessage = selectedMessages.where((e) {
      return e.sendingState == NIMMessageSendingState.failed ||
          e.sendingState == NIMMessageSendingState.sending ||
          e.messageType == NIMMessageType.avChat ||
          e.messageType == NIMMessageType.audio;
    }).toList();
    if (cannotMergeMessage.isNotEmpty) {
      showCommonDialog(
              context: context,
              content: S.of(context).chatMessageHaveCannotForwardMessages)
          .then((value) {
        if (value == true) {
          context
              .read<ChatViewModel>()
              .removeSelectedMessages(cannotMergeMessage);
        }
      });
      return;
    }
    if (context.read<ChatViewModel>().selectedMessages.isEmpty) {
      return;
    }
    var sessionName = context.read<ChatViewModel>().chatTitle;
    ChatMessageHelper.showForwardSelector(context, (conversationId,
        {String? postScript, bool? isLastUser}) {
      context.read<ChatViewModel>().forwardMessageOneByOne(conversationId,
          postScript: postScript, exitMultiMode: isLastUser == true);
    }, sessionName: sessionName, type: ForwardType.oneByOne);
  }

  void _deleteMessageOneByOne(BuildContext context) {
    //提前判断网络
    if (!checkNetwork()) {
      return;
    }
    showCommonDialog(
            context: context,
            title: S.of().chatMessageActionDelete,
            content: S.of().chatMessageDeleteConfirm)
        .then((value) => {
              if (value ?? false)
                context.read<ChatViewModel>().deleteMessageOneByOne()
            });
  }

  @override
  Widget build(BuildContext context) {
    if (NIMChatCache.instance.currentChatSession?.conversationId !=
            widget.conversationId ||
        NIMChatCache.instance.currentChatSession?.conversationType !=
            widget.conversationType) {
      _setChattingAccount();
    }

    return ChangeNotifierProvider(
        create: (context) =>
            ChatViewModel(widget.conversationId, widget.conversationType),
        builder: (context, wg) {
          String title;
          String? subTitle;
          String inputHint = context.watch<ChatViewModel>().chatTitle;
          bool? isOnline = context.watch<ChatViewModel>().contactInfo?.isOnline;
          if (context.watch<ChatViewModel>().isTyping) {
            _setTyping(context);
            title = S.of(context).chatIsTyping;
          } else if (IMKitConfigCenter.enableOnlineStatus &&
              widget.conversationType == NIMConversationType.p2p &&
              !AIUserManager.instance.isAIUser(
                  ChatKitUtils.getConversationTargetId(
                      widget.conversationId))) {
            title = inputHint;

            subTitle = isOnline == true
                ? S.of(context).chatUserOnline
                : S.of(context).chatUserOffline;
          } else {
            title = inputHint;
          }
          bool haveSelectedMessage =
              context.watch<ChatViewModel>().selectedMessages.isNotEmpty;

          final chatViewModel = context.watch<ChatViewModel>();
          // 检查群组有效性
          if (widget.conversationType == NIMConversationType.team &&
              chatViewModel.teamInfo != null &&
              chatViewModel.teamInfo!.isValidTeam == false &&
              !hasShowTeamDismissDialog) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showTeamDismissDialog();
            });
            hasShowTeamDismissDialog = true;
          }
          return PopScope(
              child: TransparentScaffold(
                  backgroundColor: Colors.white,
                  centerTitle: true,
                  title: title,
                  subTitle: subTitle,
                  elevation: 0,
                  actions: [
                    context.watch<ChatViewModel>().isMultiSelected
                        ? TextButton(
                            onPressed: () {
                              context.read<ChatViewModel>().isMultiSelected =
                                  false;
                            },
                            child: Text(S.of(context).messageCancel,
                                maxLines: 1,
                                style: TextStyle(
                                    fontSize: 16, color: '#333333'.toColor())))
                        : IconButton(
                            onPressed: () async {
                              if (widget.conversationType ==
                                  NIMConversationType.p2p) {
                                ContactInfo? info =
                                    context.read<ChatViewModel>().contactInfo;
                                if (info != null) {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ChatSettingPage(
                                              info, widget.conversationId)));
                                }
                              } else if (widget.conversationType ==
                                  NIMConversationType.team) {
                                Navigator.pushNamed(context,
                                    RouterConstants.PATH_TEAM_SETTING_PAGE,
                                    arguments: {
                                      'teamId': await getSessionId(
                                          widget.conversationId)
                                    }).then((value) {
                                  if (value == true) {
                                    Navigator.pop(context);
                                  }
                                });
                              }
                            },
                            icon: SvgPicture.asset(
                              'images/ic_setting.svg',
                              width: 26,
                              height: 26,
                              package: kPackage,
                            ))
                  ],
                  body: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!hasNetWork) NoNetWorkTip(),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (!context
                                    .read<ChatViewModel>()
                                    .isMultiSelected) {
                                  _inputField.currentState.hideAllPanel();
                                }
                              },
                              child: ChatKitMessageList(
                                scrollController: autoController,
                                popMenuAction: widget.customPopActions ??
                                    chatUIConfig?.messageClickListener
                                        ?.customPopActions,
                                anchor: widget.anchor,
                                messageBuilder: widget.messageBuilder ??
                                    chatUIConfig?.messageBuilder,
                                onTapAvatar: (String? userId,
                                    {bool isSelf = false}) {
                                  if (context
                                      .read<ChatViewModel>()
                                      .isMultiSelected) {
                                    return true;
                                  }
                                  if (widget.onTapAvatar != null &&
                                      widget.onTapAvatar!(userId,
                                          isSelf: isSelf)) {
                                    return true;
                                  }
                                  if (chatUIConfig?.messageClickListener
                                              ?.onTapAvatar !=
                                          null &&
                                      chatUIConfig!.messageClickListener!
                                              .onTapAvatar!(userId,
                                          isSelf: isSelf)) {
                                    return true;
                                  }
                                  _defaultAvatarTap(userId, isSelf: isSelf);
                                  return true;
                                },
                                onAvatarLongPress: (userId, {isSelf = false}) {
                                  if (context
                                      .read<ChatViewModel>()
                                      .isMultiSelected) {
                                    return true;
                                  }
                                  if (chatUIConfig?.messageClickListener
                                              ?.onLongPressAvatar !=
                                          null &&
                                      chatUIConfig!.messageClickListener!
                                              .onLongPressAvatar!(userId,
                                          isSelf: isSelf)) {
                                    return true;
                                  }
                                  return _defaultAvatarLongPress(userId,
                                      isSelf: isSelf);
                                },
                                chatUIConfig: chatUIConfig,
                                teamInfo:
                                    context.watch<ChatViewModel>().teamInfo,
                                onMessageItemClick: widget.onMessageItemClick ??
                                    chatUIConfig?.messageClickListener
                                        ?.onMessageItemClick,
                                onMessageItemLongClick:
                                    widget.onMessageItemLongClick ??
                                        chatUIConfig?.messageClickListener
                                            ?.onMessageItemLongClick,
                              ),
                            ),
                          ),
                          if (context.watch<ChatViewModel>().isMultiSelected)
                            Container(
                              color: '#EFF1F3'.toColor(),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  BottomOption(
                                    icon: haveSelectedMessage
                                        ? 'images/ic_chat_merge_forward.svg'
                                        : 'images/ic_chat_merge_forward_disable.svg',
                                    label:
                                        S.of(context).chatMessageMergeForward,
                                    onTap: () {
                                      _mergedForward(context);
                                    },
                                    enable: haveSelectedMessage,
                                  ),
                                  BottomOption(
                                    icon: haveSelectedMessage
                                        ? 'images/ic_chat_item_forward.svg'
                                        : 'images/ic_chat_item_forward_disable.svg',
                                    label:
                                        S.of(context).chatMessageItemsForward,
                                    onTap: () {
                                      _forwardOneByOne(context);
                                    },
                                    enable: haveSelectedMessage,
                                  ),
                                  BottomOption(
                                    icon: haveSelectedMessage
                                        ? 'images/ic_chat_delete_round.svg'
                                        : 'images/ic_chat_delete_round_disable.svg',
                                    label:
                                        S.of(context).chatMessageActionDelete,
                                    onTap: () {
                                      _deleteMessageOneByOne(context);
                                    },
                                    enable: haveSelectedMessage,
                                  ),
                                ],
                              ),
                            ),
                          Visibility(
                              visible: !context
                                  .watch<ChatViewModel>()
                                  .isMultiSelected,
                              maintainState: true,
                              child: BottomInputField(
                                scrollController: autoController,
                                conversationType: widget.conversationType,
                                conversationId: widget.conversationId,
                                hint: S
                                    .of(context)
                                    .chatMessageSendHint(inputHint),
                                chatUIConfig: chatUIConfig,
                                key: _inputField,
                              )),
                        ],
                      ),
                    ],
                  )),
              canPop: context.watch<ChatViewModel>().isMultiSelected != true,
              onPopInvokedWithResult: (bool didPop, result) async {
                if (context.read<ChatViewModel>().isMultiSelected) {
                  context.read<ChatViewModel>().isMultiSelected = false;
                }
              });
        });
  }
}

class BottomOption extends StatelessWidget {
  final String icon;

  final String label;

  final Function()? onTap;

  final bool enable;

  const BottomOption(
      {Key? key,
      required this.icon,
      required this.label,
      this.onTap,
      this.enable = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          if (enable) {
            onTap?.call();
          }
        },
        child: Column(
          children: [
            SvgPicture.asset(
              icon,
              package: kPackage,
              width: 48,
              height: 48,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              label,
              style: TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 14,
                  color: '#666666'.toColor()),
            )
          ],
        ));
  }
}
