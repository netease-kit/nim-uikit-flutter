// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/repo/team_repo.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/contact/contact_provider.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../chat_kit_client.dart';
import '../../helper/chat_message_helper.dart';
import '../../helper/chat_message_user_helper.dart';
import '../../l10n/S.dart';
import '../chat_kit_message_list/item/chat_kit_message_file_item.dart';

class ChatHistoryFileMessagePage extends StatefulWidget {
  final String conversationId;
  final NIMConversationType conversationType;

  const ChatHistoryFileMessagePage({
    Key? key,
    required this.conversationId,
    required this.conversationType,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ChatHistoryFileMessagePageState();
  }
}

class ChatHistoryFileMessagePageState
    extends BaseState<ChatHistoryFileMessagePage> {
  final ScrollController _scrollController = ScrollController();
  final List<NIMMessage> _historyMessages = [];

  ContactInfo? contactInfo;

  // 分页参数
  String _pageToken = '';
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    if (widget.conversationType == NIMConversationType.p2p) {
      getIt<ContactProvider>()
          .getContact(
              ChatKitUtils.getConversationTargetId(widget.conversationId))
          .then((value) {
        contactInfo = value;
        if (mounted) setState(() {});
      });
    }
    _scrollController.addListener(_scrollListener);
    _loadMoreOld(initial: true);
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
        messageTypes: [NIMMessageType.file],
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
      title: S.of(context).chatQuickSearchFile,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: _buildList(),
          ),
        ],
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
                S.of(context).chatSearchFileMessageEmpty,
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
      shrinkWrap: true,
      reverse: false,
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
            ListView.builder(
              shrinkWrap: true,
              reverse: false,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: messages.length,
              itemBuilder: (context, msgIndex) {
                return _buildFileItem(messages[msgIndex]);
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

  Widget _buildFileItem(NIMMessage message) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: FutureBuilder<UserAvatarInfo>(
            future: _getUserAvatarInfo(message),
            builder: (context, snapshot) {
              final userInfo = snapshot.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Row
                  Row(
                    children: [
                      Avatar(
                        avatar: userInfo?.avatar,
                        name: userInfo?.avatarName,
                        height: 32,
                        width: 32,
                        radius: 16,
                      ),
                      const SizedBox(width: 12),
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
                      const SizedBox(width: 8),
                      Text(
                        DateFormat(S.of(context).chatHistoryDateFormatMonthDay,
                                'zh')
                            .format(DateTime.fromMillisecondsSinceEpoch(
                                message.createTime!.toInt())),
                        style: const TextStyle(
                          fontSize: 12,
                          color: CommonColors.color_999999,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // File Card
                  Padding(
                    padding: const EdgeInsets.only(left: 44),
                    child: ChatKitMessageFileItem(
                      message: message,
                      backgroundColor: '#F4F4F4'.toColor(),
                      trailing: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: InkWell(
                          onTap: () {
                            //弹出操作按钮
                            _showOptionDialog(context, message, userInfo);
                          },
                          child: Icon(
                            Icons.more_vert,
                            size: 24,
                            color: CommonColors.color_999999,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }));
  }

  Future<UserAvatarInfo> _getUserAvatarInfo(NIMMessage message) async {
    if (message.aiConfig?.aiStatus == NIMMessageAIStatus.response &&
        AIUserManager.instance.isAIUser(message.aiConfig?.accountId)) {
      final aiUser =
          AIUserManager.instance.getAIUserById(message.aiConfig!.accountId!);
      return UserAvatarInfo(aiUser!.name ?? aiUser.accountId!,
          avatarName: aiUser.name, avatar: aiUser.avatar);
    }
    if (message.conversationType == NIMConversationType.p2p) {
      if (message.isSelf != true && contactInfo != null) {
        return UserAvatarInfo(contactInfo!.getName(),
            avatarName: contactInfo!.getName(needAlias: false),
            avatar: contactInfo?.user.avatar);
      }
      final selfInfo = IMKitClient.getUserInfo();
      if (message.isSelf == true && selfInfo != null) {
        return UserAvatarInfo(selfInfo.name ?? message.senderId!,
            avatar: selfInfo.avatar,
            avatarName: selfInfo.name ?? message.senderId!);
      }
      return UserAvatarInfo(message.senderId!, avatarName: message.senderId!);
    } else {
      var teamId =
          ChatKitUtils.getConversationTargetId(message.conversationId!);
      return await getUserAvatarInfoInTeam(teamId, message.senderId!);
    }
  }

  //操作弹框
  void _showOptionDialog(
      BuildContext context, NIMMessage message, UserAvatarInfo? userInfo) {
    var style = const TextStyle(fontSize: 16, color: CommonColors.color_333333);
    //将弹框的context 回调出来，解决弹框显示后Item remove的问题
    BuildContext? buildContext;
    showBottomChoose<int>(
        context: context,
        actions: [
          if (ChatKitClient
                  .instance.chatUIConfig.popMenuConfig?.enableForward !=
              false)
            CupertinoActionSheetAction(
                onPressed: () {
                  if (mounted) {
                    Navigator.of(context).pop(1);
                  } else if (buildContext != null) {
                    Navigator.pop(buildContext!);
                  }
                },
                child: Text(
                  S.of(context).chatMessageActionForward,
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
                S.of(context).chatMessageActionCollect,
                style: style,
              )),
        ],
        contextCb: (context) {
          buildContext = context;
        }).then((value) {
      if (value == 1) {
        _showForwardMessageDialog(message);
      } else if (value == 2) {
        _addCollectionMessage(message, userInfo);
      }
    });
  }

  void _addCollectionMessage(
      NIMMessage message, UserAvatarInfo? userInfo) async {
    String chatTitle = '';
    if (widget.conversationType == NIMConversationType.p2p) {
      chatTitle = contactInfo?.getName() ?? '';
    } else {
      final teamId =
          ChatKitUtils.getConversationTargetId(widget.conversationId);
      var teamInfo = await TeamRepo.getTeamInfo(teamId, NIMTeamType.typeNormal);
      chatTitle = teamInfo?.name ?? teamId;
    }
    ChatMessageRepo.addCollectMessage(message,
            senderName: userInfo?.name ?? '',
            avatar: userInfo?.avatar,
            conversationName: chatTitle)
        .then((v) {
      if (v.isSuccess) {
        Fluttertoast.showToast(msg: S.of().chatMessageCollectSuccess);
      } else if (v.code == ChatMessage.CollectionMessageLimit) {
        Fluttertoast.showToast(msg: S.of().chatMessageCollectedLimit);
      }
    });
  }

  Future<String> getSessionName() async {
    if (widget.conversationType == NIMConversationType.p2p) {
      return contactInfo?.getName() ??
          ChatKitUtils.getConversationTargetId(widget.conversationId);
    } else {
      final teamId =
          ChatKitUtils.getConversationTargetId(widget.conversationId);
      var teamInfo = await TeamRepo.getTeamInfo(teamId, NIMTeamType.typeNormal);
      return teamInfo?.name ?? teamId;
    }
  }

  void _showForwardMessageDialog(NIMMessage message) async {
    final sessionName = await getSessionName();
    ChatMessageHelper.showForwardSelector(context, (conversationId,
        {String? postScript, bool? isLastUser}) {
      haveConnectivity().then((value) async {
        if (value) {
          final params =
              await ChatMessageHelper.getSenderParams(message, conversationId);
          ChatMessageRepo.forwardMessage(message, conversationId,
                  params: params)
              .then((value) {
            if (value.code == ChatMessageRepo.errorInBlackList) {
              ChatMessageRepo.saveTipsMessage(
                  conversationId, S.of().chatMessageSendFailedByBlackList);
            }
          });
        }
      });
      if (postScript?.isNotEmpty == true) {
        ChatMessageRepo.sendTextMessageWithMessageAck(
            conversationId: conversationId, text: postScript!);
      }
    }, sessionName: sessionName);
  }
}
