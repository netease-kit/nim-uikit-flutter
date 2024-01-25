// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_corekit_im/services/message/chat_message.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/repo/chat_service_observer_repo.dart';
import 'package:nim_core/nim_core.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../l10n/S.dart';

class ChatPinViewModel extends ChangeNotifier {
  final String sessionId;

  final NIMSessionType sessionType;

  final List<ChatMessage> _pinnedMessages = List.empty(growable: true);

  List<StreamSubscription> _listSub = List.empty(growable: true);

  ChatPinViewModel(this.sessionId, this.sessionType) {
    _init();
  }

  bool isEmpty = false;

  void _init() {
    ChatMessageRepo.fetchPinMessage(sessionId, sessionType).then((value) {
      if (value.isSuccess && value.data != null) {
        value.data!.sort(
            (a, b) => b.nimMessage.timestamp.compareTo(a.nimMessage.timestamp));
        _pinnedMessages.addAll(value.data!);
        isEmpty = _pinnedMessages.isEmpty;
        notifyListeners();
      } else {
        _pinnedMessages.clear();
        isEmpty = true;
        notifyListeners();
      }
      _initListener();
    });
  }

  void _initListener() {
    _listSub.addAll([
      NimCore.instance.messageService.onMessagePinNotify.listen((event) async {
        if (event is NIMMessagePinAddedEvent) {
          if (event.pin.messageUuid != null) {
            var msgRes = await NimCore.instance.messageService
                .queryMessageListByUuid(
                    [event.pin.messageUuid!], sessionId, sessionType);
            if (msgRes.data?.isNotEmpty == true) {
              var index = 0;
              while (index < _pinnedMessages.length) {
                if (_pinnedMessages[index].nimMessage.timestamp <
                    msgRes.data!.first.timestamp) {
                  break;
                }
                index++;
              }
              _pinnedMessages.insert(
                  index, ChatMessage(msgRes.data!.first, pinOption: event.pin));
              isEmpty = false;
              notifyListeners();
            }
          }
        } else if (event is NIMMessagePinRemovedEvent) {
          _pinnedMessages.removeWhere(
              (element) => element.nimMessage.uuid == event.pin.messageUuid);
          isEmpty = _pinnedMessages.isEmpty;
          notifyListeners();
        }
      }),
      NimCore.instance.messageService.onMessageRevoked.listen((event) {
        _pinnedMessages.removeWhere(
            (element) => element.nimMessage.uuid == event.message?.uuid);
        isEmpty = _pinnedMessages.isEmpty;
        notifyListeners();
      }),
      ChatServiceObserverRepo.observeMsgStatus().listen((event) {
        Alog.d(
            tag: 'ChatPinViewModel',
            content:
                'onMessageStatus ${event.uuid} status change -->> ${event.status}, ${event.attachmentStatus}');
        //更新消息状态，解决文件消息下载后状态没有变更的问题
        for (var msg in _pinnedMessages) {
          if (msg.nimMessage.uuid == event.uuid) {
            msg.nimMessage = event;
            notifyListeners();
            break;
          }
        }
      }),
      ChatServiceObserverRepo.observeMessageDelete().listen((event) {
        if (event.isNotEmpty) {
          for (var msg in event) {
            if (msg.sessionId == sessionId && msg.sessionType == sessionType) {
              _pinnedMessages.remove(ChatMessage(msg));
              isEmpty = _pinnedMessages.isEmpty;
            }
          }
          notifyListeners();
        }
      }),
    ]);
  }

  List<ChatMessage> get pinnedMessages => _pinnedMessages;

  void removePinMessage(ChatMessage message) async {
    if (!await haveConnectivity()) {
      return;
    }
    var res = await ChatMessageRepo.removeMessagePin(message.nimMessage);
    if (res.isSuccess) {
      _pinnedMessages.remove(message);
      isEmpty = _pinnedMessages.isEmpty;
      notifyListeners();
    }
  }

  void forwardMessage(
      NIMMessage message, String sessionId, NIMSessionType sessionType) async {
    if (await haveConnectivity()) {
      ChatMessageRepo.forwardMessage(message, sessionId, sessionType)
          .then((value) {
        if (value.code == ChatMessageRepo.errorInBlackList) {
          ChatMessageRepo.saveTipsMessage(
              sessionId, sessionType, S.of().chatMessageSendFailedByBlackList);
        }
      });
    }
  }

  @override
  void dispose() {
    _listSub.forEach((element) {
      element.cancel();
    });
    _listSub.clear();
    super.dispose();
  }
}
