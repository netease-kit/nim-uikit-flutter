// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/manager/subscription_manager.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/repo/team_repo.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/contact/contact_provider.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

//默认注册数量，联系人小于或等于此数量，则在拉取后直接注册
final int defaultSubscriptionCount = 10;

class ContactViewModel extends ChangeNotifier {
  List<ContactInfo> contacts = List.empty(growable: true);

  static final logTag = 'ContactViewModel';

  ///未读的验证消息
  int unReadCount = 0;

  //群未读数
  int _teamActionUnReadCount = 0;

  //好友未读数
  int _friendAddApplicationCount = 0;

  final subscriptions = <StreamSubscription?>[];

  ContactViewModel() {
    init();
  }

  void fetchContacts() {
    //优先从缓存中拉取数据
    ContactRepo.getContactList(userCache: true).then((value) {
      Alog.i(
          tag: 'ContactKit',
          moduleName: 'ContactViewModel',
          content: 'fetchContacts size:${value.length}');
      contacts.clear();
      value.removeWhere((e) => e.isInBlack == true);
      contacts.addAll(value);
      //小于10条，直接全员注册
      if (contacts.length <= defaultSubscriptionCount) {
        final users = contacts.map((e) => e.user.accountId!).toList();
        SubscriptionManager.instance.subscribeUserStatus(users);
      }
      notifyListeners();
    });
  }

  void initListener() {
    //注册监听，在登录后获取全量联系人数据
    subscriptions
        .add(getIt<ContactProvider>().onContactListComplete?.listen((value) {
      Alog.i(
          tag: 'ContactKit',
          moduleName: 'ContactViewModel',
          content: 'onContactListComplete size:${value.length}');
      List<String> onlineUsers = contacts
          .where((contact) => contact.isOnline)
          .map((e) => e.user.accountId!)
          .toList();
      contacts.clear();
      value.removeWhere((e) => e.isInBlack == true);
      contacts.addAll(value);
      for (var contact in contacts) {
        if (onlineUsers.contains(contact.user.accountId)) {
          contact.isOnline = true;
        }
      }
      notifyListeners();
    }));

    //好友变化监听，处理好友添加，黑名单等信息
    subscriptions
        .add(getIt<ContactProvider>().onContactInfoUpdated?.listen((event) {
      //仅需好友
      if (event.friend != null) {
        var index = contacts.indexWhere(
            (element) => element.user.accountId == event.user.accountId);
        if (event.isInBlack != true) {
          if (index >= 0) {
            contacts[index] = event;
          } else {
            contacts.add(event);
          }
        } else {
          Alog.d(
              tag: logTag, content: 'block list add ${event.user.accountId}');
          contacts.removeWhere((e) => e.user.accountId == event.user.accountId);
        }
        notifyListeners();
      }
    }));

    //处理好友申请未读数
    subscriptions
        .add(ContactRepo.registerFriendAddApplicationObserver().listen((event) {
      ContactRepo.getAddApplicationUnreadCount().then((value) {
        if (value.isSuccess && value.data != null) {
          _friendAddApplicationCount = value.data!;
          unReadCount = _friendAddApplicationCount + _teamActionUnReadCount;
        }
        notifyListeners();
      });
    }));
    subscriptions
        .add(ContactRepo.registerFriendAddRejectedObserver().listen((event) {
      ContactRepo.getAddApplicationUnreadCount().then((value) {
        if (value.isSuccess && value.data != null) {
          _friendAddApplicationCount = value.data!;
          unReadCount = _friendAddApplicationCount + _teamActionUnReadCount;
        }
        notifyListeners();
      });
    }));
    //监听好友删除回调
    subscriptions
        .add(ContactRepo.registerFriendDeleteObserver().listen((removedFriend) {
      Alog.d(tag: logTag, content: 'contact delete ${removedFriend.accountId}');
      contacts.removeWhere((e) => e.user.accountId == removedFriend.accountId);
      notifyListeners();
    }));

    if (IMKitConfigCenter.enableTeam) {
      subscriptions.add(NimCore.instance.teamService.onReceiveTeamJoinActionInfo
          .listen((action) {
        _teamActionUnReadCount = _teamActionUnReadCount + 1;
        unReadCount = _friendAddApplicationCount + _teamActionUnReadCount;
        //通过重新获取未读数，更新tab 小红点
        TeamRepo.getTeamActionsUnreadCount();
        notifyListeners();
      }));
    }

    subscriptions.add(NimCore.instance.subscriptionService.onUserStatusChanged
        .listen((List<NIMUserStatus> userList) {
      final Map<String, NIMUserStatus> userMap = {};
      for (final user in userList) {
        userMap[user.accountId] = user; // 直接以 id 为键，user 对象为值
      }
      contacts.forEach((e) {
        if (userMap.containsKey(e.user.accountId)) {
          e.isOnline = userMap[e.user.accountId]?.statusType == 1;
        }
      });
      notifyListeners();
    }));
  }

  void init() {
    initListener();
    fetchContacts();
    featSystemUnreadCount();
  }

  void featSystemUnreadCount() async {
    _friendAddApplicationCount =
        (await ContactRepo.getAddApplicationUnreadCount()).data ?? 0;
    if (!IMKitConfigCenter.enableTeam) {
      unReadCount = _friendAddApplicationCount;
      notifyListeners();
      return;
    }

    _teamActionUnReadCount =
        (await TeamRepo.getTeamActionsUnreadCount()).data ?? 0;

    unReadCount = _friendAddApplicationCount + _teamActionUnReadCount;
    notifyListeners();
  }

  void cleanSystemUnreadCount() {
    unReadCount = 0;
    _teamActionUnReadCount = 0;
    _friendAddApplicationCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    for (var sub in subscriptions) {
      sub?.cancel();
    }
    getIt<ContactProvider>().removeListeners();
  }
}
