// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart' as Intl;
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/progress_ring.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/string_utils.dart';
import 'package:netease_common_ui/widgets/radio_button.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/contact/contact_provider.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit/services/message/nim_chat_cache.dart';
import 'package:nim_chatkit/services/team/team_provider.dart';
import 'package:netease_plugin_core_kit/netease_plugin_core_kit.dart';
import 'package:nim_chatkit/extension.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/message/message_helper.dart';
import 'package:nim_chatkit/message/message_reply_info.dart';
import 'package:nim_chatkit/message/message_revoke_info.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/helper/chat_message_helper.dart';
import 'package:nim_chatkit_ui/helper/chat_message_user_helper.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_audio_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_file_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_image_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_merged_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_nonsupport_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_notify_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_tips_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_video_item.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_message_pop_menu.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_pop_actions.dart';
import 'package:nim_chatkit_ui/view/page/chat_message_ack_page.dart';
import 'package:nim_chatkit_ui/view_model/chat_view_model.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helper/merge_message_helper.dart';
import 'chat_kit_message_multi_line_text_item.dart';
import 'chat_kit_message_text_item.dart';

typedef ChatMessageItemBuilder = Widget Function(NIMMessage message);

class ChatKitMessageBuilder {
  ChatMessageItemBuilder? textMessageBuilder;
  ChatMessageItemBuilder? audioMessageBuilder;
  ChatMessageItemBuilder? imageMessageBuilder;
  ChatMessageItemBuilder? videoMessageBuilder;
  ChatMessageItemBuilder? notifyMessageBuilder;
  ChatMessageItemBuilder? tipsMessageBuilder;
  ChatMessageItemBuilder? fileMessageBuilder;
  ChatMessageItemBuilder? locationMessageBuilder;
  ChatMessageItemBuilder? mergedMessageBuilder;
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

  final bool Function(String? userID, {bool isSelf})? onAvatarLongPress;

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
      this.onAvatarLongPress,
      this.onMessageItemLongClick})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageItemState();
}

class ChatKitMessageItemState extends State<ChatKitMessageItem> {
  int showTimeInterval = ChatKitClient.instance.chatUIConfig.showTimeInterval;

  static const maxReceiptNum = 100;

  static const errorCodeAIRegenNone = 107404;

  final subscriptions = <StreamSubscription>[];

  //重新编辑展示时间
  static const reeditTime = 2 * 60 * 1000;

  late UserAvatarInfo _userAvatarInfo = widget.chatMessage.nimMessage.senderId!
      .getCacheAvatar(widget.chatMessage.nimMessage.senderId!);

  MessageItemConfig _getMessageItemConfig(NIMMessage message) {
    if (message.messageType == NIMMessageType.image ||
        message.messageType == NIMMessageType.video ||
        message.messageType == NIMMessageType.location) {
      return MessageItemConfig(showMsgCommonBg: false);
    } else if (message.messageType == NIMMessageType.file) {
      return MessageItemConfig(
          showMsgCommonBg: false, showMsgLoadingState: true);
    }
    return MessageItemConfig();
  }

  bool isSelf() {
    if (ChatMessageHelper.isReceivedMessageFromAi(
        widget.chatMessage.nimMessage)) {
      return false;
    }
    return widget.chatMessage.nimMessage.isSelf == true;
  }

  ChatKitMessagePopMenu? _popMenu;

  bool isTeam() {
    return widget.chatMessage.nimMessage.conversationType ==
        NIMConversationType.team;
  }

  bool _showMsgAck(ChatMessage message) {
    if (message.nimMessage.conversationType == NIMConversationType.p2p &&
        widget.chatUIConfig?.showP2pMessageStatus == false) {
      return false;
    }
    if (message.nimMessage.conversationType == NIMConversationType.team &&
        widget.chatUIConfig?.showTeamMessageStatus == false) {
      return false;
    }
    return message.nimMessage.messageConfig?.readReceiptEnabled == true &&
        (widget.teamInfo?.memberCount ?? 0) < maxReceiptNum;
  }

  int _getProcess(ChatMessage message) {
    if (widget.chatMessage.nimMessage.conversationType ==
        NIMConversationType.p2p) {
      int receiptTime = context.watch<ChatViewModel>().receiptTime;
      if (receiptTime >= message.nimMessage.createTime!) {
        return 1;
      } else {
        return 0;
      }
    }
    if (message.ackCount != null) {
      return message.ackCount!;
    }
    return 0;
  }

  int _getAllAck(ChatMessage message) {
    if (message.nimMessage.conversationType == NIMConversationType.p2p) {
      return 1;
    } else {
      if (message.ackCount != null && message.unAckCount != null) {
        return message.ackCount! + message.unAckCount!;
      }
    }
    return 0;
  }

  double getMaxWidth(isSelect) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    return width -
        (isSelect ? 135 : 110) -
        (ChatMessageHelper.isReceivedMessageFromAi(
                widget.chatMessage.nimMessage)
            ? 7
            : 0);
  }

  bool showNickname() {
    return widget.chatMessage.nimMessage.conversationType ==
            NIMConversationType.team &&
        !isSelf();
  }

  _onLongPress(BuildContext context) {
    //如果是正在流式消息，Stream 或者PlaceHolder 长按无反应
    if (ChatMessageHelper.isReceivedMessageFromAi(
            widget.chatMessage.nimMessage) &&
        (widget.chatMessage.nimMessage.aiConfig?.aiStreamStatus ==
                V2NIMMessageAIStreamStatus
                    .V2NIM_MESSAGE_AI_STREAM_STATUS_STREAMING ||
            widget.chatMessage.nimMessage.aiConfig?.aiStreamStatus ==
                V2NIMMessageAIStreamStatus
                    .V2NIM_MESSAGE_AI_STREAM_STATUS_PLACEHOLDER)) {
      return;
    }
    _popMenu?.clean();
    _popMenu = null;
    _popMenu = ChatKitMessagePopMenu(widget.chatMessage, context,
        popMenuAction: widget.popMenuAction, chatUIConfig: widget.chatUIConfig);
    _popMenu!.show();
  }

  bool _showReeditText(RevokedMessageInfo? revokedMessageInfo) {
    var message = widget.chatMessage;
    return isSelf() &&
        revokedMessageInfo != null &&
        DateTime.now().millisecondsSinceEpoch - message.nimMessage.createTime! <
            reeditTime;
  }

  Widget _buildRevokedMessage(ChatMessage message) {
    RevokedMessageInfo? revokedMessageInfo;
    var localExtension = null;
    if (message.nimMessage.localExtension?.isNotEmpty == true) {
      localExtension = jsonDecode(message.nimMessage.localExtension!);
    }
    if ((localExtension?[ChatMessage.keyRevokeMsgContent] is Map) &&
        (localExtension?[ChatMessage.keyRevokeMsgContent] as Map?)
                ?.isNotEmpty ==
            true) {
      revokedMessageInfo = RevokedMessageInfo.fromMap(
          (localExtension![ChatMessage.keyRevokeMsgContent] as Map)
              .cast<String, dynamic>());
    }
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(S.of().chatMessageHaveBeenRevoked,
              style: TextStyle(fontSize: 16, color: '#333333'.toColor())),
          if (_showReeditText(revokedMessageInfo))
            InkWell(
              onTap: () {
                context.read<ChatViewModel>().reeditMessage =
                    revokedMessageInfo;
              },
              child: Text(S.of().chatMessageReedit,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: '#1861DF'.toColor())),
            )
        ],
      ),
    );
  }

  NIMMessageRefer? _getReplyMessageRefer(ChatMessage message) {
    if (message.nimMessage.threadReply != null &&
        message.nimMessage.threadReply?.messageClientId?.isNotEmpty == true) {
      return message.nimMessage.threadReply;
    }
    var remoteExtension = null;
    if (message.nimMessage.serverExtension?.isNotEmpty == true) {
      remoteExtension = jsonDecode(message.nimMessage.serverExtension!);
    }
    var replyMessageInfoMap =
        remoteExtension?[ChatMessage.keyReplyMsgKey] as Map?;
    if (replyMessageInfoMap != null) {
      final info =
          ReplyMessageInfo.fromMap(replyMessageInfoMap.cast<String, dynamic>());

      return NIMMessageRefer(
          senderId: info.from,
          conversationId: info.to,
          receiverId: info.receiverId,
          messageClientId: info.idClient,
          messageServerId: info.idServer,
          conversationType: ConversationTypeEx.getTypeFromValue(info.scene),
          createTime: info.time);
    }
    return null;
  }

  bool _showReplyMessage(ChatMessage message) {
    return _getReplyMessageRefer(message)?.messageClientId?.isNotEmpty == true;
  }

  Widget _buildMessageReply(ChatMessage message) {
    NIMMessageRefer? messageRefer = _getReplyMessageRefer(message);
    return Container(
        padding: const EdgeInsets.only(left: 16, top: 12, right: 16),
        child: GestureDetector(
          child: FutureBuilder<String>(
            future: ChatMessageHelper.getReplayMessageText(
                context, messageRefer!, message.nimMessage.conversationId!),
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
            widget.scrollToIndex(messageRefer.messageClientId!);
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
            message: message.nimMessage, chatUIConfig: widget.chatUIConfig);
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
        //如果被过滤，则返回空Widget
        if (!_filterNotification(message.nimMessage)) {
          return Container();
        }
        if (messageItemBuilder?.notifyMessageBuilder != null) {
          return messageItemBuilder!.notifyMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageNotificationItem(message: message.nimMessage);
      case NIMMessageType.tip:
        if (messageItemBuilder?.tipsMessageBuilder != null) {
          return messageItemBuilder!.tipsMessageBuilder!(message.nimMessage);
        }
        return ChatKitMessageTipsItem(message: message.nimMessage);
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
                chatUIConfig: widget.chatUIConfig);
          } else if (multiLineTitle != null) {
            return ChatKitMessageMultiLineItem(
              message: message.nimMessage,
              chatUIConfig: widget.chatUIConfig,
              title: multiLineTitle,
              body: multiLineBody,
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

  ///过滤消息
  ///返回结果为是否展示
  bool _filterNotification(NIMMessage message) {
    if (message.attachment is NIMMessageNotificationAttachment) {
      NIMMessageNotificationAttachment attachment =
          message.attachment as NIMMessageNotificationAttachment;
      if (attachment.type == NIMMessageNotificationType.teamOwnerTransfer &&
          getIt<TeamProvider>().isGroupTeam(widget.teamInfo)) {
        return false;
      }
    }
    return true;
  }

  bool _showMessageStatus(ChatMessage message) {
    return message.nimMessage.sendingState == NIMMessageSendingState.sending ||
        message.nimMessage.sendingState == NIMMessageSendingState.failed ||
        message.nimMessage.conversationType == NIMConversationType.p2p ||
        message.nimMessage.messageConfig?.unreadEnabled == true;
  }

  void _onVisibleChange(VisibilityInfo info) {
    //可见并且未发送回执的时候发送回执
    if (info.visibleFraction > 0 &&
        widget.chatMessage.nimMessage.isSelf != true) {
      if (widget.chatMessage.nimMessage.conversationType ==
              NIMConversationType.team &&
          widget.chatMessage.nimMessage.messageConfig?.readReceiptEnabled ==
              true &&
          widget.chatMessage.nimMessage.messageStatus?.readReceiptSent !=
              true) {
        context
            .read<ChatViewModel>()
            .sendTeamMessageReceipt(widget.chatMessage);
      } else if (widget.chatMessage.nimMessage.conversationType ==
          NIMConversationType.p2p) {
        context
            .read<ChatViewModel>()
            .sendMessageP2PReceipt(widget.chatMessage.nimMessage);
      }
    }
  }

  Widget _getMessageStatus(ChatMessage message) {
    if (message.nimMessage.sendingState == NIMMessageSendingState.sending &&
        _getMessageItemConfig(message.nimMessage).showMsgLoadingState) {
      return SizedBox(
        child: CircularProgressIndicator(
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation(Colors.blue),
          strokeWidth: 2,
        ),
        width: 16,
        height: 16,
      );
    } else if (message.nimMessage.sendingState ==
        NIMMessageSendingState.failed) {
      return GestureDetector(
        onTap: () {
          if (widget.onTapFailedMessage != null) {
            widget.onTapFailedMessage!(message);
          }
        },
        child: SvgPicture.asset('images/ic_failed.svg',
            package: kPackage, width: 16, height: 16),
      );
    } else if (_showMsgAck(message)) {
      return InkWell(
        onTap: () async {
          ///多选模式下不可点击
          if (context.read<ChatViewModel>().isMultiSelected) {
            return;
          }
          if (message.nimMessage.conversationType == NIMConversationType.team &&
              message.unAckCount != null &&
              message.unAckCount! > 0) {
            final receiptDetail =
                await ChatMessageRepo.fetchTeamMessageReceiptDetail(
                    widget.chatMessage.nimMessage);
            if (receiptDetail != null) {
              widget.chatMessage.ackCount =
                  receiptDetail.readReceipt?.readCount;
              widget.chatMessage.unAckCount =
                  receiptDetail.readReceipt?.unreadCount;
            }
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ChatMessageAckPage(
                message: message.nimMessage,
                ackInfo: receiptDetail,
              );
            }));
          }
        },
        child: ProgressRing(
          size: 16,
          progress: _getProcess(widget.chatMessage),
          max: _getAllAck(widget.chatMessage),
          startImage:
              SvgPicture.asset('images/ic_unread.svg', package: kPackage),
          finishImage:
              SvgPicture.asset('images/ic_read.svg', package: kPackage),
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

  //PIN消息时候展示
  Future<String> _getUserName(String accId) async {
    if (accId == getIt<IMLoginService>().userInfo!.accountId) {
      return S.of(context).chatMessageYou;
    }
    if (widget.chatMessage.nimMessage.conversationType ==
        NIMConversationType.team) {
      var teamId = (await NimCore.instance.conversationIdUtil
              .conversationTargetId(
                  widget.chatMessage.nimMessage.conversationId!))
          .data;
      return getUserNickInTeam(teamId!, accId);
    } else {
      return accId.getUserName();
    }
  }

  // 根据ConversationID 获取TeamId
  Future<String> _getTeamIdByConversationId() async {
    var teamId = (await NimCore.instance.conversationIdUtil
            .conversationTargetId(
                widget.chatMessage.nimMessage.conversationId!))
        .data;
    return teamId!;
  }

  //获取对方的用户信息
  Future<UserAvatarInfo> _getUserInfo(NIMMessage message) async {
    if (ChatMessageHelper.isReceivedMessageFromAi(message)) {
      final aiUser =
          AIUserManager.instance.getAIUserById(message.aiConfig!.accountId!);
      final name = aiUser?.name ?? aiUser?.accountId ?? '';
      _userAvatarInfo =
          UserAvatarInfo(name, avatar: aiUser?.avatar, avatarName: name);
    } else {
      final accId = message.senderId!;
      String name = (accId == getIt<IMLoginService>().userInfo!.accountId)
          ? (S.of(context).chatMessageYou)
          : (await (isTeam()
              ? getUserNickInTeam((await _getTeamIdByConversationId()), accId)
              : accId.getUserName()));
      String? avatar = await accId.getAvatar();

      String? avatarName = await accId.getUserName(needAlias: true);
      _userAvatarInfo =
          UserAvatarInfo(name, avatar: avatar, avatarName: avatarName);
    }

    return _userAvatarInfo;
  }

  bool _showTime(ChatMessage currentMessage, ChatMessage? lastMessage) {
    if (lastMessage == null) {
      return true;
    }
    var currentTime = currentMessage.nimMessage.createTime! == 0
        ? DateTime.now().millisecondsSinceEpoch
        : currentMessage.nimMessage.createTime!;
    if (currentTime - lastMessage.nimMessage.createTime! > showTimeInterval) {
      return true;
    }
    return false;
  }

  //是否展示流式停止按钮
  //展示流式停止按钮的时候不能被多选
  bool _showStreamStop(NIMMessage message) {
    return message.aiConfig?.aiStreamStatus ==
            V2NIMMessageAIStreamStatus
                .V2NIM_MESSAGE_AI_STREAM_STATUS_STREAMING ||
        message.aiConfig?.aiStreamStatus ==
            V2NIMMessageAIStreamStatus
                .V2NIM_MESSAGE_AI_STREAM_STATUS_PLACEHOLDER;
  }

  bool _hideAvatarMessage(ChatMessage message) {
    var configShowAvatar =
        widget.chatUIConfig?.isShowAvatar?.call(message.nimMessage);
    if (configShowAvatar != null) {
      return configShowAvatar;
    }
    return message.nimMessage.messageType == NIMMessageType.notification ||
        message.nimMessage.messageType == NIMMessageType.tip;
  }

  String _timeFormat(int milliSecond) {
    var nowTime = DateTime.now();
    var messageTime = DateTime.fromMillisecondsSinceEpoch(milliSecond);
    if (nowTime.year != messageTime.year) {
      return Intl.DateFormat('yyyy-MM-dd HH:mm').format(messageTime);
    } else if (nowTime.month != messageTime.month ||
        nowTime.day != messageTime.day) {
      return Intl.DateFormat('MM-dd HH:mm').format(messageTime);
    } else {
      return Intl.DateFormat('HH:mm').format(messageTime);
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
        color: !_getMessageItemConfig(widget.chatMessage.nimMessage)
                .showMsgCommonBg
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
    if (widget.chatMessage.nimMessage.conversationType ==
            NIMConversationType.team &&
        widget.chatMessage.nimMessage.senderId == IMKitClient.account()) {
      ChatMessageRepo.fetchTeamMessageReceiptDetail(
              widget.chatMessage.nimMessage)
          .then((result) {
        if (result != null) {
          widget.chatMessage.unAckCount = result.readReceipt?.unreadCount;
          widget.chatMessage.ackCount = result.readReceipt?.readCount;
          if (mounted) {
            setState(() {});
          }
        }
      });
    }
    subscriptions
        .add(NIMChatCache.instance.teamMembersNotifier.listen((members) {
      for (var member in members) {
        if (member.teamInfo.accountId ==
            widget.chatMessage.nimMessage.senderId) {
          if (mounted) {
            setState(() {});
          }
        }
      }
    }));
    var userInfoUpdated = getIt<ContactProvider>().onContactInfoUpdated;
    if (userInfoUpdated != null) {
      subscriptions.add(userInfoUpdated.listen((event) {
        if (event.user.accountId == widget.chatMessage.nimMessage.senderId) {
          if (mounted) {
            setState(() {});
          }
        }
      }));
    }
  }

  Widget _getSingleMiddleEllipsisText(String? data,
      {TextStyle? style, String? userName}) {
    String info = data ?? "";
    bool isMultiSelect = context.watch<ChatViewModel>().isMultiSelected;
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: info, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    //超出的宽度,多计算上头像占位
    final exceedWidth =
        (textPainter.size.width - (getMaxWidth(isMultiSelect) - 50)).toInt();
    if (exceedWidth > 0 && userName?.isNotEmpty == true) {
      //每一个字符的宽度
      final pre = textPainter.width / info.length;
      //多余出来的字符个数
      final exceedLength = exceedWidth ~/ pre;
      final nameLen = userName!.length;
      final index = nameLen - exceedLength - 1;
      if (index > 0) {
        info =
            "${info.subStringWithoutEmoji(0, index)}...${info.subStringWithoutEmoji(nameLen)}";
      }
    }
    return Text(
      info,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }

  Widget _getPinText(String content, {TextStyle? style, String? userName}) {
    return _getSingleMiddleEllipsisText(content,
        style: style, userName: userName);
  }

  String _getPintContent(String? userName) {
    return isTeam()
        ? S.of(context).chatMessagePinMessageForTeam(
              userName ?? '',
            )
        : S.of(context).chatMessagePinMessage(
              userName ?? '',
            );
  }

  Widget _getSelectWidget(bool isSelectModel, ChatViewModel chatViewModel) {
    if (isSelectModel) {
      if (!widget.chatMessage.isRevoke &&
          !_showStreamStop(widget.chatMessage.nimMessage)) {
        return Container(
          width: 18,
          margin: const EdgeInsets.only(right: 8, top: 10),
          child: CheckBoxButton(
            isChecked:
                chatViewModel.isSelectedMessage(widget.chatMessage.nimMessage),
            onChanged: (value) {
              if (value) {
                chatViewModel.addSelectedMessage(widget.chatMessage.nimMessage);
              } else {
                chatViewModel
                    .removeSelectedMessage(widget.chatMessage.nimMessage);
              }
            },
          ),
        );
      } else {
        return Container(width: 25);
      }
    }
    return Container();
  }

  @override
  void dispose() {
    _popMenu?.clean();
    _popMenu = null;
    for (var sub in subscriptions) {
      sub.cancel();
    }
    subscriptions.clear();
    super.dispose();
  }

  //是否展示重新生成数字人消息或者停止按钮
  //只有发起者才能操作
  bool _showStopOrRegenMessage(NIMMessage message) {
    if (message.conversationType == NIMConversationType.p2p &&
        AIUserManager.instance.isAIUser(message.senderId)) {
      return true;
    }
    return ChatMessageHelper.isReceivedMessageFromAi(message) &&
        message.threadReply?.senderId == IMKitClient.account();
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;

    var pinTextStyle = TextStyle(color: '#3EAF96'.toColor(), fontSize: 11);

    var chatViewModel = context.watch<ChatViewModel>();
    return VisibilityDetector(
      key: widget.key!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_showTime(widget.chatMessage, widget.lastMessage))
            Text(
              _timeFormat(widget.chatMessage.nimMessage.createTime!),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _getSelectWidget(
                          chatViewModel.isMultiSelected, chatViewModel),
                      FutureBuilder<UserAvatarInfo>(
                        future: _getUserInfo(widget.chatMessage.nimMessage),
                        builder: (context, snapshot) {
                          return Expanded(
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
                                      if (ChatMessageHelper
                                          .isReceivedMessageFromAi(
                                              widget.chatMessage.nimMessage)) {
                                        widget.onTapAvatar!(widget.chatMessage
                                            .nimMessage.aiConfig?.accountId);
                                      } else {
                                        widget.onTapAvatar!(widget
                                            .chatMessage.nimMessage.senderId);
                                      }
                                    }
                                  },
                                  onLongPress: () {
                                    if (widget.onAvatarLongPress != null) {
                                      if (ChatMessageHelper
                                          .isReceivedMessageFromAi(
                                              widget.chatMessage.nimMessage)) {
                                        widget.onAvatarLongPress!.call(widget
                                            .chatMessage
                                            .nimMessage
                                            .aiConfig
                                            ?.accountId);
                                      } else {
                                        widget.onAvatarLongPress!.call(
                                            widget.chatMessage.nimMessage
                                                .senderId,
                                            isSelf: isSelf());
                                      }
                                    }
                                  },
                                  child: Avatar(
                                    width: 32,
                                    height: 32,
                                    avatar: snapshot.data == null
                                        ? _userAvatarInfo.avatar
                                        : snapshot.data!.avatar,
                                    name: snapshot.data == null
                                        ? _userAvatarInfo.avatarName
                                        : snapshot.data!.avatarName,
                                    nameColor:
                                        widget.chatUIConfig?.userNickColor,
                                    fontSize:
                                        widget.chatUIConfig?.userNickTextSize,
                                    radius:
                                        widget.chatUIConfig?.avatarCornerRadius,
                                    bgCode: AvatarColor.avatarColor(
                                        content: widget
                                            .chatMessage.nimMessage.senderId),
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
                                        child: Text(
                                            snapshot.data?.name ??
                                                _userAvatarInfo.name,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    CommonColors.color_999999)),
                                      ),
                                    Row(
                                      crossAxisAlignment: isSelf()
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
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
                                              maxWidth: getMaxWidth(
                                                  chatViewModel
                                                      .isMultiSelected)),
                                          child: Builder(
                                            builder: (context) {
                                              return GestureDetector(
                                                child: IgnorePointer(
                                                  ignoring: chatViewModel
                                                      .isMultiSelected,
                                                  child: widget
                                                          .chatMessage.isRevoke
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
                                                onTap:
                                                    widget.onMessageItemClick !=
                                                            null
                                                        ? () {
                                                            widget
                                                                .onMessageItemClick
                                                                ?.call(widget
                                                                    .chatMessage);
                                                          }
                                                        : null,
                                                onLongPress: () {
                                                  //long press
                                                  if (widget.chatUIConfig
                                                              ?.enableMessageLongPress ==
                                                          true &&
                                                      (widget.onMessageItemLongClick ==
                                                              null ||
                                                          widget.onMessageItemLongClick!(
                                                                  widget
                                                                      .chatMessage) !=
                                                              true)) {
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
                                        if (!chatViewModel.isMultiSelected &&
                                            _showStopOrRegenMessage(
                                                widget.chatMessage.nimMessage))
                                          Padding(
                                            padding: EdgeInsets.only(left: 7),
                                            child: InkWell(
                                              onTap: () {
                                                if (chatViewModel
                                                    .isMultiSelected) {
                                                  return;
                                                }
                                                if (_showStreamStop(widget
                                                    .chatMessage.nimMessage)) {
                                                  //正在输出流式布局.可以停止输出
                                                  NIMMessageAIStreamStopParams
                                                      params =
                                                      NIMMessageAIStreamStopParams(
                                                          operationType:
                                                              V2NIMMessageAIStreamStopOpType
                                                                  .V2NIM_MESSAGE_AI_STREAM_STOP_OP_DEFAULT);
                                                  ChatMessageRepo
                                                      .stopAIStreamMessage(
                                                          widget.chatMessage
                                                              .nimMessage,
                                                          params);
                                                } else {
                                                  //其他，可以重新生成
                                                  NIMMessageAIRegenParams
                                                      params =
                                                      NIMMessageAIRegenParams(
                                                          operationType:
                                                              V2NIMMessageAIRegenOpType
                                                                  .V2NIM_MESSAGE_AI_REGEN_OP_NEW);
                                                  ChatMessageRepo
                                                          .regenAIMessage(
                                                              widget.chatMessage
                                                                  .nimMessage,
                                                              params)
                                                      .then((result) {
                                                    if (!result.isSuccess) {
                                                      if (result.code ==
                                                          errorCodeAIRegenNone) {
                                                        Fluttertoast.showToast(
                                                            msg: S
                                                                .of(context)
                                                                .chatMessageRemovedTip);
                                                      } else {
                                                        Fluttertoast.showToast(
                                                            msg: S
                                                                .of(context)
                                                                .chatAiSearchError);
                                                      }
                                                    }
                                                  });
                                                }
                                              },
                                              child: _showStreamStop(widget
                                                      .chatMessage.nimMessage)
                                                  ? SvgPicture.asset(
                                                      'images/ic_ai_stream_stop.svg',
                                                      package: kPackage,
                                                      width: 24,
                                                      height: 24,
                                                    )
                                                  : SvgPicture.asset(
                                                      'images/ic_ai_stream_regen.svg',
                                                      package: kPackage,
                                                      width: 24,
                                                      height: 24),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (widget.chatMessage.getPinAccId() !=
                                        null)
                                      FutureBuilder<String>(
                                          future: _getUserName(widget
                                              .chatMessage
                                              .getPinAccId()!),
                                          builder: (context, snapshot) {
                                            return Container(
                                                constraints: BoxConstraints(
                                                    maxWidth: getMaxWidth(
                                                        chatViewModel
                                                            .isMultiSelected)),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisAlignment: isSelf()
                                                      ? MainAxisAlignment.end
                                                      : MainAxisAlignment.start,
                                                  children: [
                                                    SvgPicture.asset(
                                                        'images/ic_message_pin.svg',
                                                        package: kPackage),
                                                    _getPinText(
                                                        _getPintContent(
                                                            snapshot.data),
                                                        style: pinTextStyle,
                                                        userName: snapshot.data)
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
                                    avatar: getIt<IMLoginService>()
                                        .userInfo!
                                        .avatar,
                                    name:
                                        getIt<IMLoginService>().userInfo!.name,
                                    nameColor:
                                        widget.chatUIConfig?.userNickColor,
                                    fontSize:
                                        widget.chatUIConfig?.userNickTextSize,
                                    radius:
                                        widget.chatUIConfig?.avatarCornerRadius,
                                    bgCode: AvatarColor.avatarColor(
                                        content: getIt<IMLoginService>()
                                            .userInfo!
                                            .accountId),
                                  ),
                                )
                            ],
                          ));
                        },
                      )
                    ],
                  ),
                )
        ],
      ),
      onVisibilityChanged: _onVisibleChange,
    );
  }
}

class MessageItemConfig {
  // 是否展示消息发送loading状态
  bool showMsgLoadingState = true;

  // 是否展示消息通用背景
  bool showMsgCommonBg = true;

  MessageItemConfig(
      {this.showMsgLoadingState = true, this.showMsgCommonBg = true});
}
