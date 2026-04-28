// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/common_browse_page.dart';
import 'package:netease_common_ui/widgets/no_network_tip.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/message/merge_message.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/router/imkit_router.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit/services/message/nim_chat_cache.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
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
import '../history/chat_history_message_page.dart';
import '../input/bottom_input_field.dart';
import 'chat_pin_page.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;

  final NIMConversationType conversationType;

  final NIMMessage? anchor;

  final int? anchorDate;

  final PopMenuAction? customPopActions;

  final bool Function(ChatMessage message)? onMessageItemClick;

  final bool Function(ChatMessage message)? onMessageItemLongClick;

  final bool Function(String? userID, {bool isSelf})? onTapAvatar;

  final ChatUIConfig? chatUIConfig;

  final ChatKitMessageBuilder? messageBuilder;

  /// 桌面端退群/解散群成功后的回调（用于关闭聊天页并清空选中会话）
  final VoidCallback? onQuitTeam;

  ChatPage({
    Key? key,
    required this.conversationId,
    required this.conversationType,
    this.anchor,
    this.customPopActions,
    this.onTapAvatar,
    this.chatUIConfig,
    this.messageBuilder,
    this.onMessageItemClick,
    this.anchorDate,
    this.onMessageItemLongClick,
    this.onQuitTeam,
  }) : super(key: key);

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

  /// 桌面端：当前激活的右侧面板
  _ActivePanel _activePanel = _ActivePanel.none;

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
    ChatAudioPlayer.instance.stopAll();
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
      null,
      widget.conversationType,
      widget.conversationId,
    );
  }

  Future<String> getSessionId(String conversationId) async {
    return (await NimCore.instance.conversationIdUtil.conversationTargetId(
      conversationId,
    ))
        .data!;
  }

  ///清除正在聊天的账号
  void _clearChattingAccount() async {
    ChatMessageRepo.clearChattingAccountWithId(
      null,
      widget.conversationType,
      widget.conversationId,
    );
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
      IMKitRouter.instance.routeObserver.subscribe(
        this,
        ModalRoute.of(context)!,
      );
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
        if (attachment.targetIds?.contains(
              getIt<IMLoginService>().userInfo?.accountId,
            ) ==
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
      showNavigate: false,
    ).then((value) {
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
      showNavigate: false,
    ).then((value) {
      if (value == true) {
        _onTeamDismissOrKicked();
      }
    });
  }

  ///踢出群后的处理逻辑
  void _onTeamDismissOrKicked() {
    // 优先使用 chatUIConfig 的回调（移动端自定义场景）
    if (widget.chatUIConfig?.onTeamDismissOrLeave?.call() == true) {
      return;
    }
    // 桌面端三栏布局中，ChatPage 不是独立的 Navigator 路由，
    // 而是 Widget 树中的子节点，无法通过 Navigator.popUntil 退出。
    // onQuitTeam 是桌面端传入的 clearContent 回调，
    // 调用后右侧内容面板回到欢迎页，会话列表取消选中。
    if (widget.onQuitTeam != null) {
      widget.onQuitTeam!();
      return;
    }
    // 移动端回退到根路由（正常的 Navigator.push 场景）
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
      ChatUIToast.show(
        S
            .of(context)
            .chatMessageMergedForwardLimitOut(mergedMessageLimit.toString()),
        context: context,
      );
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
          e.messageType == NIMMessageType.call ||
          e.sendingState == NIMMessageSendingState.sending;
    }).toList();
    if (cannotMergeMessage.isNotEmpty) {
      showCommonDialog(
        context: context,
        content: S.of(context).chatMessageHaveCannotForwardMessages,
      ).then((value) {
        if (value == true) {
          context.read<ChatViewModel>().removeSelectedMessages(
                cannotMergeMessage,
              );
        }
      });
      return;
    }
    if (context.read<ChatViewModel>().selectedMessages.isEmpty) {
      return;
    }

    // 处理合并转发
    var sessionName = context.read<ChatViewModel>().chatTitle;
    ChatMessageHelper.showForwardSelector(
      context,
      (conversationId, {String? postScript, bool? isLastUser}) {
        context.read<ChatViewModel>().mergedMessageForward(
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
    //判断网络
    if (!checkNetwork()) {
      return;
    }
    var selectedMessages = context.read<ChatViewModel>().selectedMessages;
    if (selectedMessages.length > forwardMessageLimit) {
      ChatUIToast.show(
        S
            .of(context)
            .chatMessageForwardOneByOneLimitOut(forwardMessageLimit.toString()),
        context: context,
      );
      return;
    }

    //判断有不能转发的消息
    // 1. 消息发送失败
    // 2. 消息正在发送
    // 3. 消息是语音消息
    var cannotMergeMessage = selectedMessages.where((e) {
      return e.sendingState == NIMMessageSendingState.failed ||
          e.sendingState == NIMMessageSendingState.sending ||
          e.messageType == NIMMessageType.call ||
          e.messageType == NIMMessageType.audio;
    }).toList();
    if (cannotMergeMessage.isNotEmpty) {
      showCommonDialog(
        context: context,
        content: S.of(context).chatMessageHaveCannotForwardMessages,
      ).then((value) {
        if (value == true) {
          context.read<ChatViewModel>().removeSelectedMessages(
                cannotMergeMessage,
              );
        }
      });
      return;
    }
    if (context.read<ChatViewModel>().selectedMessages.isEmpty) {
      return;
    }
    var sessionName = context.read<ChatViewModel>().chatTitle;
    ChatMessageHelper.showForwardSelector(
      context,
      (conversationId, {String? postScript, bool? isLastUser}) {
        context.read<ChatViewModel>().forwardMessageOneByOne(
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
    //提前判断网络
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
          context.read<ChatViewModel>().deleteMessageOneByOne(),
      },
    );
  }

  Widget getSwindleWidget(BuildContext context) {
    return chatUIConfig!.warningWidgetBuilder!(() {
      context.read<ChatViewModel>().showWarningTips = false;
    });
  }

  // ignore: unused_element
  Widget _defaultSwindleWidget(BuildContext context) {
    return Container(
      // 背景颜色：浅黄色
      color: const Color(0xfffff5e1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐，适应多行文字
        children: [
          // 左侧红色警告图标
          const Padding(
            padding: EdgeInsets.only(top: 2.0), // 微调图标位置以对齐文字
            child: Icon(Icons.error, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 4), // 间距
          // 中间可换行的富文本
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xffeb9718)),
                children: [
                  TextSpan(text: S.of(context).chatMessageWarningTips),
                  TextSpan(
                    text: S.of(context).chatMessageTapToReport,
                    style: const TextStyle(
                      color: Colors.blue, // 蓝色字体
                      fontWeight: FontWeight.bold,
                    ),
                    // 点击事件识别器
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        //点击逻辑
                        ChatAudioPlayer.instance.stopAll();
                        String url = 'https://yunxin.163.com/survey/report';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommonBrowser(url: url),
                          ),
                        );
                      },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8), // 间距
          // 右侧关闭图标
          GestureDetector(
            onTap: () {
              context.read<ChatViewModel>().showWarningTips = false;
            },
            child: const Padding(
              padding: EdgeInsets.only(top: 2.0),
              child: Icon(Icons.close, color: Colors.grey, size: 20),
            ),
          ),
        ],
      ),
    );
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
      create: (context) => ChatViewModel(
        widget.conversationId,
        widget.conversationType,
        anchorMessage: widget.anchor,
        findAnchorDate: widget.anchorDate,
        chatUIConfig: chatUIConfig,
      ),
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
              ChatKitUtils.getConversationTargetId(widget.conversationId),
            )) {
          title = inputHint;

          subTitle = isOnline == true
              ? S.of(context).chatUserOnline
              : S.of(context).chatUserOffline;
        } else {
          title = inputHint;
        }
        bool haveSelectedMessage =
            context.watch<ChatViewModel>().selectedMessages.isNotEmpty;

        Widget? subTitleWidget = context.watch<ChatViewModel>().voiceFromSpeaker
            ? null
            : SvgPicture.asset(
                "images/ic_ear.svg",
                package: kPackage,
                width: 18,
                height: 18,
              );

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
        final bool isDesktop = ChatKitUtils.isDesktopOrWeb;
        return PopScope(
          child: isDesktop
              ? Scaffold(
                  backgroundColor: Colors.white,
                  body: Column(
                    children: [
                      _buildDesktopHeader(
                        context,
                        title,
                        subTitle,
                        subTitleWidget,
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            // 底层：聊天内容区域 + 侧边栏
                            Row(
                              children: [
                                Expanded(
                                  child: _buildChatBody(
                                    context,
                                    inputHint,
                                    haveSelectedMessage,
                                  ),
                                ),
                                _buildDesktopSidebar(context),
                              ],
                            ),
                            // 覆盖层：右侧面板（浮动在聊天区域上方，不挤占空间）
                            if (_activePanel != _ActivePanel.none)
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: _closeActivePanel,
                                  child: Row(
                                    children: [
                                      // 左侧透明区域可点击关闭面板
                                      Expanded(
                                          child: Container(
                                              color: Colors.transparent)),
                                      // 右侧面板本体（357px）
                                      GestureDetector(
                                        onTap: () {}, // 阻止点击穿透到关闭手势
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          curve: Curves.easeOut,
                                          width: 357.0,
                                          child:
                                              _buildActivePanelContent(context),
                                        ),
                                      ),
                                      // 侧边栏宽度占位（防止面板遮挡侧边栏按钮）
                                      const SizedBox(width: 52),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : TransparentScaffold(
                  backgroundColor: Colors.white,
                  centerTitle: true,
                  title: title,
                  subTitle: subTitle,
                  subTitleWidget: subTitleWidget,
                  elevation: 0,
                  actions: [
                    _buildMobileAction(context),
                  ],
                  body: _buildChatBody(
                    context,
                    inputHint,
                    haveSelectedMessage,
                  ),
                ),
          canPop: context.watch<ChatViewModel>().isMultiSelected != true,
          onPopInvokedWithResult: (bool didPop, result) async {
            if (context.read<ChatViewModel>().isMultiSelected) {
              context.read<ChatViewModel>().isMultiSelected = false;
            }
          },
        );
      },
    );
  }

  /// 桌面端顶部标题栏
  Widget _buildDesktopHeader(
    BuildContext context,
    String title,
    String? subTitle,
    Widget? subTitleWidget,
  ) {
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
            child: Row(
              children: [
                Flexible(
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
                if (subTitle != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      subTitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: '#999999'.toColor(),
                      ),
                    ),
                  ),
                if (subTitleWidget != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: subTitleWidget,
                  ),
              ],
            ),
          ),
          // 桌面端多选模式下的取消按钮
          if (context.watch<ChatViewModel>().isMultiSelected)
            TextButton(
              onPressed: () {
                context.read<ChatViewModel>().isMultiSelected = false;
              },
              child: Text(
                S.of(context).messageCancel,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  color: '#333333'.toColor(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 桌面端右侧操作侧边栏（52px，三按钮）
  Widget _buildDesktopSidebar(BuildContext context) {
    final bool isMultiSelected = context.watch<ChatViewModel>().isMultiSelected;
    return Container(
      width: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: const Color(0xFFE4E9F2), width: 1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // 设置按钮
          _DesktopSidebarButton(
            normalIconPath: 'images/ic_chat_desktop_setting.svg',
            selectedIconPath: 'images/ic_chat_desktop_setting_selected.svg',
            isSelected: _activePanel == _ActivePanel.settings,
            enable: !isMultiSelected,
            onTap: () => _togglePanel(_ActivePanel.settings),
          ),
          const SizedBox(height: 25),
          // 查找聊天内容按钮
          _DesktopSidebarButton(
            normalIconPath: 'images/ic_chat_desktop_history.svg',
            selectedIconPath: 'images/ic_chat_desktop_history_selected.svg',
            isSelected: _activePanel == _ActivePanel.search,
            enable: !isMultiSelected,
            onTap: () => _togglePanel(_ActivePanel.search),
          ),
          const SizedBox(height: 25),
          // 标记消息按钮
          _DesktopSidebarButton(
            normalIconPath: 'images/ic_chat_desktop_pin.svg',
            selectedIconPath: 'images/ic_chat_desktop_pin_selected.svg',
            isSelected: _activePanel == _ActivePanel.pin,
            enable: !isMultiSelected,
            onTap: () => _togglePanel(_ActivePanel.pin),
          ),
        ],
      ),
    );
  }

  /// 切换右侧面板（点击已激活面板则折叠，否则切换）
  void _togglePanel(_ActivePanel panel) {
    ChatAudioPlayer.instance.stopAll();
    setState(() {
      if (_activePanel == panel) {
        _activePanel = _ActivePanel.none;
      } else {
        // 切换时重置面板内 Navigator 历史栈
        if (_activePanel != _ActivePanel.none) {
          _panelNavigatorKey.currentState?.popUntil((r) => r.isFirst);
        }
        _activePanel = panel;
      }
    });
  }

  /// 关闭当前激活面板
  void _closeActivePanel() {
    setState(() {
      _activePanel = _ActivePanel.none;
    });
  }

  /// 兼容旧代码引用
  void _closeSettingsPanel() => _closeActivePanel();

  /// 面板内嵌 Navigator 的 key，用于二级页面在面板内部路由
  final GlobalKey<NavigatorState> _panelNavigatorKey =
      GlobalKey<NavigatorState>();

  /// 根据当前激活面板分发内容
  Widget _buildActivePanelContent(BuildContext context) {
    if (_activePanel == _ActivePanel.none) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          left: BorderSide(color: Color(0xFFE4E9F2), width: 1),
        ),
      ),
      child: Navigator(
        key: _panelNavigatorKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (innerContext) {
              switch (_activePanel) {
                case _ActivePanel.settings:
                  return _buildSettingsPanelRoot(innerContext);
                case _ActivePanel.search:
                  // Task 10.2: 传入 onLocateMessage 回调，桌面端定位到聊天面板中的消息
                  return ChatHistoryMessagePage(
                    conversationId: widget.conversationId,
                    conversationType: widget.conversationType,
                    isEmbedded: true,
                    onClose: _closeActivePanel,
                    onLocateMessage: (msg) async {
                      // 先关闭搜索面板，等待关闭动画完成后再触发定位
                      _closeActivePanel();
                      await Future.delayed(const Duration(milliseconds: 300));
                      if (mounted) {
                        context
                            .read<ChatViewModel>()
                            .loadMessageWithAnchor(msg);
                      }
                    },
                  );
                case _ActivePanel.pin:
                  return ChatPinPage(
                    conversationId: widget.conversationId,
                    conversationType: widget.conversationType,
                    chatTitle: context.read<ChatViewModel>().chatTitle,
                    isEmbedded: true,
                    onClose: _closeActivePanel,
                    chatUIConfig: chatUIConfig,
                    onLocateMessage: (msg) async {
                      // 先关闭 Pin 面板，等待关闭动画完成后再触发定位
                      _closeActivePanel();
                      await Future.delayed(const Duration(milliseconds: 300));
                      if (mounted) {
                        context
                            .read<ChatViewModel>()
                            .loadMessageWithAnchor(msg);
                      }
                    },
                  );
                case _ActivePanel.none:
                  return const SizedBox.shrink();
              }
            },
            settings: settings,
          );
        },
      ),
    );
  }

  /// 构建桌面端设置面板内容（内嵌 Navigator 以支持二级页面，兼容旧逻辑）
  Widget _buildSettingsPanel(BuildContext context) {
    return ClipRect(
      child: Navigator(
        key: _panelNavigatorKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (innerContext) => _buildSettingsPanelRoot(innerContext),
            settings: settings,
          );
        },
      ),
    );
  }

  /// 设置面板的根页面内容
  Widget _buildSettingsPanelRoot(BuildContext innerContext) {
    if (widget.conversationType == NIMConversationType.p2p) {
      ContactInfo? info = innerContext.read<ChatViewModel>().contactInfo;
      if (info != null) {
        return ChatSettingPage(
          info,
          widget.conversationId,
          isDesktopDialog: true,
          onClose: _closeSettingsPanel,
        );
      }
      return const SizedBox.shrink();
    } else if (widget.conversationType == NIMConversationType.team) {
      final teamSettingBuilder = chatUIConfig?.teamSettingPanelBuilder;
      if (teamSettingBuilder != null) {
        final teamId = ChatKitUtils.getConversationTargetId(
          widget.conversationId,
        );
        return teamSettingBuilder(
            teamId, _closeSettingsPanel, widget.onQuitTeam);
      }
      // 没有配置 builder 时，fallback 到空面板
      return Material(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              height: 48,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE8E8E8),
                    width: 0.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    S.of(innerContext).chatSetting,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const Spacer(),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _closeSettingsPanel,
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  /// 移动端 AppBar action
  Widget _buildMobileAction(BuildContext context) {
    return context.watch<ChatViewModel>().isMultiSelected
        ? TextButton(
            onPressed: () {
              context.read<ChatViewModel>().isMultiSelected = false;
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
            onPressed: () async {
              ChatAudioPlayer.instance.stopAll();
              if (widget.conversationType == NIMConversationType.p2p) {
                ContactInfo? info = context.read<ChatViewModel>().contactInfo;
                if (info != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatSettingPage(
                        info,
                        widget.conversationId,
                      ),
                    ),
                  );
                }
              } else if (widget.conversationType == NIMConversationType.team) {
                goToTeamSettingPage(
                  context,
                  await getSessionId(widget.conversationId),
                ).then((value) {
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
            ),
          );
  }

  /// 聊天主体内容（桌面和移动端共享）
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
            if (!ChatKitUtils.isDesktopOrWeb && !hasNetWork) NoNetWorkTip(),
            if (context.watch<ChatViewModel>().showWarningTips)
              getSwindleWidget(context),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!context.read<ChatViewModel>().isMultiSelected) {
                    _inputField.currentState.hideAllPanel();
                  }
                },
                child: ChatKitMessageList(
                  scrollController: autoController,
                  popMenuAction: widget.customPopActions ??
                      chatUIConfig?.messageClickListener?.customPopActions,
                  anchor: widget.anchor,
                  anchorDate: widget.anchorDate,
                  messageBuilder:
                      widget.messageBuilder ?? chatUIConfig?.messageBuilder,
                  onTapAvatar: (String? userId, {bool isSelf = false}) {
                    if (context.read<ChatViewModel>().isMultiSelected) {
                      return true;
                    }
                    if (widget.onTapAvatar != null &&
                        widget.onTapAvatar!(userId, isSelf: isSelf)) {
                      return true;
                    }
                    if (chatUIConfig?.messageClickListener?.onTapAvatar !=
                            null &&
                        chatUIConfig!.messageClickListener!.onTapAvatar!(userId,
                            isSelf: isSelf)) {
                      return true;
                    }
                    _defaultAvatarTap(userId, isSelf: isSelf);
                    return true;
                  },
                  onAvatarLongPress: (userId, {isSelf = false}) {
                    if (context.read<ChatViewModel>().isMultiSelected) {
                      return true;
                    }
                    if (chatUIConfig?.messageClickListener?.onLongPressAvatar !=
                            null &&
                        chatUIConfig!.messageClickListener!.onLongPressAvatar!(
                          userId,
                          isSelf: isSelf,
                        )) {
                      return true;
                    }
                    return _defaultAvatarLongPress(
                      userId,
                      isSelf: isSelf,
                    );
                  },
                  chatUIConfig: chatUIConfig,
                  teamInfo: context.watch<ChatViewModel>().teamInfo,
                  onMessageItemClick: widget.onMessageItemClick ??
                      chatUIConfig?.messageClickListener?.onMessageItemClick,
                  onMessageItemLongClick: widget.onMessageItemLongClick ??
                      chatUIConfig
                          ?.messageClickListener?.onMessageItemLongClick,
                ),
              ),
            ),
            if (context.watch<ChatViewModel>().isMultiSelected)
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
            Visibility(
              visible: !context.watch<ChatViewModel>().isMultiSelected,
              maintainState: true,
              child: BottomInputField(
                scrollController: autoController,
                conversationType: widget.conversationType,
                conversationId: widget.conversationId,
                hint: S.of(context).chatMessageSendHint(inputHint),
                chatUIConfig: chatUIConfig,
                key: _inputField,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class BottomOption extends StatelessWidget {
  final String icon;

  final String label;

  final Function()? onTap;

  final bool enable;

  const BottomOption({
    Key? key,
    required this.icon,
    required this.label,
    this.onTap,
    this.enable = true,
  }) : super(key: key);

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
          SvgPicture.asset(icon, package: kPackage, width: 48, height: 48),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              decoration: TextDecoration.none,
              fontSize: 14,
              color: '#666666'.toColor(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 桌面端右侧面板枚举
enum _ActivePanel { none, settings, search, pin }

/// 桌面端侧边栏按钮（带 hover 效果、禁用状态和 Selected 态）
class _DesktopSidebarButton extends StatefulWidget {
  final String? normalIconPath;
  final String? selectedIconPath;
  final bool isSelected;
  final bool enable;
  final VoidCallback onTap;

  const _DesktopSidebarButton({
    this.normalIconPath,
    this.selectedIconPath,
    this.isSelected = false,
    required this.enable,
    required this.onTap,
  });

  @override
  State<_DesktopSidebarButton> createState() => _DesktopSidebarButtonState();
}

class _DesktopSidebarButtonState extends State<_DesktopSidebarButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.isSelected
        ? const Color(0xFFD7E4FF)
        : (_hovering && widget.enable
            ? const Color(0x1A337EFF)
            : Colors.transparent);

    final String iconPath =
        (widget.isSelected && widget.selectedIconPath != null)
            ? widget.selectedIconPath!
            : (widget.normalIconPath ?? '');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor:
          widget.enable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.enable ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Opacity(
            opacity: widget.enable ? 1.0 : 0.4,
            child: iconPath.isNotEmpty
                ? SvgPicture.asset(
                    iconPath,
                    package: kPackage,
                    width: 24,
                    height: 24,
                  )
                : const Icon(Icons.settings, size: 20),
          ),
        ),
      ),
    );
  }
}
