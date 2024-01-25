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
import 'package:netease_corekit_im/model/contact_info.dart';
import 'package:netease_corekit_im/router/imkit_router.dart';
import 'package:netease_corekit_im/router/imkit_router_constants.dart';
import 'package:netease_corekit_im/router/imkit_router_factory.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:netease_corekit_im/services/message/chat_message.dart';
import 'package:netease_corekit_im/services/message/nim_chat_cache.dart';
import 'package:nim_chatkit/message/merge_message.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit_ui/helper/merge_message_helper.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/chat_kit_message_list.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_pop_actions.dart';
import 'package:nim_chatkit_ui/view/page/chat_setting_page.dart';
import 'package:nim_chatkit_ui/view_model/chat_view_model.dart';
import 'package:nim_core/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../chat_kit_client.dart';
import '../../helper/chat_message_helper.dart';
import '../../l10n/S.dart';
import '../../media/audio_player.dart';
import '../input/bottom_input_field.dart';

class ChatPage extends StatefulWidget {
  final String sessionId;

  final NIMSessionType sessionType;

  final NIMMessage? anchor;

  final PopMenuAction? customPopActions;

  final bool Function(ChatMessage message)? onMessageItemClick;

  final bool Function(ChatMessage message)? onMessageItemLongClick;

  final bool Function(String? userID, {bool isSelf})? onTapAvatar;

  final ChatUIConfig? chatUIConfig;

  final ChatKitMessageBuilder? messageBuilder;

  ChatPage(
      {Key? key,
      required this.sessionId,
      required this.sessionType,
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
    ChatMessageRepo.setChattingAccount(widget.sessionId, widget.sessionType);
  }

  ///清除正在聊天的账号
  void _clearChattingAccount() {
    ChatMessageRepo.clearChattingAccountWithId(
        widget.sessionId, widget.sessionType);
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
    //初始化语音播放器
    ChatAudioPlayer.instance.initAudioPlayer();
    ChatKitClient.instance.registerRevokedMessage();
    if (widget.sessionType == NIMSessionType.team) {
      _teamDismissSub =
          NimCore.instance.messageService.onMessage.listen((event) {
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
    if (msg.sessionId == widget.sessionId &&
        msg.messageType == NIMMessageType.notification) {
      NIMTeamNotificationAttachment attachment =
          msg.messageAttachment as NIMTeamNotificationAttachment;
      if (attachment.type == NIMTeamNotificationTypes.dismissTeam &&
          msg.fromAccount != getIt<LoginService>().userInfo?.userId) {
        return true;
      }
    }
    return false;
  }

  ///是否是被踢出群的通知
  bool _isTeamKickedMessageNotify(NIMMessage msg) {
    if (msg.sessionId == widget.sessionId &&
        msg.messageType == NIMMessageType.notification) {
      NIMTeamNotificationAttachment attachment =
          msg.messageAttachment as NIMTeamNotificationAttachment;
      if (attachment.type == NIMTeamNotificationTypes.kickMember) {
        NIMMemberChangeAttachment memberChangeAttachment =
            attachment as NIMMemberChangeAttachment;
        if (memberChangeAttachment.targets
                ?.contains(getIt<LoginService>().userInfo?.userId) ==
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
        Navigator.popUntil(context, ModalRoute.withName('/'));
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
        Navigator.popUntil(context, ModalRoute.withName('/'));
      }
    });
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
    if (NIMChatCache.instance.currentChatSession?.sessionId !=
            widget.sessionId ||
        NIMChatCache.instance.currentChatSession?.sessionType !=
            widget.sessionType) {
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
      return e.status == NIMMessageStatus.fail ||
          e.messageType == NIMMessageType.avchat ||
          e.status == NIMMessageStatus.sending;
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
    ChatMessageHelper.showForwardMessageDialog(context, (sessionId, sessionType,
        {String? postScript, bool? isLastUser}) {
      context.read<ChatViewModel>().mergedMessageForward(sessionId, sessionType,
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
      return e.status == NIMMessageStatus.fail ||
          e.status == NIMMessageStatus.sending ||
          e.messageType == NIMMessageType.avchat ||
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
    ChatMessageHelper.showForwardMessageDialog(context, (sessionId, sessionType,
        {String? postScript, bool? isLastUser}) {
      context.read<ChatViewModel>().forwardMessageOneByOne(
          sessionId, sessionType,
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
    if (NIMChatCache.instance.currentChatSession?.sessionId !=
            widget.sessionId ||
        NIMChatCache.instance.currentChatSession?.sessionType !=
            widget.sessionType) {
      _setChattingAccount();
    }
    return ChangeNotifierProvider(
        create: (context) =>
            ChatViewModel(widget.sessionId, widget.sessionType),
        builder: (context, wg) {
          String title;
          String inputHint = context.watch<ChatViewModel>().chatTitle;
          if (context.watch<ChatViewModel>().isTyping) {
            _setTyping(context);
            title = S.of(context).chatIsTyping;
          } else {
            title = inputHint;
          }
          bool haveSelectedMessage =
              context.watch<ChatViewModel>().selectedMessages.isNotEmpty;
          return WillPopScope(
              child: Scaffold(
                  backgroundColor: Colors.white,
                  appBar: AppBar(
                    leading: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        size: 26,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    centerTitle: true,
                    title: Text(
                      title,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    elevation: 0.5,
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
                                      fontSize: 16,
                                      color: '#333333'.toColor())))
                          : IconButton(
                              onPressed: () {
                                if (widget.sessionType == NIMSessionType.p2p) {
                                  ContactInfo? info =
                                      context.read<ChatViewModel>().contactInfo;
                                  if (info != null) {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                ChatSettingPage(info)));
                                  }
                                } else if (widget.sessionType ==
                                    NIMSessionType.team) {
                                  Navigator.pushNamed(context,
                                      RouterConstants.PATH_TEAM_SETTING_PAGE,
                                      arguments: {
                                        'teamId': widget.sessionId
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
                  ),
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
                                sessionType: widget.sessionType,
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
              onWillPop: () async {
                if (context.read<ChatViewModel>().isMultiSelected) {
                  context.read<ChatViewModel>().isMultiSelected = false;
                  return false;
                }
                return true;
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
