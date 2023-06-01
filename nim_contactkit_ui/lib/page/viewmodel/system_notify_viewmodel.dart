// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:nim_contactkit/repo/contact_repo.dart';
import 'package:flutter/cupertino.dart';
import 'package:nim_core/nim_core.dart';

import '../../l10n/S.dart';

class SystemNotifyViewModel extends ChangeNotifier {
  List<SystemNotifyMerged> systemMessages = List.empty(growable: true);

  static const queryMessageLimit = 100;

  static const logTag = 'SystemNotifyViewModel';

  //7 day expire time
  static const expireLimit = 7 * 24 * 60 * 60 * 1000;

  //失效，其他端已经处理
  static const resInvalid = 509;

  bool haveMore = true;

  SystemMessage? lastMessage;

  StreamSubscription? _subscription;

  ///分页请求行通知
  ///如果返回false 表示 需要继续请求
  Future<bool> querySystemMessage({int offset = 0}) {
    return ContactRepo.getNotificationList(queryMessageLimit,
            offset: offset, systemMessage: lastMessage)
        .then((value) {
      if (value.isSuccess) {
        int preLen = systemMessages.length;
        _setSysMsgExpire(value.data);
        _addNewToSystemMessages(value.data ?? []);
        if (value.data != null && value.data!.length >= queryMessageLimit) {
          haveMore = true;
        } else {
          haveMore = false;
        }
        if (value.data != null && value.data!.isNotEmpty) {
          lastMessage = value.data!.last;
        }
        notifyListeners();
        int newLen = systemMessages.length;
        //1，非首次请求 2，还有更多 3，请求结果不为空 4，合并前后sysMsg长度一样
        //表示此次请求所有的结果都被merge，需要再次请求，所以返回false
        if (offset > 0 &&
            haveMore &&
            (value.data?.length ?? 0) > 0 &&
            newLen == preLen) {
          return false;
        }
      }
      return true;
    });
  }

  //设置过期
  _setSysMsgExpire(List<SystemMessage>? sysMsg) {
    var lastTime = DateTime.now().millisecondsSinceEpoch - expireLimit;
    sysMsg?.forEach((e) {
      if (e.status == SystemMessageStatus.init && (e.time ?? 0) < lastTime) {
        e.status = SystemMessageStatus.expired;
        ContactRepo.setVerifyStatus(e.messageId!, SystemMessageStatus.expired);
      }
    });
  }

  _addNewToSystemMessages(List<SystemMessage> newMsg,
      {bool insertToFirst = false}) {
    newMsg.forEach((msg) {
      var index = -1;
      for (int i = 0; i < systemMessages.length; i++) {
        if (systemMessages[i].pushMessageIfSame(msg)) {
          index = i;
          break;
        }
      }
      if (index < 0) {
        if (insertToFirst) {
          systemMessages.insert(0, SystemNotifyMerged(lastMsg: msg));
        } else {
          systemMessages.add(SystemNotifyMerged(lastMsg: msg));
        }
      } else if (insertToFirst) {
        var item = systemMessages.removeAt(index);
        systemMessages.insert(0, item);
      }
    });
  }

  void _setMessageNotifyListener() {
    _subscription = ContactRepo.registerNotificationObserver().listen((event) {
      _addNewToSystemMessages([event], insertToFirst: true);
      notifyListeners();
    });
  }

  void init() {
    haveMore = true;
    lastMessage = null;
    querySystemMessage();
    _setMessageNotifyListener();
  }

  void agree(SystemNotifyMerged message, BuildContext context) async {
    if (message.lastMsg.status == SystemMessageStatus.init &&
        message.lastMsg.fromAccount?.isNotEmpty == true) {
      NIMResult<void>? result;
      if (message.lastMsg.type == SystemMessageType.addFriend) {
        result = await ContactRepo.acceptAddFriend(
            message.lastMsg.fromAccount!, true);
      } else if (message.lastMsg.type == SystemMessageType.applyJoinTeam) {
        result = await ContactRepo.agreeTeamApply(
            message.lastMsg.targetId!, message.lastMsg.fromAccount!);
      } else if (message.lastMsg.type == SystemMessageType.teamInvite) {
        result = await ContactRepo.acceptTeamInvite(
            message.lastMsg.targetId!, message.lastMsg.fromAccount!);
      }
      if (result?.isSuccess == true) {
        _handAgree(message, context);
      } else if (result?.code != null) {
        Fluttertoast.showToast(
            msg: S.of(context).operationFailed(result!.code.toString()));
      }
    }
  }

  void _handAgree(SystemNotifyMerged message, BuildContext context) {
    if (message.lastMsg.fromAccount != null &&
        message.lastMsg.type == SystemMessageType.addFriend) {
      _sendVerifyMessage(message.lastMsg.fromAccount!, context);
    }
    var index =
        systemMessages.indexWhere((e) => e.isSameMessage(message.lastMsg));
    if (index >= 0) {
      ContactRepo.setVerifyStatus(
          message.lastMsg.messageId!, SystemMessageStatus.passed);
      message.lastMsg.status = SystemMessageStatus.passed;
      if (message.msgList.isNotEmpty) {
        message.msgList.forEach((msg) {
          ContactRepo.setVerifyStatus(
              msg.messageId!, SystemMessageStatus.passed);
          msg.status = SystemMessageStatus.passed;
        });
      }
      message.unread = false;
      systemMessages[index] = message;
      notifyListeners();
    }
  }

  void _sendVerifyMessage(String accId, BuildContext context) {
    NimCore.instance.messageService.sendTextMessage(
        sessionId: accId,
        sessionType: NIMSessionType.p2p,
        text: S.of(context).verifyAgreeMessageText);
  }

  void reject(SystemNotifyMerged messageMerged, BuildContext context,
      {String? reason}) async {
    var message = messageMerged.lastMsg;
    if (message.status == SystemMessageStatus.init &&
        message.fromAccount?.isNotEmpty == true) {
      NIMResult<void>? result;
      if (message.type == SystemMessageType.addFriend) {
        result = await ContactRepo.acceptAddFriend(message.fromAccount!, false);
      } else if (message.type == SystemMessageType.applyJoinTeam) {
        result = await ContactRepo.rejectTeamApply(
            message.targetId!, message.fromAccount!, reason ?? '');
      } else if (message.type == SystemMessageType.teamInvite) {
        result = await ContactRepo.rejectTeamInvite(
            message.targetId!, message.fromAccount!, reason ?? '');
      }
      if (result?.isSuccess == true) {
        _handleReject(messageMerged);
      } else if (result?.code == resInvalid) {
        Fluttertoast.showToast(msg: S.of(context).verifyMessageHaveBeenHandled);
        _handAgree(messageMerged, context);
      } else if (result?.code != null) {
        Fluttertoast.showToast(
            msg: S.of(context).operationFailed(result!.code.toString()));
      }
    }
  }

  void _handleReject(SystemNotifyMerged messageMerged) {
    var message = messageMerged.lastMsg;
    var index = systemMessages.indexWhere((e) => e.isSameMessage(message));
    if (index >= 0) {
      ContactRepo.setVerifyStatus(
          messageMerged.lastMsg.messageId!, SystemMessageStatus.declined);
      messageMerged.lastMsg.status = SystemMessageStatus.declined;
      if (messageMerged.msgList.isNotEmpty) {
        messageMerged.msgList.forEach((msg) {
          ContactRepo.setVerifyStatus(
              msg.messageId!, SystemMessageStatus.declined);
          msg.status = SystemMessageStatus.declined;
        });
      }
      messageMerged.unread = false;
      systemMessages[index] = messageMerged;
      notifyListeners();
    }
  }

  void cleanMessage() {
    ContactRepo.clearNotification();
    systemMessages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }
}

//合并后显示的消息
class SystemNotifyMerged {
  //保存最新的一条通知
  SystemMessage lastMsg;

  //保持之前的消息
  List<SystemMessage> msgList = List.empty(growable: true);

  NIMUser? user;

  NIMTeam? team;

  SystemNotifyMerged({required this.lastMsg}) {
    unread = lastMsg.unread ?? false;
  }

  bool unread = false;

  //如果相同，添加消息
  bool pushMessageIfSame(SystemMessage message) {
    if (isSameMessage(message)) {
      msgList.add(lastMsg);
      lastMsg = message;
      if (message.unread == true) {
        unread = message.unread!;
      }
      return true;
    }
    return false;
  }

  int messageUnreadCount() {
    return (lastMsg.unread == true ? 1 : 0) +
        msgList.where((e) => e.unread == true).length;
  }

  //是否相同消息，不包含附件，附言
  bool isSameMessage(SystemMessage message) {
    if (message.type == lastMsg.type &&
        message.fromAccount == lastMsg.fromAccount &&
        message.targetId == lastMsg.targetId &&
        message.status == lastMsg.status) {
      //好友申请类型特殊处理
      if (message.type == SystemMessageType.addFriend &&
          message.attachObject is AddFriendNotify) {
        //lastMessage不是好友类型，return false
        if (!(lastMsg.attachObject is AddFriendNotify)) {
          return false;
        }

        AddFriendNotify notification = message.attachObject as AddFriendNotify;
        AddFriendNotify lastNotification =
            lastMsg.attachObject as AddFriendNotify;

        if (notification.event == lastNotification.event &&
            notification.account == lastNotification.account) {
          return true;
        } else {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}
