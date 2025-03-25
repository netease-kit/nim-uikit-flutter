// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_corekit_im/router/imkit_router_constants.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_conversationkit_ui/widgets/conversation_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

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
    return conversationList.isNotEmpty
        ? SlidableAutoCloseBehavior(
            child: ListView.builder(
                itemCount: conversationList.length,
                itemExtent: conversationItemHeight,
                controller: _scrollController,
                itemBuilder: (context, index) {
                  ConversationInfo conversationInfo = conversationList[index];
                  return Slidable(
                    child: InkWell(
                      child: widget.config.customItemBuilder != null
                          ? widget.config.customItemBuilder!(
                              conversationInfo, index)
                          : ConversationItem(
                              conversationInfo: conversationInfo,
                              config: widget.config,
                              index: index,
                            ),
                      onLongPress: () {
                        if (widget.config.itemLongClick != null &&
                            widget.config.itemLongClick!(
                                conversationInfo, index)) {
                          return;
                        }
                      },
                      onTap: () {
                        if (widget.config.itemClick != null &&
                            widget.config.itemClick!(conversationInfo, index)) {
                          return;
                        }
                        Navigator.pushNamed(
                            context, RouterConstants.PATH_CHAT_PAGE,
                            arguments: {
                              'conversationId':
                                  conversationInfo.getConversationId(),
                              'conversationType':
                                  conversationInfo.getConversationType()
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
                            context
                                .read<ConversationViewModel>()
                                .deleteConversation(conversationInfo,
                                    clearMessageHistory: widget
                                        .config.clearMessageWhenDeleteSession);
                          },
                          backgroundColor: CommonColors.color_a8abb6,
                          foregroundColor: Colors.white,
                          label: S.of(context).deleteTitle,
                        )
                      ],
                    ),
                  );
                }),
          )
        : Column(
            children: [
              SizedBox(
                height: 170,
              ),
              SvgPicture.asset(
                'images/ic_search_empty.svg',
                package: kPackage,
              ),
              Padding(
                padding: EdgeInsets.only(top: 18),
                child: Text(
                  S.of(context).conversationEmpty,
                  style:
                      TextStyle(color: CommonColors.color_b3b7bc, fontSize: 14),
                ),
              ),
              Expanded(
                child: Container(),
                flex: 1,
              ),
            ],
          );
  }
}
