// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/router/imkit_router_constants.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_conversationkit_ui/widgets/conversation_item.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';

import '../l10n/S.dart';
import '../model/conversation_info.dart';
import '../view_model/conversation_view_model.dart';

class ConversationList extends StatefulWidget {
  const ConversationList(
      {Key? key, required this.onUnreadCountChanged, required this.config})
      : super(key: key);

  final ValueChanged<int>? onUnreadCountChanged;
  final ConversationItemConfig config;

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends BaseState<ConversationList> {
  final ScrollController _scrollController = ScrollController();
  // 顶部AI数字人列表高度
  final double conversationTopListHeight = 81;
  final double conversationTopItemHeight = 72;
  // 滚动监听
  void _scrollListener() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 20) {
      context.read<ConversationViewModel>().queryConversationNextList();
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
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
                    conversationList, index - indexPos);
              }
            },
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
                          color: CommonColors.color_b3b7bc, fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: Container(),
                    flex: 1,
                  ),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
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
                          goToP2pChat(
                              context, aiUserList[gridIndex].accountId!);
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
                                      content: aiUserList[gridIndex].accountId),
                                  height: 42,
                                  width: 42,
                                  radius: widget.config.avatarCornerRadius,
                                ),
                                Container(
                                  height: 6,
                                ),
                                Text(
                                  aiUserList[gridIndex].name ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                      color: widget.config.itemTitleColor,
                                      fontSize: 12),
                                ),
                              ],
                            )));
                  })),
        ),
        Container(
          height: 1,
          margin: EdgeInsets.only(top: 8),
          color: CommonColors.color_e9eff5,
        ),
      ]),
    );
  }

  // 构建置顶AI数字人列表
  Widget _buildConversationListItem(
      List<ConversationInfo> conversationList, int index) {
    ConversationInfo conversationInfo = conversationList[index];
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
          Navigator.pushNamed(context, RouterConstants.PATH_CHAT_PAGE,
              arguments: {
                'conversationId': conversationInfo.getConversationId(),
                'conversationType': conversationInfo.getConversationType()
              });
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
                context
                    .read<ConversationViewModel>()
                    .removeStick(conversationInfo);
              } else {
                context
                    .read<ConversationViewModel>()
                    .addStickTop(conversationInfo);
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
              context.read<ConversationViewModel>().deleteConversation(
                  conversationInfo,
                  clearMessageHistory:
                      widget.config.clearMessageWhenDeleteSession);
            },
            backgroundColor: CommonColors.color_a8abb6,
            foregroundColor: Colors.white,
            label: S.of(context).deleteTitle,
          )
        ],
      ),
    );
  }
}
