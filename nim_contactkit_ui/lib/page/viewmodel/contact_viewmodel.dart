// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/contact/contact_provider.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

class ContactViewModel extends ChangeNotifier {
  List<ContactInfo> contacts = List.empty(growable: true);

  static final logTag = 'ContactViewModel';

  ///未读的验证消息
  int unReadCount = 0;

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
      contacts.clear();
      value.removeWhere((e) => e.isInBlack == true);
      contacts.addAll(value);
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
          unReadCount = value.data!;
        }
        notifyListeners();
      });
    }));
    subscriptions
        .add(ContactRepo.registerFriendAddRejectedObserver().listen((event) {
      ContactRepo.getAddApplicationUnreadCount().then((value) {
        if (value.isSuccess && value.data != null) {
          unReadCount = value.data!;
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
  }

  void init() {
    fetchContacts();
    initListener();
    featSystemUnreadCount();
  }

  void featSystemUnreadCount() {
    ContactRepo.getAddApplicationUnreadCount().then((value) {
      if (value.data != null) {
        unReadCount = value.data!;
        notifyListeners();
      }
    });
  }

  void cleanSystemUnreadCount() {
    unReadCount = 0;
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
