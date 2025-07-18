// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/repo/config_repo.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../l10n/S.dart';

class ValidationMessageViewModel extends ChangeNotifier {
  List<ValidationFriendMessageMerged> friendAddApplications =
      List.empty(growable: true);

  List<ValidationTeamMessageMerged> teamApplications =
      List.empty(growable: true);

  static const queryMessageLimit = 100;

  static const logTag = 'ValidationMessageViewModel';

  //7 day expire time
  static const expireLimit = 7 * 24 * 60 * 60 * 1000;

  //失效，好友申请其他端已经处理
  static const resInvalid = 104405;

  //失效，已经被其他管理员处理
  static const teamMemberNotExist = 109404;

  //失效，已经在群里了
  static const alreadyInTeamCode = 109311;

  bool haveMore = true;

  NIMFriendAddApplication? lastMessage;

  StreamSubscription? _subscription;

  ///分页请求行通知
  ///如果返回false 表示 需要继续请求
  Future<bool> queryNIMFriendAddApplication({int offset = 0}) {
    return ContactRepo.getAddApplicationList(queryMessageLimit, offset: offset)
        .then((value) {
      if (value.isSuccess) {
        int preLen = friendAddApplications.length;
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
        int newLen = friendAddApplications.length;
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

  void queryTeamActions() {
    NimCore.instance.teamService
        .getTeamJoinActionInfoList(NIMTeamJoinActionInfoQueryOption(limit: 100))
        .then((value) {
      if (value.data?.infos != null) {
        _addNewToTeamActions(value.data!.infos!);
        notifyListeners();
      }
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
      for (int i = 0; i < friendAddApplications.length; i++) {
        if (friendAddApplications[i].pushMessageIfSame(msg)) {
          index = i;
          break;
        }
      }
      if (index < 0) {
        if (insertToFirst) {
          friendAddApplications.insert(
              0, ValidationFriendMessageMerged(lastMsg: msg));
        } else {
          friendAddApplications
              .add(ValidationFriendMessageMerged(lastMsg: msg));
        }
      } else if (insertToFirst) {
        var item = friendAddApplications.removeAt(index);
        friendAddApplications.insert(0, item);
      }
    });
  }

  ///添加新的数据到数据列表
  _addNewToTeamActions(List<NIMTeamJoinActionInfo> newMsg,
      {bool insertToFirst = false}) {
    newMsg.forEach((msg) {
      var index = -1;
      for (int i = 0; i < teamApplications.length; i++) {
        if (teamApplications[i].pushMessageIfSame(msg)) {
          index = i;
          break;
        }
      }
      if (index < 0) {
        if (insertToFirst) {
          teamApplications.insert(0, ValidationTeamMessageMerged(lastMsg: msg));
        } else {
          teamApplications.add(ValidationTeamMessageMerged(lastMsg: msg));
        }
      } else if (insertToFirst) {
        var item = teamApplications.removeAt(index);
        teamApplications.insert(0, item);
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

    _subscription = NimCore.instance.teamService.onReceiveTeamJoinActionInfo
        .listen((event) {
      _addNewToTeamActions([event], insertToFirst: true);
      notifyListeners();
    });
  }

  void init() {
    haveMore = true;
    lastMessage = null;
    queryNIMFriendAddApplication();
    queryTeamActions();
    _setMessageNotifyListener();
  }

  void agreeTeamActions(
      ValidationTeamMessageMerged mergeMessage, BuildContext context) async {
    if (mergeMessage.lastMsg.actionStatus ==
        NIMTeamJoinActionStatus.joinActionStatusInit) {
      final message = mergeMessage.lastMsg;

      NIMResult<void> result;
      if (message.actionType ==
          NIMTeamJoinActionType.joinActionTypeInvitation) {
        result = await NimCore.instance.teamService.acceptInvitation(message);
      } else {
        result =
            await NimCore.instance.teamService.acceptJoinApplication(message);
      }

      if (result.isSuccess == true) {
        _handTeamActionAgree(mergeMessage, context);
      } else if (result.code == teamMemberNotExist) {
        // 该验证消息已在其他端处理
        Fluttertoast.showToast(msg: S.of(context).verifyMessageHaveBeenHandled);
        _handTeamActionExpired(mergeMessage, context);
      } else {
        if (result.code == alreadyInTeamCode) {
          _handTeamActionExpired(mergeMessage, context);
        }
        Fluttertoast.showToast(
            msg: S.of(context).operationFailed(result.code.toString()));
      }
    }
  }

  void agreeUserApplication(
      ValidationFriendMessageMerged message, BuildContext context) async {
    if (message.lastMsg.status ==
            NIMFriendAddApplicationStatus.nimFriendAddApplicationStatusInit &&
        message.lastMsg.applicantAccountId?.isNotEmpty == true) {
      NIMResult<void> result =
          await ContactRepo.acceptAddApplication(message.lastMsg);

      if (result.isSuccess == true) {
        _handUserApplicationAgree(message, context);
      } else if (result.code == resInvalid) {
        // 该验证消息已在其他端处理
        Fluttertoast.showToast(msg: S.of(context).verifyMessageHaveBeenHandled);
        _handUserApplicationAgree(message, context);
      } else {
        Fluttertoast.showToast(
            msg: S.of(context).operationFailed(result.code.toString()));
      }
    }
  }

  ///处理群申请过期
  void _handTeamActionExpired(
      ValidationTeamMessageMerged messageMerged, BuildContext context) {
    var message = messageMerged.lastMsg;
    var index = teamApplications.indexWhere((e) => e.isSameMessage(message));
    if (index >= 0) {
      messageMerged.lastMsg.actionStatus =
          NIMTeamJoinActionStatus.joinActionStatusExpired;
      if (messageMerged.msgList.isNotEmpty) {
        messageMerged.msgList.forEach((msg) {
          msg.actionStatus = NIMTeamJoinActionStatus.joinActionStatusAgreed;
        });
      }
      messageMerged.unread = false;
      teamApplications[index] = messageMerged;

      for (int i = ++index; i < teamApplications.length; i++) {
        if (teamApplications[i].isSameMessage(message)) {
          teamApplications.removeAt(i);
          break;
        }
      }

      notifyListeners();
    }
  }

  void _handTeamActionAgree(
      ValidationTeamMessageMerged messageMerged, BuildContext context) {
    var message = messageMerged.lastMsg;
    var index = teamApplications.indexWhere((e) => e.isSameMessage(message));
    if (index >= 0) {
      messageMerged.lastMsg.actionStatus =
          NIMTeamJoinActionStatus.joinActionStatusAgreed;
      if (messageMerged.msgList.isNotEmpty) {
        messageMerged.msgList.forEach((msg) {
          msg.actionStatus = NIMTeamJoinActionStatus.joinActionStatusAgreed;
        });
      }
      messageMerged.unread = false;
      teamApplications[index] = messageMerged;

      for (int i = ++index; i < teamApplications.length; i++) {
        if (teamApplications[i].isSameMessage(message)) {
          teamApplications.removeAt(i);
          break;
        }
      }

      notifyListeners();
    }
  }

  void _handUserApplicationAgree(
      ValidationFriendMessageMerged messageMerged, BuildContext context) {
    var message = messageMerged.lastMsg;
    if (message.applicantAccountId != null) {
      _sendVerifyMessage(message.applicantAccountId!, context);
    }
    var index =
        friendAddApplications.indexWhere((e) => e.isSameMessage(message));
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
      friendAddApplications[index] = messageMerged;

      for (int i = ++index; i < friendAddApplications.length; i++) {
        if (friendAddApplications[i].isSameMessage(message)) {
          friendAddApplications.removeAt(i);
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

  void rejectAddApplication(
      ValidationFriendMessageMerged messageMerged, BuildContext context,
      {String? reason}) async {
    var message = messageMerged.lastMsg;
    if (message.status ==
            NIMFriendAddApplicationStatus.nimFriendAddApplicationStatusInit &&
        message.applicantAccountId?.isNotEmpty == true) {
      NIMResult<void> result = await ContactRepo.rejectAddApplication(message);
      if (result.isSuccess == true) {
        _handleRejectUserApplication(messageMerged);
      } else if (result.code == resInvalid) {
        // 该验证消息已在其他端处理
        Fluttertoast.showToast(msg: S.of(context).verifyMessageHaveBeenHandled);
        _handUserApplicationAgree(messageMerged, context);
      } else {
        Fluttertoast.showToast(
            msg: S.of(context).operationFailed(result.code.toString()));
      }
    }
  }

  void rejectTeamAction(
      ValidationTeamMessageMerged messageMerged, BuildContext context,
      {String? reason}) async {
    var message = messageMerged.lastMsg;
    if (message.actionStatus == NIMTeamJoinActionStatus.joinActionStatusInit) {
      NIMResult<void> result;
      if (message.actionType ==
          NIMTeamJoinActionType.joinActionTypeInvitation) {
        result =
            await NimCore.instance.teamService.rejectInvitation(message, null);
      } else {
        result = await NimCore.instance.teamService
            .rejectJoinApplication(message, null);
      }
      if (result.isSuccess == true) {
        _handleRejectTeamAction(messageMerged);
      } else if (result.code == teamMemberNotExist) {
        // 该验证消息已在其他端处理
        Fluttertoast.showToast(msg: S.of(context).verifyMessageHaveBeenHandled);
        _handTeamActionExpired(messageMerged, context);
      } else {
        if (result.code == alreadyInTeamCode) {
          _handTeamActionExpired(messageMerged, context);
        }
        Fluttertoast.showToast(
            msg: S.of(context).operationFailed(result.code.toString()));
      }
    }
  }

  void _handleRejectTeamAction(ValidationTeamMessageMerged messageMerged) {
    var message = messageMerged.lastMsg;
    var index = teamApplications.indexWhere((e) => e.isSameMessage(message));
    if (index >= 0) {
      messageMerged.lastMsg.actionStatus =
          NIMTeamJoinActionStatus.joinActionStatusRejected;
      if (messageMerged.msgList.isNotEmpty) {
        messageMerged.msgList.forEach((msg) {
          msg.actionStatus = NIMTeamJoinActionStatus.joinActionStatusRejected;
        });
      }
      messageMerged.unread = false;
      teamApplications[index] = messageMerged;

      for (int i = ++index; i < teamApplications.length; i++) {
        if (teamApplications[i].isSameMessage(message)) {
          teamApplications.removeAt(i);
          break;
        }
      }

      notifyListeners();
    }
  }

  void _handleRejectUserApplication(
      ValidationFriendMessageMerged messageMerged) {
    var message = messageMerged.lastMsg;
    var index =
        friendAddApplications.indexWhere((e) => e.isSameMessage(message));
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
      friendAddApplications[index] = messageMerged;

      for (int i = ++index; i < friendAddApplications.length; i++) {
        if (friendAddApplications[i].isSameMessage(message)) {
          friendAddApplications.removeAt(i);
          break;
        }
      }

      notifyListeners();
    }
  }

  void cleanUserApplicationMessage() {
    ContactRepo.clearAllAddApplication();
    friendAddApplications.clear();
    notifyListeners();
  }

  void cleanTeamActionsMessage() {
    NimCore.instance.teamService.clearAllTeamJoinActionInfo();
    teamApplications.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }
}

//合并后显示的好友消息
class ValidationFriendMessageMerged {
  //保存最新的一条通知
  NIMFriendAddApplication lastMsg;

  //保持之前的消息
  List<NIMFriendAddApplication> msgList = List.empty(growable: true);

  NIMUserInfo? user;

  ValidationFriendMessageMerged({required this.lastMsg}) {
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

///群验证消息
class ValidationTeamMessageMerged {
  //保存最新的一条通知
  NIMTeamJoinActionInfo lastMsg;

  //保持之前的消息
  List<NIMTeamJoinActionInfo> msgList = List.empty(growable: true);

  NIMTeam? team;

  NIMUserInfo? user;

  bool unread = false;

  int? readTime;

  ValidationTeamMessageMerged({required this.lastMsg}) {
    ConfigRepo.getTeamApplicationReadTime().then((time) {
      readTime = time;
      if (time <= (lastMsg.timestamp ?? 0)) {
        unread = true;
      }
    });
  }

  //如果相同，添加消息
  bool pushMessageIfSame(NIMTeamJoinActionInfo message) {
    if (isSameMessage(message)) {
      if ((message.timestamp ?? 0) > (lastMsg.timestamp ?? 0)) {
        msgList.add(lastMsg);
        lastMsg = message;
      } else {
        msgList.add(message);
      }

      if (readTime != null) {
        unread = (lastMsg.timestamp ?? 0) > readTime!;
      }
      return true;
    }
    return false;
  }

  int messageUnreadCount() {
    return ((lastMsg.timestamp ?? 0) > (readTime ?? 0) ? 1 : 0) +
        msgList.where((e) => (e.timestamp ?? 0) > (readTime ?? 0)).length;
  }

  //是否相同消息，不包含附件，附言
  bool isSameMessage(NIMTeamJoinActionInfo message) {
    if (message.teamId == lastMsg.teamId &&
        message.teamType == lastMsg.teamType &&
        message.actionType == lastMsg.actionType &&
        message.operatorAccountId == lastMsg.operatorAccountId &&
        message.actionStatus == lastMsg.actionStatus) {
      return true;
    }
    return false;
  }
}
