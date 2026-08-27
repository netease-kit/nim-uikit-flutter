// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_conversationkit_ui/widgets/conversation_group_bar.dart';
import 'package:nim_conversationkit_ui/widgets/conversation_group_desktop_panel.dart';
import 'package:nim_conversationkit_ui/widgets/conversation_item.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';

import '../l10n/S.dart';
import '../model/conversation_info.dart';
import '../view_model/conversation_group_view_model.dart';
import '../view_model/conversation_view_model.dart';

class ConversationList extends StatefulWidget {
  const ConversationList({
    Key? key,
    required this.onUnreadCountChanged,
    required this.config,
    this.selectedConversationId,
  }) : super(key: key);

  final ValueChanged<int>? onUnreadCountChanged;
  final ConversationItemConfig config;

  /// 桌面端：外部传入的当前选中会话 ID，用于同步高亮状态
  final String? selectedConversationId;

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends BaseState<ConversationList> {
  // 会话列表每次打开都从顶部开始，避免恢复旧的 PageStorage 滚动位置。
  final ScrollController _scrollController =
      ScrollController(keepScrollOffset: false);
  // 顶部AI数字人列表高度
  final double conversationTopListHeight = 84;
  final double conversationTopItemHeight = 75;
  final double conversationGroupBarHeight = 48;

  /// 桌面端当前选中的会话 ID（用于选中高亮）
  String? _desktopSelectedConversationId;

  /// 桌面端当前 hover 的会话 ID
  String? _desktopHoveredConversationId;

  /// 桌面端分组操作面板是否展开
  bool _desktopGroupPanelExpanded = false;

  bool? _lastShowGroupBar;

  static const String _desktopGroupPanelTapRegion =
      'conversation-group-desktop-panel';
  // 滚动监听
  void _scrollListener() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 20) {
      final groupViewModel = _maybeReadGroupViewModel();
      if (groupViewModel != null) {
        groupViewModel.loadMoreForSelectedGroup();
      } else {
        context.read<ConversationViewModel>().queryConversationNextList();
      }
    }
  }

  Timer? _scrollEndTimer;

  List<String> _getVisibleP2PUser() {
    final groupViewModel = _maybeReadGroupViewModel();
    List<ConversationInfo> conversationList =
        groupViewModel?.displayConversations ??
            context.read<ConversationViewModel>().conversationList;
    List<NIMAIUser> aiUserList =
        context.read<ConversationViewModel>().topAIUserList;
    List<String> visibleP2PUser = [];

    if (!_scrollController.hasClients) {
      return visibleP2PUser;
    }

    double scrollOffset = _scrollController.offset;
    double viewportHeight = _scrollController.position.viewportDimension;

    final showGroupBar = groupViewModel != null &&
        !ChatKitUtils.isDesktopOrWeb &&
        groupViewModel.visibleGroups.isNotEmpty;

    // 移动端数字人列表位于滚动区内，会话项从其之后开始；
    // 桌面端数字人列表固定在滚动区外，不参与偏移计算。
    final isDesktop = ChatKitUtils.isDesktopOrWeb;
    final topListHeight =
        !isDesktop && aiUserList.isNotEmpty ? conversationTopListHeight : 0;

    // 计算可见区域
    double visibleStart = scrollOffset;
    if (showGroupBar && scrollOffset >= topListHeight) {
      visibleStart += conversationGroupBarHeight;
    }
    double visibleEnd = scrollOffset + viewportHeight;

    // 会话项位于数字人列表和吸顶分组栏之后。
    double currentOffset =
        topListHeight + (showGroupBar ? conversationGroupBarHeight : 0);

    for (int i = 0; i < conversationList.length; i++) {
      ConversationInfo conversation = conversationList[i];

      // 计算当前会话项的位置
      double itemTop = currentOffset;
      double itemBottom = currentOffset + conversationItemHeight;

      // 检查是否在可见区域内
      bool isVisible = itemBottom > visibleStart && itemTop < visibleEnd;

      if (conversation.conversation.type == NIMConversationType.p2p &&
          isVisible) {
        visibleP2PUser.add(conversation.targetId);
      }

      currentOffset += conversationItemHeight;
    }

    return visibleP2PUser;
  }

  @override
  void initState() {
    super.initState();
    _desktopSelectedConversationId = widget.selectedConversationId;
    _scrollController.addListener(_scrollListener);
    // 首帧后强制从顶部开始，兜底任何历史 offset 恢复路径。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ConversationList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部传入的选中会话 ID 变化时，同步到内部状态
    if (widget.selectedConversationId != oldWidget.selectedConversationId &&
        widget.selectedConversationId != null) {
      setState(() {
        _desktopSelectedConversationId = widget.selectedConversationId;
      });
    }
  }

  void _subscribeUserStatus() {
    List<String> users = _getVisibleP2PUser();
    context.read<ConversationViewModel>().subscribeUserStatusByIds(users);
  }

  @override
  void dispose() {
    _scrollEndTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupViewModel = _maybeWatchGroupViewModel();
    List<ConversationInfo> conversationList =
        groupViewModel?.displayConversations ??
            context.watch<ConversationViewModel>().conversationList;
    List<NIMAIUser> aiUserList =
        context.watch<ConversationViewModel>().topAIUserList;
    final showAIUserList = aiUserList.isNotEmpty;
    final showGroupBar = groupViewModel != null &&
        !ChatKitUtils.isDesktopOrWeb &&
        groupViewModel.visibleGroups.isNotEmpty;
    final showDesktopGroupBar = groupViewModel != null &&
        ChatKitUtils.isDesktopOrWeb &&
        groupViewModel.visibleGroups.isNotEmpty;
    if (showGroupBar && _lastShowGroupBar != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToTop();
        }
      });
    }
    _lastShowGroupBar = showGroupBar;
    if (showDesktopGroupBar) {
      return _buildDesktopConversationLayout(
        conversationList: conversationList,
        aiUserList: aiUserList,
      );
    }
    return _buildConversationScroll(
      conversationList: conversationList,
      aiUserList: aiUserList,
      showAIUserList: showAIUserList,
      showGroupBar: showGroupBar,
    );
  }

  Widget _buildDesktopConversationLayout({
    required List<ConversationInfo> conversationList,
    required List<NIMAIUser> aiUserList,
  }) {
    final showAIUserList = aiUserList.isNotEmpty;
    return Stack(
      children: [
        Positioned.fill(
          top: conversationGroupBarHeight,
          child: _buildConversationScroll(
            conversationList: conversationList,
            aiUserList: aiUserList,
            showAIUserList: showAIUserList,
            showGroupBar: false,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: conversationGroupBarHeight,
          child: ConversationGroupBar(
            isDesktop: true,
            isPanelExpanded: _desktopGroupPanelExpanded,
            onPanelToggle: _toggleDesktopGroupPanel,
            onGroupSelected: _collapseDesktopGroupPanel,
            panelTapRegionGroupId: _desktopGroupPanelTapRegion,
            onPanelTapOutside: (_) => _collapseDesktopGroupPanel(),
          ),
        ),
        if (_desktopGroupPanelExpanded)
          Positioned(
            top: 0,
            left: 0,
            bottom: 0,
            width: 220,
            child: TapRegion(
              groupId: _desktopGroupPanelTapRegion,
              child: ConversationGroupDesktopPanel(
                onCollapse: _collapseDesktopGroupPanel,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConversationScroll({
    required List<ConversationInfo> conversationList,
    required List<NIMAIUser> aiUserList,
    required bool showAIUserList,
    required bool showGroupBar,
  }) {
    final isDesktop = ChatKitUtils.isDesktopOrWeb;
    // 桌面端：数字人列表固定在滚动区外顶部；
    // 移动端：数字人列表作为普通 sliver 随内容滚动（不吸顶），仅分组栏吸顶。
    final fixedTopWidgets = <Widget>[
      if (isDesktop && showAIUserList) _buildHorizontalGrid(aiUserList),
    ];
    if (conversationList.isEmpty) {
      return SlidableAutoCloseBehavior(
        child: Column(
          children: [
            ...fixedTopWidgets,
            if (!isDesktop && showAIUserList) _buildHorizontalGrid(aiUserList),
            if (showGroupBar)
              ConversationGroupBar(
                onGroupSelected: _scrollToTop,
              ),
            Expanded(
              child: _buildEmptyState(0),
            ),
          ],
        ),
      );
    }
    final scrollBody = NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        // 处理不同类型的滚动通知
        if (notification is ScrollStartNotification ||
            notification is ScrollUpdateNotification) {
          _scrollEndTimer?.cancel();
        } else if (notification is ScrollEndNotification) {
          _scrollEndTimer = Timer(
            const Duration(milliseconds: 100),
            _subscribeUserStatus,
          );
        }
        return false;
      },
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 数字人列表随内容滚动，不吸顶
          if (!isDesktop && showAIUserList)
            SliverToBoxAdapter(
              child: _buildHorizontalGrid(aiUserList),
            ),
          if (showGroupBar)
            SliverPersistentHeader(
              pinned: true,
              delegate: _ConversationGroupHeaderDelegate(
                height: conversationGroupBarHeight,
                child: ConversationGroupBar(
                  onGroupSelected: _scrollToTop,
                ),
              ),
            ),
          SliverFixedExtentList(
            itemExtent: conversationItemHeight,
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildConversationListItem(
                conversationList,
                index,
              ),
              childCount: conversationList.length,
            ),
          ),
        ],
      ),
    );
    return SlidableAutoCloseBehavior(
      child: Column(
        children: [
          ...fixedTopWidgets,
          Expanded(child: scrollBody),
        ],
      ),
    );
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients || _scrollController.offset == 0) {
      return;
    }
    _scrollController.jumpTo(0);
  }

  Widget _buildEmptyState(double topMargin) {
    return Container(
      margin: EdgeInsets.only(top: topMargin),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 0),
          SvgPicture.asset(
            'images/ic_search_empty.svg',
            package: kPackage,
          ),
          Padding(
            padding: EdgeInsets.only(top: 18),
            child: Text(
              S.of(context).conversationEmpty,
              style: TextStyle(
                color: CommonColors.color_b3b7bc,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(child: Container(), flex: 1),
        ],
      ),
    );
  }

  void _toggleDesktopGroupPanel() {
    setState(() {
      _desktopGroupPanelExpanded = !_desktopGroupPanelExpanded;
    });
  }

  void _collapseDesktopGroupPanel() {
    if (!_desktopGroupPanelExpanded) {
      return;
    }
    setState(() {
      _desktopGroupPanelExpanded = false;
    });
  }

  ConversationGroupViewModel? _maybeReadGroupViewModel() {
    if (!IMKitConfigCenter.enableConversationGroup) {
      return null;
    }
    try {
      return context.read<ConversationGroupViewModel>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  ConversationGroupViewModel? _maybeWatchGroupViewModel() {
    if (!IMKitConfigCenter.enableConversationGroup) {
      return null;
    }
    try {
      return context.watch<ConversationGroupViewModel>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  // 构建置顶AI数字人列表
  Widget _buildHorizontalGrid(List<NIMAIUser> aiUserList) {
    return Container(
      height: conversationTopListHeight, // 可以根据需要调整GridView的高度
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: conversationTopItemHeight, // 网格整体高度
            child: Padding(
              padding: EdgeInsets.only(top: 8, left: 12, right: 12),
              child: ListView.builder(
                //使用ListView.builder构建，可以避免GrideView在ListView中出现高度问题
                scrollDirection: Axis.horizontal,
                itemCount: aiUserList.length,
                itemBuilder: (context, gridIndex) {
                  return InkWell(
                    // 使用InkWell添加点击效果
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      // 点击事件处理
                      goToP2pChat(context, aiUserList[gridIndex].accountId!);
                    },
                    child: Container(
                      width: 67,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 图片容器
                          Avatar(
                            avatar: aiUserList[gridIndex].avatar ?? '',
                            name: aiUserList[gridIndex].name,
                            bgCode: AvatarColor.avatarColor(
                              content: aiUserList[gridIndex].accountId,
                            ),
                            height: 42,
                            width: 42,
                            radius: widget.config.avatarCornerRadius,
                          ),
                          Container(height: 6),
                          Text(
                            aiUserList[gridIndex].name ?? '',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: widget.config.itemTitleColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            height: 1,
            margin: EdgeInsets.only(top: 8),
            color: CommonColors.color_e9eff5,
          ),
        ],
      ),
    );
  }

  // 构建会话列表项
  Widget _buildConversationListItem(
    List<ConversationInfo> conversationList,
    int index,
  ) {
    ConversationInfo conversationInfo = conversationList[index];

    // 桌面端/Web端：使用右键菜单 + hover + 选中高亮，跳过 Slidable
    if (ChatKitUtils.isDesktopOrWeb) {
      return _buildDesktopConversationItem(conversationInfo, index);
    }

    // 移动端：保持原有 Slidable 逻辑
    return Slidable(
      child: InkWell(
        child: widget.config.customItemBuilder != null
            ? widget.config.customItemBuilder!(conversationInfo, index)
            : ConversationItem(
                conversationInfo: conversationInfo,
                config: widget.config,
                index: index,
              ),
        onLongPress: () {
          if (widget.config.itemLongClick != null &&
              widget.config.itemLongClick!(conversationInfo, index)) {
            return;
          }
        },
        onTap: () {
          if (widget.config.itemClick != null &&
              widget.config.itemClick!(conversationInfo, index)) {
            return;
          }
          goToChatPage(
            context,
            conversationInfo.getConversationId(),
            conversationInfo.getConversationType(),
          );
        },
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              //提前判断网络
              if (!checkNetwork()) {
                return;
              }
              if (conversationInfo.isStickTop()) {
                context.read<ConversationViewModel>().removeStick(
                      conversationInfo,
                    );
              } else {
                context.read<ConversationViewModel>().addStickTop(
                      conversationInfo,
                    );
              }
            },
            backgroundColor: CommonColors.color_337eff,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            label: conversationInfo.isStickTop()
                ? S.of(context).cancelStickTitle
                : S.of(context).stickTitle,
          ),
          SlidableAction(
            onPressed: (context) {
              //提前判断网络
              if (!checkNetwork()) {
                return;
              }
              final deletedId = conversationInfo.getConversationId();
              context.read<ConversationViewModel>().deleteConversation(
                    conversationInfo,
                    clearMessageHistory:
                        widget.config.clearMessageWhenDeleteSession,
                  );
              widget.config.onDeleteConversation?.call(deletedId);
            },
            backgroundColor: CommonColors.color_a8abb6,
            foregroundColor: Colors.white,
            label: S.of(context).deleteTitle,
          ),
        ],
      ),
    );
  }

  /// 桌面端会话列表项：带 hover 效果、选中高亮和右键菜单
  Widget _buildDesktopConversationItem(
    ConversationInfo conversationInfo,
    int index,
  ) {
    final conversationId = conversationInfo.getConversationId();
    final isSelected = _desktopSelectedConversationId == conversationId;
    final isHovered = _desktopHoveredConversationId == conversationId;

    // 计算背景色优先级：选中 > hover > 置顶 > 默认
    Color backgroundColor;
    if (isSelected) {
      backgroundColor = const Color(0xFFD6E4FF); // 选中蓝色
    } else if (isHovered) {
      backgroundColor = const Color(0xFFF0F0F0); // hover 浅灰
    } else if (conversationInfo.isStickTop()) {
      backgroundColor = const Color(0xFFEDEDEF); // 置顶灰色
    } else {
      backgroundColor = Colors.white;
    }

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _desktopHoveredConversationId = conversationId;
        });
      },
      onExit: (_) {
        setState(() {
          if (_desktopHoveredConversationId == conversationId) {
            _desktopHoveredConversationId = null;
          }
        });
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _desktopSelectedConversationId = conversationId;
          });
          if (widget.config.itemClick != null &&
              widget.config.itemClick!(conversationInfo, index)) {
            return;
          }
          goToChatPage(
            context,
            conversationInfo.getConversationId(),
            conversationInfo.getConversationType(),
          );
        },
        onSecondaryTapUp: (details) {
          _showDesktopContextMenu(
            details.globalPosition,
            conversationInfo,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: backgroundColor,
          child: Stack(
            children: [
              widget.config.customItemBuilder != null
                  ? widget.config.customItemBuilder!(conversationInfo, index)
                  : ConversationItem(
                      conversationInfo: conversationInfo,
                      config: widget.config,
                      index: index,
                    ),
              // 左侧选中指示条
              if (isSelected)
                Positioned(
                  left: 0,
                  top: 12,
                  bottom: 12,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF337EFF),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 桌面端右键菜单
  void _showDesktopContextMenu(
    Offset position,
    ConversationInfo conversationInfo,
  ) {
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'stick',
          child: Row(
            children: [
              conversationInfo.isStickTop()
                  ? SvgPicture.asset(
                      'images/ic_top_cancel.svg',
                      width: 24,
                      height: 24,
                      package: kPackage,
                    )
                  : SvgPicture.asset(
                      'images/ic_top.svg',
                      package: kPackage,
                      width: 24,
                      height: 24,
                    ),
              const SizedBox(width: 8),
              Text(
                conversationInfo.isStickTop()
                    ? S.of(context).cancelStickTitle
                    : S.of(context).stickTitle,
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'mute',
          child: Row(
            children: [
              conversationInfo.isMute()
                  ? SvgPicture.asset(
                      'images/ic_notify.svg',
                      package: kPackage,
                      width: 24,
                      height: 24,
                    )
                  : SvgPicture.asset(
                      'images/ic_mute.svg',
                      package: kPackage,
                      width: 24,
                      height: 24,
                    ),
              const SizedBox(width: 8),
              Text(
                conversationInfo.isMute()
                    ? S.of(context).cancelMuteTitle
                    : S.of(context).muteTitle,
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              SvgPicture.asset(
                'images/ic_delete.svg',
                package: kPackage,
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              Text(
                S.of(context).deleteTitle,
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              ),
            ],
          ),
        ),
      ],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ).then((value) {
      if (value == null) return;
      if (!checkNetwork()) return;

      switch (value) {
        case 'stick':
          if (conversationInfo.isStickTop()) {
            context.read<ConversationViewModel>().removeStick(conversationInfo);
          } else {
            context.read<ConversationViewModel>().addStickTop(conversationInfo);
          }
          break;
        case 'mute':
          context.read<ConversationViewModel>().muteConversation(
                conversationInfo,
                !conversationInfo.isMute(),
              );
          break;
        case 'delete':
          final deletedId = conversationInfo.getConversationId();
          context.read<ConversationViewModel>().deleteConversation(
                conversationInfo,
                clearMessageHistory:
                    widget.config.clearMessageWhenDeleteSession,
              );
          // 如果删除的是当前选中的会话，清除选中状态
          if (_desktopSelectedConversationId == deletedId) {
            setState(() {
              _desktopSelectedConversationId = null;
            });
          }
          widget.config.onDeleteConversation?.call(deletedId);
          break;
      }
    });
  }
}

class _ConversationGroupHeaderDelegate extends SliverPersistentHeaderDelegate {
  _ConversationGroupHeaderDelegate({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Colors.white,
      elevation: overlapsContent ? 1 : 0,
      child: SizedBox.expand(
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ConversationGroupHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
