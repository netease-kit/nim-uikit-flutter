// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/contact/contact_provider.dart';
import 'package:nim_contactkit_ui/contact_kit_client.dart';
import 'package:nim_contactkit_ui/page/viewmodel/black_list_viewmodel.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';

import '../l10n/S.dart';

///联系人黑名单
class ContactKitBlackListPage extends StatefulWidget {
  const ContactKitBlackListPage({Key? key, this.listConfig}) : super(key: key);

  final ContactListConfig? listConfig;

  @override
  State<StatefulWidget> createState() => _BlackListPageState();
}

class _BlackListPageState extends State<ContactKitBlackListPage> {
  Widget _buildItem(BuildContext context, NIMUserInfo user) {
    return FutureBuilder<ContactInfo?>(
        future: getIt<ContactProvider>().getContact(user.accountId!),
        builder: (context, snapshot) {
          var contact = snapshot.data;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Avatar(
                  width: 36,
                  height: 36,
                  avatar: user.avatar,
                  name: contact?.getName() ?? user.accountId,
                  bgCode: AvatarColor.avatarColor(content: user.accountId),
                  radius: widget.listConfig?.avatarCornerRadius,
                ),
                Expanded(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      contact?.getName() ?? user.accountId!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: widget.listConfig?.nameTextSize ?? 14,
                          color: widget.listConfig?.nameTextColor ??
                              CommonColors.color_333333),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    context
                        .read<BlackListViewModel>()
                        .removeFromBlackList(user.accountId!);
                  },
                  child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: '#337EFF'.toColor(), width: 1),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4))),
                      child: Text(S.of(context).contactRelease,
                          style: TextStyle(
                            fontSize: 14,
                            color: '#337EFF'.toColor(),
                          ))),
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        var viewModel = BlackListViewModel();
        viewModel.init();
        return viewModel;
      },
      builder: (context, child) {
        List<NIMUserInfo> users =
            context.watch<BlackListViewModel>().blackListUsers.toList();
        return TransparentScaffold(
          backgroundColor: Colors.white,
          title: S.of(context).contactBlackList,
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
                onPressed: () {
                  //选择器
                  goToContactSelector(context,
                          filter: users.map((e) => e.accountId!).toList())
                      .then((value) {
                    if (value is List<String> && value.isNotEmpty) {
                      context
                          .read<BlackListViewModel>()
                          .addUserListToBlackList(value);
                    }
                  });
                },
                icon: Icon(
                  Icons.add,
                  size: 26,
                  color: '#333333'.toColor(),
                ))
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(left: 20, top: 16),
                child: Text(
                  S
                      .of(context)
                      .contactYouWillNeverReceiveAnyMessageFromThosePerson,
                  style: TextStyle(fontSize: 14, color: '#B3B7BC'.toColor()),
                ),
              ),
              Expanded(
                  child: ListView.separated(
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _buildItem(context, user);
                },
                itemCount: users.length,
                separatorBuilder: (BuildContext context, int index) => Divider(
                  height: 1,
                  color: '#F5F8FC'.toColor(),
                ),
              ))
            ],
          ),
        );
      },
    );
  }
}
