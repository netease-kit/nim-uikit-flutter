// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:netease_corekit_im/model/ait/ait_contacts_model.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:netease_corekit_im/services/message/chat_message.dart';
import 'package:netease_corekit_im/services/message/nim_chat_cache.dart';
import 'package:nim_core/nim_core.dart';

import 'database_helper.dart';

///管理session列表的@消息处理
class AitServer {
  AitServer._();

  static AitServer? _instance;

  static AitServer get instance => _instance ??= AitServer._();

  /// 当前会话id, 用于判断是否需要保存@消息
  String? _currentSessionId;

  final StreamController<AitSession?> _onSessionAitUpdated =
      StreamController<AitSession?>.broadcast();

  get onSessionAitUpdated => _onSessionAitUpdated.stream;

  void initListener() {
    NIMChatCache.instance.currentChatIdNotifier.listen((chatSession) {
      _currentSessionId = chatSession?.sessionId;
      // 不为空代表进入会话页面，清除当前会话的@消息
      if (chatSession?.sessionId != null) {
        clearAitMessage(chatSession.sessionId);
        _onSessionAitUpdated
            .add(AitSession(chatSession.sessionId, isAit: false));
      }
    });

    // 监听收到消息
    NimCore.instance.messageService.onMessage.listen((event) {
      for (var e in event) {
        if (e.sessionType == NIMSessionType.team &&
            e.sessionId != _currentSessionId &&
            e.status != NIMMessageStatus.read) {
          if (e.remoteExtension?[ChatMessage.keyAitMsg] != null) {
            final aitContact = AitContactsModel.fromMap(
                (e.remoteExtension![ChatMessage.keyAitMsg] as Map)
                    .cast<String, dynamic>());
            final myId = getIt<LoginService>().userInfo?.userId;
            if (aitContact.isUserBeAit(myId)) {
              _onSessionAitUpdated
                  .add(AitSession(e.sessionId!, messageId: e.uuid!));
              DatabaseHelper.instance
                  .insertAitMessage(e.sessionId!, e.uuid!, myId!);
            }
          }
        }
      }
    });
    // 监听消息撤回
    NimCore.instance.messageService.onMessageRevoked.listen((e) {
      if (e.message?.sessionType == NIMSessionType.team) {
        if (e.message!.remoteExtension?[ChatMessage.keyAitMsg] != null) {
          var aitMap =
              (e.message!.remoteExtension![ChatMessage.keyAitMsg] as Map)
                  .cast<String, dynamic>();
          final aitContact = AitContactsModel.fromMap(aitMap);
          final myId = getIt<LoginService>().userInfo?.userId;
          if (aitContact.isUserBeAit(myId)) {
            _onSessionAitUpdated.add(AitSession(e.message!.sessionId!,
                isAit: false, messageId: e.message?.uuid));
            DatabaseHelper.instance
                .deleteMessage(e.message!.sessionId!, e.message!.uuid!, myId!);
          }
        }
      }
    });
  }

  /// 保存@消息
  Future<bool> saveAitMessage(String sessionId, String messageId) async {
    if (sessionId == _currentSessionId) {
      return false;
    }
    final myId = getIt<LoginService>().userInfo?.userId;
    if (myId == null) {
      return false;
    }
    return (await DatabaseHelper.instance
            .insertAitMessage(sessionId, messageId, myId)) >
        0;
  }

  /// 删除session中所有@消息
  Future<int> clearAitMessage(String sessionId) {
    final myId = getIt<LoginService>().userInfo?.userId;
    if (myId == null) {
      return Future.value(0);
    }
    return DatabaseHelper.instance.clearSessionAitMessage(sessionId, myId);
  }

  /// 获取session是否是ai消息
  Future<bool> isAitSession(String sessionId, String myId) async {
    final msgList = await DatabaseHelper.instance
        .queryMessageIdsBySessionId(sessionId, myId);
    return msgList.isNotEmpty;
  }

  Future<List<String>> getAllAitSession(String myId) async {
    return DatabaseHelper.instance.queryAllAitSession(myId);
  }
}

class AitSession {
  final String sessionId;
  final String? messageId;
  final bool isAit;
  AitSession(this.sessionId, {this.messageId, this.isAit = true});
}
