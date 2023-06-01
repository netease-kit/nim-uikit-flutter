// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_corekit_im/router/imkit_router_factory.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/update_text_info_page.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:nim_contactkit/repo/contact_repo.dart';
import 'package:netease_corekit_im/model/contact_info.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/contact/contact_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nim_core/nim_core.dart';
import 'package:flutter_svg/svg.dart';

import '../contact_kit_client.dart';
import '../l10n/S.dart';

class ContactKitDetailPage extends StatefulWidget {
  final String accId;

  const ContactKitDetailPage({Key? key, required this.accId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ContactKitDetailPageState();
}

class _ContactKitDetailPageState extends State<ContactKitDetailPage> {
  bool isBlackList = false;

  bool isFriend = false;

  var subs = <StreamSubscription>[];

  Iterable<Widget> _buildUserInfo(ContactInfo contact) {
    return ListTile.divideTiles(
        context: context,
        tiles: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Text(S.of(context).contactBirthday),
            trailing: Text(
              contact.user.birth ?? '',
              style: TextStyle(fontSize: 12, color: '#A6ADB6'.toColor()),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Text(S.of(context).contactPhone),
            trailing: Text(
              contact.user.mobile ?? '',
              style: TextStyle(fontSize: 12, color: '#A6ADB6'.toColor()),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Text(S.of(context).contactMail),
            trailing: Container(
              constraints: BoxConstraints(maxWidth: 250),
              child: Text(
                contact.user.email ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: '#A6ADB6'.toColor()),
              ),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Text(
              S.of(context).contactSignature,
              maxLines: 1,
            ),
            trailing: Container(
              constraints: BoxConstraints(maxWidth: 250),
              child: Text(
                contact.user.sign ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: '#A6ADB6'.toColor()),
              ),
            ),
          ),
        ].toList());
  }

  Iterable<Widget> _buildSetting(ContactInfo contact) {
    return ListTile.divideTiles(
        context: context,
        tiles: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Text(S.of(context).contactAddToBlacklist),
            trailing: CupertinoSwitch(
              activeColor: CommonColors.color_337eff,
              onChanged: (bool value) async {
                if (!await haveConnectivity()) {
                  return;
                }
                // 加入黑名单开关
                if (value) {
                  ContactRepo.addBlacklist(contact.user.userId!).then((result) {
                    if (result.isSuccess) {
                      setState(() {
                        isBlackList = value;
                      });
                    }
                  });
                } else {
                  ContactRepo.removeBlacklist(contact.user.userId!)
                      .then((result) {
                    if (result.isSuccess) {
                      setState(() {
                        isBlackList = value;
                      });
                    }
                  });
                }
              },
              value: isBlackList,
            ),
          ),
        ].toList());
  }

  Widget _buildHead(ContactInfo contact) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.only(right: 10, bottom: 10),
          child: Avatar(
            height: 65,
            width: 65,
            fontSize: 22,
            avatar: contact.user.avatar,
            name: contact.getName(needAlias: false),
            bgCode: AvatarColor.avatarColor(content: contact.user.userId),
          ),
        ),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Text(
                contact.getName(),
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                    fontSize: 22,
                    color: '#333333'.toColor(),
                    fontWeight: FontWeight.bold),
              ),
            ),
            Text(
                contact.friend?.alias?.isNotEmpty == true &&
                        contact.user.nick?.isNotEmpty == true
                    ? S.of(context).contactNick(contact.user.nick!)
                    : S.of(context).contactAccount(contact.user.userId!),
                style: TextStyle(fontSize: 12, color: '#666666'.toColor())),
            if (contact.friend?.alias?.isNotEmpty == true &&
                contact.user.nick?.isNotEmpty == true)
              Text(S.of(context).contactAccount(contact.user.userId!),
                  style: TextStyle(fontSize: 12, color: '#666666'.toColor()))
          ],
        ))
      ],
    );
  }

  void _deleteFriendConfirm(ContactInfo contact) {
    showCommonDialog(
            context: context,
            content:
                S.of(context).contactDeleteSpecificFriend(contact.getName()),
            positiveContent: S.of(context).contactDelete)
        .then((value) async {
      if ((value ?? false) && await haveConnectivity()) {
        ContactRepo.deleteFriend(contact.user.userId!).then((value) {
          Navigator.pop(context);
          if (!value.isSuccess) {
            Fluttertoast.showToast(msg: value.errorDetails ?? '');
          }
        });
      }
    });
  }

  void _addFriend(BuildContext context, String userId) async {
    if (!await haveConnectivity()) {
      return;
    }

    if (getIt<LoginService>().userInfo?.userId == userId) {}
    //先判断是否在黑名单,如果在黑名单则将其从黑名单移除
    var isInBlackList = (await ContactRepo.isBlackList(userId)).data;
    if (isInBlackList == true) {
      await ContactRepo.removeBlacklist(userId);
    }
    ContactRepo.addFriend(userId, NIMVerifyType.verifyRequest).then((value) {
      if (value.isSuccess) {
        Navigator.pop(context);
        Fluttertoast.showToast(msg: S.of(context).contactHaveSendApply);
      } else {
        Fluttertoast.showToast(msg: value.errorDetails ?? '');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    ContactRepo.isBlackList(widget.accId).then((value) {
      if (value.isSuccess) {
        setState(() {
          isBlackList = value.data!;
        });
      }
    });

    ContactRepo.isFriend(widget.accId).then((value) {
      setState(() {
        isFriend = value;
      });
    });

    subs.add(ContactRepo.registerFriendObserver().listen((event) {
      for (var e in event) {
        if (e.userId == widget.accId) {
          setState(() {
            isFriend = true;
          });
        }
      }
    }));

    subs.add(ContactRepo.registerFriendDeleteObserver().listen((event) {
      for (var userId in event) {
        if (userId == widget.accId) {
          setState(() {
            isFriend = false;
          });
        }
      }
    }));
  }

  @override
  void dispose() {
    super.dispose();
    for (var sub in subs) {
      sub.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget arrow = SvgPicture.asset(
      'images/ic_right_arrow.svg',
      package: kPackage,
      height: 16,
      width: 16,
    );

    var divider = const Divider(
      height: 6,
      thickness: 6,
      color: Color(0xffeff1f4),
    );

    var dividerSmall = const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xffF5F8FC),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
      ),
      body: FutureBuilder<ContactInfo?>(
        future: getIt<ContactProvider>()
            .getContact(widget.accId, needRefresh: true),
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return Container();
          } else {
            final contact = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 20, bottom: 8, top: 10),
                    child: _buildHead(contact),
                  ),
                  if (isFriend) ...[
                    dividerSmall,
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      title: Text(S.of(context).contactComment),
                      trailing: arrow,
                      onTap: () {
                        // go allis set
                        Future<bool> _saveAlias(String alias) {
                          return ContactRepo.updateAlias(
                                  widget.accId, alias.trim())
                              .then((value) => value.isSuccess);
                        }

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => UpdateTextInfoPage(
                                      title: S.of(context).contactComment,
                                      content: contact.friend?.alias,
                                      maxLength: 15,
                                      privilege: true,
                                      onSave: _saveAlias,
                                      leading:
                                          Icon(Icons.arrow_back_ios_rounded),
                                      sureStr: S.of(context).contactSave,
                                    ))).then((value) {
                          setState(() {});
                        });
                      },
                    ),
                    divider,
                    ..._buildUserInfo(contact),
                    divider,
                    ..._buildSetting(contact),
                    divider,
                    TextButton(
                      onPressed: () {
                        goToP2pChat(context, contact.user.userId!);
                      },
                      child: Text(S.of(context).contactChat,
                          style: TextStyle(
                              fontSize: 16,
                              color: '#337EFF'.toColor(),
                              fontWeight: FontWeight.bold)),
                    ),
                    dividerSmall,
                    TextButton(
                        onPressed: () {
                          _deleteFriendConfirm(contact);
                        },
                        child: Text(S.of(context).contactDelete,
                            style: TextStyle(
                                fontSize: 16,
                                color: '#E6605C'.toColor(),
                                fontWeight: FontWeight.bold)))
                  ],
                  if (!isFriend) ...[
                    divider,
                    TextButton(
                      onPressed: () {
                        // 添加好友
                        _addFriend(context, contact.user.userId!);
                      },
                      child: Text(S.of(context).contactAddFriend,
                          style: TextStyle(
                              fontSize: 16, color: '#337EFF'.toColor())),
                    ),
                    dividerSmall,
                  ],
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
