// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_common_ui/router/imkit_router_factory.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_corekit_im/model/team_models.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n.dart';
import '../../view_model/team_setting_view_model.dart';

class TeamKitMemberListPage extends StatefulWidget {
  final String tId;

  const TeamKitMemberListPage({Key? key, required this.tId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => TeamKitMemberListPageState();
}

class TeamKitMemberListPageState extends State<TeamKitMemberListPage> {
  String? filterStr;

  void _onFilterChange(String text, BuildContext context) {
    context.read<TeamSettingViewModel>().filterByText(text);
  }

  OutlineInputBorder _border() => const OutlineInputBorder(
        gapPadding: 0,
        borderSide: BorderSide(
          color: Colors.transparent,
        ),
      );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        var viewModel = TeamSettingViewModel();
        viewModel.requestTeamMembers(widget.tId);
        return viewModel;
      },
      builder: (context, child) {
        var memberList = context.watch<TeamSettingViewModel>().filterList;
        return Scaffold(
          appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Text(S().team_member_title,
                  style: TextStyle(color: '#333333'.toColor(), fontSize: 16)),
              backgroundColor: Colors.white,
              iconTheme: Theme.of(context)
                  .primaryIconTheme
                  .copyWith(color: Colors.grey),
              elevation: 0,
              centerTitle: true),
          body: Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  // controller: queryTextController,
                  onChanged: (text) {
                    _onFilterChange(text, context);
                  },
                  decoration: InputDecoration(
                      fillColor: '#F2F4F5'.toColor(),
                      filled: true,
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      border: _border(),
                      enabledBorder: _border(),
                      focusedBorder: _border(),
                      hintText: S().team_search_friend,
                      hintStyle:
                          TextStyle(fontSize: 14, color: '#A6ADB6'.toColor()),
                      prefixIcon: const Icon(Icons.search)),
                ),
                Expanded(
                    child: ListView.builder(
                        itemCount: memberList?.length ?? 0,
                        itemBuilder: (context, index) {
                          var user = memberList?[index];
                          return TeamMemberListItem(teamMember: user!);
                        }))
              ],
            ),
          ),
        );
      },
    );
  }
}

class TeamMemberListItem extends StatefulWidget {
  final UserInfoWithTeam teamMember;

  const TeamMemberListItem({Key? key, required this.teamMember})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => TeamMemberListItemState();
}

class TeamMemberListItemState extends State<TeamMemberListItem> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (getIt<LoginService>().userInfo?.userId ==
            widget.teamMember.userInfo?.userId) {
          gotoMineInfoPage(context);
        } else {
          goToContactDetail(context, widget.teamMember.userInfo!.userId!);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Avatar(
              width: 42,
              height: 42,
              avatar: widget.teamMember.getAvatar(),
              name: widget.teamMember.getName(),
              bgCode: AvatarColor.avatarColor(
                  content: widget.teamMember.teamInfo.account),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 7)),
            Expanded(
              child: Text(
                widget.teamMember.getName(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, color: '#333333'.toColor()),
              ),
            )
          ],
        ),
      ),
    );
  }
}
