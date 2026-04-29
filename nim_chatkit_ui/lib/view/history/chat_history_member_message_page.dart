// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../chat_kit_client.dart';
import '../../helper/chat_message_helper.dart';
import '../../helper/chat_message_user_helper.dart';
import '../../l10n/S.dart';
import 'chat_history_locate_menu.dart';

class ChatHistoryMemberMessagePage extends StatefulWidget {
  final String conversationId;

  final NIMConversationType conversationType;

  final String sendId;

  final NIMTeam? teamInfo;

  /// 是否嵌入在面板内（隐藏系统 AppBar，改用自定义标题栏）
  final bool isEmbedded;

  /// Task 4.2: 嵌入模式下点击返回按钮时的回调（非导航，通知父组件处理返回逻辑）
  final VoidCallback? onBack;

  /// 桌面/Web 端"定位到聊天"回调
  final void Function(NIMMessage)? onLocateMessage;

  /// 嵌入模式下关闭面板的回调（桌面/Web 端定位时使用）
  final VoidCallback? onClose;

  const ChatHistoryMemberMessagePage({
    Key? key,
    required this.conversationId,
    required this.sendId,
    required this.conversationType,
    this.teamInfo,
    this.isEmbedded = false,
    this.onBack,
    this.onLocateMessage,
    this.onClose,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ChatHistoryMemberMessagePageState();
  }
}

class ChatHistoryMemberMessagePageState
    extends BaseState<ChatHistoryMemberMessagePage> {
  final ScrollController _scrollController = ScrollController();
  final List<NIMMessage> _historyMessages = [];

  // 分页参数
  String? _pageToken;
  bool _isLoading = false;
  bool _hasMore = true;

  final int _pageSize = 100;

  UserAvatarInfo? currentUserAvatarInfo;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadMoreOld(initial: true);
  }

  @override
  void didUpdateWidget(covariant ChatHistoryMemberMessagePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 桌面/Web 嵌入模式下切换群成员时，sendId 会变化，需要重置并重新加载
    if (oldWidget.sendId != widget.sendId ||
        oldWidget.conversationId != widget.conversationId) {
      _historyMessages.clear();
      _pageToken = null;
      _isLoading = false;
      _hasMore = true;
      currentUserAvatarInfo = null;
      _loadMoreOld(initial: true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      _loadMoreOld();
    }
  }

  Future<void> _loadMoreOld({bool initial = false}) async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
    });

    NIMMessageSearchExParams params = NIMMessageSearchExParams(
      conversationId: widget.conversationId,
      senderAccountIds: [widget.sendId],
      direction: NIMSearchDirection.V2NIM_SEARCH_DIRECTION_BACKWARD,
      limit: _pageSize,
      pageToken: _pageToken,
    );

    if ((await IMKitClient.enableCloudMessageSearch) && !checkNetwork()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final result = await ChatMessageRepo.searchMessageEx(params);

    if (result.isSuccess && result.data != null) {
      final items = result.data!.items ?? [];
      // 按时间升序放入列表头部，旧消息在上，新消息在下
      for (var item in items) {
        if (item.conversationId == widget.conversationId) {
          _historyMessages.addAll(item.messages ?? []);
        }
      }
      _hasMore = result.data!.hasMore && (result.data!.count ?? 0) >= _pageSize;
      _pageToken = result.data!.nextPageToken ?? '';
    } else {
      _hasMore = false;
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final listBody = Column(children: [Expanded(child: _buildList())]);

    if (widget.isEmbedded) {
      return Material(
        color: Colors.white,
        child: Column(
          children: [
            Expanded(child: listBody),
          ],
        ),
      );
    }

    return TransparentScaffold(
      title: S.of(context).chatHistorySearchByMember,
      backgroundColor: Colors.white,
      body: listBody,
    );
  }

  Future<UserAvatarInfo?> _getMemberAvatarInfo() async {
    if (currentUserAvatarInfo != null) return currentUserAvatarInfo;
    final teamId = ChatKitUtils.getConversationTargetId(widget.conversationId);
    currentUserAvatarInfo = await getUserAvatarInfoInTeam(
      teamId,
      widget.sendId,
    );
    return currentUserAvatarInfo;
  }

  Widget _buildList() {
    if (_historyMessages.isEmpty && !_isLoading) {
      return ListView(
        children: [
          Column(
            children: [
              const SizedBox(height: 68),
              SvgPicture.asset('images/ic_list_empty.svg', package: kPackage),
              const SizedBox(height: 18),
              Text(
                S.of(context).messageSearchEmpty,
                style: TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
              ),
            ],
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: _historyMessages.length + 1,
      itemBuilder: (context, index) {
        if (index == _historyMessages.length) {
          return _buildFooter();
        }
        return _buildMessageItem(_historyMessages[index]);
      },
    );
  }

  Widget _buildFooter() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (!_hasMore && _historyMessages.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: Text(
          S.of(context).chatHistoryMessageNotAnyMore,
          style: TextStyle(fontSize: 12, color: CommonColors.color_999999),
        ),
      );
    }
    return Container();
  }

  void _showLocateMenu(
      BuildContext context, Offset globalPos, NIMMessage message) {
    ChatHistoryLocateMenu(
      context: context,
      globalPosition: globalPos,
      onLocate: () {
        widget.onClose?.call();
        if (widget.onLocateMessage != null) {
          widget.onLocateMessage!(message);
        } else {
          goToChatAndKeepHome(
            context,
            widget.conversationId,
            widget.conversationType,
            message: message,
          );
        }
      },
    ).show();
  }

  Widget _buildMessageItem(NIMMessage message) {
    // 桌面/Web 端：右键弹出"定位到原始消息"菜单，左键无响应
    // 移动端：左键点击直接定位
    final isDesktopOrWeb = ChatKitUtils.isDesktopOrWeb;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapUp: isDesktopOrWeb
          ? (d) => _showLocateMenu(context, d.globalPosition, message)
          : null,
      child: InkWell(
        // 保留 hover 高亮效果
        onTap: isDesktopOrWeb
            ? null
            : () {
                goToChatAndKeepHome(
                  context,
                  widget.conversationId,
                  widget.conversationType,
                  message: message,
                );
              },
        hoverColor: const Color(0xFFF6F8FA),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: FutureBuilder<UserAvatarInfo>(
            future: _getUserAvatarInfo(message),
            builder: (context, snapshot) {
              final userInfo = snapshot.data;
              final timeStr = message.createTime != null
                  ? getFormatTime(message.createTime!.toInt(), context)
                  : '';
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 发送者头像 32×32
                  Avatar(
                    avatar: userInfo?.avatar,
                    name: userInfo?.avatarName,
                    height: 32,
                    width: 32,
                    radius: 16,
                    bgCode: AvatarColor.avatarColor(content: widget.sendId),
                  ),
                  const SizedBox(width: 12),
                  // 中间：昵称 + 消息摘要
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                userInfo?.name ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: CommonColors.color_333333,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // 发送时间（右对齐）
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // 消息内容摘要（点击后定位到消息）
                        buildHistoryMessage(
                          context,
                          message,
                          teamInfo: widget.teamInfo,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ), // FutureBuilder
        ), // Container
      ), // InkWell
    ); // GestureDetector
  }

  Future<UserAvatarInfo> _getUserAvatarInfo(NIMMessage message) async {
    if (message.aiConfig?.aiStatus == NIMMessageAIStatus.response &&
        AIUserManager.instance.isAIUser(message.aiConfig?.accountId)) {
      final aiUser = AIUserManager.instance.getAIUserById(
        message.aiConfig!.accountId!,
      );
      return UserAvatarInfo(
        aiUser!.name ?? aiUser.accountId!,
        avatarName: aiUser.name,
        avatar: aiUser.avatar,
      );
    }
    if (currentUserAvatarInfo != null) {
      return currentUserAvatarInfo!;
    }

    var teamId = ChatKitUtils.getConversationTargetId(message.conversationId!);
    currentUserAvatarInfo = await getUserAvatarInfoInTeam(
      teamId,
      message.senderId!,
    );
    return currentUserAvatarInfo!;
  }
}
