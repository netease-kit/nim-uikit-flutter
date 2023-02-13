// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/repo/chat_service_observer_repo.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

  String? _reeditMessage;

  String? get reeditMessage => _reeditMessage;

  set reeditMessage(String? value) {
    _reeditMessage = value;
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

  bool hasNetWork = true;

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
    //net work
    Connectivity()
        .checkConnectivity()
        .then((value) => hasNetWork = value != ConnectivityResult.none);
    subscriptions.add(Connectivity().onConnectivityChanged.listen((event) {
      hasNetWork = event != ConnectivityResult.none;
      notifyListeners();
    }));
    //new message
    subscriptions.add(
        ChatServiceObserverRepo.observeReceiveMessage().listen((event) async {
      _logI('receive msg -->> ${event.length}');
      if (event.length > 0) {
        _logI('onMessage 0:${event[0].toMap()}');
      }
      List<NIMMessage> list = event.where((element) {
        return element.sessionId == sessionId && !_isFilterMessage(element);
      }).toList();
      if (list.isNotEmpty) {
        var res = await ChatMessageRepo.fillUserInfo(list);
        _messageList.addAll(res);
        notifyListeners();
      }
    }));
    //message status change
    subscriptions
        .add(ChatServiceObserverRepo.observeMsgStatus().listen((event) {
      _logI(
          'onMessageStatus ${event.uuid} status change -->> ${event.status}, ${event.attachmentStatus}');
      if (_updateNimMessage(event) == false &&
          event.messageDirection == NIMMessageDirection.outgoing) {
        //如果更新失败则添加
        _messageList.add(ChatMessage(event));
        notifyListeners();
      }
    }));

    //p2p message receipt
    subscriptions
        .add(ChatServiceObserverRepo.observeMessageReceipt().listen((event) {
      _updateP2PReceipt(event);
    }));

    //team message receipt
    if (sessionType == NIMSessionType.team) {
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
      _updateMessage(ChatMessage(event.message!, isRevoke: true));
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
          sessionId: sessionId,
          sessionType: sessionType,
          timestamp: DateTime.now().millisecondsSinceEpoch);
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
          if (_isMessageCredible(value.data![0].nimMessage)) {
            _onListFetchSuccess(list, direction);
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

  _onListFetchSuccess(List<ChatMessage>? list, QueryDirection direction) {
    list = list
        ?.where((element) => !_isFilterMessage(element.nimMessage))
        .toList();
    _logI('onListFetchSuccess -->> size:${list?.length}, direction:$direction');
    if (direction == QueryDirection.QUERY_OLD) {
      hasMoreForwardMessages = list != null && list.isNotEmpty;
      _logI('older forward has more:$hasMoreForwardMessages');
      if (list != null) {
        _messageList.insertAll(0, list);
        if (list.isNotEmpty &&
            list[0].nimMessage.sessionType == NIMSessionType.p2p) {
          sendMessageP2PReceipt(list[list.length - 1].nimMessage);
        }
        notifyListeners();
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

  void sendMessage(NIMMessage message,
      {NIMMessage? replyMsg, bool resend = false}) async {
    message.messageAck = await ConfigRepo.getShowReadStatus();
    var chatMessage = ChatMessage(message, replyMsg: replyMsg);
    if (resend == false) {
      _messageList.add(chatMessage);
      notifyListeners();
    } else {
      _onMessageSending(chatMessage);
    }
    if (replyMsg != null) {
      ChatMessageRepo.replyMessage(
              msg: message, replyMsg: replyMsg, resend: resend)
          .then((value) {
        _onMessageSend(value, chatMessage);
      });
    } else {
      ChatMessageRepo.sendMessage(message: message, resend: resend)
          .then((value) {
        _onMessageSend(value, chatMessage);
      });
    }
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
      NIMMessage message, String sessionId, NIMSessionType sessionType) {
    ChatMessageRepo.forwardMessage(message, sessionId, sessionType);
  }

  void addMessagePin(NIMMessage message, {String? ext}) {
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

  void removeMessagePin(NIMMessage message, {String? ext}) {
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
  void deleteMessage(ChatMessage message) {
    ChatMessageRepo.deleteMessage(message.nimMessage).then((value) {
      _messageList.remove(message);
      notifyListeners();
    });
  }

  ///撤回消息
  Future<NIMResult<void>> revokeMessage(ChatMessage message) {
    return ChatMessageRepo.revokeMessage(message.nimMessage).then((value) {
      if (value.isSuccess) {
        message.isRevoke = true;
        _updateMessage(message);
      }
      return value;
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
