// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_corekit_im/im_kit_client.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/contact/contact_provider.dart';
import 'package:netease_corekit_im/services/login/im_login_service.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/repo/conversation_repo.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_conversationkit_ui/service/ait/ait_server.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:yunxin_alog/yunxin_alog.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import '../model/conversation_info.dart';

class ConversationViewModel extends ChangeNotifier {
  final String modelName = 'ConversationViewModel';

  List<ConversationInfo> _conversationList = [];

  List<ConversationInfo> get conversationList => _conversationList;

  ValueChanged<int>? onUnreadCountChanged;

  final int pageLimit = 50;
  int _offset = 0; //分页加载
  // 是否还有下一页
  bool _finished = false;

  // 是否正在请求数据
  bool _isLoading = false;

  set conversationList(List<ConversationInfo> value) {
    _conversationList = value;
    notifyListeners();
  }

  Comparator<ConversationInfo> _comparator = (a, b) {
    return (b.conversation.sortOrder ?? 0) - (a.conversation.sortOrder ?? 0);
  };

  final subscriptions = <StreamSubscription?>[];

  ConversationViewModel(ValueChanged<int>? onUnreadChanged,
      Comparator<ConversationInfo>? comparator) {
    this.onUnreadCountChanged = onUnreadChanged;
    if (comparator != null) {
      _comparator = comparator;
    }
    _init();
  }

  _logI(String content) {
    Alog.i(tag: 'ConversationKit', moduleName: modelName, content: content);
  }

  doUnreadCallback() {
    ConversationRepo.getMsgUnreadCount().then((value) {
      _logI('doUnreadCallback $value');
      if (value.isSuccess &&
          value.data != null &&
          onUnreadCountChanged != null) {
        onUnreadCountChanged!(value.data!);
      }
    });
  }

  /// 补充会话信息，会话列表中的个人信息和群组信息都在这里填充
  List<ConversationInfo>? convertConversationInfo(
      List<NIMConversation>? infoList,
      {bool fillUserInfo = true}) {
    if (infoList == null) {
      return null;
    }
    List<ConversationInfo> conversationList = [];
    for (int i = 0; i < infoList.length; ++i) {
      var e = infoList[i];
      var conversationInfo = ConversationInfo(e);
      conversationList.add(conversationInfo);
    }
    return conversationList;
  }

  _init() {
    _logI('init -->> ');

    // 会话列表同步完成（仅保证列表完整性，会话具体信息如 name 需等待其他同步回调）
    subscriptions.add(ConversationRepo.onSyncFinished().listen((event) {
      _logI('conversationService onSyncFinished');
      queryConversationList();
    }));

    // 主数据同步完成（包含 P2P 数据，iOS 不包含群信息）
    subscriptions.add(NimCore.instance.loginService.onDataSync.listen((event) {
      _logI('loginService onDataSync');
      if (event.type == NIMDataSyncType.nimDataSyncMain &&
          event.state == NIMDataSyncState.nimDataSyncStateCompleted) {
        queryConversationList();
      }
    }));

    // 群信息同步完成
    subscriptions
        .add(NimCore.instance.teamService.onSyncFinished.listen((event) {
      _logI('teamService onSyncFinished');
      if (Platform.isIOS) {
        queryConversationList();
      }
    }));

    subscriptions.add(NimCore.instance.friendService.onFriendInfoChanged
        .listen((event) async {
      _logI('friendService onFriendInfoChanged');
      for (var conversationInfo in conversationList) {
        var sessionId = ChatKitUtils.getConversationTargetId(
            conversationInfo.conversation.conversationId);
        if (sessionId == event.accountId) {
          if (event.alias?.isNotEmpty == true) {
            conversationInfo.setNickName(event.alias);
          } else {
            var name = event.userProfile?.name ??
                getIt<ContactProvider>()
                    .getContactInCache(event.accountId)
                    ?.user
                    .name;
            conversationInfo.setNickName(name);
          }
          notifyListeners();
          return;
        }
      }
    }));

    subscriptions.add(
        NimCore.instance.userService.onUserProfileChanged.listen((event) async {
      for (var e in event) {
        for (var conversationInfo in conversationList) {
          var sessionId = ChatKitUtils.getConversationTargetId(
              conversationInfo.conversation.conversationId);
          if (sessionId == e.accountId) {
            if (e.name?.isNotEmpty == true) {
              conversationInfo.conversation.name = e.name;
            }
            if (e.avatar?.isNotEmpty == true) {
              conversationInfo.conversation.avatar = e.avatar;
            }
            notifyListeners();
            return;
          }
        }
      }
    }));

    // getIt<MessageProvider>().initListener();
    // change observer
    subscriptions
        .add(ConversationRepo.onConversationChanged().listen((event) async {
      _logI('onConversationChanged ${event.length}');
      List<ConversationInfo>? result = convertConversationInfo(event);
      if (result != null) {
        for (var conversationInfo in result) {
          _updateItem(conversationInfo);
          _logI(
              'changeObserver:onSuccess:update ${conversationInfo.getConversationId()}');
          // }
        }
        doUnreadCallback();
      }
    }));

    // delete observer
    subscriptions.add(ConversationRepo.onConversationDeleted().listen((event) {
      _logI('onConversationDeleted ${event.length}');
      _deleteItem(event);
      doUnreadCallback();
    }));

    // delete observer
    subscriptions
        .add(ConversationRepo.onConversationCreated().listen((event) async {
      _logI('onConversationCreated ${event.conversationId}');
      if (!_isValidConversation(event)) {
        deleteConversationById(event.conversationId);
        return;
      }
      ConversationInfo conversationInfo = ConversationInfo(event);
      if (event.type == NIMConversationType.team &&
          IMKitClient.account() != null) {
        conversationInfo.haveBeenAit = await AitServer.instance
            .isAitConversation(event.conversationId, IMKitClient.account()!);
      }
      _addItem(conversationInfo);
      doUnreadCallback();
    }));

    // ait observer
    subscriptions.add(
        AitServer.instance.onSessionAitUpdated.listen((AitSession? aitSession) {
      final index = _conversationList.indexWhere(
          (element) => element.getConversationId() == aitSession?.sessionId);
      if (index > -1) {
        _conversationList[index].haveBeenAit = aitSession!.isAit;
        notifyListeners();
      }
    }));

    subscriptions
        .add(NimCore.instance.teamService.onTeamDismissed.listen((team) async {
      var conversationId =
          (await ConversationIdUtil().teamConversationId(team.teamId)).data;
      _logI('onTeamDismissed ${team.teamId}');
      if (conversationId != null) {
        deleteConversationById(conversationId);
      }
    }));

    subscriptions.add(
        NimCore.instance.teamService.onTeamLeft.listen((teamLeftResult) async {
      var conversationId = (await ConversationIdUtil()
              .teamConversationId(teamLeftResult.team.teamId))
          .data;
      _logI('onTeamLeft ${teamLeftResult.team.teamId}');
      if (conversationId != null) {
        deleteConversationById(conversationId);
      }
    }));
  }

  int _searchComparatorIndex(ConversationInfo data) {
    if (data.isStickTop()) {
      return 0;
    }
    int index = _conversationList.length;
    for (int i = 0; i < _conversationList.length; ++i) {
      if (_comparator(data, _conversationList[i]) < 1) {
        index = i;
        break;
      }
    }
    return index;
  }

  _addRemoveStickTop(String conversationId, bool add) {
    int index = _conversationList
        .indexWhere((element) => element.getConversationId() == conversationId);
    if (index > -1) {
      // _conversationList[index].isStickTop() = add;
      var tmp = _conversationList.removeAt(index);
      if (add) {
        _conversationList.insert(0, tmp);
      } else {
        int insertIndex = _searchComparatorIndex(tmp);
        _conversationList.insert(insertIndex, tmp);
      }
    }
    notifyListeners();
  }

  ///是否合法的群
  ///如果最后一条消息是群退出，解散，被踢的消息，则非法
  bool _isValidConversation(NIMConversation conversation) {
    if (conversation.lastMessage?.messageType == NIMMessageType.notification &&
        conversation.lastMessage?.attachment
            is NIMMessageNotificationAttachment) {
      final notificationType = (conversation.lastMessage?.attachment
              as NIMMessageNotificationAttachment)
          .type;
      if (notificationType == NIMMessageNotificationType.teamDismiss ||
          notificationType == NIMMessageNotificationType.teamKick ||
          notificationType == NIMMessageNotificationType.teamLeave) {
        return false;
      }
    }
    return true;
  }

  _addItem(ConversationInfo conversationInfo) async {
    int index = _conversationList
        .indexWhere((element) => element.isSame(conversationInfo));
    if (index > -1) {
      if (conversationInfo.getConversationType() == NIMConversationType.team) {
        bool haveBeenAit = _conversationList[index].haveBeenAit;
        if ((conversationInfo.conversation.unreadCount ?? 0) <= 0) {
          AitServer.instance
              .clearAitMessage(conversationInfo.getConversationId());
          haveBeenAit = false;
        }
        if (haveBeenAit) {
          conversationInfo.haveBeenAit = true;
        }
      }
      _conversationList.removeAt(index);
      int insertIndex = _searchComparatorIndex(conversationInfo);
      _logI(
          'additem insertIndex:$insertIndex unread:${conversationInfo.conversation.unreadCount} haveBeenAit:${conversationInfo.haveBeenAit}');
      _conversationList.insert(insertIndex, conversationInfo);
    } else {
      int insertIndex = _searchComparatorIndex(conversationInfo);
      _conversationList.insert(insertIndex, conversationInfo);
    }
    notifyListeners();
  }

  _updateItem(ConversationInfo conversationInfo) async {
    int index = _conversationList
        .indexWhere((element) => element.isSame(conversationInfo));
    if (index > -1) {
      if (conversationInfo.getConversationType() == NIMConversationType.team) {
        bool haveBeenAit = _conversationList[index].haveBeenAit;
        if ((conversationInfo.conversation.unreadCount ?? 0) <= 0) {
          AitServer.instance
              .clearAitMessage(conversationInfo.getConversationId());
          haveBeenAit = false;
        }
        if (haveBeenAit) {
          conversationInfo.haveBeenAit = true;
        }
      }
      _conversationList.removeAt(index);
      int insertIndex = _searchComparatorIndex(conversationInfo);
      _logI(
          'insertIndex:$insertIndex unread:${conversationInfo.conversation.unreadCount} haveBeenAit:${conversationInfo.haveBeenAit}');
      _conversationList.insert(insertIndex, conversationInfo);
    } else {
      int insertIndex = _searchComparatorIndex(conversationInfo);
      _conversationList.insert(insertIndex, conversationInfo);
    }
    notifyListeners();
  }

  _deleteItem(List<String> idList) {
    for (String conversationId in idList) {
      int index = _conversationList.indexWhere(
          (element) => element.getConversationId() == conversationId);
      if (index > -1) {
        _conversationList.removeAt(index);
        notifyListeners();
      }
    }
  }

  void queryConversationList() async {
    _logI('queryConversationList start');

    if (_isLoading) {
      return;
    }
    _isLoading = true;
    final _resultData =
        await ConversationRepo.getConversationList(0, pageLimit);
    if (_resultData != null) {
      _offset = _resultData.offset;
      _finished = _resultData.finished;
      final myId = IMKitClient.account();
      if (myId != null) {
        final aitSessionList = await AitServer.instance.getAllAitSession(myId);
        var resultList = convertConversationInfo(_resultData.conversationList)!;
        _logI('queryConversationList size ${resultList.length}');

        for (int index = resultList.length - 1; index >= 0; index--) {
          var element = resultList[index];
          if (_isMineLeave(element)) {
            deleteConversation(element);
            _logI('queryConversationList ${element.getConversationId()}');
            resultList.remove(index);
          } else {
            if (IMKitClient.enableAit) {
              if (aitSessionList.contains(element.getConversationId()) &&
                  element.getUnreadCount() > 0) {
                element.haveBeenAit = true;
              }
            }
          }
        }
        _conversationList.clear();
        _conversationList.addAll(resultList);
        notifyListeners();
      }
    }
    _isLoading = false;
  }

  void queryConversationNextList() async {
    int offset = _conversationList.length;
    _logI('queryConversationNextList _isLoading ${offset},${_isLoading},'
        '${_finished}');
    if (_isLoading || _finished) {
      return;
    }
    _isLoading = true;
    final _resultData =
        await ConversationRepo.getConversationList(_offset, pageLimit);
    if (_resultData != null) {
      _offset = _resultData.offset;
      _finished = _resultData.finished;
      final myId = IMKitClient.account();
      _logI(
          'queryConversationNextList ${_offset},${_finished},${_resultData.conversationList?.length}');

      if (myId != null) {
        final aitSessionList = await AitServer.instance.getAllAitSession(myId);
        var resultList = convertConversationInfo(_resultData.conversationList)!;
        List<String> userIdList = [];
        for (int index = resultList.length - 1; index >= 0; index--) {
          var element = resultList[index];
          if (_isMineLeave(element)) {
            deleteConversation(element);
            resultList.remove(index);
          } else {
            if (IMKitClient.enableAit) {
              if (aitSessionList.contains(element.getConversationId()) &&
                  element.getUnreadCount() > 0) {
                element.haveBeenAit = true;
              }
            }
            if (element.conversation.type == NIMConversationType.p2p &&
                getIt<ContactProvider>().getContactInCache(element.targetId) ==
                    null) {
              userIdList.add(element.targetId);
            }
          }
        }
        _conversationList.addAll(resultList);
        notifyListeners();
        fetchUserInfo(userIdList);
      }
      _isLoading = false;
    }
  }

  void fetchUserInfo(List<String>? userIds) {
    if (userIds != null && userIds.length > 0) {
      ContactRepo.getUserListFromCloud(userIds);
    }
  }

  void deleteConversation(ConversationInfo conversationInfo,
      {bool? clearMessageHistory}) async {
    if (!await haveConnectivity()) {
      return;
    }
    this.deleteConversationById(conversationInfo.getConversationId());
  }

  void deleteConversationById(String conversationId,
      {bool? clearMessageHistory}) {
    if (clearMessageHistory == null) {
      clearMessageHistory = ConversationKitClient.instance.conversationUIConfig
          .itemConfig.clearMessageWhenDeleteSession;
    }
    ConversationRepo.deleteConversation(conversationId, clearMessageHistory);
  }

  bool _isMineLeave(ConversationInfo conversationInfo) {
    if (conversationInfo.getLastAttachment()
        is NIMMessageNotificationAttachment) {
      NIMMessageNotificationAttachment notify = conversationInfo
          .getLastAttachment() as NIMMessageNotificationAttachment;
      if (notify.type == NIMMessageNotificationType.teamDismiss) {
        return true;
      } else if (notify.type == NIMMessageNotificationType.teamKick) {
        var accId = getIt<IMLoginService>().userInfo?.accountId;
        var targetIds = notify.targetIds;
        if (targetIds != null && targetIds!.contains(accId)) {
          return true;
        }
      } else if (notify.type == NIMMessageNotificationType.teamLeave) {
        var accId = getIt<IMLoginService>().userInfo?.accountId;
        var senderId =
            conversationInfo.conversation.lastMessage?.messageRefer?.senderId;
        if (accId == senderId) {
          return true;
        }
      }
    }
    return false;
  }

  void addStickTop(ConversationInfo info) async {
    if (await haveConnectivity()) {
      ConversationRepo.addStickTop(info.getConversationId());
    }
  }

  void removeStick(ConversationInfo info) async {
    if (await haveConnectivity()) {
      ConversationRepo.removeStickTop(info.getConversationId());
    }
  }

  @override
  void dispose() {
    _logI('dispose');
    for (var element in subscriptions) {
      element?.cancel();
    }
    super.dispose();
  }
}
