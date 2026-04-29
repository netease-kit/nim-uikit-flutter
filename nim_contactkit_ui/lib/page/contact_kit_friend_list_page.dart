// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:nim_contactkit_ui/contact_kit_client.dart';
import 'package:nim_contactkit_ui/page/viewmodel/contact_viewmodel.dart';
import 'package:provider/provider.dart';

import '../l10n/S.dart';
import '../widgets/contact_kit_contact_list_view.dart';

/// 桌面端"我的好友"列表页面
///
/// 在右侧内容面板展示按字母排序的好友列表，不包含顶部功能入口。
class ContactKitFriendListPage extends StatefulWidget {
  final ContactListConfig? listConfig;

  const ContactKitFriendListPage({Key? key, this.listConfig}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FriendListPageState();
}

class _FriendListPageState extends State<ContactKitFriendListPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ContactViewModel(),
      builder: (context, child) {
        final contacts = context
            .watch<ContactViewModel>()
            .contacts
            .where((e) => e.isInBlack != true)
            .toList();
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              S.of(context).myFriend,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            centerTitle: false,
            elevation: 0.5,
            shadowColor: const Color(0xFFF5F8FC),
            backgroundColor: Colors.white,
          ),
          body: ContactListView(
            contactList: contacts,
            config: ContactUIConfig(
              showHeader: false,
              contactListConfig: widget.listConfig ?? const ContactListConfig(),
            ),
          ),
        );
      },
    );
  }
}
