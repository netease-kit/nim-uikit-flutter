// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart' as Intl;
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_plugin_core_kit/netease_plugin_core_kit.dart';
import 'package:nim_chatkit/message/message_helper.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/helper/chat_message_helper.dart';
import 'package:nim_chatkit_ui/helper/chat_message_user_helper.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_audio_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_file_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_image_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_nonsupport_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_video_item.dart';
import 'package:nim_chatkit_ui/view_model/chat_pin_view_model.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';

import '../../../../helper/merge_message_helper.dart';
import '../chat_kit_message_item.dart';
import '../chat_kit_message_merged_item.dart';
import '../chat_kit_message_multi_line_text_item.dart';
import '../chat_kit_message_text_item.dart';

class ChatKitPinMessageItem extends StatefulWidget {
  final ChatMessage chatMessage;

  final ChatKitMessageBuilder? messageBuilder;

  final ChatUIConfig? chatUIConfig;

  final String chatTitle;

  ChatKitPinMessageItem(
      {Key? key,
      required this.chatMessage,
      required this.chatTitle,
      this.messageBuilder,
      this.chatUIConfig})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChatKitPinMessageItemState();
}

class _ChatKitPinMessageItemState extends State<ChatKitPinMessageItem> {
  late UserAvatarInfo _userAvatarInfo = widget.chatMessage.nimMessage.senderId
          ?.getCacheAvatar(widget.chatMessage.nimMessage.senderId!) ??
      UserAvatarInfo('');

  bool isSelf() {
    return widget.chatMessage.nimMessage.isSelf == true;
  }

  bool isTeam() {
    return widget.chatMessage.nimMessage.conversationType ==
        NIMConversationType.team;
  }

  //item 复用MessageItem
  Widget _buildMessage(ChatMessage message) {
    var messageItemBuilder = widget.messageBuilder;
    switch (message.nimMessage.messageType) {
      case NIMMessageType.text:
        if (messageItemBuilder?.textMessageBuilder != null) {
          return messageItemBuilder!.textMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageTextItem(
          message: message.nimMessage,
          chatUIConfig: widget.chatUIConfig,
          needPadding: false,
          maxLines: 3,
        );
      case NIMMessageType.audio:
        if (messageItemBuilder?.audioMessageBuilder != null) {
          return messageItemBuilder!.audioMessageBuilder!(message.nimMessage);
        }
        return Container(
          decoration: BoxDecoration(
              border: Border.all(color: '#F0F0F0'.toColor()),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12))),
          child: ChatKitMessageAudioItem(
            message: message.nimMessage,
            showDirection: true,
          ),
        );
      case NIMMessageType.image:
        if (messageItemBuilder?.imageMessageBuilder != null) {
          return messageItemBuilder!.imageMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageImageItem(
          message: message.nimMessage,
          showOneImage: true,
          showDirection: false,
        );
      case NIMMessageType.video:
        if (messageItemBuilder?.videoMessageBuilder != null) {
          return messageItemBuilder!.videoMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageVideoItem(message: message.nimMessage);
      case NIMMessageType.file:
        if (messageItemBuilder?.fileMessageBuilder != null) {
          return messageItemBuilder!.fileMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageFileItem(message: message.nimMessage);

      case NIMMessageType.location:
      default:
        if (message.nimMessage.messageType == NIMMessageType.location &&
            messageItemBuilder?.locationMessageBuilder != null) {
          return messageItemBuilder!.locationMessageBuilder!
              .call(message.nimMessage);
        }
        if (message.nimMessage.messageType == NIMMessageType.custom) {
          var mergedMessage =
              MergeMessageHelper.parseMergeMessage(message.nimMessage);
          var multiLineMap =
              MessageHelper.parseMultiLineMessage(message.nimMessage);
          var multiLineTitle = multiLineMap?[ChatMessage.keyMultiLineTitle];
          var multiLineBody = multiLineMap?[ChatMessage.keyMultiLineBody];
          if (mergedMessage != null) {
            if (messageItemBuilder?.mergedMessageBuilder != null) {
              return messageItemBuilder!.mergedMessageBuilder!
                  .call(message.nimMessage);
            }
            return ChatKitMessageMergedItem(
              message: message.nimMessage,
              mergedMessage: mergedMessage,
              chatUIConfig: widget.chatUIConfig,
              showMargin: false,
              diffDirection: false,
            );
          } else if (multiLineTitle != null) {
            return ChatKitMessageMultiLineItem(
              message: message.nimMessage,
              chatUIConfig: widget.chatUIConfig,
              title: multiLineTitle,
              body: multiLineBody,
              titleMaxLines: 1,
              bodyMaxLines: 2,
            );
          }
        }

        ///插件消息
        Widget? pluginBuilder = NimPluginCoreKit()
            .messageBuilderPool
            .buildMessageContent(context, message.nimMessage);
        if (pluginBuilder != null) {
          return pluginBuilder;
        }

        if (messageItemBuilder?.extendBuilder != null) {
          if (messageItemBuilder
                  ?.extendBuilder![message.nimMessage.messageType] !=
              null) {
            return messageItemBuilder!.extendBuilder![
                message.nimMessage.messageType]!(message.nimMessage);
          }
        }
        return ChatKitMessageNonsupportItem();
    }
  }

  //获取对方的用户信息
  Future<UserAvatarInfo> _getUserInfo(String accId) async {
    String name = '';
    if (isTeam()) {
      var teamId = (await NimCore.instance.conversationIdUtil
                  .conversationTargetId(
                      widget.chatMessage.nimMessage.conversationId!))
              .data ??
          '';
      name = await getUserNickInTeam(teamId, accId);
    } else {
      name = await accId.getUserName();
    }
    String? avatar = await accId.getAvatar();

    String? avatarName = await accId.getUserName(needAlias: false);
    _userAvatarInfo =
        UserAvatarInfo(name, avatar: avatar, avatarName: avatarName);
    return _userAvatarInfo;
  }

  //时间格式化
  String _timeFormat(int milliSecond) {
    var messageTime = DateTime.fromMillisecondsSinceEpoch(milliSecond);
    return Intl.DateFormat('yyyy-MM-dd HH:mm:ss').format(messageTime);
  }

  //操作弹框
  void _showOptionDialog(BuildContext context, ChatMessage optionMsg) {
    final message = optionMsg;
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
                S.of(context).chatMessageActionUnPin,
                style: style,
              )),
          if (widget.chatMessage.nimMessage.messageType == NIMMessageType.text)
            CupertinoActionSheetAction(
                onPressed: () {
                  if (mounted) {
                    Navigator.of(context).pop(2);
                  } else if (buildContext != null) {
                    Navigator.of(buildContext!).pop(2);
                  }
                },
                child: Text(
                  S.of(context).chatMessageActionCopy,
                  style: style,
                )),
          if (_showForward(widget.chatUIConfig, message))
            CupertinoActionSheetAction(
                onPressed: () {
                  if (mounted) {
                    Navigator.of(context).pop(3);
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
        context.read<ChatPinViewModel>().removePinMessage(message);
      } else if (value == 2) {
        if (mounted) {
          Clipboard.setData(ClipboardData(text: message.nimMessage.text!));
          Fluttertoast.showToast(msg: S.of().chatMessageCopySuccess);
        }
      } else if (value == 3) {
        _showForwardMessageDialog(message);
      }
    });
  }

  bool _showForward(ChatUIConfig? config, ChatMessage message) {
    if (config?.popMenuConfig?.enableForward != false) {
      if (message.nimMessage.messageType != NIMMessageType.audio) {
        return true;
      }
    }
    return false;
  }

  void _showForwardMessageDialog(ChatMessage message) {
    final NIMMessage msg = message.nimMessage;
    ChatMessageHelper.showForwardSelector(context, (conversationId,
        {String? postScript, bool? isLastUser}) {
      if (mounted) {
        context.read<ChatPinViewModel>().forwardMessage(msg, conversationId);
      } else {
        haveConnectivity().then((value) async {
          if (value) {
            final params =
                await ChatMessageHelper.getSenderParams(msg, conversationId);
            ChatMessageRepo.forwardMessage(msg, conversationId, params: params)
                .then((value) {
              if (value.code == ChatMessageRepo.errorInBlackList) {
                ChatMessageRepo.saveTipsMessage(
                    conversationId, S.of().chatMessageSendFailedByBlackList);
              }
            });
          }
        });
      }
      if (postScript?.isNotEmpty == true) {
        ChatMessageRepo.sendTextMessageWithMessageAck(
            conversationId: conversationId, text: postScript!);
      }
    }, sessionName: widget.chatTitle);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var nameTextStyle = TextStyle(color: '#333333'.toColor(), fontSize: 14);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<UserAvatarInfo>(
              future: _getUserInfo(widget.chatMessage.nimMessage.senderId!),
              builder: (context, snap) {
                return Container(
                    constraints: BoxConstraints.expand(height: 64),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Avatar(
                            avatar: snap.data?.avatar,
                            name: snap.data?.avatarName,
                            width: 32,
                            height: 32),
                        Positioned(
                            left: 42,
                            right: 32,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  snap.data?.name ?? _userAvatarInfo.name,
                                  style: nameTextStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _timeFormat(widget
                                      .chatMessage.nimMessage.createTime!),
                                  style: TextStyle(
                                      color: '#999999'.toColor(), fontSize: 12),
                                )
                              ],
                            )),
                        Positioned(
                            right: 0,
                            child: InkWell(
                              child: SvgPicture.asset(
                                'images/ic_setting.svg',
                                width: 30,
                                height: 30,
                                package: kPackage,
                              ),
                              onTap: () {
                                _showOptionDialog(context, widget.chatMessage);
                              },
                            ))
                      ],
                    ));
              }),
          Container(
            color: '#E4E9F2'.toColor(),
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: 16),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _buildMessage(widget.chatMessage),
          )
        ],
      ),
    );
  }
}
