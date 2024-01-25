// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_corekit_im/im_kit_client.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:netease_corekit_im/services/message/message_provider.dart';
import 'package:nim_conversationkit/extention.dart';
import 'package:nim_conversationkit/model/conversation_info.dart';
import 'package:nim_conversationkit/repo/conversation_repo.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_conversationkit_ui/service/ait/ait_server.dart';
import 'package:nim_core/nim_core.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

class ConversationViewModel extends ChangeNotifier {
  final String modelName = 'ConversationViewModel';

  List<ConversationInfo> _conversationList = [];

  List<ConversationInfo> get conversationList => _conversationList;

  ValueChanged<int>? onUnreadCountChanged;

  set conversationList(List<ConversationInfo> value) {
    _conversationList = value;
    notifyListeners();
  }

  Comparator<ConversationInfo> _comparator = (a, b) {
    if (a.isStickTop == b.isStickTop) {
      var time = a.session.lastMessageTime! - b.session.lastMessageTime!;
      return time == 0 ? 0 : (time > 0 ? -1 : 1);
    }
    return a.isStickTop ? -1 : 1;
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

  _init() {
    _logI('init -->> ');
    if (getIt<LoginService>().status == NIMAuthStatus.dataSyncFinish) {
      queryConversationList();
    } else {
      subscriptions.add(getIt<LoginService>().loginStatus?.listen((event) {
        if (event == NIMAuthStatus.dataSyncFinish) {
          queryConversationList();
        }
      }));
    }
    getIt<MessageProvider>().initListener();
    // change observer
    subscriptions.add(
        ConversationRepo.registerSessionChangedObserver().listen((event) async {
      _logI('onSessionUpdate ${event.length}');
      List<ConversationInfo>? result =
          await ConversationRepo.fillSessionInfo(event);
      if (result != null) {
        for (var conversationInfo in result) {
          if (_isMineLeave(conversationInfo.session)) {
            deleteConversation(conversationInfo);
            _logI(
                'changeObserver:onSuccess:DismissTeam ${conversationInfo.session.sessionId}');
          } else {
            _updateItem(conversationInfo);
            _logI(
                'changeObserver:onSuccess:update ${conversationInfo.session.sessionId}');
          }
        }
        doUnreadCallback();
      }
    }));

    // delete observer
    subscriptions
        .add(ConversationRepo.registerSessionDeleteObserver().listen((event) {
      _logI('onSessionDelete ${event?.sessionId}');
      if (event == null) {
        // 清空会话列表
        _conversationList.clear();
        notifyListeners();
      } else {
        _deleteItem(event.sessionId, event.sessionType);
      }
      doUnreadCallback();
    }));

    // userInfo observer
    subscriptions
        .add(ConversationRepo.registerUserInfoObserver().listen((event) {
      _logI('onUserInfoChange size:${event.length}');
      _updateUserInfo(event);
    }));

    // friend observer
    subscriptions.add(ConversationRepo.registerFriendObserver()
        .listen((addedOrUpdatedFriends) {
      _logI('onFriendAddedOrUpdated size:${addedOrUpdatedFriends.length}');
      _updateFriendInfo(addedOrUpdatedFriends);
    }));

    // team update observer
    subscriptions
        .add(ConversationRepo.registerTeamUpdateObserver().listen((teamList) {
      _logI('onTeamListUpdate size:${teamList.length}');
      _updateTeamInfo(teamList);
    }));

    // mute observer
    subscriptions
        .add(ConversationRepo.registerFriendMuteObserver().listen((notify) {
      _logI('onMuteListChanged $notify');
      int index = _conversationList
          .indexWhere((element) => element.session.sessionId == notify.account);
      if (index > -1) {
        _conversationList[index].mute = notify.mute;
        notifyListeners();
      }
    }));

    // add stick observer
    subscriptions
        .add(ConversationRepo.registerAddStickTopObserver().listen((event) {
      _logI('onStickTopSessionAdd ${event.sessionId}');
      _addRemoveStickTop(event.sessionId, true);
      doUnreadCallback();
    }));

    // remove stick observer
    subscriptions
        .add(ConversationRepo.registerRemoveStickTopObserver().listen((event) {
      _logI('onStickTopSessionRemove ${event.sessionId}');
      _addRemoveStickTop(event.sessionId, false);
      doUnreadCallback();
    }));

    // sync stick observer
    subscriptions.add(
        ConversationRepo.registerSyncStickTopObserver().listen((eventList) {
      _logI('onSyncStickTop');
      queryConversationList();
    }));

    // ait observer
    subscriptions.add(
        AitServer.instance.onSessionAitUpdated.listen((AitSession? aitSession) {
      final index = _conversationList.indexWhere(
          (element) => element.session.sessionId == aitSession?.sessionId);
      if (index > -1) {
        _conversationList[index].haveBeenAit = aitSession!.isAit;
        notifyListeners();
      }
    }));

    // all read observer for ios
    subscriptions.add(
        NimCore.instance.messageService.allMessagesReadForIOS.listen((event) {
      _logI('allMessagesReadForIOS');
      _conversationList.forEach((element) {
        element.session.unreadCount = 0;
      });
      notifyListeners();
    }));

    //异步加载userInfo 回调
    subscriptions
        .add(ConversationRepo.instance.onUserInfoUpdated.listen((event) {
      var sessionList = event as List<ConversationInfo>;
      for (var session in sessionList) {
        int index = _conversationList.indexWhere((element) =>
            element.session.sessionType == NIMSessionType.p2p &&
            element.session.sessionId == session.user?.userId);
        if (index > -1) {
          _conversationList[index].user = session.user;
          _conversationList[index].friend = session.friend;
          _conversationList[index].mute = session.mute;
        }
      }
      notifyListeners();
    }));
  }

  _addRemoveStickTop(String sessionId, bool add) {
    int index = _conversationList
        .indexWhere((element) => element.session.sessionId == sessionId);
    if (index > -1) {
      _conversationList[index].isStickTop = add;
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

  int _searchComparatorIndex(ConversationInfo data) {
    if (data.isStickTop) {
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

  _updateTeamInfo(List<NIMTeam> teamList) {
    for (var team in teamList) {
      int index = _conversationList.indexWhere(
          (element) => element.team != null && element.team!.id == team.id);
      if (index > -1) {
        _conversationList[index].team = team;
        _conversationList[index].mute =
            team.messageNotifyType == NIMTeamMessageNotifyTypeEnum.mute;
      }
    }
    notifyListeners();
  }

  _updateFriendInfo(List<NIMFriend> addedOrUpdatedFriends) {
    for (var friend in addedOrUpdatedFriends) {
      int index = _conversationList.indexWhere((element) =>
          element.friend != null && element.friend!.userId == friend.userId);
      if (index > -1) {
        _conversationList[index].friend = friend;
      }
    }
    notifyListeners();
  }

  _updateUserInfo(List<NIMUser> users) {
    for (var userInfo in users) {
      int index = _conversationList.indexWhere((element) =>
          element.user != null && element.user!.userId == userInfo.userId);
      if (index > -1) {
        _conversationList[index].user = userInfo;
      }
    }
    notifyListeners();
  }

  _updateItem(ConversationInfo conversationInfo) async {
    int index = _conversationList
        .indexWhere((element) => element.isSame(conversationInfo));
    if (index > -1) {
      if (conversationInfo.session.sessionType == NIMSessionType.team) {
        bool haveBeenAit = _conversationList[index].haveBeenAit;
        if ((conversationInfo.session.unreadCount ?? 0) <= 0) {
          AitServer.instance
              .clearAitMessage(conversationInfo.session.sessionId);
          haveBeenAit = false;
        }
        if (haveBeenAit) {
          conversationInfo.haveBeenAit = true;
        }
      }
      _conversationList.removeAt(index);
      int insertIndex = _searchComparatorIndex(conversationInfo);
      _logI(
          'insertIndex:$insertIndex unread:${conversationInfo.session.unreadCount} haveBeenAit:${conversationInfo.haveBeenAit}');
      _conversationList.insert(insertIndex, conversationInfo);
    } else if (_isMySession(conversationInfo)) {
      int insertIndex = _searchComparatorIndex(conversationInfo);
      _conversationList.insert(insertIndex, conversationInfo);
    }
    notifyListeners();
  }

  /// 是否是我的会话,如果不是则不展示
  /// p2p 一定是我的会话
  /// team 有可能不是我的会话
  bool _isMySession(ConversationInfo conversationInfo) {
    if (conversationInfo.session.sessionType == NIMSessionType.p2p) {
      return true;
    }
    if (conversationInfo.session.sessionType == NIMSessionType.team) {
      return conversationInfo.team?.isMyTeam == true;
    }
    return true;
  }

  _deleteItem(String sessionId, NIMSessionType sessionType) {
    int index = _conversationList.indexWhere((element) =>
        element.session.sessionId == sessionId &&
        element.session.sessionType == sessionType);
    if (index > -1) {
      _conversationList.removeAt(index);
      notifyListeners();
    }
  }

  void queryConversationList() async {
    final _resultData = await ConversationRepo.getSessionList(_comparator);
    if (_resultData != null) {
      if (IMKitClient.enableAit) {
        final myId = IMKitClient.account();
        if (myId != null) {
          final aitSessionList =
              await AitServer.instance.getAllAitSession(myId);
          _resultData.forEach((element) {
            if (aitSessionList.contains(element.session.sessionId) &&
                (element.session.unreadCount ?? 0) > 0) {
              element.haveBeenAit = true;
            }
          });
        }
      }
      conversationList = _resultData;
    }
  }

  void deleteConversation(ConversationInfo conversationInfo,
      {bool? clearMessageHistory}) async {
    if (!await haveConnectivity()) {
      return;
    }
    if (clearMessageHistory == null) {
      clearMessageHistory = ConversationKitClient.instance.conversationUIConfig
          .itemConfig.clearMessageWhenDeleteSession;
    }
    ConversationRepo.deleteSession(
            conversationInfo.session.sessionId,
            conversationInfo.session.sessionType,
            NIMSessionDeleteType.localAndRemote,
            true,
            deleteHistory: clearMessageHistory)
        .then((value) {
      if (value.isSuccess) {
        _deleteItem(conversationInfo.session.sessionId,
            conversationInfo.session.sessionType);
      }
    });
  }

  bool _isMineLeave(NIMSession session) {
    if (session.lastMessageAttachment is NIMTeamNotificationAttachment) {
      NIMTeamNotificationAttachment notify =
          session.lastMessageAttachment as NIMTeamNotificationAttachment;
      var accId = getIt<LoginService>().userInfo?.userId;
      return notify.type == NIMTeamNotificationTypes.dismissTeam ||
          (notify.type == NIMTeamNotificationTypes.kickMember &&
              (notify as NIMMemberChangeAttachment?)
                      ?.targets
                      ?.contains(accId) ==
                  true) ||
          (notify.type == NIMTeamNotificationTypes.leaveTeam &&
              session.senderAccount == accId);
    }
    return false;
  }

  void addStickTop(ConversationInfo info) async {
    if (await haveConnectivity()) {
      ConversationRepo.addStickTop(
              info.session.sessionId, info.session.sessionType, '')
          .then((value) {
        if (value != null) {
          _logI('addStickTop:onSuccess sessionId:${value.sessionId}');
          info.isStickTop = true;
          _updateItem(info);
        }
      });
    }
  }

  void removeStick(ConversationInfo info) async {
    if (await haveConnectivity()) {
      ConversationRepo.removeStickTop(
              info.session.sessionId, info.session.sessionType, '')
          .then((value) {
        if (value) {
          _logI('removeStick:onSuccess sessionId:${info.session.sessionId}');
          info.isStickTop = false;
          _updateItem(info);
        }
      });
    }
  }

  @override
  void dispose() {
    _logI('dispose');
    for (var element in subscriptions) {
      element?.cancel();
    }
    getIt<MessageProvider>().removeListeners();
    super.dispose();
  }
}
