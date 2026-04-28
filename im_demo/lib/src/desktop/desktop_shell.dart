// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/extension.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import 'package:nim_chatkit/repo/conversation_repo.dart';
import 'package:nim_chatkit/repo/team_repo.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit_ui/view/page/chat_collection_message_list_page.dart';
import 'package:nim_chatkit_ui/view/page/chat_page.dart';
import 'package:nim_contactkit_ui/contact_kit_client.dart';
import 'package:nim_contactkit_ui/page/contact_kit_ai_user_list_page.dart';
import 'package:nim_contactkit_ui/page/contact_kit_black_list_page.dart';
import 'package:nim_contactkit_ui/page/contact_kit_friend_list_page.dart';
import 'package:nim_contactkit_ui/page/contact_kit_team_list_page.dart';
import 'package:nim_contactkit_ui/page/contact_kit_verify_message_page.dart';
import 'package:nim_contactkit_ui/page/contact_page.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_conversationkit_ui/page/conversation_page.dart';
import 'package:nim_conversationkit_ui/widgets/conversation_desktop_top_bar.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:nim_searchkit_ui/page/search_kit_search_page.dart';
import 'package:provider/provider.dart';

import '../../l10n/S.dart';
import 'desktop_content_controller.dart';
import 'desktop_more_menu.dart';
import 'desktop_welcome_page.dart';

/// 桌面端 Shell 三栏布局
///
/// 结构：
/// ┌─────────┬────────────────┬──────────────────────────────┐
/// │ Sidebar │   ListPanel    │        ContentPanel           │
/// │  56px   │  274~360px     │        Expanded               │
/// │         │                │                               │
/// │ Avatar  │ ConversationList│ ChatPage / WelcomePage       │
/// │ Nav     │ or ContactList │ or ContactDetailList          │
/// │ Setting │                │                               │
/// └─────────┴────────────────┴──────────────────────────────┘
class DesktopShell extends StatefulWidget {
  const DesktopShell({Key? key}) : super(key: key);

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  final DesktopContentController _controller = DesktopContentController();

  int _chatUnreadCount = 0;
  int _contactUnreadCount = 0;
  int _teamActionsUnreadCount = 0;

  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    // 注册桌面端聊天导航回调，使 goToP2pChat/goToTeamChat 通过状态切换打开聊天
    setDesktopChatNavigator(_controller.navigateToChat);
    _initUnread();
    // 切换到通讯录 tab 时清空通讯录红点
    _controller.addListener(_onNavChanged);
  }

  void _onNavChanged() {
    if (_controller.currentNavIndex == 1 &&
        (_contactUnreadCount > 0 || _teamActionsUnreadCount > 0)) {
      setState(() {
        _contactUnreadCount = 0;
        _teamActionsUnreadCount = 0;
      });
    }
  }

  void _initUnread() {
    // 初始化时读取一次存量未读数
    ConversationRepo.getMsgUnreadCount().then((value) {
      if (value.isSuccess && value.data != null) {
        setState(() {
          _chatUnreadCount = value.data!;
        });
      }
    });

    // 主动 fetch 一次好友申请未读数，保证初始红点正确
    ContactRepo.getAddApplicationUnreadCount();

    // 主动 fetch 一次群操作未读数，保证初始红点正确
    TeamRepo.getTeamActionsUnreadCount();

    // 订阅 SDK 全局未读数变化，保证在非会话 tab 时红点也能实时更新
    // （ConversationPage.onUnreadCountChanged 只在会话 tab 可见时有效）
    _subscriptions.add(
      ConversationRepo.onTotalUnreadCountChanged().listen((count) {
        setState(() {
          _chatUnreadCount = count;
        });
      }),
    );

    // 订阅好友申请未读数变化（由 getAddApplicationUnreadCount 或 SDK 事件推入）
    _subscriptions.add(
      ContactRepo.addApplicationUnreadCountNotifier.listen((count) {
        if (!mounted) return;
        setState(() {
          _contactUnreadCount = count;
        });
      }),
    );

    // 订阅群操作未读数变化
    _subscriptions.add(
      TeamRepo.teamActionsUnreadCountNotifier.listen((count) {
        if (!mounted) return;
        setState(() {
          _teamActionsUnreadCount = count;
        });
      }),
    );

    // 实时监听好友申请事件，收到后重新 fetch 未读数（不依赖 ContactPage 是否挂载）
    _subscriptions.add(
      NimCore.instance.friendService.onFriendAddApplication.listen((_) {
        // 仅在验证消息页未打开时才累加红点
        if (!ContactRepo.isVerifyPageOpen) {
          ContactRepo.getAddApplicationUnreadCount();
        }
      }),
    );

    // 实时监听群申请/邀请事件，收到后重新 fetch 未读数
    _subscriptions.add(
      NimCore.instance.teamService.onReceiveTeamJoinActionInfo.listen((_) {
        TeamRepo.getTeamActionsUnreadCount();
      }),
    );
  }

  @override
  void dispose() {
    clearDesktopChatNavigator();
    _controller.removeListener(_onNavChanged);
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        body: Column(
          children: [
            // 桌面端顶部工具栏：搜索框 + "+" 菜单按钮（仅桌面/Web 端有效）
            ConversationDesktopTopBar(
              onSearchTap: () {
                showDesktopDialog(
                  context,
                  const SearchKitGlobalSearchPage(),
                  width: 480,
                  height: 600,
                );
              },
            ),
            getSwindleWidget(),
            Expanded(
              child: Row(
                children: [
                  // === Sidebar (56px) ===
                  _buildSidebar(),

                  // === ListPanel + ContentPanel（动态布局）===
                  Expanded(
                    child: Consumer<DesktopContentController>(
                      builder: (context, controller, _) {
                        final isCollect = controller.currentNavIndex == 2;
                        return Row(
                          children: [
                            // ListPanel：收藏模式隐藏，使用 Offstage 保持位置固定，
                            // 避免条件渲染导致 Expanded 在 children 中位置变化，
                            // 引发 InheritedWidget _dependents 断言错误
                            Offstage(
                              offstage: isCollect,
                              child: SizedBox(
                                width: 280,
                                child: _buildListPanel(),
                              ),
                            ),
                            Offstage(
                              offstage: isCollect,
                              child: Container(
                                width: 1,
                                color: const Color(0xFFE8EAED),
                              ),
                            ),
                            // ContentPanel：位置始终固定在 children[2]
                            Expanded(child: _buildContentPanel(controller)),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  /// 侧边栏：用户头像 + 导航图标 + 底部设置
  Widget _buildSidebar() {
    return Consumer<DesktopContentController>(
      builder: (context, controller, child) {
        return Container(
          width: 64,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: Color(0xFFE8EAED), width: 1),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // 用户头像
              _buildUserAvatar(),

              const SizedBox(height: 24),

              // 会话导航（红点由 ConversationPage.onUnreadCountChanged 驱动）
              _buildSvgNavItemWithLabel(
                svgNormal: 'assets/ic_chat_desktop.svg',
                svgSelected: 'assets/ic_chat_desktop_selected.svg',
                label: S.of(context).tabChat,
                index: 0,
                isActive: controller.currentNavIndex == 0,
                hasUnread: _chatUnreadCount > 0,
              ),

              const SizedBox(height: 4),

              // 收藏导航
              _buildSvgNavItemWithLabel(
                svgNormal: 'assets/ic_collect_nav.svg',
                svgSelected: 'assets/ic_collect_nav_selected.svg',
                label: S.of(context).mineCollect,
                index: 2,
                isActive: controller.currentNavIndex == 2,
              ),

              const SizedBox(height: 4),

              // 通讯录导航
              _buildSvgNavItemWithLabel(
                svgNormal: 'assets/ic_contact_desktop.svg',
                svgSelected: 'assets/ic_contact_desktop_selected.svg',
                label: S.of(context).contact,
                index: 1,
                isActive: controller.currentNavIndex == 1,
                hasUnread: (_contactUnreadCount + _teamActionsUnreadCount) > 0,
              ),

              const Spacer(),

              // 底部"更多"菜单按钮
              const DesktopMoreMenu(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// 弹出个人信息编辑弹框
  void _showUserProfileDialog() {
    gotoMineInfoPage(context);
  }

  /// 用户头像（点击弹出编辑弹框）
  Widget _buildUserAvatar() {
    final userInfo = IMKitClient.getUserInfo();
    return GestureDetector(
      onTap: _showUserProfileDialog,
      child: Avatar(
        avatar: userInfo?.avatar,
        name: userInfo?.name,
        bgCode: AvatarColor.avatarColor(content: userInfo?.accountId),
        height: 36,
        width: 36,
      ),
    );
  }

  /// 导航项（SVG 图标 + 文字标签，白色侧边栏风格）
  ///
  /// 未选中：图标使用 [svgNormal]，标签颜色 #C5C9D2
  /// 选中：图标使用 [svgSelected]，标签颜色 #2A6BF2
  Widget _buildSvgNavItemWithLabel({
    required String svgNormal,
    required String svgSelected,
    required String label,
    required int index,
    required bool isActive,
    bool hasUnread = false,
    String? package,
  }) {
    const Color selectedColor = Color(0xFF2A6BF2);
    const Color normalColor = Color(0xFFC5C9D2);

    return GestureDetector(
      onTap: () => _controller.switchNav(index),
      child: SizedBox(
        width: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    isActive ? svgSelected : svgNormal,
                    width: 24,
                    height: 24,
                    package: package,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive ? selectedColor : normalColor,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              // 未读红点
              if (hasUnread)
                Positioned(
                  top: 0,
                  right: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 中间列表面板
  Widget _buildListPanel() {
    return Consumer<DesktopContentController>(
      builder: (context, controller, child) {
        if (controller.currentNavIndex == 2) {
          // 收藏模式：列表面板留空（收藏列表在右侧内容面板全展示）
          return const SizedBox.expand();
        }

        if (controller.currentNavIndex == 0) {
          // 会话列表（隐藏 AppBar），拦截点击事件走桌面端内容切换
          // 注意：基于全局 conversationUIConfig.itemConfig 做 copyWith，
          // 否则会覆盖业务方在 HomePage 里设置的 lastMessageContentBuilder
          // 等字段，导致自定义消息摘要、排序规则等全局配置在桌面端失效。
          final globalUIConfig =
              ConversationKitClient.instance.conversationUIConfig;
          return ConversationPage(
            config: globalUIConfig.copyWith(
              titleBarConfig: const ConversationTitleBarConfig(
                showTitleBar: false,
              ),
              itemConfig: globalUIConfig.itemConfig.copyWith(
                itemClick: (data, position) {
                  final conversationId = data.getConversationId();
                  controller.selectConversation(conversationId);
                  return true; // 返回 true 拦截默认的 Navigator.push 导航
                },
                onDeleteConversation: (conversationId) {
                  // 如果删除的是当前选中会话，关闭聊天页并清空选中状态
                  if (controller.currentConversationId == conversationId) {
                    controller.clearContent();
                  }
                },
              ),
            ),
            onUnreadCountChanged: (unreadCount) {
              setState(() {
                _chatUnreadCount = unreadCount;
              });
            },
            // 同步当前选中的会话到左侧列表高亮
            selectedConversationId: controller.currentConversationId,
          );
        } else {
          // 通讯录列表（隐藏 AppBar）—— 桌面端只显示分类菜单
          return ContactPage(
            config: ContactUIConfig(
              contactTitleBarConfig: const ContactTitleBarConfig(
                showTitleBar: false,
              ),
            ),
            onDesktopCategorySelect: (categoryIndex) {
              // categoryIndex: 0=验证消息, 1=黑名单, 2=我的好友, 3=我的群聊, 4=我的数字人
              final categoryMap = {
                0: ContactCategory.verifyMessage,
                1: ContactCategory.blackList,
                2: ContactCategory.myFriends,
                3: ContactCategory.myTeams,
                4: ContactCategory.myAIUsers,
              };
              final category =
                  categoryMap[categoryIndex] ?? ContactCategory.none;
              controller.selectContactCategory(category);
            },
            desktopSelectedCategoryIndex:
                _getCategoryIndex(controller.currentContactCategory),
          );
        }
      },
    );
  }

  /// 将 ContactCategory 枚举转为对应的 categoryIndex
  int? _getCategoryIndex(ContactCategory category) {
    switch (category) {
      case ContactCategory.verifyMessage:
        return 0;
      case ContactCategory.blackList:
        return 1;
      case ContactCategory.myFriends:
        return 2;
      case ContactCategory.myTeams:
        return 3;
      case ContactCategory.myAIUsers:
        return 4;
      case ContactCategory.none:
        return null;
    }
  }

  /// 右侧内容面板（直接接收外层 Consumer 传入的 controller，避免双重 Consumer 嵌套）
  Widget _buildContentPanel(DesktopContentController controller) {
    // 收藏模式：展示收藏消息列表（隐藏返回按钮）
    if (controller.currentNavIndex == 2) {
      return const ChatCollectionMessageListPage(
        key: ValueKey('collection_list'),
        showBack: false,
      );
    }

    // 会话模式下，展示聊天页
    if (controller.currentNavIndex == 0) {
      final conversationId = controller.currentConversationId;
      if (conversationId == null || conversationId.isEmpty) {
        return const DesktopWelcomePage();
      }
      final components =
          conversationId.split(ChatKitUtils.CONVERSATION_ID_SPLIT);
      NIMConversationType conversationType = NIMConversationType.p2p;
      if (components.length == 3) {
        conversationType = ConversationTypeEx.getTypeFromValue(
          int.tryParse(components[1]),
        );
      }
      return ChatPage(
        key: ValueKey(conversationId),
        conversationId: conversationId,
        conversationType: conversationType,
        onQuitTeam: controller.clearContent,
      );
    }

    // 通讯录模式下，根据分类展示不同的列表内容
    return _buildContactContentPanel(controller.currentContactCategory);
  }

  /// 通讯录右侧内容面板 — 根据分类展示不同列表
  Widget _buildContactContentPanel(ContactCategory category) {
    switch (category) {
      case ContactCategory.verifyMessage:
        return const ContactKitSystemNotifyMessagePage(
          key: ValueKey('verify_message'),
        );
      case ContactCategory.blackList:
        return const ContactKitBlackListPage(
          key: ValueKey('black_list'),
        );
      case ContactCategory.myFriends:
        return const ContactKitFriendListPage(
          key: ValueKey('my_friends'),
        );
      case ContactCategory.myTeams:
        return const ContactKitTeamListPage(
          key: ValueKey('my_teams'),
        );
      case ContactCategory.myAIUsers:
        return const ContactKitAIUserListPage(
          key: ValueKey('ai_users'),
        );
      case ContactCategory.none:
        return const DesktopWelcomePage();
    }
  }
}
