// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/model/system_notify_info.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import 'package:nim_contactkit_ui/contact_kit_client.dart';
import 'package:nim_contactkit_ui/page/viewmodel/friend_add_application_viewmodel.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../l10n/S.dart';

class ContactKitSystemNotifyMessagePage extends StatefulWidget {
  const ContactKitSystemNotifyMessagePage({Key? key, this.listConfig})
      : super(key: key);

  final ContactListConfig? listConfig;

  @override
  State<StatefulWidget> createState() => _SystemNotifyPageState();
}

class _SystemNotifyPageState
    extends BaseState<ContactKitSystemNotifyMessagePage> {
  int offset = 0;

  Widget _buildItem(
      BuildContext context, ValidationMessageMerged messageMerged) {
    var message = messageMerged.lastMsg;
    var count = messageMerged.messageUnreadCount();
    bool unread = messageMerged.unread;
    String getHeadMessageText(String userName) {
      if (message.applicantAccountId == IMKitClient.account()) {
        if (message.status ==
            NIMFriendAddApplicationStatus.nimFriendAddApplicationStatusAgreed) {
          return S.of(context).contactSomeAcceptYourApply(userName);
        }

        if (message.status ==
            NIMFriendAddApplicationStatus
                .nimFriendAddApplicationStatusRejected) {
          return S.of(context).contactSomeRejectYourApply(userName);
        }
      }
      return S.of(context).contactApplyFrom(userName);
    }

    String getStatueText() {
      switch (message.status) {
        case NIMFriendAddApplicationStatus.nimFriendAddApplicationStatusAgreed:
          return message.operatorAccountId == IMKitClient.account()
              ? S.of(context).contactAccepted
              : '';
        case NIMFriendAddApplicationStatus
              .nimFriendAddApplicationStatusRejected:
          return message.operatorAccountId == IMKitClient.account()
              ? S.of(context).contactRejected
              : '';
        case NIMFriendAddApplicationStatus.nimFriendAddApplicationStatusExpired:
          return S.of(context).contactExpired;
        default:
          return '';
      }
    }

    Widget _getAvatar(NIMUserInfo? user) {
      String? avatar = user?.avatar;
      String? name = user?.name?.isNotEmpty == true
          ? user?.name
          : message.applicantAccountId;
      ;
      String? avatarColorContent = message.applicantAccountId;

      return Avatar(
        width: 36,
        height: 36,
        avatar: avatar,
        name: name,
        bgCode: AvatarColor.avatarColor(content: avatarColorContent),
        radius: widget.listConfig?.avatarCornerRadius,
      );
    }

    var nameTextStyle = TextStyle(
        fontSize: widget.listConfig?.nameTextSize ?? 14,
        color: widget.listConfig?.nameTextColor ?? CommonColors.color_333333);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: unread ? BoxDecoration(color: '#ededef'.toColor()) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: FutureBuilder<NotifyExtension>(
                future: message.getNotifyExt(),
                builder: (context, snapShot) {
                  if (snapShot.data != null) {
                    messageMerged.user = snapShot.data?.fromUser;
                  }
                  var user = messageMerged.user;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          _getAvatar(user),
                          if (count > 1 && unread)
                            Container(
                              padding: EdgeInsets.all(4),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                count > 99 ? '99+' : count.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 10, color: Colors.white),
                              ),
                            )
                        ],
                      ),
                      Expanded(
                          child: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name?.isNotEmpty == true
                                  ? user!.name!
                                  : message.applicantAccountId!,
                              style: nameTextStyle,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              getHeadMessageText(''),
                              style: nameTextStyle,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            )
                          ],
                        ),
                      )),
                    ],
                  );
                }),
          ),
          if (message.status ==
              NIMFriendAddApplicationStatus.nimFriendAddApplicationStatusInit)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    context
                        .read<ValidationMessageViewModel>()
                        .reject(messageMerged, context);
                  },
                  child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: '#D9D9D9'.toColor(), width: 1),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4))),
                      child: Text(S.of(context).contactReject,
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
                    context
                        .read<ValidationMessageViewModel>()
                        .agree(messageMerged, context);
                  },
                  child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: '#337EFF'.toColor(), width: 1),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4))),
                      child: Text(S.of(context).contactAccept,
                          style: TextStyle(
                            fontSize: 14,
                            color: '#337EFF'.toColor(),
                          ))),
                ),
              ],
            ),
          if (message.operatorAccountId == IMKitClient.account() &&
              (message.status ==
                      NIMFriendAddApplicationStatus
                          .nimFriendAddApplicationStatusRejected ||
                  message.status ==
                      NIMFriendAddApplicationStatus
                          .nimFriendAddApplicationStatusAgreed))
            Row(
              children: [
                if (message.status ==
                    NIMFriendAddApplicationStatus
                        .nimFriendAddApplicationStatusAgreed)
                  SvgPicture.asset(
                    'images/ic_agree.svg',
                    package: kPackage,
                    height: 16,
                    width: 16,
                  ),
                if (message.status ==
                    NIMFriendAddApplicationStatus
                        .nimFriendAddApplicationStatusRejected)
                  SvgPicture.asset(
                    'images/ic_reject.svg',
                    package: kPackage,
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

  @override
  void onAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      //退后台清除未读数
      ContactRepo.setAddApplicationRead();
    }
    super.onAppLifecycleState(state);
  }

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onLoading(BuildContext context) {
    if (context.read<ValidationMessageViewModel>().haveMore) {
      offset = offset + 100;

      context
          .read<ValidationMessageViewModel>()
          .queryNIMFriendAddApplication(offset: offset)
          .then((value) {
        if (value) {
          _refreshController.loadComplete();
        } else {
          _onLoading(context);
        }
      });
    } else {
      _refreshController.loadComplete();
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    //清理未读数
    ContactRepo.setAddApplicationRead();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (context) {
      var viewModel = ValidationMessageViewModel();
      viewModel.init();
      return viewModel;
    }, builder: (context, child) {
      List<ValidationMessageMerged> messages =
          context.watch<ValidationMessageViewModel>().NIMFriendAddApplications;
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
            S.of(context).contactVerifyMessage,
            style: TextStyle(fontSize: 16, color: '#333333'.toColor()),
          ),
          centerTitle: true,
          elevation: 0.5,
          shadowColor: '#F5F8FC'.toColor(),
          actions: [
            InkWell(
              onTap: () {
                context.read<ValidationMessageViewModel>().cleanMessage();
              },
              child: Container(
                padding: EdgeInsets.only(right: 20),
                alignment: Alignment.center,
                child: Text(
                  S.of(context).contactClean,
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
          child: messages.isNotEmpty
              ? ListView.separated(
                  itemBuilder: (context, index) {
                    return _buildItem(context, messages[index]);
                  },
                  separatorBuilder: (BuildContext context, int index) =>
                      Divider(
                        height: 1,
                        color: '#F5F8FC'.toColor(),
                      ),
                  itemCount: messages.length)
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
                        S.of(context).systemVerifyMessageEmpty,
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
        ),
      );
    });
  }
}
