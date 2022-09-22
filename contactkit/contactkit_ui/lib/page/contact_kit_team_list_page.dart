// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:im_common_ui/router/imkit_router_factory.dart';
import 'package:im_common_ui/ui/avatar.dart';
import 'package:im_common_ui/utils/color_utils.dart';
import 'package:contactkit/repo/contact_repo.dart';
import 'package:flutter/material.dart';
import 'package:nim_core/nim_core.dart';

import '../contact_kit_client.dart';
import '../generated/l10n.dart';

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
          goToTeamChat(context, team.id!);
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
              avatar: team.icon,
              name: team.name,
              bgCode: AvatarColor.avatarColor(content: team.id),
              radius: widget.listConfig?.avatarCornerRadius,
            ),
            Expanded(
              child: Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    team.name!,
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
          S.of(context).contact_team,
          style: TextStyle(
              fontSize: 16,
              color: '#333333'.toColor(),
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<NIMTeam>>(
        initialData: List.empty(),
        future: ContactRepo.getTeamList().then((value) {
          if (value.isSuccess && value.data != null) {
            return value.data!;
          } else {
            return List.empty();
          }
        }),
        builder: (context, users) {
          return ListView.separated(
            itemBuilder: (context, index) {
              final user = users.data![index];
              return _buildItem(context, user);
            },
            itemCount: users.data!.length,
            separatorBuilder: (BuildContext context, int index) => Divider(
              height: 1,
              color: '#F5F8FC'.toColor(),
            ),
          );
        },
      ),
    );
  }
}
