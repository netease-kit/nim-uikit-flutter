// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:nim_contactkit/repo/contact_repo.dart';
import 'package:netease_corekit_im/model/contact_info.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/contact/contact_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:nim_core/nim_core.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

class ContactViewModel extends ChangeNotifier {
  List<ContactInfo> contacts = List.empty(growable: true);

  static final logTag = 'ContactViewModel';

  ///未读的验证消息
  int unReadCount = 0;

  final subscriptions = <StreamSubscription?>[];

  void fetchContacts() {
    ContactRepo.getContactList().then((value) {
      Alog.i(
          tag: 'ContactKit',
          moduleName: 'ContactViewModel',
          content: 'fetchContacts size:${value.length}');
      contacts.clear();
      contacts.addAll(value);
      notifyListeners();
    });
  }

  void initListener() {
    subscriptions.add(getIt<LoginService>().loginStatus?.listen((event) {
      if (event == NIMAuthStatus.dataSyncFinish) {
        fetchContacts();
      }
    }));
    subscriptions.add(ContactRepo.registerFriendObserver().listen((event) {
      for (var e in event) {
        var userId = e.userId;
        Alog.d(tag: logTag, content: 'onFriendAdded ${e.userId}');
        var index =
            contacts.indexWhere((element) => element.user.userId == userId);
        if (index >= 0) {
          contacts[index].friend = e;
          notifyListeners();
        } else {
          ContactRepo.getFriend(userId!).then((value) {
            if (value != null) {
              Alog.d(
                  tag: logTag,
                  content: 'contacts add value ${value.user.userId}');
              contacts.add(value);
              notifyListeners();
            }
          });
        }
      }
    }));
    subscriptions.add(
        ContactRepo.registerNotificationUnreadCountObserver().listen((event) {
      unReadCount = event;
      notifyListeners();
    }));
    subscriptions
        .add(ContactRepo.registerFriendDeleteObserver().listen((removedList) {
      if (removedList.isNotEmpty) {
        Alog.d(tag: logTag, content: 'contacts delete ${removedList.length}');
        contacts.removeWhere((e) => removedList.contains(e.user.userId));
      }
      notifyListeners();
    }));
    subscriptions
        .add(getIt<ContactProvider>().onContactInfoUpdated?.listen((event) {
      if (event != null) {
        var index = contacts
            .indexWhere((element) => element.user.userId == event.user.userId);
        if (index >= 0) {
          contacts[index] = event;
          notifyListeners();
        }
      }
    }));
  }

  void init() {
    if (getIt<LoginService>().status == NIMAuthStatus.dataSyncFinish) {
      fetchContacts();
    }
    getIt<ContactProvider>().initListener();
    initListener();
    featSystemUnreadCount();
  }

  void featSystemUnreadCount() {
    ContactRepo.getNotificationUnreadCount().then((value) {
      if (value.data != null) {
        unReadCount = value.data!;
        notifyListeners();
      }
    });
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
