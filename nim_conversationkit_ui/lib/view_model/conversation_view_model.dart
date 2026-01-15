// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/manager/subscription_manager.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import 'package:nim_chatkit/repo/conversation_repo.dart';
import 'package:nim_chatkit/repo/team_repo.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/contact/contact_provider.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_conversationkit_ui/service/ait/ait_server.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../model/conversation_info.dart';

class ConversationViewModel extends ChangeNotifier {
  final String modelName = 'ConversationViewModel';

  List<ConversationInfo> _conversationList = [];
  List<NIMAIUser> _topAIUserList = [];

  List<ConversationInfo> get conversationList => _conversationList;
  List<NIMAIUser> get topAIUserList => _topAIUserList;

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
    // stickTop 相同，比较 sortOrder（降序）
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

    //先拉去一遍，解决会话列表在二级页面，不能监听同步数据的case
    queryConversationList();

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

    // ios 端处理会话信息不更新的问题
    if (Platform.isIOS) {
      final contactInfoChange = getIt<ContactProvider>().onContactInfoUpdated;
      if (contactInfoChange != null) {
        subscriptions.add(contactInfoChange.listen((userInfo) {
          for (var conversationInfo in conversationList) {
            var sessionId = ChatKitUtils.getConversationTargetId(
                conversationInfo.conversation.conversationId);
            if (sessionId == userInfo.user.accountId) {
              conversationInfo.conversation.name = userInfo.getName();
              conversationInfo.conversation.avatar = userInfo.user.avatar;
              notifyListeners();
              return;
            }
          }
        }));
      }
    }

    subscriptions.add(
        NimCore.instance.userService.onUserProfileChanged.listen((event) async {
      _logI('onUserProfileChanged -->> ${event.length}');
      for (var e in event) {
        if (IMKitClient.enableAi && e.accountId == IMKitClient.account()) {
          // 个人信息更新，重新拉取置顶AI数字人。因为修改置顶信息在个人信息的扩展字段中保存
          queryTopAIUser();
        }
      }
    }));

    // getIt<MessageProvider>().initListener();
    // change observer
    subscriptions
        .add(ConversationRepo.onConversationChanged().listen((event) async {
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

    // create observer
    subscriptions
        .add(ConversationRepo.onConversationCreated().listen((event) async {
      _logI('onConversationCreated ${event.conversationId}');
      if (!(await _isValidConversation(event))) {
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
      if (event.type == NIMConversationType.p2p) {
        subscribeP2PUserStatus([conversationInfo]);
      }
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
    // 群解散通知，删除相关群会话
    subscriptions
        .add(NimCore.instance.teamService.onTeamDismissed.listen((team) async {
      var conversationId =
          (await ConversationIdUtil().teamConversationId(team.teamId)).data;
      _logI('onTeamDismissed ${team.teamId}');
      if (IMKitConfigCenter.deleteTeamSessionWhenLeave &&
          conversationId != null) {
        deleteConversationById(conversationId);
      }
    }));

    // 退群通知，删除相关群会话
    subscriptions.add(
        NimCore.instance.teamService.onTeamLeft.listen((teamLeftResult) async {
      var conversationId = (await ConversationIdUtil()
              .teamConversationId(teamLeftResult.team.teamId))
          .data;
      _logI('onTeamLeft ${teamLeftResult.team.teamId}');
      if (IMKitConfigCenter.deleteTeamSessionWhenLeave &&
          conversationId != null) {
        deleteConversationById(conversationId);
      }
    }));

    subscriptions.add(NimCore.instance.subscriptionService.onUserStatusChanged
        .listen((List<NIMUserStatus> userList) {
      final Map<String, NIMUserStatus> userMap = {};
      for (final user in userList) {
        userMap[user.accountId] = user; // 直接以 id 为键，user 对象为值
      }
      conversationList.forEach((e) {
        if (e.conversation.type == NIMConversationType.p2p) {
          if (userMap.containsKey(e.targetId)) {
            e.isOnline = userMap[e.targetId]?.statusType == 1;
          }
        }
      });
      notifyListeners();
    }));

    // 查询置顶AI数字人列表，数字人配置为置顶，并且当前账号没有取消置顶
    if (IMKitClient.enableAi) {
      _logI('init queryTopAIUser ');
      queryTopAIUser();
      subscriptions.add(
          AIUserManager.instance.aiUserChanged?.listen((userListData) async {
        _logI('aiUserChanged size: ${userListData.length}');
        queryTopAIUser();
      }));
    }
  }

  int _searchComparatorIndex(ConversationInfo data) {
    int index = _conversationList.length;
    for (int i = 0; i < _conversationList.length; ++i) {
      if (_comparator(data, _conversationList[i]) < 1) {
        index = i;
        break;
      }
    }
    return index;
  }

  ///是否合法的群
  ///如果最后一条消息是群退出，解散，被踢的消息，则非法
  Future<bool> _isValidConversation(NIMConversation conversation) async {
    if (conversation.lastMessage?.messageType == NIMMessageType.notification &&
        conversation.lastMessage?.attachment
            is NIMMessageNotificationAttachment) {
      final notificationType = (conversation.lastMessage?.attachment
              as NIMMessageNotificationAttachment)
          .type;
      if (IMKitConfigCenter.deleteTeamSessionWhenLeave &&
          (notificationType == NIMMessageNotificationType.teamDismiss ||
              notificationType == NIMMessageNotificationType.teamKick ||
              notificationType == NIMMessageNotificationType.teamLeave)) {
        return false;
      }
    }
    if (conversation.type == NIMConversationType.team) {
      final team = await TeamRepo.getTeamInfo(
          ChatKitUtils.getConversationTargetId(conversation.conversationId),
          NIMTeamType.typeNormal);
      if (team?.isValidTeam != true) {
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
      if (conversationInfo.getConversationType() == NIMConversationType.p2p) {
        conversationInfo.isOnline = _conversationList[index].isOnline;
      }
      _conversationList.removeAt(index);
      int insertIndex = _searchComparatorIndex(conversationInfo);
      _logI(
          'insertIndex:$insertIndex unread:${conversationInfo.conversation.unreadCount} haveBeenAit:${conversationInfo.haveBeenAit}');
      _conversationList.insert(insertIndex, conversationInfo);
    } else {
      bool isValid = true;
      if (Platform.isIOS) {
        final conversationUpdated = await ConversationRepo.getConversation(
            conversationInfo.conversation.conversationId);
        isValid = conversationUpdated.data != null;
      }
      if (isValid) {
        int insertIndex = _searchComparatorIndex(conversationInfo);
        _conversationList.insert(insertIndex, conversationInfo);
        if (conversationInfo.getConversationType() == NIMConversationType.p2p) {
          subscribeP2PUserStatus([conversationInfo]);
        }
      }
    }
    notifyListeners();
  }

  _deleteItem(List<String> idList) {
    for (String conversationId in idList) {
      // 清除@消息
      AitServer.instance.clearAitMessage(conversationId);
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
          if (IMKitConfigCenter.deleteTeamSessionWhenLeave &&
              _haveLeftTeam(element)) {
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
        List<String> onlineUserList = _conversationList
            .where((conversation) => conversation.isOnline)
            .map((e) => e.targetId)
            .toList();
        _conversationList.clear();
        _conversationList.addAll(resultList);
        for (var conversation in _conversationList) {
          if (conversation.conversation.type == NIMConversationType.p2p) {
            if (onlineUserList.contains(conversation.targetId)) {
              conversation.isOnline = true;
            }
          }
        }
        subscribeP2PUserStatus(resultList);
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
          if (IMKitConfigCenter.deleteTeamSessionWhenLeave &&
              _haveLeftTeam(element)) {
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
        subscribeP2PUserStatus(resultList);
        notifyListeners();
        fetchUserInfo(userIdList);
      }
      _isLoading = false;
    }
  }

  void subscribeP2PUserStatus(List<ConversationInfo>? conversationList) {
    if (conversationList != null) {
      final userAccountIds = conversationList
          .where((e) => e.conversation.type == NIMConversationType.p2p)
          .map((e) => e.targetId)
          .toList();
      SubscriptionManager.instance.subscribeUserStatus(userAccountIds);
    }
  }

  bool _isQuerying = false; // 标志位
  void queryTopAIUser() {
    if (_isQuerying) return; // 如果正在查询，直接返回
    _isQuerying = true; // 设置为正在查询

    var userList = AIUserManager.instance.getPinDefaultUserList();
    _logI('queryTopAIUser -->> ${userList.length}');

    _topAIUserList.clear(); // 清空列表

    if (userList.isNotEmpty) {
      ContactRepo.getUserList([IMKitClient.account()!]).then((value) {
        _isQuerying = false; // 查询结束，重置标志位
        if (value.isSuccess && value.data != null && value.data!.isNotEmpty) {
          var userUnpinArray =
              AIUserManager.instance.getUnpinAIUserList(value.data![0]);
          for (var user in userList) {
            if (!userUnpinArray.contains(user.accountId) &&
                !_topAIUserList.contains(user.accountId)) {
              _logI('queryTopAIUser addAIUser-->> ${user.accountId}');
              _topAIUserList.add(user);
            }
          }
        }
        notifyListeners(); // 仅在查询完成后调用
      });
    } else {
      _isQuerying = false; // 如果没有用户，重置标志位
      notifyListeners(); // 直接通知更新
    }
  }

  void fetchUserInfo(List<String>? userIds) {
    if (userIds != null && userIds.length > 0) {
      ContactRepo.getUserListFromCloud(userIds);
    }
  }

  ///删除会话
  void deleteConversation(ConversationInfo conversationInfo,
      {bool? clearMessageHistory}) async {
    if (!await haveConnectivity()) {
      return;
    }
    this.deleteConversationById(conversationInfo.getConversationId());
  }

  ///通过ID 删除会话
  void deleteConversationById(String conversationId,
      {bool? clearMessageHistory}) {
    if (clearMessageHistory == null) {
      clearMessageHistory = ConversationKitClient.instance.conversationUIConfig
          .itemConfig.clearMessageWhenDeleteSession;
    }
    ConversationRepo.deleteConversation(conversationId, clearMessageHistory);
  }

  ///本人是否已经退出了群
  bool _haveLeftTeam(ConversationInfo conversationInfo) {
    if (conversationInfo.getLastAttachment()
        is NIMMessageNotificationAttachment) {
      NIMMessageNotificationAttachment notify = conversationInfo
          .getLastAttachment() as NIMMessageNotificationAttachment;
      if (notify.type == NIMMessageNotificationType.teamDismiss) {
        return true;
      } else if (notify.type == NIMMessageNotificationType.teamKick) {
        var accId = getIt<IMLoginService>().userInfo?.accountId;
        var targetIds = notify.targetIds;
        if (targetIds != null && targetIds.contains(accId)) {
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
