// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/model/team_models.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_chatkit/services/message/nim_chat_cache.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:nim_teamkit_ui/view/pages/team_kit_member_list_page.dart';
import 'package:provider/provider.dart';

import '../../l10n/S.dart';
import '../../team_kit_client.dart';
import '../../view_model/team_setting_view_model.dart';

class TeamKitManagerListPage extends StatefulWidget {
  final String tId;

  const TeamKitManagerListPage({Key? key, required this.tId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => TeamKitManagerListPageState();
}

class TeamKitManagerListPageState extends State<TeamKitManagerListPage> {
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
        viewModel.addTeamSubscribe();
        return viewModel;
      },
      builder: (context, child) {
        var memberList = context
            .watch<TeamSettingViewModel>()
            .userInfoData
            ?.where((e) =>
                e.teamInfo.memberRole == NIMTeamMemberRole.memberRoleManager)
            .toList();
        memberList?.sort(
            (a, b) => a.teamInfo.joinTime.compareTo(b.teamInfo.joinTime));
        return TransparentScaffold(
          title: S.of(context).teamManagers,
          appBarBackgroundColor: Colors.white,
          iconTheme:
              Theme.of(context).primaryIconTheme.copyWith(color: Colors.grey),
          elevation: 0,
          centerTitle: true,
          body: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    S.of(context).teamAddManagers,
                    style: TextStyle(fontSize: 16, color: '#333333'.toColor()),
                  ),
                  trailing: const Icon(Icons.keyboard_arrow_right_outlined),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TeamKitMemberListPage(
                                  tId: widget.tId,
                                  showOwnerAndManager: false,
                                  isMultiSelectModel: true,
                                  showAIMember: false,
                                ))).then((value) {
                      if (value is List<String>) {
                        context
                            .read<TeamSettingViewModel>()
                            .addTeamManager(widget.tId, value);
                      }
                    });
                  },
                ),
                (memberList?.length ?? 0) > 0
                    ? Expanded(
                        child: ListView.builder(
                            itemCount: memberList?.length ?? 0,
                            itemBuilder: (context, index) {
                              var user = memberList?[index];
                              return TeamMemberListItem(teamMember: user!);
                            }),
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: 170,
                          ),
                          SvgPicture.asset(
                            'images/ic_member_empty.svg',
                            package: kPackage,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 18),
                            child: Text(
                              S.of(context).teamManagerEmpty,
                              style: TextStyle(
                                  color: CommonColors.color_b3b7bc,
                                  fontSize: 14),
                            ),
                          ),
                        ],
                      )
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

class TeamMemberListItemState extends BaseState<TeamMemberListItem> {
  void _showRemoveConfirmDialog(
      BuildContext context, String tid, String account) {
    showCommonDialog(
      context: context,
      title: S.of(context).teamRemoveConfirm,
      content: S.of(context).teamRemoveConfirmContent,
      positiveContent: S.of(context).teamMemberRemove,
      navigateContent: S.of(context).teamCancel,
    ).then((value) {
      if (value == true) {
        if (checkNetwork()) {
          context
              .read<TeamSettingViewModel>()
              .removeTeamManager(tid, account)
              .then((value) {
            if (!value.isSuccess) {
              Fluttertoast.showToast(
                  msg: S.of(context).teamManagerRemoveFailed);
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (getIt<IMLoginService>().userInfo?.accountId ==
            widget.teamMember.userInfo?.accountId) {
          gotoMineInfoPage(context);
        } else {
          goToContactDetail(context, widget.teamMember.userInfo!.accountId!);
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
              name: widget.teamMember
                  .getName(needAlias: false, needTeamNick: false),
              bgCode: AvatarColor.avatarColor(
                  content: widget.teamMember.teamInfo.accountId),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 7)),
            Expanded(
              child: Text(
                widget.teamMember.getName(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, color: '#333333'.toColor()),
              ),
            ),
            if (NIMChatCache.instance.myTeamRole() ==
                NIMTeamMemberRole.memberRoleOwner)
              TextButton(
                onPressed: () {
                  _showRemoveConfirmDialog(
                      context,
                      widget.teamMember.teamInfo.teamId,
                      widget.teamMember.userInfo!.accountId!);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                      border: Border.all(color: '#E6605C'.toColor(), width: 1),
                      borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Text(
                    S.of(context).teamMemberRemove,
                    maxLines: 1,
                    style: TextStyle(fontSize: 12, color: '#E6605C'.toColor()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
