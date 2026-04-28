// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../chat_kit_client.dart';
import '../../l10n/S.dart';
import 'chat_history_locate_menu.dart';
import 'history_message_item.dart';

/// 历史消息搜索结果列表（关键字搜索/日期搜索/成员搜索均复用此组件）
class HistorySearchResult extends StatefulWidget {
  final List<NIMMessage>? searchResult;
  final String keyword;

  final String? teamId;

  final String conversationId;

  final NIMConversationType conversationType;

  final ContactInfo? contactInfo;

  final VoidCallback? onLoadMore;
  final bool isLoading;
  final bool hasMore;

  /// 桌面/Web 端右键"定位到消息"的回调（移动端不使用）
  final void Function(NIMMessage)? onLocateMessage;

  /// 嵌入模式下关闭面板的回调（桌面/Web 端定位时使用）
  final VoidCallback? onClose;

  HistorySearchResult({
    this.searchResult,
    required this.keyword,
    required this.conversationId,
    Key? key,
    this.teamId,
    this.contactInfo,
    required this.conversationType,
    this.onLoadMore,
    this.isLoading = false,
    this.hasMore = true,
    this.onLocateMessage,
    this.onClose,
  }) : super(key: key);

  @override
  State<HistorySearchResult> createState() => _HistorySearchResultState();
}

class _HistorySearchResultState extends State<HistorySearchResult> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      widget.onLoadMore?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.searchResult == null || widget.searchResult?.isEmpty == true
        ? (widget.isLoading
            ? Container()
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'images/ic_list_empty.svg',
                      package: kPackage,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      S.of(context).messageSearchEmpty,
                      style: TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
                    ),
                  ],
                ),
              ))
        : ListView.builder(
            controller: _scrollController,
            itemCount: widget.searchResult!.length + 1,
            itemBuilder: (context, index) {
              if (index == widget.searchResult!.length) {
                return _buildFooter();
              }
              NIMMessage item = widget.searchResult![index];
              final isDesktopOrWeb = ChatKitUtils.isDesktopOrWeb;

              // 桌面/Web 端右键弹出"定位到原始消息"菜单，左键无响应
              if (isDesktopOrWeb) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onSecondaryTapUp: (details) {
                    ChatHistoryLocateMenu(
                      context: context,
                      globalPosition: details.globalPosition,
                      onLocate: () {
                        widget.onClose?.call();
                        widget.onLocateMessage?.call(item);
                      },
                    ).show();
                  },
                  child: HistoryMessageItem(
                    item,
                    widget.keyword,
                    contactInfo: widget.contactInfo,
                  ),
                );
              }

              // 移动端（或桌面端文件消息）：左键点击触发定位
              return InkWell(
                onTap: () async {
                  if (isDesktopOrWeb) {
                    // 桌面端文件消息保持原有逻辑
                    widget.onLocateMessage?.call(item);
                  } else {
                    goToChatAndKeepHome(
                      context,
                      widget.conversationId,
                      widget.conversationType,
                      message: item,
                    );
                  }
                },
                child: HistoryMessageItem(
                  item,
                  widget.keyword,
                  contactInfo: widget.contactInfo,
                ),
              );
            },
          );
  }

  Widget _buildFooter() {
    if (widget.isLoading) {
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
    if (!widget.hasMore && widget.searchResult?.isNotEmpty == true) {
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
}
