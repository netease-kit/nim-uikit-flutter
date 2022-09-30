// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit_ui/generated/l10n.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/helper/chat_message_helper.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/helper/chat_message_user_helper.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_audio_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_image_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_notify_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_tips_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_video_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_message_pop_menu.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_pop_actions.dart';
import 'package:nim_chatkit_ui/view/chat_message_ack_page.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/progress_ring.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:netease_corekit_im/services/message/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:nim_core/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../../../chat_kit_client.dart';
import '../../../view_model/chat_view_model.dart';
import 'chat_kit_message_text_item.dart';

typedef ChatMessageItemBuilder = Widget Function(NIMMessage message);

class ChatKitMessageBuilder {
  ChatMessageItemBuilder? textMessageBuilder;
  ChatMessageItemBuilder? audioMessageBuilder;
  ChatMessageItemBuilder? imageMessageBuilder;
  ChatMessageItemBuilder? videoMessageBuilder;
  ChatMessageItemBuilder? notifyMessageBuilder;
  ChatMessageItemBuilder? tipsMessageBuilder;
  Map<NIMMessageType, ChatMessageItemBuilder?>? extendBuilder;
}

class ChatKitMessageItem extends StatefulWidget {
  final ChatMessage chatMessage;

  final ChatMessage? lastMessage;

  final NIMTeam? teamInfo;

  final ChatKitMessageBuilder? messageBuilder;

  final bool Function(ChatMessage message)? onMessageItemClick;

  final bool Function(ChatMessage message)? onMessageItemLongClick;

  final bool Function(String? userID, {bool isSelf})? onTapAvatar;

  final void Function(ChatMessage message)? onTapFailedMessage;

  final Function(String messageId) scrollToIndex;

  final PopMenuAction? popMenuAction;

  final bool showReadAck;

  final ChatUIConfig? chatUIConfig;

  ChatKitMessageItem(
      {Key? key,
      required this.chatMessage,
      required this.lastMessage,
      this.messageBuilder,
      this.showReadAck = true,
      this.onTapAvatar,
      this.popMenuAction,
      this.onTapFailedMessage,
      required this.scrollToIndex,
      this.teamInfo,
      this.chatUIConfig,
      this.onMessageItemClick,
      this.onMessageItemLongClick})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageItemState();
}

class ChatKitMessageItemState extends State<ChatKitMessageItem> {
  static const showTimeInterval = 5 * 60 * 1000;

  static const maxReceiptNum = 100;

  int _teamAck = 0;

  int _teamUnAck = 0;

  _log(String text) {
    Alog.d(tag: 'ChatKit', moduleName: 'MessageItem', content: text);
  }

  bool isSelf() {
    return widget.chatMessage.nimMessage.messageDirection ==
        NIMMessageDirection.outgoing;
  }

  ChatKitMessagePopMenu? _popMenu;

  bool isTeam() {
    return widget.chatMessage.nimMessage.sessionType == NIMSessionType.team;
  }

  bool _showMsgAck(ChatMessage message) {
    if (message.nimMessage.sessionType == NIMSessionType.p2p &&
        widget.chatUIConfig?.showP2pMessageStatus == false) {
      return false;
    }
    if (message.nimMessage.sessionType == NIMSessionType.team &&
        widget.chatUIConfig?.showTeamMessageStatus == false) {
      return false;
    }
    return message.nimMessage.messageAck &&
        (widget.teamInfo?.memberCount ?? 0) < maxReceiptNum;
  }

  int _getProcess(ChatMessage message) {
    if (widget.chatMessage.nimMessage.sessionType == NIMSessionType.p2p) {
      int receiptTime = context.watch<ChatViewModel>().receiptTime;
      if (receiptTime >= message.nimMessage.timestamp ||
          message.nimMessage.isRemoteRead == true) {
        return 1;
      } else {
        return 0;
      }
    }
    if (message.ackCount > 0) {
      _teamAck = message.ackCount;
    }
    return _teamAck;
  }

  int _getAllAck(ChatMessage message) {
    if (message.nimMessage.sessionType == NIMSessionType.p2p) {
      return 1;
    } else {
      if (message.ackCount > 0 || message.unAckCount > 0) {
        _teamAck = message.ackCount;
        _teamUnAck = message.unAckCount;
        _log('_getAllAck _teamUnAck:$_teamUnAck, _teamAck:$_teamAck');
      }
      return _teamAck + _teamUnAck;
    }
  }

  double getMaxWidth(isSelect) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    return width - (isSelect ? 130 : 110);
  }

  bool showNickname() {
    return widget.chatMessage.nimMessage.sessionType == NIMSessionType.team &&
        !isSelf();
  }

  _onLongPress(BuildContext context) {
    _popMenu?.clean();
    _popMenu = null;
    _popMenu = ChatKitMessagePopMenu(widget.chatMessage, context,
        popMenuAction: widget.popMenuAction, chatUIConfig: widget.chatUIConfig);
    _popMenu!.show();
  }

  Widget _buildRevokedMessage(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(S().chat_message_have_been_revoked,
              style: TextStyle(fontSize: 16, color: '#333333'.toColor())),
          if (isSelf() && message.nimMessage.messageType == NIMMessageType.text)
            InkWell(
              onTap: () {
                context.read<ChatViewModel>().reeditMessage =
                    message.nimMessage.content;
              },
              child: Text(S().chat_message_reedit,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: '#1861DF'.toColor())),
            )
        ],
      ),
    );
  }

  bool _showReplyMessage(ChatMessage message) {
    return message.nimMessage.messageThreadOption?.replyMessageFromAccount
            .isNotEmpty ==
        true;
  }

  Widget _buildMessageReply(ChatMessage message) {
    NIMMessageThreadOption threadOption =
        message.nimMessage.messageThreadOption!;
    return Container(
        padding: const EdgeInsets.only(left: 16, top: 12, right: 16),
        child: GestureDetector(
          child: FutureBuilder<String>(
            future: ChatMessageHelper.getReplayMessageText(
                threadOption.replyMessageIdClient,
                message.nimMessage.sessionId!,
                message.nimMessage.sessionType!),
            builder: (context, snapshot) {
              return Text(
                '| ${snapshot.data}',
                textWidthBasis: TextWidthBasis.parent,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(fontSize: 13, color: '#929299'.toColor()),
              );
            },
          ),
          onTap: () {
            widget.scrollToIndex(threadOption.replyMessageIdClient);
          },
        ));
  }

  Widget _buildMessage(ChatMessage message) {
    var messageItemBuilder = widget.messageBuilder;
    switch (message.nimMessage.messageType) {
      case NIMMessageType.text:
        if (messageItemBuilder?.textMessageBuilder != null) {
          return messageItemBuilder!.textMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageTextItem(
            text: message.nimMessage.content!,
            chatUIConfig: widget.chatUIConfig);
      case NIMMessageType.audio:
        if (messageItemBuilder?.audioMessageBuilder != null) {
          return messageItemBuilder!.audioMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageAudioItem(message: message.nimMessage);
      case NIMMessageType.image:
        if (messageItemBuilder?.imageMessageBuilder != null) {
          return messageItemBuilder!.imageMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageImageItem(message: message.nimMessage);
      case NIMMessageType.video:
        if (messageItemBuilder?.videoMessageBuilder != null) {
          return messageItemBuilder!.videoMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageVideoItem(message: message.nimMessage);
      case NIMMessageType.notification:
        if (messageItemBuilder?.notifyMessageBuilder != null) {
          return messageItemBuilder!.notifyMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageNotificationItem(message: message.nimMessage);
      case NIMMessageType.tip:
        if (messageItemBuilder?.tipsMessageBuilder != null) {
          return messageItemBuilder!.tipsMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageTipsItem(message: message.nimMessage);
      default:
        if (messageItemBuilder?.extendBuilder != null) {
          if (messageItemBuilder
                  ?.extendBuilder![message.nimMessage.messageType] !=
              null) {
            return messageItemBuilder!.extendBuilder![
                message.nimMessage.messageType]!(message.nimMessage);
          }
        }
        return Text(S.of(context).chat_message_unknown_type);
    }
  }

  bool _showMessageStatus(ChatMessage message) {
    return message.nimMessage.status == NIMMessageStatus.sending ||
        message.nimMessage.status == NIMMessageStatus.fail ||
        message.nimMessage.sessionType == NIMSessionType.p2p ||
        message.nimMessage.messageAck;
  }

  void _onVisibleChange(VisibilityInfo info) {
    //可见并且未发送回执的时候发送回执
    if (info.visibleFraction > 0 &&
        !isSelf() &&
        widget.chatMessage.nimMessage.messageAck &&
        !widget.chatMessage.nimMessage.hasSendAck) {
      context.read<ChatViewModel>().sendTeamMessageReceipt(widget.chatMessage);
    }
  }

  Widget _getMessageStatus(ChatMessage message) {
    if (message.nimMessage.status == NIMMessageStatus.sending) {
      return SizedBox(
        child: CircularProgressIndicator(
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation(Colors.blue),
          strokeWidth: 2,
        ),
        width: 16,
        height: 16,
      );
    } else if (message.nimMessage.status == NIMMessageStatus.fail) {
      return GestureDetector(
        onTap: () {
          if (widget.onTapFailedMessage != null) {
            widget.onTapFailedMessage!(message);
          }
        },
        child: SvgPicture.asset('images/ic_failed.svg',
            package: 'nim_chatkit_ui', width: 16, height: 16),
      );
    } else if (_showMsgAck(message)) {
      return InkWell(
        onTap: () {
          _log('click $_teamUnAck');
          if (message.nimMessage.sessionType == NIMSessionType.team &&
              _teamUnAck != 0) {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ChatMessageAckPage(message: message.nimMessage);
            }));
          }
        },
        child: ProgressRing(
          size: 16,
          progress: _getProcess(widget.chatMessage),
          max: _getAllAck(widget.chatMessage),
          startImage: SvgPicture.asset('images/ic_unread.svg',
              package: 'nim_chatkit_ui'),
          finishImage:
              SvgPicture.asset('images/ic_read.svg', package: 'nim_chatkit_ui'),
        ),
      );
    } else {
      return Container();
    }
  }

  Color? _getBgColor() {
    if (widget.chatMessage.getPinAccId() != null) {
      return widget.chatUIConfig?.signalBgColor ?? '#FFFBEA'.toColor();
    }
    return null;
  }

  Future<String> _getUserName(String accId) async {
    if (accId == getIt<LoginService>().userInfo!.userId) {
      return S.of(context).chat_message_you;
    }
    if (widget.chatMessage.nimMessage.sessionType == NIMSessionType.team) {
      return getUserNickInTeam(widget.chatMessage.nimMessage.sessionId!, accId);
    } else {
      return accId.getUserName();
    }
  }

  Future<UserAvatarInfo> _getUserInfo(String accId) async {
    String name = await (isTeam()
        ? getUserNickInTeam(widget.chatMessage.nimMessage.sessionId!, accId)
        : accId.getUserName());
    String? avatar = await accId.getAvatar();
    return UserAvatarInfo(name, avatar: avatar);
  }

  bool _showTime(ChatMessage currentMessage, ChatMessage? lastMessage) {
    if (lastMessage == null) {
      return true;
    }
    var currentTime = currentMessage.nimMessage.timestamp == 0
        ? DateTime.now().millisecondsSinceEpoch
        : currentMessage.nimMessage.timestamp;
    if (currentTime - lastMessage.nimMessage.timestamp > showTimeInterval) {
      return true;
    }
    return false;
  }

  bool _hideAvatarMessage(ChatMessage message) {
    return message.nimMessage.messageType == NIMMessageType.notification ||
        message.nimMessage.messageType == NIMMessageType.tip;
  }

  String _timeFormat(int milliSecond) {
    var nowTime = DateTime.now();
    var messageTime = DateTime.fromMillisecondsSinceEpoch(milliSecond);
    if (nowTime.year != messageTime.year) {
      return DateFormat('yyyy-MM-dd HH:mm').format(messageTime);
    } else if (nowTime.day != messageTime.day) {
      return DateFormat('MM-dd HH:mm').format(messageTime);
    } else {
      return DateFormat('HH:mm').format(messageTime);
    }
  }

  BoxDecoration _getMessageDecoration() {
    if (isSelf() && widget.chatUIConfig?.selfMessageBg != null) {
      return widget.chatUIConfig!.selfMessageBg!;
    } else if (!isSelf() && widget.chatUIConfig?.receiveMessageBg != null) {
      return widget.chatUIConfig!.receiveMessageBg!;
    } else {
      Color color = isSelf() ? '#D6E5F6'.toColor() : '#E8EAED'.toColor();
      return BoxDecoration(
        color: (widget.chatMessage.nimMessage.messageType ==
                    NIMMessageType.image ||
                widget.chatMessage.nimMessage.messageType ==
                    NIMMessageType.video)
            ? Colors.transparent
            : color,
        borderRadius: isSelf()
            ? const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12))
            : const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.chatMessage.nimMessage.sessionType == NIMSessionType.team &&
        widget.chatMessage.nimMessage.messageDirection ==
            NIMMessageDirection.outgoing) {
      ChatMessageRepo.fetchTeamMessageReceiptDetail(
              widget.chatMessage.nimMessage)
          .then((value) {
        if (mounted) {
          _log('mounted fetchTeamMessageReceiptDetail ${value?.toMap()}');
          setState(() {
            _teamAck = value?.ackAccountList?.length ?? 0;
            _teamUnAck = value?.unAckAccountList?.length ?? 0;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _popMenu?.clean();
    _popMenu = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    return VisibilityDetector(
      key: widget.key!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_showTime(widget.chatMessage, widget.lastMessage))
            Text(
              _timeFormat(widget.chatMessage.nimMessage.timestamp),
              style: TextStyle(
                  fontSize: widget.chatUIConfig?.timeTextSize ?? 12,
                  color: widget.chatUIConfig?.timeTextColor ??
                      '#B3B7BC'.toColor()),
            ),
          _hideAvatarMessage(widget.chatMessage)
              ? _buildMessage(widget.chatMessage)
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  margin: const EdgeInsets.only(bottom: 10),
                  color: _getBgColor(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: GestureDetector(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: isSelf()
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            //对方头像
                            if (!isSelf())
                              InkWell(
                                onTap: () {
                                  if (widget.onTapAvatar != null) {
                                    widget.onTapAvatar!(widget
                                        .chatMessage.nimMessage.fromAccount);
                                  }
                                },
                                child: FutureBuilder<UserAvatarInfo>(
                                  future: _getUserInfo(widget
                                      .chatMessage.nimMessage.fromAccount!),
                                  builder: (context, snapshot) {
                                    return Avatar(
                                      width: 32,
                                      height: 32,
                                      avatar: snapshot.data == null
                                          ? ''
                                          : snapshot.data!.avatar,
                                      name: snapshot.data == null
                                          ? ''
                                          : snapshot.data!.name,
                                      nameColor:
                                          widget.chatUIConfig?.userNickColor,
                                      fontSize:
                                          widget.chatUIConfig?.userNickTextSize,
                                      radius: widget
                                          .chatUIConfig?.avatarCornerRadius,
                                      bgCode: AvatarColor.avatarColor(
                                          content: widget.chatMessage.nimMessage
                                              .fromAccount),
                                    );
                                  },
                                ),
                              ),
                            //消息
                            Container(
                              margin: isSelf()
                                  ? const EdgeInsets.only(right: 8)
                                  : const EdgeInsets.only(left: 8),
                              child: Column(
                                crossAxisAlignment: isSelf()
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (showNickname())
                                    Container(
                                      width: screenWidth - 200,
                                      child: FutureBuilder<String>(
                                        future: _getUserName(widget.chatMessage
                                            .nimMessage.fromAccount!),
                                        builder: (context, snapshot) {
                                          return Text(snapshot.data ?? '',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: CommonColors
                                                      .color_999999));
                                        },
                                      ),
                                    ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (isSelf() &&
                                          !widget.chatMessage.isRevoke &&
                                          _showMessageStatus(
                                              widget.chatMessage))
                                        _getMessageStatus(widget.chatMessage),
                                      Container(
                                        margin: EdgeInsets.only(
                                            left: isSelf() ? 8 : 0),
                                        decoration: _getMessageDecoration(),
                                        constraints: BoxConstraints(
                                            maxWidth: getMaxWidth(false)),
                                        child: Builder(
                                          builder: (context) {
                                            return GestureDetector(
                                              child: IgnorePointer(
                                                ///todo ignoring for multiSelect
                                                ignoring: false,
                                                child:
                                                    widget.chatMessage.isRevoke
                                                        ? _buildRevokedMessage(
                                                            widget.chatMessage)
                                                        : Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              if (_showReplyMessage(
                                                                  widget
                                                                      .chatMessage))
                                                                _buildMessageReply(
                                                                    widget
                                                                        .chatMessage),
                                                              _buildMessage(widget
                                                                  .chatMessage)
                                                            ],
                                                          ),
                                              ),
                                              onTap: () {
                                                if (widget.onMessageItemClick !=
                                                    null) {
                                                  widget.onMessageItemClick!(
                                                      widget.chatMessage);
                                                }
                                              },
                                              onLongPress: () {
                                                //long press
                                                if (widget.onMessageItemLongClick ==
                                                        null ||
                                                    widget.onMessageItemLongClick!(
                                                            widget
                                                                .chatMessage) !=
                                                        true) {
                                                  if (!widget
                                                      .chatMessage.isRevoke) {
                                                    _onLongPress(context);
                                                  }
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (widget.chatMessage.getPinAccId() != null)
                                    FutureBuilder<String>(
                                        future: _getUserName(
                                            widget.chatMessage.getPinAccId()!),
                                        builder: (context, snapshot) {
                                          return Container(
                                              constraints: BoxConstraints(
                                                  maxWidth: getMaxWidth(false)),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment: isSelf()
                                                    ? MainAxisAlignment.end
                                                    : MainAxisAlignment.start,
                                                children: [
                                                  SvgPicture.asset(
                                                      'images/ic_message_pin.svg',
                                                      package:
                                                          'nim_chatkit_ui'),
                                                  Expanded(
                                                      child: Text(
                                                    isTeam()
                                                        ? S
                                                            .of(context)
                                                            .chat_message_pin_message_for_team(
                                                              snapshot.data ??
                                                                  '',
                                                            )
                                                        : S
                                                            .of(context)
                                                            .chat_message_pin_message(
                                                              snapshot.data ??
                                                                  '',
                                                            ),
                                                    textWidthBasis:
                                                        TextWidthBasis.parent,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        color:
                                                            '#3EAF96'.toColor(),
                                                        fontSize: 11),
                                                  ))
                                                ],
                                              ));
                                        })
                                ],
                              ),
                            ),
                            if (isSelf())
                              InkWell(
                                onTap: () {
                                  if (widget.onTapAvatar != null) {
                                    widget.onTapAvatar!(null, isSelf: true);
                                  }
                                },
                                child: Avatar(
                                  width: 32,
                                  height: 32,
                                  avatar:
                                      getIt<LoginService>().userInfo!.avatar,
                                  name: getIt<LoginService>().userInfo!.nick,
                                  nameColor: widget.chatUIConfig?.userNickColor,
                                  fontSize:
                                      widget.chatUIConfig?.userNickTextSize,
                                  radius:
                                      widget.chatUIConfig?.avatarCornerRadius,
                                  bgCode: AvatarColor.avatarColor(
                                      content: getIt<LoginService>()
                                          .userInfo!
                                          .userId),
                                ),
                              )
                          ],
                        ),
                      ))
                    ],
                  ),
                )
        ],
      ),
      onVisibilityChanged: _onVisibleChange,
    );
  }
}
