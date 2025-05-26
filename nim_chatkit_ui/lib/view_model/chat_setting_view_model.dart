// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:netease_common/netease_common.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import 'package:nim_chatkit/repo/conversation_repo.dart';
import 'package:nim_core_v2/nim_core.dart';

class ChatSettingViewModel extends ChangeNotifier {
  static const String logTag = 'ChatSettingViewModel';
  final subscriptions = <StreamSubscription?>[];
  final String conversationId;
  late String accountId;
  // 消息提醒是否开启
  bool _isNotify = false;
  // 消息置顶是否开启
  bool _isStick = false;
  // AI数字人PIN置顶信息KEY
  bool _isPin = false;
  // 是否为配置的置顶AI数字人
  bool _hasPin = false;

  get isStick => _isStick;
  get isNotify => _isNotify;
  get isPin => _isPin;
  get hasPin => _hasPin;

  ChatSettingViewModel(this.conversationId) {
    _init();
  }

  void _init() {
    _initSetting();
  }

  void _initSetting() {
    accountId = ChatKitUtils.getConversationTargetId(conversationId);
    subscriptions.add(
        NimCore.instance.userService.onUserProfileChanged.listen((event) async {
      for (var e in event) {
        Alog.d(tag: logTag, content: 'onUserProfileChanged ${e.accountId}');
        if (e.accountId == IMKitClient.account()) {
          // 个人信息更新，重新拉取置顶AI数字人。因为修改置顶信息在个人信息的扩展字段中保存
          _loadAIPin();
        }
      }
    }));
    ConversationRepo.getConversation(conversationId).then((conversation) {
      if (conversation.data != null) {
        _isStick = conversation.data!.stickTop;
        notifyListeners();
      }
    });

    ChatMessageRepo.isNeedNotify(accountId).then((value) {
      _isNotify = value;
      notifyListeners();
    });

    _loadAIPin();
  }

  void _loadAIPin() {
    //判断是否PIN置顶
    var currentAIUser = AIUserManager.instance.getAIUserById(accountId);
    if (currentAIUser != null &&
        AIUserManager.instance.isPinDefault(currentAIUser) &&
        IMKitClient.account() != null) {
      _hasPin = true;
      ContactRepo.getUserList([IMKitClient.account()!]).then((value) {
        if (value.isSuccess && value.data != null && value.data!.length > 0) {
          var userUnpinArray =
              AIUserManager.instance.getUnpinAIUserList(value.data![0]);
          if (userUnpinArray.contains(accountId)) {
            _isPin = false;
          } else {
            _isPin = true;
          }
          notifyListeners();
        }
      });
    } else {
      _hasPin = false;
    }
    notifyListeners();
  }

  void setNotify(bool value) {
    ChatMessageRepo.setNotify(accountId, value).then((suc) {
      if (!suc.isSuccess) {
        _isNotify = !value;
        notifyListeners();
      }
    });
    _isNotify = value;
    notifyListeners();
  }

  void setStick(bool value) {
    if (value) {
      // 调用Conversation 添加置顶
      ConversationRepo.addStickTop(conversationId).then((result) {
        if (!result.isSuccess) {
          _isStick = false;
          notifyListeners();
        }
      });
    } else {
      // 调用Conversation 移除置顶
      ConversationRepo.removeStickTop(conversationId).then((result) {
        if (!result.isSuccess) {
          _isStick = true;
          notifyListeners();
        }
      });
    }
    notifyListeners();
    _isStick = value;
  }

  void setAIUserPin(bool addPin) {
    var currentUserId = IMKitClient.account();
    if (currentUserId == null) {
      return;
    }
    AIUserManager.instance.unpinAIUser(accountId, addPin).then((value) {
      if (!value.isSuccess) {
        _isPin = !addPin;
        notifyListeners();
      }
    });
    _isPin = addPin;
    notifyListeners();
  }

  @override
  void dispose() {
    for (var element in subscriptions) {
      element?.cancel();
    }
    super.dispose();
  }
}
