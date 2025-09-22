// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_contactkit_ui/page/viewmodel/team_list_viewmodel.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';

import '../contact_kit_client.dart';
import '../l10n/S.dart';

class ContactKitTeamListPage extends StatefulWidget {
  final bool? selectorModel;
  final ContactListConfig? listConfig;

  const ContactKitTeamListPage({Key? key, this.selectorModel, this.listConfig})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _TeamListPageState();
}

class _TeamListPageState extends State<ContactKitTeamListPage> {
  Widget _buildItem(BuildContext context, NIMTeam team) {
    return InkWell(
      onTap: () {
        // goto team chat
        if (widget.selectorModel == true) {
          Navigator.pop(context, team);
        } else {
          goToTeamChat(context, team.teamId);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Avatar(
              width: 36,
              height: 36,
              avatar: team.avatar,
              name: team.name,
              bgCode: AvatarColor.avatarColor(content: team.teamId),
              radius: widget.listConfig?.avatarCornerRadius,
            ),
            Expanded(
              child: Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    team.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: widget.listConfig?.nameTextSize ?? 16,
                        color: widget.listConfig?.nameTextColor ??
                            CommonColors.color_333333),
                  )),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        var viewModel = TeamListViewModel();
        viewModel.init();
        return viewModel;
      },
      builder: (context, child) {
        List<NIMTeam> teams =
            context.watch<TeamListViewModel>().teamList.toList();
        return TransparentScaffold(
          backgroundColor: Colors.white,
          title: S.of(context).contactTeam,
          centerTitle: true,
          elevation: 0,
          body: ListView.separated(
            itemBuilder: (context, index) {
              final team = teams[index];
              return _buildItem(context, team);
            },
            itemCount: teams.length,
            separatorBuilder: (BuildContext context, int index) => Divider(
              height: 1,
              color: '#F5F8FC'.toColor(),
            ),
          ),
        );
      },
    );
  }
}
