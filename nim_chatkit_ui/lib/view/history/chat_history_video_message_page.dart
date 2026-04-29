// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../chat_kit_client.dart';
import '../../helper/chat_message_helper.dart';
import '../../l10n/S.dart';
import 'chat_history_locate_menu.dart';
import 'item/chat_history_video_message_item.dart';

class ChatHistoryVideoMessagePage extends StatefulWidget {
  final String conversationId;
  final NIMConversationType conversationType;

  /// 嵌入模式：为 true 时不渲染 Scaffold/AppBar，仅返回内容区域
  final bool isEmbedded;

  /// 桌面/Web 端"定位到聊天"回调
  final void Function(NIMMessage)? onLocateMessage;

  /// 嵌入模式下关闭面板的回调（桌面/Web 端定位时使用）
  final VoidCallback? onClose;

  const ChatHistoryVideoMessagePage({
    Key? key,
    required this.conversationId,
    required this.conversationType,
    this.isEmbedded = false,
    this.onLocateMessage,
    this.onClose,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ChatHistoryVideoMessagePageState();
  }
}

class ChatHistoryVideoMessagePageState
    extends BaseState<ChatHistoryVideoMessagePage> {
  final ScrollController _scrollController = ScrollController();
  final List<NIMMessage> _historyMessages = [];

  // 分页参数
  String _pageToken = '';
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMoreOld(initial: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMoreOld({bool initial = false}) async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
    });

    NIMMessageSearchExParams params = NIMMessageSearchExParams(
      conversationId: widget.conversationId,
      messageTypes: [NIMMessageType.video],
      direction: NIMSearchDirection.V2NIM_SEARCH_DIRECTION_BACKWARD,
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
      _hasMore = result.data!.hasMore;
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
    final content = RefreshIndicator(
      onRefresh: () => _loadMoreOld(initial: false),
      child: _buildList(),
    );
    if (widget.isEmbedded) {
      return content;
    }
    return TransparentScaffold(
      title: S.of(context).chatQuickSearchVideo,
      body: content,
    );
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
                S.of(context).chatSearchVideoMessageEmpty,
                style: TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
              ),
            ],
          ),
        ],
      );
    }

    final grouped = _groupByDate(_historyMessages);
    final dates = grouped.keys.toList(); // 已按时间升序

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(bottom: 8),
      reverse: true,
      shrinkWrap: true,
      itemCount: dates.length + 1,
      itemBuilder: (context, index) {
        if (index == dates.length) {
          return _buildFooter();
        }
        final date = dates[index];
        final messages = grouped[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: 8,
              ),
              child: Text(
                date,
                style: const TextStyle(
                  fontSize: 14,
                  color: CommonColors.color_333333,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              reverse: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
                childAspectRatio: 1.0,
              ),
              itemCount: messages.length,
              itemBuilder: (context, msgIndex) {
                return _buildVideoItem(messages[msgIndex]);
              },
            ),
          ],
        );
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
    if (!_hasMore && _historyMessages.isNotEmpty == true) {
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

  Map<String, List<NIMMessage>> _groupByDate(List<NIMMessage> list) {
    final map = LinkedHashMap<String, List<NIMMessage>>();
    final now = DateTime.now();
    final currentYearFormatter = DateFormat(
      S.of(context).chatHistoryDateFormatMonthDay,
      'zh',
    );
    final otherYearFormatter = DateFormat(
      S.of(context).chatHistoryDateFormaYearMonthDay,
      'zh',
    );

    for (final msg in list) {
      final date = DateTime.fromMillisecondsSinceEpoch(msg.createTime!.toInt());
      String key;
      if (date.year == now.year) {
        key = currentYearFormatter.format(date);
      } else {
        key = otherYearFormatter.format(date);
      }
      map.putIfAbsent(key, () => []);
      map[key]!.add(msg);
    }
    return map;
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
            message.conversationId!,
            message.conversationType!,
            message: message,
          );
        }
      },
    ).show();
  }

  Widget _buildVideoItem(NIMMessage message) {
    // 桌面/Web 端：右键弹出"定位到原始消息"菜单，左键无响应
    // 用透明遮罩覆盖视频 item，避免内部组件消耗右键事件
    if (ChatKitUtils.isDesktopOrWeb) {
      return Stack(
        children: [
          ChatHistoryVideoMessageItem(message: message),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onSecondaryTapUp: (d) =>
                  _showLocateMenu(context, d.globalPosition, message),
            ),
          ),
        ],
      );
    }

    // 移动端：长按弹底部菜单
    return GestureDetector(
      onLongPress: () {
        _showOptionDialog(context, message);
      },
      child: ChatHistoryVideoMessageItem(message: message),
    );
  }

  void _showOptionDialog(BuildContext context, NIMMessage message) {
    showAdaptiveChoose<int>(
      context: context,
      items: [
        AdaptiveChooseItem(
          label: S.of(context).chatHistoryOrientation,
          value: 1,
        ),
        AdaptiveChooseItem(
          label: S.of(context).chatMessageActionForward,
          value: 2,
        ),
      ],
    ).then((value) {
      if (value == 1) {
        goToChatAndKeepHome(
          context,
          message.conversationId!,
          message.conversationType!,
          message: message,
        );
      } else if (value == 2) {
        showForwardMessageDialog(context, message);
      }
    });
  }
}
