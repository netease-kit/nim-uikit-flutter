// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:contactkit_ui/page/contact_kit_black_list_page.dart';
import 'package:contactkit_ui/page/contact_kit_system_notify_message_page.dart';
import 'package:contactkit_ui/page/contact_kit_team_list_page.dart';
import 'package:contactkit_ui/page/viewmodel/contact_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../contact_kit_client.dart';
import '../generated/l10n.dart';
import '../widgets/contact_kit_contact_list_view.dart';

class ContactKitContactPage extends StatefulWidget {
  final ContactUIConfig? config;

  const ContactKitContactPage({Key? key, this.config}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ContactKitContactState();
}

class _ContactKitContactState extends State<ContactKitContactPage> {
  ContactUIConfig get uiConfig =>
      widget.config ?? ContactKitClient.instance.contactUIConfig;

  String? _getTips(BuildContext context) {
    int unreadCount = context.watch<ContactViewModel>().unReadCount;
    if (unreadCount > 99) {
      return '99+';
    } else if (unreadCount > 0) {
      return '$unreadCount';
    } else {
      return null;
    }
  }

  List<TopListItem> _buildDefaultTopList(BuildContext context) {
    return [
      TopListItem(
          name: S.of(context).contact_verify_message,
          icon: SvgPicture.asset(
            'images/ic_verify.svg',
            package: 'contactkit_ui',
            height: 36,
            width: 36,
          ),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ContactKitSystemNotifyMessagePage(
                listConfig: uiConfig.contactListConfig,
              );
            }));
          },
          tips: _getTips(context)),
      TopListItem(
          name: S.of(context).contact_black_list,
          icon: SvgPicture.asset(
            'images/ic_black_list.svg',
            package: 'contactkit_ui',
            height: 36,
            width: 36,
          ),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ContactKitBlackListPage(
                listConfig: uiConfig.contactListConfig,
              );
            }));
          }),
      TopListItem(
          name: S.of(context).contact_team,
          icon: SvgPicture.asset(
            'images/ic_team.svg',
            package: 'contactkit_ui',
            height: 36,
            width: 36,
          ),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ContactKitTeamListPage(
                listConfig: uiConfig.contactListConfig,
              );
            }));
          }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        var viewModel = ContactViewModel();
        viewModel.init();
        return viewModel;
      },
      builder: (context, child) {
        return ContactListView(
          contactList: context
              .watch<ContactViewModel>()
              .contacts
              .where((e) => e.isInBlack != true)
              .toList(),
          config: uiConfig,
          topList: uiConfig.headerData ?? _buildDefaultTopList(context),
        );
      },
    );
  }
}
