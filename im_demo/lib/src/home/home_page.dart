// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:netease_common_ui/duo/duo_page_route.dart';
import 'package:flutter_svg/svg.dart';
import 'package:im_demo/l10n/S.dart';
import 'package:im_demo/src/mine/mine_page.dart';
import 'package:netease_common_ui/duo/duo_shell_controller.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/common_browse_page.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/extension.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import 'package:nim_chatkit/repo/conversation_repo.dart';
import 'package:nim_chatkit/repo/team_repo.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:nim_chatkit_pushkit/nim_chatkit_pushkit.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/helper/duo_layout.dart';
import 'package:nim_chatkit_ui/l10n/S.dart' as chatkit_s;
import 'package:nim_chatkit_ui/media/audio_player.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_item.dart';
import 'package:nim_chatkit_ui/view/input/actions.dart';
import 'package:nim_contactkit_ui/page/contact_page.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_conversationkit_ui/page/conversation_page.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../desktop/desktop_shell.dart';
import '../desktop/desktop_welcome_page.dart';

class HomePage extends StatefulWidget {
  final int pageIndex;

  const HomePage({Key? key, this.pageIndex = 0}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// 当前选择下标
  int currentIndex = 0;

  int chatUnreadCount = 0;
  int contactUnreadCount = 0;
  int teamActionsUnreadCount = 0;

  StreamSubscription? _contactUnreadSub;
  StreamSubscription? _teamActionsUnreadSub;
  StreamSubscription? _pushClickSub;

  /// 是否处于 iPhone Duo 展开（双屏）状态。
  /// 仅在该状态下启用双栏布局与桌面化交互，折叠或普通设备保持 false。
  bool _duoExpanded = false;

  /// 双屏聊天页打开前左侧显示的 Tab，聊天页关闭后恢复。
  int? _duoTabBeforeChat;

  /// 双屏下当前左侧是否因为聊天页而显示会话列表。
  bool _duoChatTabActive = false;

  /// 聊天页切换会话时会短暂清空选中态，延迟恢复左侧 Tab 避免闪回。
  Timer? _duoRestoreTabTimer;

  initUnread() {
    ConversationRepo.getMsgUnreadCount().then((value) {
      if (!mounted) return;
      if (value.isSuccess && value.data != null) {
        setState(() {
          chatUnreadCount = value.data!;
        });
      }
    });
    _contactUnreadSub =
        ContactRepo.addApplicationUnreadCountNotifier.listen((count) {
      if (!mounted) return;
      setState(() {
        contactUnreadCount = count;
      });
    });
    _teamActionsUnreadSub =
        TeamRepo.teamActionsUnreadCountNotifier.listen((count) {
      if (!mounted) return;
      setState(() {
        teamActionsUnreadCount = count;
      });
    });
  }

  void _requestHomeTab(int index) {
    if (!mounted) return;
    if (DuoShellController.instance.enabled) {
      // 这里只切换首页左侧 Tab，不 pop 当前来源页面；调用方随后会
      // 统一清理导航栈并打开聊天页，避免 context 在这里提前失效。
      _switchDuoTab(index);
      return;
    }
    _changePage(index);
  }

  //分发消息，跳转到聊天页面
  void _dispatchPushMessage(PushKitMessage? message) {
    var sessionType = message?.sessionType;
    var sessionId = message?.sessionId;
    if (sessionType?.isNotEmpty == true && sessionId?.isNotEmpty == true) {
      if (sessionType == 'p2p') {
        goToP2pChat(context, sessionId!);
      } else if (sessionType == 'team') {
        goToTeamChat(context, sessionId!);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    currentIndex = widget.pageIndex;
    ChatKitUtils.onHomeTabRequested = _requestHomeTab;
    initUnread();
    DuoShellController.instance.addListener(_onDuoShellChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onDuoShellChanged();
    });
    //注册撤回消息监听
    ChatKitClient.instance.registerRevokedMessage();
    //设置pushPayload
    ChatKitClient.instance.chatUIConfig.getPushPayload =
        PushKit.instance.buildDefaultPushPayload;
    //处理native端传递过来的消息
    if (ChatKitUtils.isMobleClient) {
      _initPushKit();
    }

    // 警告提示栏仅移动端注入，桌面端和 web 端不显示
    if (ChatKitUtils.isMobleClient) {
      ChatKitClient.instance.chatUIConfig.warningWidgetBuilder =
          _buildWarningWidget;
    }
    // todo 以下演示添加自定义消息发送，客户根据自己需求定制
    var messageBuilder = ChatKitMessageBuilder();
    messageBuilder.extendBuilder = {
      NIMMessageType.custom: (NIMMessage msg) {
        return Container(
          child: Text(
            msg.text ?? 'default text',
            style: TextStyle(fontSize: 20, color: Colors.red),
          ),
        );
      },
    };

    // chat config
    ChatKitClient.instance.chatUIConfig.moreActions = [
      ActionItem(
        type: 'custom',
        icon: Icon(Icons.android_outlined),
        title: "自定义",
        onTap: (
          BuildContext context,
          String conversationId,
          NIMConversationType sessionType, {
          NIMMessageSender? messageSender,
        }) async {
          var msg = await MessageCreator.createCustomMessage('自定义消息', '');
          if (msg.isSuccess && msg.data != null) {
            ChatUIToast.show('发送自定义消息！ ');
            messageSender?.call(msg.data!);
          }
        },
      ),
    ];

    ChatKitClient.instance.chatUIConfig.messageBuilder = messageBuilder;

    //如果需要自己设置的更多按钮覆盖默认的，请设置keepDefaultMoreAction = false
    // 默认为true，表示保留默认的更多按钮，包括拍摄，位置，文件
    ChatKitClient.instance.chatUIConfig.keepDefaultMoreAction = true;

    //设置自定义消息在会话列表的展示
    ConversationKitClient.instance.conversationUIConfig = ConversationUIConfig(
      itemConfig: ConversationItemConfig(
        lastMessageContentBuilder: (context, conversationInfo) {
          if (conversationInfo.conversation.lastMessage?.messageType ==
                  NIMMessageType.custom &&
              conversationInfo.conversation.lastMessage?.attachment == null) {
            return S.of(context).customMessage;
          }
          return null;
        },
      ),
    );
    _addLoginListener();
  }

  void _addLoginListener() {
    NimCore.instance.loginService.onKickedOffline.listen((event) {
      //返回根目录
      Navigator.popUntil(context, ModalRoute.withName('/'));
      ChatUIToast.show(S.of(context).kickedOff);
      //被踢下线
      IMKitClient.logoutIM();
    });
  }

  void _initPushKit() {
    PushKit.instance.init();
    _pushClickSub = PushKit.instance.onNotificationClick.listen((message) {
      Alog.d(tag: 'HomePage', content: "PushKit message = ${message.toMap()}");
      _dispatchPushMessage(message);
    });
    PushKit.instance.getInitialNotification().then((message) {
      Alog.d(
        tag: 'HomePage',
        content: "PushKit initial message = ${message?.toMap()}",
      );
      _dispatchPushMessage(message);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 依赖 DuoMediaQuery/MediaQuery，折叠状态或窗口尺寸变化时同步刷新。
    final bool expanded =
        !ChatKitUtils.isDesktopOrWeb && DuoLayout.isExpanded(context);
    if (_duoExpanded == expanded) {
      return;
    }
    _duoExpanded = expanded;
    // 展开态下让路由/详情弹窗走桌面化交互；折叠后立即恢复手机交互。
    ChatKitUtils.setFoldableExpanded(expanded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 折叠/展开只重新布局当前打开的页面，保留右侧抽屉和当前会话。
      DuoShellController.instance.notifyLayoutChanged();
    });
  }

  /// 双屏下聊天页与左侧会话列表成对出现。
  ///
  /// 任一路径打开聊天页时，左侧切换到会话列表并选中当前会话；聊天页关闭后
  /// 恢复进入聊天前的 Tab。折叠单屏、普通 iPhone 不涉及此逻辑。
  void _onDuoShellChanged() {
    if (!mounted) return;
    final DuoShellController shell = DuoShellController.instance;
    final bool chatActive =
        shell.enabled && shell.dual && shell.selectedConversationId != null;
    if (chatActive == _duoChatTabActive) return;
    _duoChatTabActive = chatActive;
    if (chatActive) {
      _duoRestoreTabTimer?.cancel();
      _duoRestoreTabTimer = null;
      _duoTabBeforeChat ??= currentIndex;
      _switchDuoTab(0);
      return;
    }
    // 聊天页之间切换会话时选中态会短暂为空，延迟恢复原 Tab，
    // 避免左侧在会话列表和原 Tab 之间闪一下。
    _duoRestoreTabTimer?.cancel();
    _duoRestoreTabTimer = Timer(const Duration(milliseconds: 150), () {
      _duoRestoreTabTimer = null;
      if (!mounted) return;
      if (DuoShellController.instance.selectedConversationId != null) {
        return;
      }
      final int? restore = _duoTabBeforeChat;
      _duoTabBeforeChat = null;
      if (restore != null) {
        _switchDuoTab(restore);
      }
    });
  }

  /// 切换双屏左侧首页 Tab；构建阶段切换时延后到当前帧结束。
  void _switchDuoTab(int index) {
    if (index == currentIndex) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _switchDuoTab(index);
        }
      });
      return;
    }
    setState(() {
      currentIndex = index;
    });
  }

  /// 本页是否仍是当前活跃首页。
  ///
  /// 语言切换会先创建新的 HomePage、再销毁旧的 HomePage：新首页在
  /// `initState` 里接管 [ChatKitUtils.onHomeTabRequested]，以此判断旧页是否
  /// 已经交出首页归属。
  bool get _isActiveHome => ChatKitUtils.onHomeTabRequested == _requestHomeTab;

  /// 把本页注册为 DuoShell 的首页布局与工具栏回调。
  ///
  /// 只有仍持有 [ChatKitUtils.onHomeTabRequested] 的首页才有资格写入。语言
  /// 切换时旧首页在新首页构建后仍会参与一段路由过渡的构建/布局，如果它继续
  /// 写入，全局 DuoShell 就会持有指向已销毁 State 的闭包，点击右侧工具栏时
  /// 访问 defunct context 直接抛断言。
  void _syncDuoShellLayout({
    required bool dual,
    required double leftWidth,
    required double toolbarWidth,
  }) {
    if (!_isActiveHome) return;
    final shell = DuoShellController.instance;
    shell.onBack = _duoBack;
    shell.updateLayoutSilently(
      enabled: true,
      dual: dual,
      leftWidth: leftWidth,
      toolbarWidth: toolbarWidth,
      onTabSelected: _duoSwitchTab,
    );
    if (shell.currentTab != currentIndex ||
        shell.chatUnreadCount != chatUnreadCount ||
        shell.contactUnreadCount != contactUnreadCount ||
        shell.teamUnreadCount != teamActionsUnreadCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_isActiveHome) return;
        DuoShellController.instance.updateHomeState(
          currentTab: currentIndex,
          chatUnreadCount: chatUnreadCount,
          contactUnreadCount: contactUnreadCount,
          teamUnreadCount: teamActionsUnreadCount,
        );
      });
    }
  }

  /// 撤销本页注册到 DuoShell 的回调。
  ///
  /// 只清理仍指向本页的闭包，保留新首页已经接管的布局和回调，这样旧页
  /// dispose 时既不会让工具栏失效，也不会留下已销毁 State 的闭包。
  void _unregisterDuoShell() {
    final shell = DuoShellController.instance;
    if (shell.onTabSelected == _duoSwitchTab) {
      shell.updateLayoutSilently(
        enabled: shell.enabled,
        dual: shell.dual,
        leftWidth: shell.leftWidth,
        toolbarWidth: shell.toolbarWidth,
        onTabSelected: null,
      );
    }
    if (shell.onBack == _duoBack) {
      shell.onBack = null;
    }
  }

  /// 右侧工具栏默认返回：关闭最上层的抽屉页面。
  void _duoBack() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).maybePop();
  }

  @override
  void dispose() {
    // 语言切换会先创建新的 HomePage、再销毁旧的 HomePage。旧页只能清理
    // 自己仍持有的全局状态，不能把新页已经接管的首页回调、撤回监听、
    // 折叠展开标记和 DuoShell 布局重置掉。
    //
    // 该判断在非 Duo 设备上同样安全：普通 iPhone/Android/桌面端只有一个
    // HomePage，dispose 时回调必然仍指向自己，行为与改动前一致。
    final bool isActiveHome = _isActiveHome;
    if (isActiveHome) {
      ChatKitUtils.onHomeTabRequested = null;
    }
    final shell = DuoShellController.instance;
    shell.removeListener(_onDuoShellChanged);
    _duoRestoreTabTimer?.cancel();
    _duoRestoreTabTimer = null;
    // DuoShell 上绑定的是本 State 的闭包，必须按回调归属清理：语言切换时
    // 旧页会在新首页构建后、销毁前继续参与一段路由过渡，可能最后写入过一次
    // DuoShell；若只按“是否活跃首页”判断就会跳过清理，把已销毁 State 的
    // 闭包留在工具栏上，点击时直接抛 This widget has been unmounted。
    _unregisterDuoShell();
    // 仅当本页仍是活跃首页时才关闭 DuoShell，否则会把新首页已经接管的
    // 布局一起重置，表现为右侧一级导航消失/闪烁。
    if (isActiveHome && shell.enabled) {
      shell.updateLayoutSilently(
        enabled: false,
        dual: false,
        leftWidth: 0,
        toolbarWidth: 0,
        onTabSelected: null,
      );
      shell.notifyLayoutChanged();
    }
    if (isActiveHome && _duoExpanded) {
      ChatKitUtils.setFoldableExpanded(false);
    }
    _contactUnreadSub?.cancel();
    _teamActionsUnreadSub?.cancel();
    _pushClickSub?.cancel();
    if (isActiveHome) {
      ChatKitClient.instance.unregisterRevokedMessage();
    }
    super.dispose();
  }

  Widget _getIcon(Widget tabIcon, {bool showRedPoint = false}) {
    if (!showRedPoint) {
      return tabIcon;
    } else {
      return Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          tabIcon,
          if ((contactUnreadCount + teamActionsUnreadCount) > 0 ||
              chatUnreadCount > 0)
            Positioned(
              top: -2.0,
              right: -3.0,
              child: Offstage(
                offstage: false,
                child: Container(
                  height: 6,
                  width: 6,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 桌面端/Web 使用三栏布局
    if (ChatKitUtils.isDesktopOrWeb) {
      DuoShellController.instance.updateLayoutSilently(
        enabled: false,
        dual: false,
        leftWidth: 0,
        toolbarWidth: 0,
        onTabSelected: null,
      );
      return const DesktopShell();
    }

    final tabs = bottomNavigatorList();

    final bool duoDevice = DuoLayout.isFoldableDevice(context);

    if (duoDevice) {
      if (DuoLayout.isExpanded(context)) {
        // 双屏：左侧固定首页 Tab，右侧抽屉展示二级/三级页面。
        return _buildDuoShell(tabs);
      }
      // 单屏：全屏页面 + 右侧一级导航/页面工具栏，不使用底部 Tab。
      return _buildDuoFoldedShell(tabs);
    }

    DuoShellController.instance.updateLayoutSilently(
      enabled: false,
      dual: false,
      leftWidth: 0,
      toolbarWidth: 0,
      // 路由层从通讯录/搜索打开聊天后，需要把返回基页切回会话列表。
      onTabSelected: _changePage,
    );

    // 其他移动端保持原有 BottomNavigationBar 布局
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: tabs.map((res) => res.widget).toList(),
      ),
      bottomNavigationBar: Theme(
        data: ThemeData(
          brightness: Brightness.light,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: "#F6F8FA".toColor(),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          elevation: 0,
          items: List.generate(
            tabs.length,
            (index) => BottomNavigationBarItem(
              icon: _getIcon(
                index == currentIndex
                    ? tabs[index].selectedIcon
                    : tabs[index].unselectedIcon,
                showRedPoint: (index == 1 &&
                        (contactUnreadCount + teamActionsUnreadCount) > 0) ||
                    (index == 0 && chatUnreadCount > 0),
              ),
              label: tabs[index].title,
            ),
          ),
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            _changePage(index);
          },
        ),
      ),
    ); // end of mobile Scaffold
  }

  /// iPhone Duo 首页：
  /// - 折叠：左侧为当前 Tab 内容，右侧为工具栏；
  /// - 展开：左侧常驻当前 Tab 内容，右侧为欢迎页/抽屉页面，最右侧为工具栏。
  Widget _buildDuoFoldedShell(List<NavigationBarData> tabs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        const double toolbarWidth = 76;
        final double contentWidth = width - toolbarWidth;
        _syncDuoShellLayout(
          dual: false,
          leftWidth: 0,
          toolbarWidth: toolbarWidth,
        );
        return Scaffold(
          backgroundColor: Colors.white,
          body: Row(
            children: [
              SizedBox(
                width: contentWidth,
                child: IndexedStack(
                  index: currentIndex,
                  children: tabs.map((item) => item.widget).toList(),
                ),
              ),
              const SizedBox(width: toolbarWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDuoShell(List<NavigationBarData> tabs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        const double toolbarWidth = 76;
        final double leftWidth = width * 318 / 890;
        _syncDuoShellLayout(
          dual: true,
          leftWidth: leftWidth,
          toolbarWidth: toolbarWidth,
        );
        return Scaffold(
          backgroundColor: Colors.white,
          body: Row(
            children: [
              SizedBox(
                width: leftWidth,
                child: IndexedStack(
                  index: currentIndex,
                  children: tabs.map((item) => item.widget).toList(),
                ),
              ),
              Container(width: 1, color: const Color(0xFFE8EAED)),
              const Expanded(child: DesktopWelcomePage()),
              // 右侧工具栏由 DuoShellOverlay 渲染在 Navigator 之上，
              // 这里只预留宽度，保证工具栏始终可点击。
              SizedBox(width: toolbarWidth),
            ],
          ),
        );
      },
    );
  }

  /// Duo 工具栏切换 Tab：先关闭右侧所有抽屉页面，再切换左侧 Tab。
  void _duoSwitchTab(int index) {
    if (!mounted) {
      // 首页被重建（例如设置里切换语言）后，DuoShell 上可能还残留指向本页
      // 的回调。这里不能访问已销毁 State 的 context，转交给当前活跃首页。
      final ValueChanged<int>? requestTab = ChatKitUtils.onHomeTabRequested;
      if (requestTab != null && requestTab != _requestHomeTab) {
        requestTab(index);
      }
      return;
    }
    Navigator.of(context, rootNavigator: true)
        .popUntil((route) => route.isFirst);
    // 用户主动切换 Tab 时不再恢复聊天前的 Tab。
    _duoRestoreTabTimer?.cancel();
    _duoRestoreTabTimer = null;
    _duoTabBeforeChat = null;
    _duoChatTabActive = false;
    if (index != currentIndex) {
      setState(() {
        currentIndex = index;
      });
    }
    DuoShellController.instance.updateHomeState(
      currentTab: index,
      chatUnreadCount: chatUnreadCount,
      contactUnreadCount: contactUnreadCount,
      teamUnreadCount: teamActionsUnreadCount,
    );
  }

  //如果点击的导航页不是当前项，切换
  void _changePage(int index) {
    if (index != currentIndex) {
      setState(() {
        currentIndex = index;
      });
    }
  }

  List<NavigationBarData> bottomNavigatorList() {
    return getBottomNavigatorList(context);
  }

  /// 聊天页面警告提示栏构建器（仅移动端注入）
  Widget _buildWarningWidget(VoidCallback onClose) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Duo 路由切换瞬间可能短暂继承到很窄的旧面板约束，此时提示栏
        // 的图标、文本和关闭按钮无法同时排布，直接隐藏临时提示，避免
        // 触发 RenderFlex overflow；正常手机宽度不受影响。
        if (constraints.maxWidth.isFinite && constraints.maxWidth < 80) {
          return const SizedBox.shrink();
        }
        return Container(
          // 背景颜色：浅黄色
          color: const Color(0xfffff5e1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧红色警告图标
              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Icon(Icons.error, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 4),
              // 中间可换行的富文本
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xffeb9718),
                    ),
                    children: [
                      TextSpan(
                        text: chatkit_s.S.of(context).chatMessageWarningTips,
                      ),
                      TextSpan(
                        text: chatkit_s.S.of(context).chatMessageTapToReport,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            ChatAudioPlayer.instance.stopAll();
                            const url = 'https://yunxin.163.com/survey/report';
                            Navigator.push(
                              context,
                              DuoPageRoute(
                                builder: (context) => CommonBrowser(url: url),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 右侧关闭图标
              GestureDetector(
                onTap: onClose,
                child: const Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Icon(Icons.close, color: Colors.grey, size: 20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget getSwindleWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      alignment: Alignment.center,
      color: Color(0xfffff5e1),
      child: Text(
        S.of(context).swindleTips,
        style: TextStyle(fontSize: 14, color: Color(0xffeb9718)),
      ),
    );
  }

  List<NavigationBarData> getBottomNavigatorList(BuildContext context) {
    final List<NavigationBarData> bottomNavigatorList = [
      NavigationBarData(
        widget: ConversationPage(
          onUnreadCountChanged: (unreadCount) {
            setState(() {
              chatUnreadCount = unreadCount;
            });
          },
          topWidget: getSwindleWidget(),
        ),
        title: S.of(context).message,
        selectedIcon: SvgPicture.asset(
          'assets/icon_session_selected.svg',
          width: 28,
          height: 28,
        ),
        unselectedIcon: SvgPicture.asset(
          'assets/icon_session_selected.svg',
          width: 28,
          height: 28,
          colorFilter: ColorFilter.mode(
            CommonColors.color_c5c9d2,
            BlendMode.srcIn,
          ),
        ),
      ),
      NavigationBarData(
        widget: const ContactPage(),
        title: S.of(context).contact,
        selectedIcon: SvgPicture.asset(
          'assets/icon_contact_selected.svg',
          width: 28,
          height: 28,
        ),
        unselectedIcon: SvgPicture.asset(
          'assets/icon_contact_unselected.svg',
          width: 28,
          height: 28,
          colorFilter: ColorFilter.mode(
            CommonColors.color_c5c9d2,
            BlendMode.srcIn,
          ),
        ),
      ),
      NavigationBarData(
        widget: const MinePage(),
        title: S.of(context).mine,
        selectedIcon: SvgPicture.asset(
          'assets/icon_my_selected.svg',
          width: 28,
          height: 28,
        ),
        unselectedIcon: SvgPicture.asset(
          'assets/icon_my_selected.svg',
          width: 28,
          height: 28,
          colorFilter: ColorFilter.mode(
            CommonColors.color_c5c9d2,
            BlendMode.srcIn,
          ),
        ),
      ),
    ];

    return bottomNavigatorList;
  }
}

/// 底部导航栏数据对象
class NavigationBarData {
  /// 未选择时候的图标
  final Widget unselectedIcon;

  /// 选择后的图标
  final Widget selectedIcon;

  /// 标题内容
  final String title;

  /// 页面组件
  final Widget widget;

  NavigationBarData({
    required this.unselectedIcon,
    required this.selectedIcon,
    required this.title,
    required this.widget,
  });
}
