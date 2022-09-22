// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:im_common_ui/router/imkit_router_factory.dart';
import 'package:im_common_ui/widgets/search_page.dart';
import 'package:corekit_im/service_locator.dart';
import 'package:corekit_im/services/user_info/user_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_core/nim_core.dart';

import '../generated/l10n.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({Key? key}) : super(key: key);

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  @override
  Widget build(BuildContext context) {
    return SearchPage(
      title: S.of(context).add_friend,
      searchHint: S.of(context).add_friend_search_hint,
      buildOnComplete: true,
      builder: (context, keyword) {
        if (keyword.isEmpty)
          return Container();
        else {
          return FutureBuilder<List<NIMUser>?>(
              future: getIt<UserInfoProvider>().fetchUserInfo([keyword]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return Column(
                      children: [
                        const SizedBox(
                          height: 68,
                        ),
                        SvgPicture.asset(
                          'images/ic_search_empty.svg',
                          package: 'conversationkit_ui',
                        ),
                        const SizedBox(
                          height: 18,
                        ),
                        Text(
                          S.of(context).add_friend_search_empty_tips,
                          style:
                              TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
                        )
                      ],
                    );
                  } else {
                    Future.delayed(Duration(milliseconds: 200), () {
                      goToContactDetail(context, snapshot.data![0].userId!);
                    });
                  }
                }
                return Container();
              });
        }
      },
    );
  }
}
