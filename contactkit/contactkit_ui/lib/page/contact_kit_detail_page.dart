// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:im_common_ui/router/imkit_router_factory.dart';
import 'package:im_common_ui/ui/avatar.dart';
import 'package:im_common_ui/ui/dialog.dart';
import 'package:im_common_ui/utils/color_utils.dart';
import 'package:im_common_ui/widgets/update_text_info_page.dart';
import 'package:contactkit/repo/contact_repo.dart';
import 'package:corekit_im/model/contact_info.dart';
import 'package:corekit_im/service_locator.dart';
import 'package:corekit_im/services/contact/contact_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nim_core/nim_core.dart';
import 'package:flutter_svg/svg.dart';

import '../generated/l10n.dart';

class ContactKitDetailPage extends StatefulWidget {
  final String accId;

  const ContactKitDetailPage({Key? key, required this.accId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ContactKitDetailPageState();
}

class _ContactKitDetailPageState extends State<ContactKitDetailPage> {
  bool isBlackList = false;

  bool isFriend = false;

  Iterable<Widget> _buildUserInfo(ContactInfo contact) {
    return ListTile.divideTiles(
        context: context,
        tiles: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Text(S.of(context).contact_birthday),
            trailing: Text(
              contact.user.birth ?? '',
              style: TextStyle(fontSize: 12, color: '#A6ADB6'.toColor()),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Text(S.of(context).contact_phone),
            trailing: Text(
              contact.user.mobile ?? '',
              style: TextStyle(fontSize: 12, color: '#A6ADB6'.toColor()),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Text(S.of(context).contact_mail),
            trailing: Text(
              contact.user.email ?? '',
              style: TextStyle(fontSize: 12, color: '#A6ADB6'.toColor()),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Text(
              S.of(context).contact_signature,
              maxLines: 1,
            ),
            trailing: Container(
              width: 200,
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
            title: Text(S.of(context).contact_add_to_blacklist),
            trailing: CupertinoSwitch(
              activeColor: CommonColors.color_337eff,
              onChanged: (bool value) {
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
            name: contact.getName(),
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
                contact.friend?.alias?.isNotEmpty == true
                    ? S.of(context).contact_nick(contact.user.nick!)
                    : S.of(context).contact_account(contact.user.userId!),
                style: TextStyle(fontSize: 12, color: '#666666'.toColor())),
            if (contact.friend?.alias?.isNotEmpty == true)
              Text(S.of(context).contact_account(contact.user.userId!),
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
                S.of(context).contact_delete_specific_friend(contact.getName()),
            positiveContent: S.of(context).contact_delete)
        .then((value) {
      if (value ?? false) {
        ContactRepo.deleteFriend(contact.user.userId!).then((value) {
          Navigator.pop(context);
          if (!value.isSuccess) {
            Fluttertoast.showToast(msg: value.errorDetails ?? '');
          }
        });
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
  }

  @override
  Widget build(BuildContext context) {
    Widget arrow = SvgPicture.asset(
      'images/ic_right_arrow.svg',
      package: 'contactkit_ui',
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
        future: getIt<ContactProvider>().getContact(widget.accId),
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
                      title: Text(S.of(context).contact_comment),
                      trailing: arrow,
                      onTap: () {
                        // go allis set
                        Future<bool> _saveAlias(String alias) {
                          return ContactRepo.updateAlias(widget.accId, alias)
                              .then((value) => value.isSuccess);
                        }

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => UpdateTextInfoPage(
                                      title: S.of(context).contact_comment,
                                      content: contact.friend?.alias,
                                      maxLength: 30,
                                      privilege: true,
                                      onSave: _saveAlias,
                                      leading:
                                          Icon(Icons.arrow_back_ios_rounded),
                                      sureStr: S.of(context).contact_save,
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
                      child: Text(S.of(context).contact_chat,
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
                        child: Text(S.of(context).contact_delete,
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
                        ContactRepo.addFriend(contact.user.userId!,
                                NIMVerifyType.verifyRequest)
                            .then((value) {
                          if (value.isSuccess) {
                            Navigator.pop(context);
                            Fluttertoast.showToast(
                                msg: S.of(context).contact_have_send_apply);
                          } else {
                            Fluttertoast.showToast(
                                msg: value.errorDetails ?? '');
                          }
                        });
                      },
                      child: Text(S.of(context).contact_add_friend,
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
