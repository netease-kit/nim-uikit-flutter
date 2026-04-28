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
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_conversationkit_ui/widgets/conversation_item.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';

import '../l10n/S.dart';
import '../model/conversation_info.dart';
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
  final ScrollController _scrollController = ScrollController();
  // 顶部AI数字人列表高度
  final double conversationTopListHeight = 84;
  final double conversationTopItemHeight = 75;

  /// 桌面端当前选中的会话 ID（用于选中高亮）
  String? _desktopSelectedConversationId;

  /// 桌面端当前 hover 的会话 ID
  String? _desktopHoveredConversationId;
  // 滚动监听
  void _scrollListener() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 20) {
      context.read<ConversationViewModel>().queryConversationNextList();
    }
  }

  Timer? _scrollEndTimer;

  List<String> _getVisibleP2PUser() {
    List<ConversationInfo> conversationList =
        context.read<ConversationViewModel>().conversationList;
    List<NIMAIUser> aiUserList =
        context.read<ConversationViewModel>().topAIUserList;

    List<String> visibleP2PUser = [];

    if (!_scrollController.hasClients) {
      return visibleP2PUser;
    }

    double scrollOffset = _scrollController.offset;
    double viewportHeight = _scrollController.position.viewportDimension;

    // 计算可见区域
    double visibleStart = scrollOffset;
    double visibleEnd = scrollOffset + viewportHeight;

    // AI用户列表的偏移量
    double currentOffset =
        aiUserList.isNotEmpty ? conversationTopListHeight : 0;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<ConversationInfo> conversationList =
        context.watch<ConversationViewModel>().conversationList;
    List<NIMAIUser> aiUserList =
        context.watch<ConversationViewModel>().topAIUserList;
    var indexPos = aiUserList.length > 0 ? 1 : 0;
    return Stack(
      children: [
        SlidableAutoCloseBehavior(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              // 处理不同类型的滚动通知
              if (notification is ScrollStartNotification ||
                  notification is ScrollUpdateNotification) {
                // 滚动开始或滚动中，取消之前的定时器
                _scrollEndTimer?.cancel();
              } else if (notification is ScrollEndNotification) {
                // 滚动结束，设置定时器，延迟1秒后执行操作
                _scrollEndTimer = Timer(
                  const Duration(milliseconds: 100),
                  _subscribeUserStatus,
                );
              }
              return false; // 不阻止通知继续传递
            },
            child: ListView.builder(
              itemCount: conversationList.length + indexPos,
              // itemExtent: conversationItemHeight,
              itemExtentBuilder: (index, options) {
                if (index == 0 && aiUserList.isNotEmpty) {
                  return conversationTopListHeight;
                }
                return conversationItemHeight;
              },
              controller: _scrollController,
              itemBuilder: (context, index) {
                if (index == 0 && aiUserList.isNotEmpty) {
                  return _buildHorizontalGrid(aiUserList);
                } else {
                  return _buildConversationListItem(
                    conversationList,
                    index - indexPos,
                  );
                }
              },
            ),
          ),
        ),
        if (conversationList.isEmpty) // 条件判断
          Positioned.fill(
            child: Container(
              margin: EdgeInsets.only(top: 180), // 设置距离顶部的 margin
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 0), // 这个 SizedBox 用于保持布局
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
            ),
          ),
      ],
    );
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
