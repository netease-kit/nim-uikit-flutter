// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_common_ui/router/imkit_router_constants.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_conversationkit/model/conversation_info.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_conversationkit_ui/widgets/conversation_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../generated/l10n.dart';
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

class _ConversationListState extends State<ConversationList> {
  @override
  Widget build(BuildContext context) {
    List<ConversationInfo> conversationList =
        context.watch<ConversationViewModel>().conversationList;
    return conversationList.isNotEmpty
        ? SlidableAutoCloseBehavior(
            child: ListView.builder(
                itemCount: conversationList.length,
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
                              'sessionId': conversationInfo.session.sessionId,
                              'sessionType':
                                  conversationInfo.session.sessionType
                            });
                      },
                    ),
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (context) {
                            if (conversationInfo.isStickTop) {
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
                          label: conversationInfo.isStickTop
                              ? S.of(context).cancel_stick_title
                              : S.of(context).stick_title,
                        ),
                        SlidableAction(
                          onPressed: (context) {
                            context
                                .read<ConversationViewModel>()
                                .deleteConversation(conversationInfo);
                          },
                          backgroundColor: CommonColors.color_a8abb6,
                          foregroundColor: Colors.white,
                          label: S.of(context).delete_title,
                        )
                      ],
                    ),
                  );
                }),
          )
        : Container();
  }
}
