// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:contactkit/repo/contact_repo.dart';
import 'package:flutter/cupertino.dart';
import 'package:nim_core/nim_core.dart';

class SystemNotifyViewModel extends ChangeNotifier {
  List<SystemMessage> systemMessages = List.empty(growable: true);

  static const queryMessageLimit = 50;

  static const logTag = 'SystemNotifyViewModel';

  bool haveMore = true;

  SystemMessage? lastMessage;

  StreamSubscription? _subscription;

  Future<NIMResult<void>> querySystemMessage({int offset = 0}) {
    return ContactRepo.getNotificationList(queryMessageLimit,
            offset: offset, systemMessage: lastMessage)
        .then((value) {
      if (value.isSuccess) {
        systemMessages.addAll(value.data ?? []);
        if (value.data != null && value.data!.length >= queryMessageLimit) {
          haveMore = true;
        } else {
          haveMore = false;
        }
        if (value.data != null) {
          lastMessage = value.data!.last;
        }
        notifyListeners();
      }
      return value;
    });
  }

  void _setMessageNotifyListener() {
    _subscription = ContactRepo.registerNotificationObserver().listen((event) {
      systemMessages.insert(0, event);
      notifyListeners();
    });
  }

  void init() {
    haveMore = true;
    lastMessage = null;
    querySystemMessage();
    _setMessageNotifyListener();
  }

  void agree(SystemMessage message) async {
    if (message.status == SystemMessageStatus.init &&
        message.fromAccount?.isNotEmpty == true) {
      NIMResult<void>? result;
      if (message.type == SystemMessageType.addFriend) {
        result = await ContactRepo.acceptAddFriend(message.fromAccount!, true);
      } else if (message.type == SystemMessageType.applyJoinTeam) {
        result = await ContactRepo.agreeTeamApply(
            message.targetId!, message.fromAccount!);
      } else if (message.type == SystemMessageType.teamInvite) {
        result = await ContactRepo.acceptTeamInvite(
            message.targetId!, message.fromAccount!);
      }
      if (result?.isSuccess == true) {
        var index =
            systemMessages.indexWhere((e) => e.messageId == message.messageId);
        if (index >= 0) {
          ContactRepo.setVerifyStatus(
              message.messageId!, SystemMessageStatus.passed);
          message.status = SystemMessageStatus.passed;
          systemMessages[index] = message;
          notifyListeners();
        }
      }
    }
  }

  void reject(SystemMessage message, {String? reason}) async {
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
        var index =
            systemMessages.indexWhere((e) => e.messageId == message.messageId);
        if (index >= 0) {
          ContactRepo.setVerifyStatus(
              message.messageId!, SystemMessageStatus.declined);
          message.status = SystemMessageStatus.declined;
          systemMessages[index] = message;
          notifyListeners();
        }
      }
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
