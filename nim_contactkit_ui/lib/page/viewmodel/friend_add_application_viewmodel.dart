// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../l10n/S.dart';

class ValidationMessageViewModel extends ChangeNotifier {
  List<ValidationMessageMerged> NIMFriendAddApplications =
      List.empty(growable: true);

  static const queryMessageLimit = 100;

  static const logTag = 'ValidationMessageViewModel';

  //7 day expire time
  static const expireLimit = 7 * 24 * 60 * 60 * 1000;

  //失效，其他端已经处理
  static const resInvalid = 104405;

  bool haveMore = true;

  NIMFriendAddApplication? lastMessage;

  StreamSubscription? _subscription;

  ///分页请求行通知
  ///如果返回false 表示 需要继续请求
  Future<bool> queryNIMFriendAddApplication({int offset = 0}) {
    return ContactRepo.getAddApplicationList(queryMessageLimit, offset: offset)
        .then((value) {
      if (value.isSuccess) {
        int preLen = NIMFriendAddApplications.length;
        _setSysMsgExpire(value.data?.infos);
        _addNewToNIMFriendAddApplications(value.data?.infos ?? []);
        if (value.data != null &&
            value.data!.infos != null &&
            value.data!.infos!.length >= queryMessageLimit) {
          haveMore = true;
        } else {
          haveMore = false;
        }
        if (value.data != null &&
            value.data!.infos != null &&
            value.data!.infos!.isNotEmpty) {
          lastMessage = value.data!.infos!.last;
        }
        notifyListeners();
        int newLen = NIMFriendAddApplications.length;
        //1，非首次请求 2，还有更多 3，请求结果不为空 4，合并前后sysMsg长度一样
        //表示此次请求所有的结果都被merge，需要再次请求，所以返回false
        if (offset > 0 &&
            haveMore &&
            (value.data?.infos?.length ?? 0) > 0 &&
            newLen == preLen) {
          return false;
        }
      }
      return true;
    });
  }

  //设置过期
  _setSysMsgExpire(List<NIMFriendAddApplication>? sysMsg) {
    var lastTime = DateTime.now().millisecondsSinceEpoch - expireLimit;
    sysMsg?.forEach((e) {
      if (e.status ==
              NIMFriendAddApplicationStatus.nimFriendAddApplicationStatusInit &&
          (e.timestamp ?? 0) < lastTime) {
        e.status =
            NIMFriendAddApplicationStatus.nimFriendAddApplicationStatusExpired;
      }
    });
  }

  _addNewToNIMFriendAddApplications(List<NIMFriendAddApplication> newMsg,
      {bool insertToFirst = false}) {
    newMsg.forEach((msg) {
      var index = -1;
      for (int i = 0; i < NIMFriendAddApplications.length; i++) {
        if (NIMFriendAddApplications[i].pushMessageIfSame(msg)) {
          index = i;
          break;
        }
      }
      if (index < 0) {
        if (insertToFirst) {
          NIMFriendAddApplications.insert(
              0, ValidationMessageMerged(lastMsg: msg));
        } else {
          NIMFriendAddApplications.add(ValidationMessageMerged(lastMsg: msg));
        }
      } else if (insertToFirst) {
        var item = NIMFriendAddApplications.removeAt(index);
        NIMFriendAddApplications.insert(0, item);
      }
    });
  }

  void _setMessageNotifyListener() {
    _subscription =
        ContactRepo.registerFriendAddApplicationObserver().listen((event) {
      _addNewToNIMFriendAddApplications([event], insertToFirst: true);
      notifyListeners();
    });

    _subscription =
        ContactRepo.registerFriendAddRejectedObserver().listen((event) {
      if (event.operatorAccountId == IMKitClient.account()) {
        return;
      }
      _addNewToNIMFriendAddApplications([event], insertToFirst: true);
      notifyListeners();
    });
  }

  void init() {
    haveMore = true;
    lastMessage = null;
    queryNIMFriendAddApplication();
    _setMessageNotifyListener();
  }

  void agree(ValidationMessageMerged message, BuildContext context) async {
    if (message.lastMsg.status ==
            NIMFriendAddApplicationStatus.nimFriendAddApplicationStatusInit &&
        message.lastMsg.applicantAccountId?.isNotEmpty == true) {
      NIMResult<void> result =
          await ContactRepo.acceptAddApplication(message.lastMsg);

      if (result.isSuccess == true) {
        _handAgree(message, context);
      } else if (result.code == resInvalid) {
        // 该验证消息已在其他端处理
        Fluttertoast.showToast(msg: S.of(context).verifyMessageHaveBeenHandled);
        _handAgree(message, context);
      } else {
        Fluttertoast.showToast(
            msg: S.of(context).operationFailed(result.code.toString()));
      }
    }
  }

  void _handAgree(ValidationMessageMerged messageMerged, BuildContext context) {
    var message = messageMerged.lastMsg;
    if (message.applicantAccountId != null) {
      _sendVerifyMessage(message.applicantAccountId!, context);
    }
    var index =
        NIMFriendAddApplications.indexWhere((e) => e.isSameMessage(message));
    if (index >= 0) {
      messageMerged.lastMsg.status =
          NIMFriendAddApplicationStatus.nimFriendAddApplicationStatusAgreed;
      messageMerged.lastMsg.operatorAccountId = IMKitClient.account();
      if (messageMerged.msgList.isNotEmpty) {
        messageMerged.msgList.forEach((msg) {
          msg.status =
              NIMFriendAddApplicationStatus.nimFriendAddApplicationStatusAgreed;
        });
      }
      messageMerged.unread = false;
      NIMFriendAddApplications[index] = messageMerged;

      for (int i = ++index; i < NIMFriendAddApplications.length; i++) {
        if (NIMFriendAddApplications[i].isSameMessage(message)) {
          NIMFriendAddApplications.removeAt(i);
          break;
        }
      }

      notifyListeners();
    }
  }

  void _sendVerifyMessage(String accId, BuildContext context) {
    MessageCreator.createTextMessage(S.of(context).verifyAgreeMessageText)
        .then((message) async {
      if (message.isSuccess && message.data != null) {
        var conversationId =
            (await NimCore.instance.conversationIdUtil.p2pConversationId(accId))
                .data;
        if (conversationId != null) {
          NimCore.instance.messageService.sendMessage(
              message: message.data!, conversationId: conversationId);
        }
      }
    });
  }

  void reject(ValidationMessageMerged messageMerged, BuildContext context,
      {String? reason}) async {
    var message = messageMerged.lastMsg;
    if (message.status ==
            NIMFriendAddApplicationStatus.nimFriendAddApplicationStatusInit &&
        message.applicantAccountId?.isNotEmpty == true) {
      NIMResult<void> result = await ContactRepo.rejectAddApplication(message);
      if (result.isSuccess == true) {
        _handleReject(messageMerged);
      } else if (result.code == resInvalid) {
        // 该验证消息已在其他端处理
        Fluttertoast.showToast(msg: S.of(context).verifyMessageHaveBeenHandled);
        _handAgree(messageMerged, context);
      } else {
        Fluttertoast.showToast(
            msg: S.of(context).operationFailed(result.code.toString()));
      }
    }
  }

  void _handleReject(ValidationMessageMerged messageMerged) {
    var message = messageMerged.lastMsg;
    var index =
        NIMFriendAddApplications.indexWhere((e) => e.isSameMessage(message));
    if (index >= 0) {
      messageMerged.lastMsg.status =
          NIMFriendAddApplicationStatus.nimFriendAddApplicationStatusRejected;
      messageMerged.lastMsg.operatorAccountId = IMKitClient.account();
      if (messageMerged.msgList.isNotEmpty) {
        messageMerged.msgList.forEach((msg) {
          msg.status = NIMFriendAddApplicationStatus
              .nimFriendAddApplicationStatusRejected;
        });
      }
      messageMerged.unread = false;
      NIMFriendAddApplications[index] = messageMerged;

      for (int i = ++index; i < NIMFriendAddApplications.length; i++) {
        if (NIMFriendAddApplications[i].isSameMessage(message)) {
          NIMFriendAddApplications.removeAt(i);
          break;
        }
      }

      notifyListeners();
    }
  }

  void cleanMessage() {
    ContactRepo.clearAllAddApplication();
    NIMFriendAddApplications.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }
}

//合并后显示的消息
class ValidationMessageMerged {
  //保存最新的一条通知
  NIMFriendAddApplication lastMsg;

  //保持之前的消息
  List<NIMFriendAddApplication> msgList = List.empty(growable: true);

  NIMUserInfo? user;

  ValidationMessageMerged({required this.lastMsg}) {
    unread = !(lastMsg.read ?? false);
  }

  bool unread = false;

  //如果相同，添加消息
  bool pushMessageIfSame(NIMFriendAddApplication message) {
    if (isSameMessage(message)) {
      msgList.add(lastMsg);
      lastMsg = message;
      if (message.read == false) {
        unread = !message.read!;
      }
      return true;
    }
    return false;
  }

  int messageUnreadCount() {
    return (lastMsg.read == true ? 0 : 1) +
        msgList.where((e) => e.read == false).length;
  }

  //是否相同消息，不包含附件，附言
  bool isSameMessage(NIMFriendAddApplication message) {
    if (message.applicantAccountId == lastMsg.applicantAccountId &&
        message.recipientAccountId == lastMsg.recipientAccountId &&
        message.status == lastMsg.status) {
      return true;
    }
    return false;
  }
}
