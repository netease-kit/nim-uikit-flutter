// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:netease_corekit_im/model/contact_info.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/contact/contact_provider.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import 'package:nim_core_v2/nim_core.dart';
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
    subscriptions.add(NimCore.instance.loginService.onDataSync.listen((event) {
      if (event.type == NIMDataSyncType.nimDataSyncMain &&
          event.state == NIMDataSyncState.nimDataSyncStateCompleted) {
        fetchContacts();
      }
    }));

    subscriptions.add(ContactRepo.registerFriendAddedObserver().listen((event) {
      var userId = event.accountId;
      Alog.d(tag: logTag, content: 'onFriendAdded ${userId}');
      var index =
          contacts.indexWhere((element) => element.user.accountId == userId);
      if (index >= 0) {
        contacts[index].friend = event;
        notifyListeners();
      } else {
        getIt<ContactProvider>().getContact(userId).then((value) {
          if (value != null) {
            Alog.d(
                tag: logTag,
                content: 'contacts add value ${value.user.accountId}');
            contacts.add(value);
            notifyListeners();
          }
        });
      }
    }));

    subscriptions
        .add(ContactRepo.registerFriendInfoChangedObserver().listen((event) {
      var userId = event.accountId;
      Alog.d(tag: logTag, content: 'onFriendInfoChanged ${userId}');
      var index =
          contacts.indexWhere((element) => element.user.accountId == userId);
      if (index >= 0) {
        contacts[index].friend = event;
        notifyListeners();
      } else {
        getIt<ContactProvider>().getContact(userId).then((value) {
          if (value != null) {
            Alog.d(
                tag: logTag,
                content: 'contact update value ${value.user.accountId}');
            contacts.add(value);
            notifyListeners();
          }
        });
      }
    }));
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
    subscriptions
        .add(ContactRepo.registerFriendDeleteObserver().listen((removedFriend) {
      Alog.d(tag: logTag, content: 'contact delete ${removedFriend.accountId}');
      contacts.removeWhere((e) => e.user.accountId == removedFriend.accountId);
      notifyListeners();
    }));

    subscriptions
        .add(ContactRepo.registerBlackListAddedObserver().listen((blockFriend) {
      Alog.d(tag: logTag, content: 'onBlackListAdded ${blockFriend.accountId}');
      contacts.removeWhere((e) => e.user.accountId == blockFriend.accountId);
      notifyListeners();
    }));

    subscriptions
        .add(ContactRepo.registerBlackListRemovedObserver().listen((userId) {
      Alog.d(tag: logTag, content: 'onBlackListRemoved ${userId}');
      var index =
          contacts.indexWhere((element) => element.user.accountId == userId);
      if (index >= 0) {
        contacts[index].friend =
            getIt<ContactProvider>().getContactInCache(userId)?.friend;
        notifyListeners();
      } else {
        final value = getIt<ContactProvider>().getContactInCache(userId);
        if (value != null && value.friend != null) {
          Alog.d(
              tag: logTag,
              content: 'contacts add value ${value.user.accountId}');
          contacts.add(value);
          notifyListeners();
        }
      }
    }));

    subscriptions
        .add(getIt<ContactProvider>().onContactInfoUpdated?.listen((event) {
      if (event != null) {
        var index = contacts.indexWhere(
            (element) => element.user.accountId == event.user.accountId);
        if (index >= 0) {
          contacts[index] = event;
          notifyListeners();
        }
      }
    }));
  }

  void init() {
    getIt<ContactProvider>().initListener();
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
