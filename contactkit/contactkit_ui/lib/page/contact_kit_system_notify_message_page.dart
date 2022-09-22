// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:im_common_ui/ui/avatar.dart';
import 'package:im_common_ui/utils/color_utils.dart';
import 'package:contactkit/model/system_notify_info.dart';
import 'package:contactkit/repo/contact_repo.dart';
import 'package:contactkit_ui/contact_kit_client.dart';
import 'package:contactkit_ui/page/viewmodel/system_notify_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_core/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../generated/l10n.dart';

class ContactKitSystemNotifyMessagePage extends StatefulWidget {
  const ContactKitSystemNotifyMessagePage({Key? key, this.listConfig})
      : super(key: key);

  final ContactListConfig? listConfig;

  @override
  State<StatefulWidget> createState() => _SystemNotifyPageState();
}

class _SystemNotifyPageState extends State<ContactKitSystemNotifyMessagePage> {
  int offset = 0;

  Widget _buildItem(BuildContext context, SystemMessage message) {
    String getHeadMessageText(String userName, String? teamName) {
      if (message.type == SystemMessageType.addFriend &&
          message.attachObject is AddFriendNotify) {
        AddFriendNotify notification = message.attachObject as AddFriendNotify;
        switch (notification.event) {
          case FriendEvent.addFriendDirect:
            return S.of(context).contact_some_add_your_as_friend(userName);
          case FriendEvent.addFriendVerifyRequest:
            return S.of(context).contact_apply_from(userName);
          case FriendEvent.agreeAddFriend:
            return S.of(context).contact_some_accept_your_apply(userName);
          case FriendEvent.rejectAddFriend:
            return S.of(context).contact_some_reject_your_apply(userName);
          default:
            break;
        }
      }
      if (message.type == SystemMessageType.teamInvite) {
        return S
            .of(context)
            .contact_someone_invite_your_join_team(userName, teamName ?? '');
      }
      if (message.type == SystemMessageType.declineTeamInvite) {
        return S.of(context).contact_some_reject_your_invitation(userName);
      }
      if (message.type == SystemMessageType.rejectTeamApply) {
        return S.of(context).contact_some_reject_your_team_apply(userName);
      }
      if (message.type == SystemMessageType.applyJoinTeam) {
        return S
            .of(context)
            .contact_someone_apply_join_team(userName, teamName ?? '');
      }
      return userName;
    }

    String getStatueText() {
      switch (message.status) {
        case SystemMessageStatus.passed:
          return S.of(context).contact_accepted;
        case SystemMessageStatus.declined:
          return S.of(context).contact_rejected;
        case SystemMessageStatus.ignored:
          return S.of(context).contact_ignored;
        case SystemMessageStatus.expired:
          return S.of(context).contact_expired;
        default:
          return '';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: FutureBuilder<NotifyExtension>(
                future: message.getNotifyExt(),
                builder: (context, snapShot) {
                  var user = snapShot.data?.fromUser;
                  var team = snapShot.data?.targetTeam;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Avatar(
                        width: 36,
                        height: 36,
                        avatar: user?.avatar,
                        name: user?.nick?.isNotEmpty == true
                            ? user?.nick
                            : message.fromAccount,
                        bgCode: AvatarColor.avatarColor(
                            content: message.fromAccount),
                        radius: widget.listConfig?.avatarCornerRadius,
                      ),
                      Expanded(
                          child: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          getHeadMessageText(
                              user?.nick?.isNotEmpty == true
                                  ? user!.nick!
                                  : message.fromAccount!,
                              team?.name),
                          style: TextStyle(
                              fontSize: widget.listConfig?.nameTextSize ?? 14,
                              color: widget.listConfig?.nameTextColor ??
                                  CommonColors.color_333333),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                    ],
                  );
                }),
          ),
          if (message.status == SystemMessageStatus.init &&
              !(message.attachObject is AddFriendNotify &&
                  (message.attachObject as AddFriendNotify).event !=
                      FriendEvent.addFriendVerifyRequest) &&
              message.type != SystemMessageType.declineTeamInvite &&
              message.type != SystemMessageType.rejectTeamApply)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    context.read<SystemNotifyViewModel>().reject(message);
                  },
                  child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: '#D9D9D9'.toColor(), width: 1),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4))),
                      child: Text(S.of(context).contact_reject,
                          style: TextStyle(
                            fontSize: 14,
                            color: '#333333'.toColor(),
                          ))),
                ),
                Container(
                  width: 16,
                ),
                InkWell(
                  onTap: () {
                    context.read<SystemNotifyViewModel>().agree(message);
                  },
                  child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: '#337EFF'.toColor(), width: 1),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4))),
                      child: Text(S.of(context).contact_accept,
                          style: TextStyle(
                            fontSize: 14,
                            color: '#337EFF'.toColor(),
                          ))),
                ),
              ],
            ),
          if (message.status == SystemMessageStatus.declined ||
              message.status == SystemMessageStatus.expired ||
              message.status == SystemMessageStatus.ignored ||
              message.status == SystemMessageStatus.passed)
            Row(
              children: [
                if (message.status == SystemMessageStatus.passed)
                  SvgPicture.asset(
                    'images/ic_agree.svg',
                    package: 'contactkit_ui',
                    height: 16,
                    width: 16,
                  ),
                if (message.status == SystemMessageStatus.declined)
                  SvgPicture.asset(
                    'images/ic_reject.svg',
                    package: 'contactkit_ui',
                    height: 16,
                    width: 16,
                  ),
                Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Text(
                    getStatueText(),
                    style: TextStyle(fontSize: 14, color: '#B3B7BC'.toColor()),
                  ),
                )
              ],
            )
        ],
      ),
    );
  }

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onLoading(BuildContext context) {
    if (context.read<SystemNotifyViewModel>().haveMore) {
      offset = offset + 50;

      context
          .read<SystemNotifyViewModel>()
          .querySystemMessage(offset: offset)
          .then((value) {
        _refreshController.loadComplete();
      });
    } else {
      _refreshController.loadComplete();
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    ContactRepo.clearNotificationUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (context) {
      var viewModel = SystemNotifyViewModel();
      viewModel.init();
      return viewModel;
    }, builder: (context, child) {
      List<SystemMessage> messages =
          context.watch<SystemNotifyViewModel>().systemMessages;
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
            S.of(context).contact_verify_message,
            style: TextStyle(fontSize: 16, color: '#333333'.toColor()),
          ),
          centerTitle: true,
          elevation: 0.5,
          shadowColor: '#F5F8FC'.toColor(),
          actions: [
            InkWell(
              onTap: () {
                context.read<SystemNotifyViewModel>().cleanMessage();
              },
              child: Container(
                padding: EdgeInsets.only(right: 20),
                alignment: Alignment.center,
                child: Text(
                  S.of(context).contact_clean,
                  style: TextStyle(fontSize: 14, color: '#666666'.toColor()),
                ),
              ),
            )
          ],
        ),
        body: SmartRefresher(
          controller: _refreshController,
          enablePullDown: false,
          enablePullUp: true,
          onLoading: () {
            _onLoading(context);
          },
          child: ListView.separated(
              itemBuilder: (context, index) {
                return _buildItem(context, messages[index]);
              },
              separatorBuilder: (BuildContext context, int index) => Divider(
                    height: 1,
                    color: '#F5F8FC'.toColor(),
                  ),
              itemCount: messages.length),
        ),
      );
    });
  }
}
