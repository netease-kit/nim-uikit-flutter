// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../chat_kit_client.dart';
import '../../helper/chat_message_helper.dart';
import '../../l10n/S.dart';
import 'item/chat_history_video_message_item.dart';

class ChatHistoryVideoMessagePage extends StatefulWidget {
  final String conversationId;
  final NIMConversationType conversationType;

  const ChatHistoryVideoMessagePage({
    Key? key,
    required this.conversationId,
    required this.conversationType,
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
        pageToken: _pageToken);

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
    return TransparentScaffold(
      title: S.of(context).chatQuickSearchVideo,
      body: RefreshIndicator(
        onRefresh: () => _loadMoreOld(initial: false),
        child: _buildList(),
      ),
    );
  }

  Widget _buildList() {
    if (_historyMessages.isEmpty && !_isLoading) {
      return ListView(
        children: [
          Column(
            children: [
              const SizedBox(
                height: 68,
              ),
              SvgPicture.asset(
                'images/ic_list_empty.svg',
                package: kPackage,
              ),
              const SizedBox(
                height: 18,
              ),
              Text(
                S.of(context).chatSearchVideoMessageEmpty,
                style: TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
              )
            ],
          )
        ],
      );
    }

    final grouped = _groupByDate(_historyMessages);
    final dates = grouped.keys.toList(); // 已按时间升序

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
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
                  left: 20, right: 20, top: 12, bottom: 8),
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
            child: CircularProgressIndicator(strokeWidth: 2)),
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
    final currentYearFormatter =
        DateFormat(S.of(context).chatHistoryDateFormatMonthDay, 'zh');
    final otherYearFormatter =
        DateFormat(S.of(context).chatHistoryDateFormaYearMonthDay, 'zh');

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

  Widget _buildVideoItem(NIMMessage message) {
    return GestureDetector(
        onLongPress: () {
          _showOptionDialog(context, message);
        },
        child: ChatHistoryVideoMessageItem(message: message));
  }

  void _showOptionDialog(BuildContext context, NIMMessage message) {
    var style = const TextStyle(fontSize: 16, color: CommonColors.color_333333);
    //将弹框的context 回调出来，解决弹框显示后Item remove的问题
    BuildContext? buildContext;
    showBottomChoose<int>(
        context: context,
        actions: [
          CupertinoActionSheetAction(
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop(1);
                } else if (buildContext != null) {
                  Navigator.pop(buildContext!);
                }
              },
              child: Text(
                S.of(context).chatHistoryOrientation,
                style: style,
              )),
          CupertinoActionSheetAction(
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop(2);
                } else if (buildContext != null) {
                  Navigator.pop(buildContext!);
                }
              },
              child: Text(
                S.of(context).chatMessageActionForward,
                style: style,
              )),
        ],
        contextCb: (context) {
          buildContext = context;
        }).then((value) {
      if (value == 1) {
        goToChatAndKeepHome(
            context, message.conversationId!, message.conversationType!,
            message: message);
      } else if (value == 2) {
        showForwardMessageDialog(context, message);
      }
    });
  }
}
