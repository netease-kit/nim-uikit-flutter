// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:nim_chatkit/location.dart';
import 'package:nim_chatkit/message/message_reply_info.dart';
import 'package:nim_chatkit/message/message_revoke_info.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/repo/chat_service_observer_repo.dart';
import 'package:netease_corekit_im/model/contact_info.dart';
import 'package:netease_corekit_im/model/team_models.dart';
import 'package:netease_corekit_im/repo/config_repo.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/contact/contact_provider.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:netease_corekit_im/services/message/chat_message.dart';
import 'package:netease_corekit_im/services/team/team_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:nim_core/nim_core.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../chat_kit_client.dart';
import '../l10n/S.dart';

class ChatViewModel extends ChangeNotifier {
  static const String logTag = 'ChatViewModel';

  static const String typeState = "typing";

  final String sessionId;

  final NIMSessionType sessionType;

  int _receiptTime = 0;

  int get receiptTime => _receiptTime;

  ///only for p2p
  bool isTyping = false;

  set receiptTime(int value) {
    _receiptTime = value;
    notifyListeners();
  }

  bool showReadAck;

  String chatTitle = '';
  ContactInfo? contactInfo;

  NIMTeam? teamInfo;
  List<UserInfoWithTeam>? userInfoTeam;

  //重新编辑的消息
  RevokedMessageInfo? _reeditMessage;

  RevokedMessageInfo? get reeditMessage => _reeditMessage;

  set reeditMessage(RevokedMessageInfo? value) {
    _reeditMessage = value;
    //如果被撤回的消息有被回复的消息，则重新编辑时需要显示被回复的消息
    if (value?.replyMsgId?.isNotEmpty == true) {
      NimCore.instance.messageService.queryMessageListByUuid(
          [value!.replyMsgId!], sessionId, sessionType).then((value) {
        if (value.data?.isNotEmpty == true) {
          replyMessage = ChatMessage(value.data!.first);
        }
      });
    }
    notifyListeners();
  }

  void resetTyping() {
    isTyping = false;
    notifyListeners();
  }

  ChatMessage? _replyMessage;

  ChatMessage? get replyMessage => _replyMessage;

  set replyMessage(ChatMessage? value) {
    _replyMessage = value;
    notifyListeners();
  }

  int credibleTimestamp = -1;
  bool hasMoreForwardMessages = true;
  bool hasMoreNewerMessages = false;

  bool initListener = false;
  static const int messageLimit = 100;

  ChatViewModel(this.sessionId, this.sessionType, {this.showReadAck = true}) {
    setChattingAccount();
    setNIMMessageListener();
    if (sessionType == NIMSessionType.p2p) {
      getIt<ContactProvider>().getContact(sessionId).then((value) {
        contactInfo = value;
        chatTitle = value!.getName();
        notifyListeners();
      });
    } else if (sessionType == NIMSessionType.team) {
      ChatMessageRepo.queryTeam(sessionId).then((value) {
        if (value.isSuccess) {
          teamInfo = value.data;
          chatTitle = value.data!.name!;
          notifyListeners();
        }
      });
      getIt<TeamProvider>().queryMemberList(sessionId).then((value) {
        userInfoTeam = value
            ?.where((element) =>
                element.userInfo?.userId !=
                getIt<LoginService>().userInfo?.userId)
            .toList();
        notifyListeners();
      });
    }
    initFetch(null);
  }

  List<ChatMessage> _messageList = [];

  List<ChatMessage> get messageList => _messageList.reversed.toList();

  NIMMessage getAnchor(QueryDirection direction) {
    return direction == QueryDirection.QUERY_OLD
        ? _messageList[0].nimMessage
        : _messageList[_messageList.length - 1].nimMessage;
  }

  set messageList(List<ChatMessage> value) {
    _messageList = value;
    notifyListeners();
  }

  final subscriptions = <StreamSubscription>[];

  bool _isFilterMessage(NIMMessage message) {
    // 过滤被邀请人相关通知消息
    return message.messageType == NIMMessageType.notification &&
        message.messageAttachment is NIMUpdateTeamAttachment &&
        (message.messageAttachment as NIMUpdateTeamAttachment)
                .updatedFields
                .updatedBeInviteMode !=
            null;
  }

  void setNIMMessageListener() {
    if (initListener) return;
    initListener = true;
    _logI('message init listener');
    //new message
    subscriptions.add(
        ChatServiceObserverRepo.observeReceiveMessage().listen((event) async {
      _logI('receive msg -->> ${event.length}');
      if (event.length > 0) {
        _logI('onMessage 0:${event[0].toMap()}');
      }
      List<NIMMessage> list = event.where((element) {
        return element.sessionId == sessionId &&
            element.serverId! > 0 &&
            !_isFilterMessage(element) &&
            !_updateNimMessage(element);
      }).toList();
      if (list.isNotEmpty) {
        var res = await ChatMessageRepo.fillUserInfo(list);
        _insertMessages(res);
      }
    }));
    //message status change
    subscriptions
        .add(ChatServiceObserverRepo.observeMsgStatus().listen((event) {
      _logI(
          'onMessageStatus ${event.uuid} status change -->> ${event.status}, ${event.attachmentStatus}');
      if (_updateNimMessage(event) == false &&
          event.messageDirection == NIMMessageDirection.outgoing &&
          event.sessionId == sessionId) {
        //如果更新失败则添加
        _insertMessages([ChatMessage(event)]);
      }
    }));

    //昵称更新
    var contactChange = getIt<ContactProvider>().onContactInfoUpdated;
    if (contactChange != null) {
      subscriptions.add(contactChange.listen((e) {
        if (e != null &&
            sessionType == NIMSessionType.p2p &&
            e.user.userId == sessionId) {
          contactInfo = e;
          chatTitle = e.getName();
        }
        notifyListeners();
      }));
    }

    if (sessionType == NIMSessionType.team) {
      //team message receipt
      subscriptions.add(
          ChatServiceObserverRepo.observeTeamMessageReceipt().listen((event) {
        for (var element in event) {
          _updateTeamReceipt(element);
        }
      }));

      subscriptions
          .add(ChatServiceObserverRepo.observerTeamUpdate().listen((event) {
        for (var team in event) {
          _logI('observeTeamUpdate ${team.id}');
          if (team.id == teamInfo?.id) {
            chatTitle = team.name!;
            teamInfo = team;
            notifyListeners();
          }
        }
      }));
    } else {
      //p2p message receipt
      subscriptions
          .add(ChatServiceObserverRepo.observeMessageReceipt().listen((event) {
        _updateP2PReceipt(event);
      }));

      subscriptions.add(ChatServiceObserverRepo.observeCustomNotification()
          .listen((notification) {
        if (notification.sessionId != sessionId ||
            notification.sessionType != NIMSessionType.p2p) {
          return;
        }
        var content = notification.content;
        if (content?.isNotEmpty == true) {
          Map<String, dynamic> options = jsonDecode(content!);
          if (options[typeState] == 1) {
            isTyping = true;
          } else {
            isTyping = false;
          }
          notifyListeners();
        }
      }));
    }

    subscriptions
        .add(ChatServiceObserverRepo.observeRevokeMessage().listen((event) {
      _logI('received revokeMessage notify and save a local message');
      _onMessageRevoked(ChatMessage(event.message!));
    }));

    subscriptions
        .add(ChatServiceObserverRepo.observeMessagePin().listen((event) {
      _logI('onMessagePinNotify');
      if (event is NIMMessagePinAddedEvent) {
        _updateMessagePin(event.pin);
      } else if (event is NIMMessagePinRemovedEvent) {
        _updateMessagePin(event.pin, delete: true);
      }
    }));
  }

  void _insertMessages(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return;
    }
    if (_messageList.isEmpty) {
      _messageList.addAll(messages);
    } else {
      //如果第一条比最后一条新，则反转
      bool needReverse = messages.first.nimMessage.timestamp >
          messages.last.nimMessage.timestamp;
      if (needReverse) {
        messages.reversed;
      }
      //获取第一条，结果为最老的消息
      var oldestMsg = messages.first;
      var index = 0;
      for (int i = _messageList.length - 1; i >= 0; i--) {
        if (_messageList[i].nimMessage.timestamp <
            oldestMsg.nimMessage.timestamp) {
          index = i + 1;
          break;
        }
      }
      _messageList.insertAll(index, messages);
    }
    notifyListeners();
  }

  void sendInputNotification(bool isTyping) {
    Map<String, dynamic> content = {typeState: isTyping ? 1 : 0};
    var json = jsonEncode(content);
    var notification = CustomNotification(
        sessionId: sessionId,
        sessionType: NIMSessionType.p2p,
        content: json,
        config: CustomNotificationConfig(
            enablePush: false, enableUnreadCount: false));
    ChatMessageRepo.sendCustomNotification(notification);
  }

  void setChattingAccount() {
    _logI('setChattingAccount:$sessionId');
    ChatMessageRepo.setChattingAccount(sessionId, sessionType);
    if (Platform.isIOS) {
      ChatMessageRepo.clearSessionUnreadCount(sessionId, sessionType);
    }
  }

  void clearChattingAccount() {
    _logI('clearChattingAccount:$sessionId');
    if (Platform.isIOS) {
      ChatMessageRepo.clearSessionUnreadCount(sessionId, sessionType);
    }
    ChatMessageRepo.clearChattingAccount();
  }

  void initFetch(NIMMessage? anchor) async {
    _logI('initFetch -->> anchor:${anchor?.content}');
    late NIMMessage message;
    credibleTimestamp =
        await ChatMessageRepo.queryRoamMsgTimestamps(sessionId, sessionType);
    _logI('queryRoamMsgHasMoreTime -->> credibleTimestamp:$credibleTimestamp');
    hasMoreForwardMessages = true;
    if (anchor == null) {
      hasMoreNewerMessages = false;
      var result = await MessageBuilder.createEmptyMessage(
          sessionId: sessionId, sessionType: sessionType, timestamp: 0);
      if (result.isSuccess && result.data != null) {
        message = result.data!;
        _fetchMoreMessage(message, QueryDirection.QUERY_OLD);
      }
    } else {
      hasMoreNewerMessages = true;
      message = anchor;
      fetchMessageListBothDirect(message);
    }
  }

  fetchMessageListBothDirect(NIMMessage anchor) {
    _logI('fetchMessageListBothDirect');
    _fetchMoreMessage(anchor, QueryDirection.QUERY_OLD);
    _fetchMoreMessage(anchor, QueryDirection.QUERY_NEW);
  }

  fetchMoreMessage(QueryDirection direction) {
    _fetchMoreMessage(getAnchor(direction), direction);
  }

  _fetchMoreMessage(NIMMessage anchor, QueryDirection direction) {
    _logI(
        '_fetchMoreMessage anchor ${anchor.content}, ${anchor.timestamp}, $direction');
    if (!_isMessageCredible(anchor)) {
      _logI('fetchMoreMessage anchor is not credible');
      if (direction == QueryDirection.QUERY_NEW) {
        fetchMessageRemoteNewer(anchor);
      } else {
        fetchMessageRemoteOlder(anchor, false);
      }
      return;
    }
    _logI('fetch local anchor time:${anchor.timestamp}, direction:$direction');
    ChatMessageRepo.getHistoryMessage(anchor, direction, messageLimit)
        .then((value) {
      if (value.isSuccess) {
        List<ChatMessage>? list = value.data;
        if (list == null || list.isEmpty) {
          if (direction == QueryDirection.QUERY_OLD) {
            _logI('fetch local no more messages -->> try remote');
            fetchMessageRemoteOlder(anchor, true);
          } else {
            _onListFetchSuccess(list, direction);
          }
          return;
        }
        if (direction == QueryDirection.QUERY_OLD) {
          var lastMsg =
              list.last.nimMessage.timestamp > list.first.nimMessage.timestamp
                  ? list.last
                  : list.first;
          if (_isMessageCredible(lastMsg.nimMessage)) {
            _onListFetchSuccess(list, direction, isInit: anchor.timestamp == 0);
          } else {
            fetchMessageRemoteOlder(anchor, true);
          }
        } else {
          _onListFetchSuccess(list, direction);
        }
      } else {
        _onListFetchFailed(value.code, value.errorDetails);
      }
    });
  }

  fetchMessageRemoteNewer(NIMMessage anchor) {
    _logI('fetch remote newer anchor time:${anchor.timestamp}');
    ChatMessageRepo.fetchHistoryMessage(
            anchor,
            DateTime.now().millisecondsSinceEpoch,
            messageLimit,
            QueryDirection.QUERY_NEW)
        .then((value) {
      if (value.isSuccess) {
        // no need to update credible time, because all messages behind this
        _onListFetchSuccess(value.data, QueryDirection.QUERY_NEW);
      } else {
        _onListFetchFailed(value.code, value.errorDetails);
      }
    });
  }

  fetchMessageRemoteOlder(NIMMessage anchor, bool updateCredible) {
    _logI(
        'fetch remote old anchor time:${anchor.timestamp}, need update:$updateCredible');
    ChatMessageRepo.fetchHistoryMessage(
            anchor, 0, messageLimit, QueryDirection.QUERY_OLD)
        .then((value) {
      if (value.isSuccess && value.data != null) {
        var result = value.data!.reversed.toList();
        if (updateCredible && result.length > 0) {
          var lastMsg = result[result.length - 1].nimMessage;
          credibleTimestamp = lastMsg.timestamp;
          _logI(
              'updateCredible content:${lastMsg.content}, time:$credibleTimestamp');
          ChatMessageRepo.updateRoamMsgTimestamps(lastMsg);
        }
        _onListFetchSuccess(result, QueryDirection.QUERY_OLD);
      } else {
        _onListFetchFailed(value.code, value.errorDetails);
      }
    });
  }

  bool _isMessageCredible(NIMMessage message) {
    _logI(
        'isMessageCredible -->> credibleTimestamp:$credibleTimestamp, msgTime:${message.timestamp}');
    return credibleTimestamp <= 0 || message.timestamp >= credibleTimestamp;
  }

  _onListFetchSuccess(List<ChatMessage>? list, QueryDirection direction,
      {bool isInit = false}) {
    list = list
        ?.where((element) =>
            !_isFilterMessage(element.nimMessage) &&
            !_updateNimMessage(element.nimMessage))
        .toList();
    _logI('onListFetchSuccess -->> size:${list?.length}, direction:$direction');
    if (direction == QueryDirection.QUERY_OLD) {
      hasMoreForwardMessages = isInit ||
          (list != null && list.isNotEmpty && list.length >= messageLimit);
      _logI('older forward has more:$hasMoreForwardMessages');
      if (list != null) {
        _insertMessages(list);
        if (list.isNotEmpty &&
            list[0].nimMessage.sessionType == NIMSessionType.p2p) {
          sendMessageP2PReceipt(list[list.length - 1].nimMessage);
        }
      }
    } else {
      hasMoreNewerMessages = list != null && list.isNotEmpty;
      _logI('newer load has more:$hasMoreNewerMessages');
      if (list != null) {
        _messageList.addAll(list);
        notifyListeners();
      }
    }
  }

  _onListFetchFailed(int code, String? errorMsg) {
    _logI('onListFetchFailed code:$code, msg:$errorMsg');
  }

  void _updateTeamReceipt(NIMTeamMessageReceipt messageReceipt) {
    for (var message in _messageList) {
      if (message.nimMessage.uuid == messageReceipt.messageId) {
        message.unAckCount = messageReceipt.unAckCount!;
        message.ackCount = messageReceipt.ackCount!;
        _updateMessage(message);
      }
    }
  }

  void _updateP2PReceipt(List<NIMMessageReceipt> receipts) {
    for (var element in receipts) {
      if (receiptTime < element.time) {
        receiptTime = element.time;
      }
    }
  }

  void _updateMessage(ChatMessage message) {
    int pos = _messageList.indexOf(message);
    _logI('update message find $pos');
    if (pos >= 0) {
      _logI('update message at $pos');
      _messageList[pos] = message;
      notifyListeners();
    }
  }

  void _updateMessagePin(NIMMessagePin messagePin, {bool delete = false}) {
    for (int i = 0; i < _messageList.length; i++) {
      if (_isSameMessage(_messageList[i].nimMessage, messagePin)) {
        _messageList[i].pinOption = delete ? null : messagePin;
        notifyListeners();
        break;
      }
    }
  }

  void sendTextMessage(String text,
      {NIMMessage? replyMsg, List<String>? pushList}) {
    MessageBuilder.createTextMessage(
      sessionId: sessionId,
      sessionType: sessionType,
      text: text,
    ).then((value) {
      if (value.isSuccess && value.data != null) {
        if (sessionType == NIMSessionType.team &&
            pushList != null &&
            pushList.isNotEmpty) {
          value.data!.memberPushOption = NIMMemberPushOption(
              forcePushContent: value.data!.content,
              forcePushList:
                  pushList.length == 1 && pushList[0] == 'ACCOUNT_ALL'
                      ? null
                      : pushList);
        }
        sendMessage(value.data!, replyMsg: replyMsg);
      }
    });
  }

  void sendAudioMessage(String filePath, int fileSize, int duration,
      {NIMMessage? replyMsg}) {
    MessageBuilder.createAudioMessage(
            sessionId: sessionId,
            sessionType: sessionType,
            filePath: filePath,
            fileSize: fileSize,
            duration: duration)
        .then((value) {
      if (value.isSuccess) {
        sendMessage(value.data!, replyMsg: replyMsg);
      }
    });
  }

  void sendImageMessage(String filePath, int fileSize, {NIMMessage? replyMsg}) {
    MessageBuilder.createImageMessage(
            sessionId: sessionId,
            sessionType: sessionType,
            filePath: filePath,
            fileSize: fileSize)
        .then((value) {
      if (value.isSuccess) {
        sendMessage(value.data!, replyMsg: replyMsg);
      }
    });
  }

  //发送位置消息，不能用位置消息回复其他消息
  void sendLocationMessage(LocationInfo location) {
    MessageBuilder.createLocationMessage(
            sessionId: sessionId,
            sessionType: sessionType,
            latitude: location.latitude,
            longitude: location.longitude,
            address: location.address ?? '')
        .then((ret) {
      if (ret.isSuccess && ret.data != null) {
        ret.data!.content = location.name;
        sendMessage(ret.data!);
      }
    });
  }

  void sendVideoMessage(
      String filePath, int duration, int width, int height, String displayName,
      {NIMMessage? replyMsg}) {
    MessageBuilder.createVideoMessage(
            sessionId: sessionId,
            sessionType: sessionType,
            filePath: filePath,
            duration: duration,
            width: width,
            height: height,
            displayName: displayName)
        .then((value) {
      if (value.isSuccess) {
        sendMessage(value.data!, replyMsg: replyMsg);
      }
    });
  }

  void sendFileMessage(String filePath, String displayName,
      {NIMMessage? replyMsg}) {
    MessageBuilder.createFileMessage(
            sessionId: sessionId,
            sessionType: sessionType,
            filePath: filePath,
            displayName: displayName)
        .then((value) => sendMessage(value.data!, replyMsg: replyMsg));
  }

  void sendMessage(NIMMessage message,
      {NIMMessage? replyMsg, bool resend = false}) async {
    message.messageAck = await ConfigRepo.getShowReadStatus();
    //回调
    if (ChatKitClient.instance.messageAction != null) {
      ChatKitClient.instance.messageAction!(message);
    }
    message.config = NIMCustomMessageConfig(enablePush: true);
    if (message.pushPayload == null &&
        ChatKitClient.instance.chatUIConfig.getPushPayload != null) {
      message.pushPayload =
          ChatKitClient.instance.chatUIConfig.getPushPayload!.call(message);
    }
    var chatMessage = ChatMessage(message, replyMsg: replyMsg);
    if (resend == false) {
      _messageList.add(chatMessage);
      notifyListeners();
    } else {
      _onMessageSending(chatMessage);
    }
    if (replyMsg != null) {
      var msgInfo = ReplyMessageInfo(
          idClient: replyMsg.uuid!,
          scene: replyMsg.sessionType?.name,
          to: replyMsg.sessionId,
          from: getIt<LoginService>().userInfo?.userId,
          idServer: replyMsg.serverId?.toString(),
          time: replyMsg.timestamp);
      if (message.remoteExtension != null) {
        message.remoteExtension![ChatMessage.keyReplyMsgKey] = msgInfo.toMap();
      } else {
        message.remoteExtension = {ChatMessage.keyReplyMsgKey: msgInfo.toMap()};
      }
    }
    ChatMessageRepo.sendMessage(message: message, resend: resend).then((value) {
      _onMessageSend(value, chatMessage);
    });
  }

  void _onMessageSending(ChatMessage message) {
    message.nimMessage.status = NIMMessageStatus.sending;
    _updateMessage(message);
  }

  void _onMessageSend(NIMResult<dynamic> value, ChatMessage message) {
    _logI('_onMessageSend ${message.nimMessage.toMap()}');
    if (value.isSuccess) {
      message.nimMessage.status = NIMMessageStatus.success;
    } else {
      message.nimMessage.status = NIMMessageStatus.fail;
    }
    _updateNimMessage(message.nimMessage);
  }

  bool _updateNimMessage(NIMMessage nimMessage) {
    int pos = _messageList
        .indexWhere((element) => nimMessage.uuid == element.nimMessage.uuid);
    _logI('update nim message find $pos');
    if (pos >= 0) {
      _logI('update nim message at $pos');
      _messageList[pos].nimMessage = nimMessage;
      notifyListeners();
      return true;
    }
    return false;
  }

  void forwardMessage(
      NIMMessage message, String sessionId, NIMSessionType sessionType) async {
    message.remoteExtension?.remove(ChatMessage.keyReplyMsgKey);
    if (await haveConnectivity()) {
      ChatMessageRepo.forwardMessage(message, sessionId, sessionType);
    }
  }

  void addMessagePin(NIMMessage message, {String? ext}) async {
    if (!await haveConnectivity()) {
      return;
    }
    ChatMessageRepo.addMessagePin(message, ext: ext).then((value) {
      if (value.isSuccess) {
        _updateMessagePin(NIMMessagePin(
            sessionId: message.sessionId!,
            sessionType: message.sessionType!,
            messageId: message.messageId,
            messageUuid: message.uuid));
      }
    });
  }

  void removeMessagePin(NIMMessage message, {String? ext}) async {
    if (!await haveConnectivity()) {
      return;
    }
    ChatMessageRepo.removeMessagePin(message, ext: ext).then((value) {
      if (value.isSuccess) {
        _updateMessagePin(
            NIMMessagePin(
                sessionId: message.sessionId!,
                sessionType: message.sessionType!,
                messageId: message.messageId,
                messageUuid: message.uuid),
            delete: true);
      }
    });
  }

  void collectMessage(NIMMessage message) {
    ChatMessageRepo.collectMessage(message);
  }

  ///delete local message
  void deleteMessage(ChatMessage message) async {
    if (!await haveConnectivity()) {
      return;
    }
    ChatMessageRepo.deleteMessage(message.nimMessage).then((value) {
      _messageList.remove(message);
      notifyListeners();
    });
  }

  ///撤回消息
  Future<NIMResult<void>> revokeMessage(ChatMessage message) {
    return ChatMessageRepo.revokeMessage(message.nimMessage).then((value) {
      if (value.isSuccess) {
        _logI('revokeMessage success and save a local message');
        _onMessageRevoked(message);
      }
      return value;
    });
  }

  void _onMessageRevoked(ChatMessage revokedMsg) async {
    var textMsg = revokedMsg.nimMessage.messageType == NIMMessageType.text
        ? revokedMsg.nimMessage.content
        : null;
    RevokedMessageInfo? revokedMessageInfo;
    if (textMsg?.isNotEmpty == true) {
      revokedMessageInfo = RevokedMessageInfo(reeditMessage: textMsg);
      var replyMessageInfoMap = revokedMsg
          .nimMessage.remoteExtension?[ChatMessage.keyReplyMsgKey] as Map?;
      if (replyMessageInfoMap != null) {
        revokedMessageInfo.replyMsgId = ReplyMessageInfo.fromMap(
                replyMessageInfoMap.cast<String, dynamic>())
            .idClient;
      }
    }
    //创建一条特殊的占位消息
    MessageBuilder.createTextMessage(
            sessionId: revokedMsg.nimMessage.sessionId!,
            sessionType: revokedMsg.nimMessage.sessionType!,
            text: S.of().chatMessageHaveBeenRevoked)
        .then((msgResult) {
      if (msgResult.isSuccess && msgResult.data != null) {
        //设置撤回标识
        if (msgResult.data!.localExtension != null) {
          msgResult.data!.localExtension![ChatMessage.keyRevokeMsg] = true;
          msgResult.data!.localExtension![ChatMessage.keyRevokeMsgContent] =
              revokedMessageInfo?.toMap();
        } else {
          msgResult.data!.localExtension = {
            ChatMessage.keyRevokeMsg: true,
            ChatMessage.keyRevokeMsgContent: revokedMessageInfo?.toMap()
          };
        }
        msgResult.data!.fromAccount = revokedMsg.nimMessage.fromAccount;
        msgResult.data!.messageDirection =
            revokedMsg.nimMessage.messageDirection;
        //将占位消息插入到本地
        NimCore.instance.messageService
            .saveMessageToLocalEx(
                message: msgResult.data!, time: revokedMsg.nimMessage.timestamp)
            .then((savedMsg) {
          //找到位置，跟新
          if (savedMsg.isSuccess && savedMsg.data != null) {
            int pos = _messageList.indexOf(revokedMsg);
            if (pos >= 0) {
              _messageList[pos] = ChatMessage(savedMsg.data!);
              notifyListeners();
            }
          }
        });
      }
    });
  }

  void sendMessageP2PReceipt(NIMMessage message) {
    ChatMessageRepo.markP2PMessageRead(sessionId: sessionId, message: message);
  }

  void sendTeamMessageReceipt(ChatMessage message) {
    ChatMessageRepo.markTeamMessageRead(message.nimMessage);
  }

  void downloadAttachment(NIMMessage message, bool thumb) {
    _logI('downloadAttachment message:${message.uuid}, thumb:$thumb');
    ChatMessageRepo.downloadAttachment(message: message, thumb: thumb);
  }

  bool _isSameMessage(NIMMessage nimMessage, NIMMessagePin messagePin) {
    if (nimMessage.messageId != null &&
        nimMessage.messageId != '-1' &&
        messagePin.messageId != null &&
        messagePin.messageId != '-1') {
      return nimMessage.messageId == messagePin.messageId;
    } else {
      return nimMessage.uuid == messagePin.messageUuid;
    }
  }

  void _logI(String content) {
    Alog.i(tag: 'ChatKit', moduleName: '$logTag $sessionId', content: content);
  }

  @override
  void dispose() {
    clearChattingAccount();
    for (var sub in subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
