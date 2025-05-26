// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/contact/contact_provider.dart';
import 'package:nim_contactkit_ui/contact_kit_client.dart';
import 'package:nim_contactkit_ui/page/viewmodel/ai_user_list_viewmodel.dart';
import 'package:nim_contactkit_ui/page/viewmodel/black_list_viewmodel.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';

import '../l10n/S.dart';

///联系人AI数字人列表
class ContactKitAIUserListPage extends StatefulWidget {
  const ContactKitAIUserListPage({Key? key, this.listConfig}) : super(key: key);

  final ContactListConfig? listConfig;

  @override
  State<StatefulWidget> createState() => _AIUserListPageState();
}

class _AIUserListPageState extends State<ContactKitAIUserListPage> {
  Widget _buildItem(BuildContext context, NIMAIUser user) {
    return InkWell(
        onTap: () {
          goToContactDetail(context, user.accountId!!);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Avatar(
                width: 36,
                height: 36,
                avatar: user.avatar,
                name: user.name ?? user.accountId,
                bgCode: AvatarColor.avatarColor(content: user.accountId),
                radius: widget.listConfig?.avatarCornerRadius,
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    user.name ?? user.accountId!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: widget.listConfig?.nameTextSize ?? 14,
                        color: widget.listConfig?.nameTextColor ??
                            CommonColors.color_333333),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        var viewModel = AIUserListViewModel();
        viewModel.init();
        return viewModel;
      },
      builder: (context, child) {
        List<NIMAIUser> users =
            context.watch<AIUserListViewModel>().aiUserList.toList();
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
              S.of(context).contactAIUserList,
              style: TextStyle(
                  fontSize: 16,
                  color: '#333333'.toColor(),
                  fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            elevation: 0,
          ),
          body: users.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: ListView.separated(
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _buildItem(context, user);
                      },
                      itemCount: users.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          Divider(
                        height: 1,
                        color: '#F5F8FC'.toColor(),
                      ),
                    ))
                  ],
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 170,
                    ),
                    SvgPicture.asset(
                      'images/ic_search_empty.svg',
                      package: kPackage,
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      child: Text(
                        S.of(context).aiUsersEmpty,
                        style:
                            TextStyle(fontSize: 14, color: '#B3B7BC'.toColor()),
                      ),
                    ),
                    Expanded(
                      child: Container(),
                      flex: 1,
                    ),
                  ],
                ),
        );
      },
    );
  }
}
