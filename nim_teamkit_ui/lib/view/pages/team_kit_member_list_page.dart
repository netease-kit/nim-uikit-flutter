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
import 'package:netease_common_ui/widgets/radio_button.dart';
import 'package:netease_corekit_im/model/team_models.dart';
import 'package:netease_corekit_im/router/imkit_router_factory.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:netease_corekit_im/services/message/nim_chat_cache.dart';
import 'package:nim_core/nim_core.dart';
import 'package:nim_teamkit_ui/team_kit_client.dart';
import 'package:provider/provider.dart';

import '../../l10n/S.dart';
import '../../view_model/team_setting_view_model.dart';

/// 默认群管理数量限制
const int teamManagersLimitDefault = 10;

class TeamKitMemberListPage extends StatefulWidget {
  final String tId;

  /// 是否显示群主和管理员
  final bool showOwnerAndManager;

  final bool isSelectModel;

  const TeamKitMemberListPage(
      {Key? key,
      required this.tId,
      this.showOwnerAndManager = true,
      this.isSelectModel = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => TeamKitMemberListPageState();
}

class TeamKitMemberListPageState extends BaseState<TeamKitMemberListPage> {
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
        viewModel.addTeamSubscribe();
        return viewModel;
      },
      builder: (context, child) {
        var memberList = context.watch<TeamSettingViewModel>().filterList;
        if (!widget.showOwnerAndManager) {
          memberList = memberList
              ?.where((e) =>
                  e.teamInfo.type != TeamMemberType.owner &&
                  e.teamInfo.type != TeamMemberType.manager)
              .toList();
        }
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: widget.isSelectModel
                  ? Text(
                      S.of(context).teamCancel,
                      style:
                          TextStyle(color: '#666666'.toColor(), fontSize: 16),
                    )
                  : const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
                widget.isSelectModel
                    ? S.of(context).teamMemberSelect
                    : S.of(context).teamMemberTitle,
                style: TextStyle(color: '#333333'.toColor(), fontSize: 16)),
            backgroundColor: Colors.white,
            iconTheme:
                Theme.of(context).primaryIconTheme.copyWith(color: Colors.grey),
            elevation: 0,
            centerTitle: true,
            actions: [
              if (widget.isSelectModel)
                TextButton(
                    onPressed: () {
                      if (!checkNetwork()) {
                        return;
                      }
                      if (context
                          .read<TeamSettingViewModel>()
                          .selectedList
                          .isNotEmpty) {
                        int managerLimit =
                            TeamKitClient.instance.teamManagerLimit ??
                                teamManagersLimitDefault;
                        int teamManagersCount =
                            NIMChatCache.instance.getTeamManagers()?.length ??
                                0;
                        if (teamManagersCount +
                                context
                                    .read<TeamSettingViewModel>()
                                    .selectedList
                                    .length >
                            managerLimit) {
                          Fluttertoast.showToast(
                              msg: S
                                  .of(context)
                                  .teamManagerLimit(managerLimit.toString()));
                          return;
                        }
                        Navigator.pop(
                            context,
                            context
                                .read<TeamSettingViewModel>()
                                .selectedList
                                .map((e) => e.teamInfo.account!)
                                .toList());
                      } else {
                        Fluttertoast.showToast(
                            msg: S.of(context).teamSelectMembers);
                      }
                    },
                    child: Text(
                      '${S.of(context).teamConfirm}(${context.read<TeamSettingViewModel>().selectedList.length})',
                      style:
                          TextStyle(color: '#337EFF'.toColor(), fontSize: 16),
                    ))
            ],
          ),
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
                          horizontal: 18, vertical: 15),
                      border: _border(),
                      enabledBorder: _border(),
                      focusedBorder: _border(),
                      hintText: S.of(context).teamSearchMember,
                      hintStyle:
                          TextStyle(fontSize: 14, color: '#A6ADB6'.toColor()),
                      prefixIcon: const Icon(Icons.search)),
                ),
                memberList?.isNotEmpty == true
                    ? Expanded(
                        child: ListView.builder(
                            itemCount: memberList?.length ?? 0,
                            itemBuilder: (context, index) {
                              var user = memberList?[index];
                              return TeamMemberListItem(
                                  teamMember: user!,
                                  isSelectModel: widget.isSelectModel);
                            }))
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
                              S.of(context).teamMemberEmpty,
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

  final bool isSelectModel;

  const TeamMemberListItem(
      {Key? key, required this.teamMember, this.isSelectModel = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => TeamMemberListItemState();
}

class TeamMemberListItemState extends BaseState<TeamMemberListItem> {
  bool _showRemoveButton(UserInfoWithTeam teamMember) {
    if (teamMember.teamInfo.type == TeamMemberType.owner) {
      return false;
    }
    if (NIMChatCache.instance.myTeamRole() == TeamMemberType.owner) {
      return true;
    } else if (NIMChatCache.instance.myTeamRole() == TeamMemberType.manager) {
      if (teamMember.teamInfo.type == TeamMemberType.normal) {
        return true;
      }
    }
    return false;
  }

  void _showRemoveConfirmDialog(
      BuildContext context, String tid, String account) {
    showCommonDialog(
      context: context,
      title: S.of(context).teamRemoveConfirm,
      content: S.of(context).teamMemberRemoveContent,
      positiveContent: S.of(context).teamMemberRemove,
      navigateContent: S.of(context).teamCancel,
    ).then((value) {
      if (value == true) {
        if (checkNetwork()) {
          context
              .read<TeamSettingViewModel>()
              .removeTeamMember(tid, account)
              .then((value) {
            if (value.isSuccess == false) {
              Fluttertoast.showToast(msg: S.of(context).teamMemberRemoveFailed);
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
        if (widget.isSelectModel) {
          if (context
              .read<TeamSettingViewModel>()
              .isSelected(widget.teamMember)) {
            context
                .read<TeamSettingViewModel>()
                .removeSelected(widget.teamMember);
          } else {
            context.read<TeamSettingViewModel>().addSelected(widget.teamMember);
          }
          return;
        }
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
            if (widget.isSelectModel)
              Container(
                margin: const EdgeInsets.only(right: 10),
                // 选择框
                child: CheckBoxButton(
                  isChecked: context
                      .watch<TeamSettingViewModel>()
                      .isSelected(widget.teamMember),
                  clickable: false,
                ),
              ),
            Avatar(
              width: 42,
              height: 42,
              avatar: widget.teamMember.getAvatar(),
              name: widget.teamMember
                  .getName(needAlias: false, needTeamNick: false),
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
            ),
            if (widget.teamMember.teamInfo.type == TeamMemberType.owner)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                    color: '#F7F7F7'.toColor(),
                    border: Border.all(color: '#D6D8DB'.toColor(), width: 1),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(
                  S.of(context).teamOwner,
                  style: TextStyle(fontSize: 12, color: '#656A72'.toColor()),
                ),
              ),
            if (widget.teamMember.teamInfo.type == TeamMemberType.manager)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                    color: '#F7F7F7'.toColor(),
                    border: Border.all(color: '#D6D8DB'.toColor(), width: 1),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(
                  S.of(context).teamManager,
                  style: TextStyle(fontSize: 12, color: '#656A72'.toColor()),
                ),
              ),
            if (!widget.isSelectModel && _showRemoveButton(widget.teamMember))
              TextButton(
                onPressed: () {
                  _showRemoveConfirmDialog(
                      context,
                      widget.teamMember.teamInfo.id!,
                      widget.teamMember.userInfo!.userId!);
                },
                child: Container(
                  width: 50,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                      border: Border.all(color: '#E6605C'.toColor(), width: 1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    S.of(context).teamMemberRemove,
                    maxLines: 1,
                    style: TextStyle(fontSize: 12, color: '#E6605C'.toColor()),
                  ),
                ),
              ),
            if (!widget.isSelectModel && !_showRemoveButton(widget.teamMember))
              Container(
                width: 70,
              )
          ],
        ),
      ),
    );
  }
}
