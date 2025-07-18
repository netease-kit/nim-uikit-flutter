// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/manager/subscription_manager.dart';
import 'package:nim_chatkit/model/ait/ait_contacts_model.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/contact/contact_provider.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit/services/message/nim_chat_cache.dart';
import 'package:nim_chatkit/chatkit_client_repo.dart';
import 'package:nim_chatkit/location.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/message/message_revoke_info.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/repo/chat_service_observer_repo.dart';
import 'package:nim_chatkit_ui/helper/chat_message_helper.dart';
import 'package:nim_chatkit_ui/helper/merge_message_helper.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:yunxin_alog/yunxin_alog.dart';
import 'package:uuid/uuid.dart';

import '../chat_kit_client.dart';
import '../l10n/S.dart';

class ChatViewModel extends ChangeNotifier {
  static const String logTag = 'ChatViewModel';

  static const String typeState = "typing";

  //默认上下文的取值范围
  static const int aiMessageSize = 30;

  // 用于控制随机性和多样性的程度
  static const double translateTemperature = 0.2;

  // 获取翻译 prompt key
  static const String translatePromptKey = "Language";

  String? _sessionId;

  // 翻译 request id
  String? translationLanguageRequestId;

  // 数字人请求成功code
  int aiUserRequestSuccess = 200;

  // p2p 消息标记已读回执的时间戳
  int markP2PMessageReadReceiptTime = 0;

  Future<String> get sessionId async {
    if (_sessionId?.isNotEmpty == true) {
      return _sessionId!;
    }
    _sessionId = (await NimCore.instance.conversationIdUtil
            .conversationTargetId(conversationId))
        .data;
    return _sessionId!;
  }

  String? get p2pUserAccId {
    if (conversationType == NIMConversationType.p2p) {
      return _sessionId;
    }
    return null;
  }

  //会话ID
  final String conversationId;

  final NIMConversationType conversationType;

  int _receiptTime = 0;

  int get receiptTime => _receiptTime;

  ///only for p2p
  bool isTyping = false;

  ///当消息列表中的数据少于这个值的时候自动拉取更多消息
  ///用于批量删除和删除回调
  final int _autoFetchMessageSize = 15;

  set receiptTime(int value) {
    _receiptTime = value;
    notifyListeners();
  }

  bool showReadAck;

  String chatTitle = '';
  //联系人信息，P2P
  ContactInfo? contactInfo;

  //群信息，群组
  NIMTeam? teamInfo;

  bool mute = false;

  // 本端撤回消息 id
  String? revokeMessageId;

  //重新编辑的消息
  RevokedMessageInfo? _reeditMessage;

  RevokedMessageInfo? get reeditMessage => _reeditMessage;

  set reeditMessage(RevokedMessageInfo? value) {
    _reeditMessage = value;
    _replyMessage = null;
    //如果被撤回的消息有被回复的消息，则重新编辑时需要显示被回复的消息
    if (value?.replyMsgId?.isNotEmpty == true) {
      NimCore.instance.messageService.getMessageListByIds(
          messageClientIds: [value!.replyMsgId!]).then((value) {
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

  bool hasMoreForwardMessages = true;
  bool hasMoreNewerMessages = false;
  bool isLoading = false;

  bool initListener = false;
  static const int messageLimit = 100;

  //是否是多选状态
  bool _isMultiSelected = false;

  bool get isMultiSelected => _isMultiSelected;

  set isMultiSelected(bool value) {
    _isMultiSelected = value;
    if (!value) {
      _selectedMessages.clear();
    }
    notifyListeners();
  }

  //多选状态下选中的消息
  List<NIMMessage> _selectedMessages = [];

  List<NIMMessage> get selectedMessages => _selectedMessages.toList();

  ChatViewModel(this.conversationId, this.conversationType,
      {this.showReadAck = true}) {
    _setNIMMessageListener();
    initData();
  }

  initData() async {
    _sessionId = (await NimCore.instance.conversationIdUtil
            .conversationTargetId(conversationId))
        .data;
    if (conversationType == NIMConversationType.p2p && _sessionId != null) {
      getIt<ContactProvider>().getContact(_sessionId!).then((value) {
        updateContactInfo(value);

        chatTitle = value!.getName();
        initUserState(value.user.accountId!);
        notifyListeners();
      });
      ChatMessageRepo.getP2PMessageReceipt(conversationId).then((result) {
        if (result.isSuccess && result.data?.timestamp != null) {
          receiptTime = result.data!.timestamp!;
        }
      });
    } else if (conversationType == NIMConversationType.team &&
        _sessionId != null) {
      ChatMessageRepo.queryTeam(_sessionId!).then((value) {
        if (value.isSuccess) {
          teamInfo = value.data;
          chatTitle = value.data!.name;
          NIMChatCache.instance.getMyTeamMember(_sessionId!).then((value) {
            mute = (teamInfo?.chatBannedMode ==
                        NIMTeamChatBannedMode.chatBannedModeBannedNormal &&
                    value?.teamInfo.memberRole ==
                        NIMTeamMemberRole.memberRoleNormal) ||
                teamInfo?.chatBannedMode ==
                    NIMTeamChatBannedMode.chatBannedModeBannedAll;
            notifyListeners();
          });
        }
      });
    }
    _initFetch();
  }

  ///更新对方的用户信息
  void updateContactInfo(ContactInfo? info) {
    if (contactInfo == null) {
      contactInfo = info;
    } else {
      final isOnline = contactInfo!.isOnline;
      contactInfo = info;
      contactInfo?.isOnline = isOnline;
    }
  }

  ///初始化用户在线状态
  void initUserState(String accountId) {
    if (!AIUserManager.instance.isAIUser(accountId)) {
      SubscriptionManager.instance.subscribeUserStatus([accountId]);
    }
  }

  List<ChatMessage> _messageList = [];

  List<ChatMessage> get messageList => _messageList.toList();

  //收到消息后滚动到最下边的回调
  void Function()? _scrollToEnd;

  set scrollToEnd(void Function() scrollToEnd) {
    _scrollToEnd = scrollToEnd;
  }

  NIMMessage? getAnchor(NIMQueryDirection direction) {
    return direction == NIMQueryDirection.asc
        ? _messageList.first.nimMessage
        : _messageList.last.nimMessage;
  }

  set messageList(List<ChatMessage> value) {
    _messageList = value;
    notifyListeners();
  }

  final subscriptions = <StreamSubscription>[];

  bool _isFilterMessage(NIMMessage message) {
    if (message.messageType == NIMMessageType.notification &&
        message.attachment is NIMMessageNotificationAttachment) {
      var attachment = message.attachment as NIMMessageNotificationAttachment;
      if (attachment.type == NIMMessageNotificationType.teamUpdateTInfo) {
        // 过滤被邀请人相关通知消息
        // if (attachment.updatedTeamInfo?.agreeMode != null &&
        //     attachment.updatedTeamInfo?.agreeMode != NIMTeamAgreeMode.unknown) {
        //   return true;
        // }
        // // 过滤群信息扩展参数变更通知消息
        // if (attachment.updatedTeamInfo?.serverExtension?.isNotEmpty == true) {
        //   return true;
        // }
      }
    }
    return false;
  }

  void _setNIMMessageListener() {
    if (initListener) return;
    initListener = true;
    _logI('message init listener');
    //new message
    subscriptions.add(
        NimCore.instance.messageService.onReceiveMessages.listen((event) async {
      //非当前会话的消息不处理
      if (event.first.conversationId != conversationId) {
        return;
      }
      _logI('receive msg -->> ${event.length}');
      //解决从搜索，PIN列表跳转的逻辑
      if (hasMoreNewerMessages) {
        _messageList.clear();
        _initFetch();
        return;
      }
      List<NIMMessage> list = event.where((element) {
        return element.conversationId == conversationId &&
            element.messageServerId != null &&
            !_isFilterMessage(element);
      }).toList();
      if (list.isNotEmpty) {
        var res = await ChatMessageRepo.fillUserInfo(list);
        //用户数据填充完成后再更新过滤
        //解决非常罕见的在填充数据时，消息状态更新回调，导致消息多一条的问题
        _insertMessages(
            res
                .where((element) => !_updateNimMessage(element.nimMessage))
                .toList(),
            toEnd: false);
        _scrollToEnd?.call();
      }
    }));
    //message status change
    subscriptions
        .add(NimCore.instance.messageService.onSendMessage.listen((msg) {
          //非当前会话的消息不处理
      if (msg.conversationId != conversationId) {
        return;
      }
      _logI(
          'onSendMessage ${msg.messageClientId} status change -->> ${msg.sendingState}, ${msg.attachmentUploadState}');
      if (hasMoreNewerMessages) {
        _messageList.clear();
        _initFetch();
      } else {
        if (_updateNimMessage(msg,
                    resort:
                        msg.sendingState == NIMMessageSendingState.succeeded) ==
                false &&
            msg.conversationId == conversationId) {
          //撤回的本地消息，不插入
          final chatMessage = ChatMessage(msg);
          if (chatMessage.isRevoke) {
            return;
          }
          //如果更新失败则添加
          _insertMessages([ChatMessage(msg)], toEnd: false);
        }
      }
    }));

    subscriptions
        .add(ChatServiceObserverRepo.observeMessageDelete().listen((event) {
      if (event.isNotEmpty) {
        for (var msg in event) {
          if (msg.messageRefer?.conversationId == conversationId &&
              msg.messageRefer?.conversationType == conversationType) {
            _messageList.removeWhere((element) =>
                element.nimMessage.messageClientId ==
                msg.messageRefer?.messageClientId);
            _selectedMessages.removeWhere(
                (e) => e.messageClientId == msg.messageRefer?.messageClientId);
          }
        }
        if (_messageList.length < _autoFetchMessageSize &&
            hasMoreForwardMessages) {
          fetchMoreMessage(NIMQueryDirection.desc);
        }
        notifyListeners();
      }
    }));

    //昵称更新
    subscriptions.add(NIMChatCache.instance.contactInfoNotifier.listen((event) {
      if (conversationType == NIMConversationType.p2p &&
          event.user.accountId == _sessionId) {
        updateContactInfo(event);
        chatTitle = event.getName();
      }
      notifyListeners();
    }));

    if (conversationType == NIMConversationType.team) {
      //team message receipt
      subscriptions.add(
          ChatServiceObserverRepo.observeTeamMessageReceipt().listen((event) {
        for (var element in event) {
          _updateTeamReceipt(element);
        }
      }));

      //群信息更新
      subscriptions.add(NIMChatCache.instance.teamInfoNotifier.listen((event) {
        if (event.teamId == _sessionId) {
          teamInfo = event;
          chatTitle = event.name;
          mute = (teamInfo?.chatBannedMode ==
                      NIMTeamChatBannedMode.chatBannedModeBannedNormal &&
                  NIMChatCache.instance.myTeamRole() ==
                      NIMTeamMemberRole.memberRoleNormal) ||
              teamInfo?.chatBannedMode ==
                  NIMTeamChatBannedMode.chatBannedModeBannedAll;
          notifyListeners();
        }
      }));

      //群成员更新
      subscriptions
          .add(NIMChatCache.instance.teamMembersNotifier.listen((event) {
        if (event.first.teamInfo.teamId == _sessionId) {
          for (var member in event) {
            if (member.teamInfo.accountId == IMKitClient.account()) {
              mute = (teamInfo?.chatBannedMode ==
                          NIMTeamChatBannedMode.chatBannedModeBannedNormal &&
                      NIMChatCache.instance.myTeamRole() ==
                          NIMTeamMemberRole.memberRoleNormal) ||
                  teamInfo?.chatBannedMode ==
                      NIMTeamChatBannedMode.chatBannedModeBannedAll;
            }
          }
        }
      }));
    } else if (conversationType == NIMConversationType.p2p) {
      //p2p message receipt
      subscriptions
          .add(ChatServiceObserverRepo.observeMessageReceipt().listen((event) {
        _updateP2PReceipt(event);
      }));

      subscriptions.add(ChatServiceObserverRepo.observeCustomNotification()
          .listen((notifications) {
        notifications.forEach((notification) {
          if (notification.senderId != _sessionId ||
              notification.conversationType != NIMConversationType.p2p) {
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
        });
      }));

      subscriptions.add(NimCore.instance.subscriptionService.onUserStatusChanged
          .listen((List<NIMUserStatus> userList) {
        for (final user in userList) {
          if (user.accountId == contactInfo?.user.accountId) {
            contactInfo?.isOnline = (user.statusType == 1);
            notifyListeners();
          }
        }
      }));
    }

    //监听消息修改
    subscriptions
        .add(ChatServiceObserverRepo.observeModifyMessage().listen((msgList) {
      _logI('received modifyMessage notify and save a local message');
      // 将 msgList 转换为 Map<messageId, Message>
      final msgMap = {for (var msg in msgList) msg.messageClientId: msg};
      // 生成新列表：存在则替换，否则保留原元素
      List<ChatMessage> updatedList = messageList.map((msg) {
        if (msgMap.containsKey(msg.nimMessage.messageClientId)) {
          msg.nimMessage = msgMap[msg.nimMessage.messageClientId!]!;
        }
        return msg;
      }).toList();
      _messageList = updatedList;
      notifyListeners();
    }));

    //监听消息撤回
    subscriptions
        .add(ChatServiceObserverRepo.observeRevokeMessage().listen((messages) {
      _logI('received revokeMessage notify and save a local message');
      messages.forEach((e) {
        if (e.messageRefer?.conversationId == conversationId) {
          _onMessageRevokedNotify(e);
        }
      });
    }));

    //监听Pin消息变化
    subscriptions
        .add(NIMChatCache.instance.pinnedMessagesNotifier.listen((event) {
      Alog.d(tag: 'ChatViewModel', content: 'pinnedMessagesNotifier $event');
      event = event as PinMessageEvent;
      if (event.notification?.pinState == NIMMessagePinState.notPinned &&
          event.notification?.pin != null) {
        _updateMessagePin(event.notification!.pin!, delete: true);
      } else if (event.type == PinEventType.init) {
        for (var message in messageList) {
          message.pinOption = null;
        }
        for (var pin in event.pinMessages) {
          _updateMessagePin(pin);
        }
      } else if (event.notification?.pin != null) {
        _updateMessagePin(event.notification!.pin!);
      }
    }));
  }

  void _onMessageRevokedNotify(
      NIMMessageRevokeNotification notification) async {
    //不处理自己revoke的消息
    if (notification.revokeAccountId == IMKitClient.account() &&
        revokeMessageId == notification.messageRefer?.messageClientId) {
      return;
    }
    final localMessage = await ChatKitClientRepo.instance
        .onMessageRevokedNotify(
            notification, S.of().chatMessageHaveBeenRevoked);
    if (localMessage.isSuccess && localMessage.data != null) {
      int pos = _messageList.indexWhere((e) =>
          e.nimMessage.messageClientId ==
          notification.messageRefer?.messageClientId);
      if (pos >= 0) {
        _messageList[pos] = ChatMessage(localMessage.data!);
        _selectedMessages.removeWhere((element) =>
            element.messageClientId ==
            notification.messageRefer?.messageClientId);
        notifyListeners();
      }
    }
  }

  ///将消息插入列表，确保插入后的消息新消息在前，
  ///[toEnd] true:插入到最后，false:插入到最前
  void _insertMessages(List<ChatMessage> messages, {bool toEnd = true}) {
    if (messages.isEmpty) {
      return;
    }
    //如果第一条比最后一条旧，则反转,确保最新的消息在最前
    bool needReverse = messages.first.nimMessage.createTime! <
        messages.last.nimMessage.createTime!;
    if (needReverse) {
      messages = messages.reversed.toList();
    }
    if (_messageList.isEmpty) {
      _messageList.addAll(messages);
    } else {
      //获取第一条，结果为最新的消息
      var lastMsg = messages.first;
      var index = 0;
      if (toEnd) {
        //如果最新消息比消息列表中最后一条消息还要旧，则插入到最后
        if (lastMsg.nimMessage.createTime! <
            _messageList.last.nimMessage.createTime!) {
          index = _messageList.length;
        } else {
          //则从后遍历，插入到比自己新的消息之后的位置
          for (int i = _messageList.length - 1; i >= 0; i--) {
            //找到第一条比最新的消息更新的消息，插入到该消息后面
            if (lastMsg.nimMessage.createTime! <
                _messageList[i].nimMessage.createTime!) {
              index = i + 1;
              break;
            }
          }
        }
      } else if (lastMsg.nimMessage.createTime! <
          _messageList.first.nimMessage.createTime!) {
        //如果消息列表中的第一条消息比最新消息新，则从前遍历，插入到比自己旧的消息之前的位置
        for (int i = 0; i < _messageList.length; i++) {
          //找到第一条比最新的消息旧的消息，插入到该消息前面
          if (lastMsg.nimMessage.createTime! >
              _messageList[i].nimMessage.createTime!) {
            index = i;
            break;
          }
        }
      }

      _logD('insert message at $index to end:$toEnd');
      _messageList.insertAll(index, messages);
      _messageList
          .sort((a, b) => b.nimMessage.createTime! - a.nimMessage.createTime!);
    }
    notifyListeners();
  }

  void sendInputNotification(bool isTyping) {
    Map<String, dynamic> content = {typeState: isTyping ? 1 : 0};
    var json = jsonEncode(content);
    var params = NIMSendCustomNotificationParams(
        notificationConfig:
            NIMNotificationConfig(unreadEnabled: false, offlineEnabled: false),
        pushConfig: NIMNotificationPushConfig(pushEnabled: false));
    ChatMessageRepo.sendCustomNotification(conversationId, json, params);
  }

  void _initFetch() async {
    _logI('initFetch -->>');
    hasMoreForwardMessages = true;
    hasMoreNewerMessages = false;
    _fetchMoreMessage(anchor: null, init: true);
  }

  void loadMessageWithAnchor(NIMMessage anchor) {
    _logI('initFetch -->> anchor:${anchor.text}');
    _messageList.clear();
    hasMoreForwardMessages = true;
    hasMoreNewerMessages = true;
    _fetchMessageListBothDirect(anchor);
  }

  _fetchMessageListBothDirect(NIMMessage anchor) async {
    _logI('fetchMessageListBothDirect');

    isLoading = true;

    NIMMessageListOption optionNewer = NIMMessageListOption(
        conversationId: conversationId,
        limit: (messageLimit / 2).toInt(),
        direction: NIMQueryDirection.asc,
        anchorMessage: anchor);
    final newerMsgs = await ChatMessageRepo.getMessageList(optionNewer,
        enablePin: IMKitClient.enablePin, addUserInfo: true);

    if (newerMsgs.isSuccess) {
      hasMoreNewerMessages = newerMsgs.data?.isNotEmpty == true;
      if (newerMsgs.data?.isNotEmpty == true) {
        _messageList.addAll(newerMsgs.data!.reversed);
      }
    }

    ChatMessage anchorMessage = ChatMessage(anchor);
    var contact = await getIt<ContactProvider>()
        .getContact(anchor.senderId!, needFriend: false);
    anchorMessage.fromUser = contact?.user;

    List<NIMMessagePin> pinRes = NIMChatCache.instance.pinnedMessages;
    if (pinRes.isNotEmpty) {
      var pinList = pinRes;
      anchorMessage.pinOption = pinList.firstWhereOrNull(
          (pin) => _isSameMessage(anchorMessage.nimMessage, pin));
    }

    _messageList.add(anchorMessage);

    NIMMessageListOption optionOlder = NIMMessageListOption(
        conversationId: conversationId,
        limit: (messageLimit / 2).toInt(),
        direction: NIMQueryDirection.desc,
        anchorMessage: anchor);
    final olderMsgs = await ChatMessageRepo.getMessageList(optionOlder,
        enablePin: IMKitClient.enablePin, addUserInfo: true);
    if (olderMsgs.isSuccess) {
      hasMoreForwardMessages = olderMsgs.data?.isNotEmpty == true;
      if (olderMsgs.data?.isNotEmpty == true) {
        _messageList.addAll(olderMsgs.data!);
      }
    }

    isLoading = false;

    notifyListeners();
  }

  fetchMoreMessage(NIMQueryDirection direction) {
    _fetchMoreMessage(anchor: getAnchor(direction), direction: direction);
  }

  _fetchMoreMessage(
      {NIMMessage? anchor,
      int? limit,
      NIMQueryDirection direction = NIMQueryDirection.desc,
      bool init = false}) {
    _logI(
        '_fetchMoreMessage anchor ${anchor?.text}, time = ${anchor?.createTime!}, direction = $direction');

    isLoading = true;
    NIMMessageListOption option = NIMMessageListOption(
        conversationId: conversationId,
        limit: limit ?? messageLimit,
        direction: direction,
        anchorMessage: anchor);
    ChatMessageRepo.getMessageList(option,
            enablePin: IMKitClient.enablePin, addUserInfo: true)
        .then((value) {
      if (value.isSuccess && value.data != null) {
        _logI('_fetchMoreMessage success, length = ${value.data?.length}');
        if (init &&
            value.data?.isNotEmpty != true &&
            AIUserManager.instance.isAIUser(_sessionId)) {
          //如果拉取不到消息，并且是数字人，则插入消息
          final welcomeText =
              AIUserManager.instance.getWelcomeText(_sessionId!);
          if (welcomeText?.isNotEmpty == true) {
            ChatMessageRepo.insertLocalTextMessage(conversationId, welcomeText!,
                senderId: _sessionId);
          }
          isLoading = false;
        } else {
          _onListFetchSuccess(value.data!, direction);
        }

        // }
      } else {
        _logI(
            '_fetchMoreMessage failed, code = ${value.code}, error = ${value.errorDetails}');
        _onListFetchFailed(value.code, value.errorDetails);
      }
    });
  }

  ///会话对象是否是数字人
  bool isAIUser() {
    if (conversationType != NIMConversationType.p2p) {
      return false;
    }
    return AIUserManager.instance.isAIUser(_sessionId);
  }

  _onListFetchSuccess(List<ChatMessage>? list, NIMQueryDirection direction) {
    if (direction == NIMQueryDirection.desc) {
      //先判断是否有更多，在过滤
      hasMoreForwardMessages = (list != null && list.isNotEmpty);
      _logD(
          'older forward has more:$hasMoreForwardMessages because list length =  ${list?.length}');
      list = _successMessageFilter(list);
      if (list != null) {
        _insertMessages(list, toEnd: true);
      }
    } else {
      hasMoreNewerMessages = list != null && list.isNotEmpty;
      list = _successMessageFilter(list);
      _logI('newer load has more:$hasMoreNewerMessages');
      if (list != null) {
        _insertMessages(list, toEnd: false);
        notifyListeners();
      }
    }
    isLoading = false;
  }

  //请求列表成功后过滤掉不需要添加的消息
  List<ChatMessage>? _successMessageFilter(List<ChatMessage>? list) {
    return list
        ?.where((element) =>
            !_isFilterMessage(element.nimMessage) &&
            !_updateNimMessage(element.nimMessage))
        .toList();
  }

  _onListFetchFailed(int code, String? errorMsg) {
    isLoading = false;
    _logI('onListFetchFailed code:$code, msg:$errorMsg');
  }

  void _updateTeamReceipt(NIMTeamMessageReadReceipt messageReceipt) {
    for (var message in _messageList) {
      if (message.nimMessage.messageClientId ==
          messageReceipt.messageClientId) {
        message.unAckCount = messageReceipt.unreadCount;
        message.ackCount = messageReceipt.readCount;
        _updateMessage(message);
      }
    }
  }

  void _updateP2PReceipt(List<NIMP2PMessageReadReceipt> receipts) {
    for (var element in receipts) {
      if (receiptTime < element.timestamp!) {
        receiptTime = element.timestamp!;
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

  ///是否是被选中的消息
  bool isSelectedMessage(NIMMessage message) {
    return _selectedMessages.firstWhereOrNull(
            (element) => element.messageClientId == message.messageClientId) !=
        null;
  }

  ///添加选中的消息
  void addSelectedMessage(NIMMessage message) {
    if (isSelectedMessage(message)) {
      return;
    }
    _selectedMessages.add(message);
    notifyListeners();
  }

  ///移除选中的消息
  void removeSelectedMessage(NIMMessage message) {
    _selectedMessages.removeWhere(
        (element) => element.messageClientId == message.messageClientId);
    notifyListeners();
  }

  ///移除选中的消息
  void removeSelectedMessages(List<NIMMessage> messages) {
    for (var msg in messages) {
      _selectedMessages.removeWhere(
          (element) => element.messageClientId == msg.messageClientId);
    }
    notifyListeners();
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
      {NIMMessage? replyMsg,
      List<String>? pushList,
      AitContactsModel? aitContactsModel,
      String? title}) async {
    var aitMap;

    if (aitContactsModel?.aitBlocks.isNotEmpty == true) {
      aitMap = aitContactsModel?.toMap();
    }

    var customData =
        ChatMessageHelper.getMultiLineMessageMap(title: title, content: text);

    var customJson = customData == null ? '' : jsonEncode(customData);

    var pushConfig = null;

    var msgBuildResult = (title?.isNotEmpty == true)
        ? (await MessageCreator.createCustomMessage("", customJson))
        : (await MessageCreator.createTextMessage(text));
    if (msgBuildResult.isSuccess && msgBuildResult.data != null) {
      if (conversationType == NIMConversationType.team && pushList != null) {
        pushConfig = NIMMessagePushConfig(
            pushContent: title ?? text,
            forcePush: true,
            forcePushContent: title ?? text,
            forcePushAccountIds: pushList);
      } else {
        //兼容单聊@ 数字人的case，此处forcePush 不生效，只用于获取数字人agent
        pushConfig = NIMMessagePushConfig(
            pushContent: title ?? text, forcePushAccountIds: pushList);
      }
      if (aitMap != null) {
        msgBuildResult.data!.serverExtension = jsonEncode({
          ChatMessage.keyAitMsg: aitMap,
        });
      }
      sendMessage(
        msgBuildResult.data!,
        replyMsg: replyMsg,
        pushConfig: pushConfig,
      );
    }
  }

  void sendAudioMessage(String filePath, String? name, int duration,
      {NIMMessage? replyMsg}) {
    MessageCreator.createAudioMessage(filePath, name, null, duration)
        .then((value) {
      if (value.isSuccess) {
        sendMessage(value.data!, replyMsg: replyMsg);
      }
    });
  }

  void sendImageMessage(String filePath, String? name, int width, int height,
      {NIMMessage? replyMsg, String? imageType}) {
    MessageCreator.createImageMessage(filePath, name, null, width, height)
        .then((value) {
      if (value.isSuccess) {
        if (imageType?.isNotEmpty == true) {
          value.data!.serverExtension =
              jsonEncode({ChatMessage.keyImageType: imageType});
        }
        sendMessage(value.data!, replyMsg: replyMsg);
      }
    });
  }

  //发送位置消息，不能用位置消息回复其他消息
  void sendLocationMessage(LocationInfo location) {
    MessageCreator.createLocationMessage(
            location.latitude, location.longitude, location.address ?? '')
        .then((ret) {
      if (ret.isSuccess && ret.data != null) {
        ret.data!.text = location.name;
        sendMessage(ret.data!);
      }
    });
  }

  void sendVideoMessage(
      String videoPath, String? name, int duration, int width, int height,
      {NIMMessage? replyMsg}) {
    MessageCreator.createVideoMessage(
            videoPath, name, null, duration, width, height)
        .then((value) {
      if (value.isSuccess) {
        sendMessage(value.data!, replyMsg: replyMsg);
      }
    });
  }

  void sendFileMessage(String filePath, String name, {NIMMessage? replyMsg}) {
    MessageCreator.createFileMessage(filePath, name, null)
        .then((value) => sendMessage(value.data!, replyMsg: replyMsg));
  }

  void resendMessage(ChatMessage message, {NIMMessage? replyMsg}) {}

  ///发送消息最终实现
  ///[message] 消息
  ///[replyMsg] 回复消息
  /// [pushConfig] 推送配置
  /// [aiAgent] 消息发送的AI代理
  void sendMessage(
    NIMMessage message, {
    NIMMessage? replyMsg,
    NIMMessagePushConfig? pushConfig,
  }) async {
    final params = await ChatMessageHelper.getSenderParams(
        message, conversationId,
        pushConfig: pushConfig);
    //设置aiAgent
    // 根据forcePushAccountIds 设置
    NIMAIUser? aiAgent;
    if (pushConfig?.forcePushAccountIds?.isNotEmpty == true ||
        message.pushConfig?.forcePushAccountIds?.isNotEmpty == true) {
      final pushList = pushConfig?.forcePushAccountIds?.isNotEmpty == true
          ? pushConfig?.forcePushAccountIds
          : message.pushConfig?.forcePushAccountIds;
      for (var accId in pushList!) {
        if (AIUserManager.instance.getAIUserById(accId!) != null) {
          aiAgent = AIUserManager.instance.getAIUserById(accId);
          break;
        }
      }
    }
    if (aiAgent == null && isAIUser()) {
      //如果是AI用户，设置aiAgent 为单聊对象
      aiAgent = AIUserManager.instance.getAIUserById(_sessionId!);
    }
    //处理重发的case，从消息的 Config 中获取
    if (aiAgent == null && message.aiConfig?.accountId?.isNotEmpty == true) {
      aiAgent =
          AIUserManager.instance.getAIUserById(message.aiConfig!.accountId!);
    }
    //根据回复消息设置上下文
    List<NIMAIModelCallMessage>? aiMessages;
    if (aiAgent != null && replyMsg != null) {
      final textMsg = ChatMessageHelper.getAIContentMsg(replyMsg);
      if (textMsg != null) {
        aiMessages = [
          NIMAIModelCallMessage(
              type: 0, msg: textMsg, role: NIMAIModelRoleType.user)
        ];
      }
    }
    NIMMessageAIConfigParams? aiConfigParams;
    if (aiAgent != null) {
      final aiStreamMode = await IMKitClient.enableAIStream;
      // AI 参数处理
      aiConfigParams = NIMMessageAIConfigParams(
          accountId: aiAgent.accountId, aiStream: aiStreamMode);
      if (ChatMessageHelper.getAIContentMsg(message)?.isNotEmpty == true) {
        NIMAIModelCallContent content = NIMAIModelCallContent(
            type: 0, msg: ChatMessageHelper.getAIContentMsg(message));
        aiConfigParams.content = content;
      }
    }
    //处理与数字人单聊的上下文
    if (aiConfigParams != null) {
      if (aiMessages?.isNotEmpty == true) {
        aiConfigParams.messages = aiMessages;
      } else if (isAIUser()) {
        //如果没有AI上下文，则取最近的30条消息
        aiConfigParams.messages = getAIMessages();
      }
    }

    params.aiConfig = aiConfigParams;

    //处理重发case
    if (replyMsg == null &&
        message.sendingState == NIMMessageSendingState.failed &&
        message.threadReply?.messageClientId?.isNotEmpty == true) {
      replyMsg = (await NimCore.instance.messageService
              .getMessageListByRefers(messageRefers: [message.threadReply!]))
          .data
          ?.first;
    }

    //发送前的对外回调
    if (ChatKitClient.instance.messageAction != null) {
      ChatKitClient.instance.messageAction!(message, conversationId, params);
    }

    if (replyMsg != null) {
      ChatMessageRepo.replyMessage(
              msg: message, replyMsg: replyMsg, params: params)
          .then((result) {
        //如果是被拉黑，则提示
        if (result.code == ChatMessageRepo.errorInBlackList) {
          _saveBlackListTips();
        }
      });
    } else {
      ChatMessageRepo.sendMessage(
              message: message, conversationId: conversationId, params: params)
          .then((result) {
        //如果是被拉黑，则提示
        if (result.code == ChatMessageRepo.errorInBlackList) {
          _saveBlackListTips();
        }
      });
    }
  }

  ///获取AI消息的上下文
  ///仅对数字人单聊
  List<NIMAIModelCallMessage?>? getAIMessages() {
    int size = min(_messageList.length, aiMessageSize);
    List<NIMAIModelCallMessage?>? aiMessages;
    if (isAIUser() && _messageList.isNotEmpty) {
      aiMessages = <NIMAIModelCallMessage?>[];
      //第一条消息不能是数字人消息
      // 标记是否已经设置过第一条消息
      bool firstSet = false;
      for (int index = 0; index < size; index++) {
        final message = _messageList[index];
        bool isFromAI =
            AIUserManager.instance.isAIUser(message.nimMessage.senderId);
        //1 如果第一条是数字人消息，则不再添加
        //2 如果消息已经撤回，则不再添加
        //3 如果消息没有服务器ID，说明不是发出去的消息，则不再添加
        //4 如果没有消息内容，则不再添加
        if ((!firstSet && !isFromAI) ||
            message.isRevoke ||
            message.nimMessage.messageServerId?.isNotEmpty != true ||
            ChatMessageHelper.getAIContentMsg(message.nimMessage)?.isNotEmpty !=
                true) {
          continue;
        }
        firstSet = true;
        aiMessages.add(NIMAIModelCallMessage(
            type: 0,
            msg: ChatMessageHelper.getAIContentMsg(message.nimMessage),
            role: isFromAI
                ? NIMAIModelRoleType.assistant
                : NIMAIModelRoleType.user));
      }
    }
    return aiMessages;
  }

  void translateInputText(String sourceText, String language) {
    NIMProxyAIModelCallParams request = NIMProxyAIModelCallParams();
    request.accountId = AIUserManager.instance.getAITranslateUser()?.accountId;

    translationLanguageRequestId = Uuid().v4().toUpperCase();
    request.requestId = translationLanguageRequestId;

    NIMAIModelCallContent content = NIMAIModelCallContent(type: 0);
    content.msg = sourceText;
    request.content = content;

    NIMAIModelConfigParams configParams = NIMAIModelConfigParams();
    configParams.temperature = translateTemperature;
    request.modelConfigParams = configParams;

    String promptKey = translatePromptKey;
    final Map<String, dynamic> promptVariables = {};
    promptVariables[promptKey] = language;
    request.promptVariables = jsonEncode(promptVariables);

    NimCore.instance.aiService.proxyAIModelCall(request);
  }

  void _saveBlackListTips() {
    MessageCreator.createTipsMessage(S.of().chatMessageSendFailedByBlackList)
        .then((value) {
      if (value.isSuccess && value.data != null) {
        // value.data!.config =
        //     NIMCustomMessageConfig(enablePush: false, enableUnreadCount: false);
        value.data!.pushConfig = NIMMessagePushConfig(pushEnabled: false);
        value.data!.messageConfig = NIMMessageConfig(unreadEnabled: false);
        NimCore.instance.messageService.insertMessageToLocal(
          message: value.data!,
          conversationId: conversationId,
        );
        _messageList.insert(0, ChatMessage(value.data!));
        notifyListeners();
      }
    });
  }

  bool _updateNimMessage(NIMMessage nimMessage, {bool resort = false}) {
    int pos = _messageList.indexWhere((element) =>
        nimMessage.messageClientId == element.nimMessage.messageClientId);
    if (pos >= 0) {
      _logI('update nim message at $pos');
      //如果列表中的附件已经是完成状态，而更新的文件是传输状态，则不更新
      if (!(_messageList[pos].nimMessage.attachmentUploadState ==
              NIMMessageAttachmentUploadState.succeed &&
          nimMessage.attachmentUploadState ==
              NIMMessageAttachmentUploadState.uploading)) {
        _messageList[pos].nimMessage = nimMessage;
      }
      if (resort) {
        _messageList.sort(
            (a, b) => b.nimMessage.createTime! - a.nimMessage.createTime!);
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  ///合并转发
  ///[exitMultiMode] 是否退出多选模式
  ///[postScript] 转发后的附言
  ///[conversationId] 转发的目标会话id
  ///[errorToast] 转发失败的提示
  void mergedMessageForward(String conversationId,
      {String? postScript,
      String? errorToast,
      bool exitMultiMode = true}) async {
    if (await haveConnectivity()) {
      _selectedMessages.removeWhere((element) =>
          element.sendingState == NIMMessageSendingState.failed ||
          element.sendingState == NIMMessageSendingState.sending);
      _selectedMessages.sort((a, b) => a.createTime! - b.createTime!);
      MergeMessageHelper.createMergedMessage(selectedMessages)
          .then((value) async {
        if (value.isSuccess && value.data != null) {
          final params = await ChatMessageHelper.getSenderParams(
              value.data!, conversationId);
          ChatMessageRepo.sendMessage(
                  message: value.data!,
                  conversationId: conversationId,
                  params: params)
              .then((value) {
            if (value.code == ChatMessageRepo.errorInBlackList) {
              ChatMessageRepo.saveTipsMessage(
                  conversationId, S.of().chatMessageSendFailedByBlackList);
            }
            if (postScript?.isNotEmpty == true) {
              ChatMessageRepo.sendTextMessageWithMessageAck(
                      conversationId: conversationId, text: postScript!)
                  .then((msgSend) {
                if (msgSend.code == ChatMessageRepo.errorInBlackList) {
                  ChatMessageRepo.saveTipsMessage(
                      conversationId, S.of().chatMessageSendFailedByBlackList);
                }
              });
            }
          });
        } else {
          _logI(
              'createMergedMessage failed, code = ${value.code}, error = ${value.errorDetails}');
          if (errorToast?.isNotEmpty == true) {
            Fluttertoast.showToast(msg: errorToast!);
          }
        }
        if (exitMultiMode) {
          isMultiSelected = false;
        }
        notifyListeners();
      });
    }
  }

  bool filterForwardMessage(bool Function(NIMMessage) filter) {
    var oldLength = _selectedMessages.length;
    _selectedMessages.removeWhere((element) => filter(element));
    notifyListeners();
    return oldLength > _selectedMessages.length;
  }

  ///逐条转发
  ///[exitMultiMode] 是否退出多选模式
  ///[postScript] 转发后的附言
  ///[conversationId] 转发的目标会话id
  void forwardMessageOneByOne(String conversationId,
      {String? postScript, bool exitMultiMode = true}) async {
    if (!await haveConnectivity()) {
      return;
    }
    _selectedMessages.removeWhere((element) =>
        element.sendingState == NIMMessageSendingState.failed ||
        element.sendingState == NIMMessageSendingState.sending);
    for (var element in _selectedMessages) {
      forwardMessage(element, conversationId);
    }
    if (postScript?.isNotEmpty == true) {
      ChatMessageRepo.sendTextMessageWithMessageAck(
              conversationId: conversationId, text: postScript!)
          .then((msgSend) {
        if (msgSend.code == ChatMessageRepo.errorInBlackList) {
          ChatMessageRepo.saveTipsMessage(
              conversationId, S.of().chatMessageSendFailedByBlackList);
        }
      });
    }
    if (exitMultiMode) {
      isMultiSelected = false;
    }
    notifyListeners();
  }

  ///逐条删除
  void deleteMessageOneByOne() async {
    if (!await haveConnectivity()) {
      return;
    }

    if (_selectedMessages.length < 100) {
      _deleteMsgList(_selectedMessages);
    } else {
      //远端删除消息，每次最多删除99条
      int i = 0;
      int j = 99;
      final deleteMessage = List.of(_selectedMessages);
      while (i < deleteMessage.length && j <= deleteMessage.length) {
        //异步操作防止触发频控
        await _deleteMsgList(
            deleteMessage.sublist(i, min(j, deleteMessage.length)));
        i = j;
        j = min(j + 99, deleteMessage.length);
      }
    }
  }

  //批量删除消息
  //如果是本地消息，则直接删除本地消息
  //如果是远程消息，则删除远程消息
  Future<void> _deleteMsgList(List<NIMMessage> deleteMsgList) async {
    var localMessage = deleteMsgList
        .where((element) =>
            element.sendingState == NIMMessageSendingState.failed ||
            element.messageServerId == '0')
        .toList();
    if (localMessage.isNotEmpty) {
      await ChatMessageRepo.deleteLocalMessageList(localMessage);
      var uuidList = localMessage.map((e) => e.messageClientId).toList();
      _messageList
          .removeWhere((e) => uuidList.contains(e.nimMessage.messageClientId));
    }

    var remoteMessage = deleteMsgList
        .where((element) =>
            element.sendingState == NIMMessageSendingState.succeeded ||
            element.messageServerId != '0')
        .toList();
    if (remoteMessage.isNotEmpty) {
      var remoteResult = await ChatMessageRepo.deleteMessageList(remoteMessage);
      if (remoteResult.isSuccess) {
        var uuidList = remoteMessage.map((e) => e.messageClientId).toList();
        _messageList.removeWhere(
            (e) => uuidList.contains(e.nimMessage.messageClientId));
      }
    }
    isMultiSelected = false;
    notifyListeners();
    if (_messageList.length < _autoFetchMessageSize && hasMoreForwardMessages) {
      fetchMoreMessage(NIMQueryDirection.desc);
    }
  }

  void forwardMessage(NIMMessage message, String conversationId,
      {String? postScript}) async {
    if (await haveConnectivity()) {
      final params =
          await ChatMessageHelper.getSenderParams(message, conversationId);
      ChatMessageRepo.forwardMessage(message, conversationId, params: params)
          .then((value) {
        if (value.code == ChatMessageRepo.errorInBlackList) {
          ChatMessageRepo.saveTipsMessage(
              conversationId, S.of().chatMessageSendFailedByBlackList);
        }
        if (postScript?.isNotEmpty == true) {
          ChatMessageRepo.sendTextMessageWithMessageAck(
                  conversationId: conversationId, text: postScript!)
              .then((msgSend) {
            if (msgSend.code == ChatMessageRepo.errorInBlackList) {
              ChatMessageRepo.saveTipsMessage(
                  conversationId, S.of().chatMessageSendFailedByBlackList);
            }
          });
        }
        notifyListeners();
      });
    }
  }

  Future<NIMResult<void>> addMessagePin(NIMMessage message,
      {String? ext}) async {
    if (!await haveConnectivity()) {
      return NIMResult.failure();
    }
    return ChatMessageRepo.addMessagePin(message, ext: ext).then((value) {
      if (value.isSuccess) {
        _updateMessagePin(NIMMessagePin(
            messageRefer: NIMMessageRefer(
                senderId: message.senderId,
                receiverId: message.receiverId,
                messageClientId: message.messageClientId,
                messageServerId: message.messageServerId,
                conversationId: message.conversationId,
                conversationType: message.conversationType,
                createTime: message.createTime)));
      }
      return value;
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
                messageRefer: NIMMessageRefer(
                    senderId: message.senderId,
                    receiverId: message.receiverId,
                    messageClientId: message.messageClientId,
                    messageServerId: message.messageServerId,
                    conversationId: message.conversationId,
                    conversationType: message.conversationType,
                    createTime: message.createTime)),
            delete: true);
      }
    });
  }

  void collectMessage(NIMMessage message) {
    ChatMessageRepo.collectMessage(message);
  }

  ///delete message
  void deleteMessage(ChatMessage message) async {
    if (!await haveConnectivity()) {
      return;
    }

    ///删除消息,如果失败则调用本地删除
    ChatMessageRepo.deleteMessage(message.nimMessage).then((value) {
      if (value.isSuccess) {
        _onMessageDeleted(message);
      } else {
        ChatMessageRepo.deleteLocalMessage(message.nimMessage).then((value) {
          _onMessageDeleted(message);
        });
      }
    });
  }

  void _onMessageDeleted(ChatMessage message) {
    _messageList.remove(message);
    notifyListeners();
  }

  ///撤回消息
  Future<NIMResult<void>> revokeMessage(ChatMessage message) {
    revokeMessageId = message.nimMessage.messageClientId;
    return ChatMessageRepo.revokeMessage(message.nimMessage).then((value) {
      if (value.isSuccess) {
        _logI('revokeMessage success and save a local message');
        _onMessageRevoked(message);
      }
      return value;
    });
  }

  void _onMessageRevoked(ChatMessage revokedMsg) async {
    final localMessage = await ChatKitClientRepo.instance
        .onMessageRevoked(revokedMsg, S.of().chatMessageHaveBeenRevoked);
    if (localMessage.isSuccess && localMessage.data != null) {
      int pos = _messageList.indexOf(revokedMsg);
      if (pos >= 0) {
        _messageList[pos] = ChatMessage(localMessage.data!);
        _selectedMessages.removeWhere((element) =>
            element.messageClientId == revokedMsg.nimMessage.messageClientId);
        notifyListeners();
      }
    }
  }

  //发送已读回执，只有当前的消息比之前发的新的时候才发
  void sendMessageP2PReceipt(NIMMessage message) {
    if ((message.createTime ?? 0) > markP2PMessageReadReceiptTime) {
      ChatMessageRepo.markP2PMessageRead(message: message).then((result) {
        if (result.isSuccess) {
          markP2PMessageReadReceiptTime = message.createTime!;
        }
      });
    }
  }

  void sendTeamMessageReceipt(ChatMessage message) {
    ChatMessageRepo.markTeamMessageRead([message.nimMessage]).then((result) {
      //do nothing
    });
  }

  bool _isSameMessage(NIMMessage nimMessage, NIMMessagePin messagePin) {
    if (nimMessage.messageServerId != null &&
        nimMessage.messageServerId != '-1' &&
        messagePin.messageRefer?.messageServerId != null &&
        messagePin.messageRefer?.messageServerId != '-1') {
      return nimMessage.messageServerId ==
          messagePin.messageRefer?.messageServerId;
    } else {
      return nimMessage.messageClientId ==
          messagePin.messageRefer?.messageClientId;
    }
  }

  void _logI(String content) {
    Alog.i(tag: 'ChatKit', moduleName: '$logTag $_sessionId', content: content);
  }

  void _logD(String content) {
    Alog.d(tag: 'ChatKit', moduleName: '$logTag $_sessionId', content: content);
  }

  @override
  void dispose() {
    for (var sub in subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
