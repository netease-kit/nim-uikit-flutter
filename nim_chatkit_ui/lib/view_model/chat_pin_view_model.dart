// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_corekit_im/services/message/chat_message.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/repo/chat_service_observer_repo.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../helper/chat_message_helper.dart';
import '../l10n/S.dart';

class ChatPinViewModel extends ChangeNotifier {
  String? sessionId;

  final String conversationId;

  final NIMConversationType conversationType;

  final List<ChatMessage> _pinnedMessages = List.empty(growable: true);

  List<StreamSubscription> _listSub = List.empty(growable: true);

  ChatPinViewModel(this.conversationId, this.conversationType) {
    _init();
  }

  bool isEmpty = false;

  void _loadData() async {
    _pinnedMessages.clear();
    ChatMessageRepo.fetchPinMessage(conversationId).then((value) {
      if (value.isSuccess && value.data != null) {
        value.data!.sort((a, b) =>
            b.nimMessage.createTime!.compareTo(a.nimMessage.createTime!));
        _pinnedMessages.addAll(value.data!);
        isEmpty = _pinnedMessages.isEmpty;
        notifyListeners();
      } else {
        _pinnedMessages.clear();
        isEmpty = true;
        notifyListeners();
      }
    });
  }

  void _init() async {
    sessionId = (await NimCore.instance.conversationIdUtil
            .conversationTargetId(conversationId))
        .data;
    _loadData();
    _initListener();
  }

  void _initListener() {
    _listSub.addAll([
      // 断网重连，重新拉取数据
      NimCore.instance.loginService.onDataSync.listen((event) {
        if (event.type == NIMDataSyncType.nimDataSyncMain &&
            event.state == NIMDataSyncState.nimDataSyncStateCompleted) {
          _loadData();
        }
      }),
      NimCore.instance.messageService.onMessagePinNotification
          .listen((event) async {
        if (event.pinState == NIMMessagePinState.pinned) {
          if (event.pin?.messageRefer?.messageClientId != null) {
            var msgRes = await NimCore.instance.messageService
                .getMessageListByIds(messageClientIds: [
              event.pin!.messageRefer!.messageClientId!
            ]);
            if (msgRes.data?.isNotEmpty == true) {
              var index = 0;
              while (index < _pinnedMessages.length) {
                if (_pinnedMessages[index].nimMessage.createTime! <
                    msgRes.data!.first.createTime!) {
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
        } else if (event.pinState == NIMMessagePinState.notPinned) {
          _pinnedMessages.removeWhere((element) =>
              element.nimMessage.messageClientId ==
              event.pin?.messageRefer?.messageClientId);
          isEmpty = _pinnedMessages.isEmpty;
          notifyListeners();
        }
      }),
      NimCore.instance.messageService.onMessageRevokeNotifications
          .listen((event) {
        //获取撤回List
        var revokedList = event
            .where((element) =>
                element.messageRefer?.messageClientId?.isNotEmpty == true)
            .map((e) => e.messageRefer!.messageClientId!)
            .toList();
        _pinnedMessages.removeWhere((element) =>
            revokedList.contains(element.nimMessage.messageClientId));
        isEmpty = _pinnedMessages.isEmpty;
        notifyListeners();
      }),
      ChatServiceObserverRepo.observeSendMessage().listen((event) {
        Alog.d(
            tag: 'ChatPinViewModel',
            content:
                'onMessageStatus ${event.messageClientId} status change -->> ${event.sendingState}, ${event.attachmentUploadState}');
        //更新消息状态，解决文件消息下载后状态没有变更的问题
        for (var msg in _pinnedMessages) {
          if (msg.nimMessage.messageClientId == event.messageClientId) {
            msg.nimMessage = event;
            notifyListeners();
            break;
          }
        }
      }),
      ChatServiceObserverRepo.observeMessageDelete().listen((event) {
        if (event.isNotEmpty) {
          for (var msg in event) {
            if (msg.messageRefer?.conversationId == conversationId &&
                msg.messageRefer?.conversationType == conversationType) {
              _pinnedMessages.removeWhere((e) =>
                  e.nimMessage.messageClientId ==
                  msg.messageRefer?.messageClientId);
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

  void forwardMessage(NIMMessage message, String conversationId) async {
    if (await haveConnectivity()) {
      final params =
          await ChatMessageHelper.getSenderParams(message, conversationId);
      ChatMessageRepo.forwardMessage(message, conversationId, params: params)
          .then((value) {
        if (value.code == ChatMessageRepo.errorInBlackList) {
          ChatMessageRepo.saveTipsMessage(
              conversationId, S.of().chatMessageSendFailedByBlackList);
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
