// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:netease_plugin_core_kit/netease_plugin_core_kit.dart';
import 'package:nim_chatkit/message/message_helper.dart';
import 'package:nim_chatkit/model/collect_message.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../chat_kit_client.dart';
import '../../helper/chat_message_helper.dart';
import '../../helper/chat_message_user_helper.dart';
import '../../helper/merge_message_helper.dart';
import '../../l10n/S.dart';
import '../../media/audio_player.dart';
import '../chat_kit_message_list/item/chat_kit_message_audio_item.dart';
import '../chat_kit_message_list/item/chat_kit_message_file_item.dart';
import '../chat_kit_message_list/item/chat_kit_message_image_item.dart';
import '../chat_kit_message_list/item/chat_kit_message_merged_item.dart';
import '../chat_kit_message_list/item/chat_kit_message_multi_line_text_item.dart';
import '../chat_kit_message_list/item/chat_kit_message_nonsupport_item.dart';
import '../chat_kit_message_list/item/chat_kit_message_notify_item.dart';
import '../chat_kit_message_list/item/chat_kit_message_text_item.dart';
import '../chat_kit_message_list/item/chat_kit_message_tips_item.dart';
import '../chat_kit_message_list/item/chat_kit_message_video_item.dart';

class ChatCollectionMessageListPage extends StatefulWidget {
  const ChatCollectionMessageListPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ChatCollectionMessageListPageState();
  }
}

class ChatCollectionMessageListPageState
    extends BaseState<ChatCollectionMessageListPage> {
  final ScrollController _scrollController = ScrollController();

  List<CollectMessage> _historyMessages = [];

  // 分页参数
  NIMCollection? anchor;
  bool _isLoading = false;
  bool _hasMore = true;

  UserAvatarInfo? currentUserAvatarInfo;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadMoreOld(initial: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    ChatAudioPlayer.instance.stopAll();
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

    final result =
        await ChatMessageRepo.getCollectionList(anchorCollection: anchor);

    if (result.isSuccess && result.data != null) {
      final items = result.data!.collectionList;
      if (items != null) {
        for (var item in items) {
          var collect =
              CollectMessage.fromJsonString(item.collectionData ?? '');
          if (collect != null) {
            collect.collection = item;
            await collect.deserializationMsg();
            _historyMessages.add(collect);
          }
        }
      }
      _hasMore = (items?.length ?? 0) < (result.data?.totalCount ?? 0);
      if (items?.isNotEmpty == true) {
        anchor = items?.last;
      }
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
      title: S.of(context).chatMessageActionCollect,
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
      return Container(
        alignment: Alignment.center,
        child: Column(
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
              S.of(context).chatHaveNoCollectionMessage,
              style: TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
            )
          ],
        ),
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
        });
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

  Widget _buildMessageItem(CollectMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Avatar(
              avatar: message.avatar,
              name: message.senderName,
              width: 32,
              height: 32,
            ),
            SizedBox(
              width: 8,
            ),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.senderName,
                      style: TextStyle(
                          fontSize: 14, color: CommonColors.color_333333),
                    ),
                    Text(
                      S
                          .of(context)
                          .chatCollectionFrom(message.conversationName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: CommonColors.color_999999),
                    )
                  ]),
            ),
            GestureDetector(
                onTap: () {
                  _showOptionDialog(context, message);
                },
                child: SvgPicture.asset(
                  'images/ic_more_point.svg',
                  package: kPackage,
                ))
          ]),
          SizedBox(
            height: 12,
          ),
          buildNIMMessage(context, message.nimMessage!),
          SizedBox(
            height: 12,
          ),
          Divider(
            height: 1,
            color: '#F5F8FC'.toColor(),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
                _timestampToFormattedString(message.collection!.createTime!),
                style:
                    TextStyle(fontSize: 12, color: CommonColors.color_999999)),
          )
        ],
      ),
    );
  }

  String _timestampToFormattedString(int timestamp) {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy.MM.dd HH:mm:ss').format(date);
  }

  void _showOptionDialog(BuildContext context, CollectMessage message) {
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
                S.of(context).chatMessageActionDelete,
                style: style,
              )),
          if (message.nimMessage?.messageType == NIMMessageType.text)
            CupertinoActionSheetAction(
                onPressed: () {
                  if (mounted) {
                    Navigator.of(context).pop(3);
                  } else if (buildContext != null) {
                    Navigator.pop(buildContext!);
                  }
                },
                child: Text(
                  S.of(context).chatMessageActionCopy,
                  style: style,
                )),
          if (message.nimMessage?.messageType != NIMMessageType.audio)
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
        }).then((value) async {
      if (value == 1) {
        if (!await haveConnectivity()) {
          return;
        }
        showCommonDialog(
                context: context,
                title: S.of().chatMessageActionDelete,
                content: S.of().chatCollectionDeleteConfirm)
            .then((value) {
          if (value ?? false)
            ChatMessageRepo.removeCollection([message.collection!])
                .then((result) {
              if (result.isSuccess) {
                setState(() {
                  _historyMessages.remove(message);
                });
              }
            });
        });
      } else if (value == 2) {
        if (message.nimMessage != null) {
          if (!await haveConnectivity()) {
            return;
          }
          showForwardMessageDialog(context, message.nimMessage!);
        }
      } else if (value == 3) {
        if (mounted) {
          Clipboard.setData(ClipboardData(text: message.nimMessage!.text!));
          Fluttertoast.showToast(msg: S.of().chatMessageCopySuccess);
        }
      }
    });
  }

  Widget buildNIMMessage(BuildContext context, NIMMessage message) {
    final chatUIConfig = ChatKitClient.instance.chatUIConfig;
    var messageItemBuilder = chatUIConfig.messageBuilder;
    switch (message.messageType) {
      case NIMMessageType.text:
        if (messageItemBuilder?.textMessageBuilder != null) {
          return messageItemBuilder!.textMessageBuilder!(message);
        } else {
          return ChatKitMessageTextItem(
            message: message,
            chatUIConfig: chatUIConfig,
            maxLines: 3,
            needPadding: false,
            checkDetailEnable: true,
          );
        }

      case NIMMessageType.audio:
        if (messageItemBuilder?.audioMessageBuilder != null) {
          return messageItemBuilder!.audioMessageBuilder!(message);
        } else {
          return Container(
            decoration: BoxDecoration(
                border: Border.all(color: '#F0F0F0'.toColor()),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12))),
            child: ChatKitMessageAudioItem(
              message: message,
              showDirection: true,
            ),
          );
        }

      case NIMMessageType.image:
        if (messageItemBuilder?.imageMessageBuilder != null) {
          return messageItemBuilder!.imageMessageBuilder!(message);
        } else {
          return ChatKitMessageImageItem(
            message: message,
            showDirection: false,
            showOneImage: true,
          );
        }

      case NIMMessageType.video:
        if (messageItemBuilder?.videoMessageBuilder != null) {
          return messageItemBuilder!.videoMessageBuilder!(message);
        } else {
          return ChatKitMessageVideoItem(message: message);
        }

      case NIMMessageType.notification:
        //如果被过滤，则返回空Widget
        if (messageItemBuilder?.notifyMessageBuilder != null) {
          return messageItemBuilder!.notifyMessageBuilder!(message);
        } else {
          return ChatKitMessageNotificationItem(message: message);
        }

      case NIMMessageType.tip:
        if (messageItemBuilder?.tipsMessageBuilder != null) {
          return messageItemBuilder!.tipsMessageBuilder!(message);
        } else {
          return ChatKitMessageTipsItem(message: message);
        }

      case NIMMessageType.file:
        if (messageItemBuilder?.fileMessageBuilder != null) {
          return messageItemBuilder!.fileMessageBuilder!(message);
        } else {
          return ChatKitMessageFileItem(
            message: message,
            independentFile: true,
          );
        }

      case NIMMessageType.location:
      default:
        if (message.messageType == NIMMessageType.location &&
            messageItemBuilder?.locationMessageBuilder != null) {
          return messageItemBuilder!.locationMessageBuilder!.call(message);
        }
        if (message.messageType == NIMMessageType.call &&
            messageItemBuilder?.avChatMessageBuilder != null) {
          return messageItemBuilder!.avChatMessageBuilder!.call(message);
        }
        if (message.messageType == NIMMessageType.custom) {
          var mergedMessage = MergeMessageHelper.parseMergeMessage(message);
          var multiLineMap = MessageHelper.parseMultiLineMessage(message);
          var multiLineTitle = multiLineMap?[ChatMessage.keyMultiLineTitle];
          var multiLineBody = multiLineMap?[ChatMessage.keyMultiLineBody];
          if (mergedMessage != null) {
            if (messageItemBuilder?.mergedMessageBuilder != null) {
              return messageItemBuilder!.mergedMessageBuilder!.call(message);
            } else {
              return ChatKitMessageMergedItem(
                  message: message,
                  mergedMessage: mergedMessage,
                  chatUIConfig: ChatKitClient.instance.chatUIConfig,
                  showMargin: false,
                  diffDirection: false);
            }
          } else if (multiLineTitle != null) {
            return ChatKitMessageMultiLineItem(
              message: message,
              chatUIConfig: ChatKitClient.instance.chatUIConfig,
              title: multiLineTitle,
              body: multiLineBody,
              titleMaxLines: 1,
              checkDetailEnable: true,
              bodyMaxLines: 2,
            );
          }
        }

        ///插件消息
        Widget? pluginBuilder = NimPluginCoreKit()
            .messageBuilderPool
            .buildMessageContent(context, message);
        if (pluginBuilder != null) {
          return pluginBuilder;
        }
        if (messageItemBuilder?.extendBuilder != null) {
          if (messageItemBuilder?.extendBuilder![message.messageType] != null) {
            return messageItemBuilder!
                .extendBuilder![message.messageType]!(message);
          }
        }
        return ChatKitMessageNonsupportItem();
    }
  }
}
