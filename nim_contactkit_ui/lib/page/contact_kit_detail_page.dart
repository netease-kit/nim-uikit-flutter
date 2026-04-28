// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:netease_common_ui/widgets/update_text_info_page.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/contact/contact_provider.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../contact_kit_client.dart';
import '../l10n/S.dart';

class ContactKitDetailPage extends StatefulWidget {
  final String accId;

  /// 桌面端 Dialog 模式：隐藏 AppBar，使用内嵌布局
  final bool isDesktopDialog;

  const ContactKitDetailPage({
    Key? key,
    required this.accId,
    this.isDesktopDialog = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ContactKitDetailPageState();
}

class _ContactKitDetailPageState extends State<ContactKitDetailPage> {
  bool isBlackList = false;

  bool isFriend = false;

  bool isAIUser = false;

  var subs = <StreamSubscription>[];

  Iterable<Widget> _buildUserInfo(ContactInfo contact) {
    return ListTile.divideTiles(
      context: context,
      tiles: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Text(S.of(context).contactBirthday),
          trailing: Text(
            contact.user.birthday ?? '',
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
          title: Text(S.of(context).contactSignature, maxLines: 1),
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
      ].toList(),
    );
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
                ContactRepo.addBlocklist(contact.user.accountId!).then((
                  result,
                ) {
                  if (result.isSuccess) {
                    setState(() {
                      isBlackList = value;
                    });
                  }
                });
              } else {
                ContactRepo.removeBlocklist(contact.user.accountId!).then((
                  result,
                ) {
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
      ].toList(),
    );
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
            bgCode: AvatarColor.avatarColor(content: contact.user.accountId),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                contact.friend?.alias?.isNotEmpty == true &&
                        contact.user.name?.isNotEmpty == true
                    ? S.of(context).contactNick(contact.user.name!)
                    : S.of(context).contactAccount(contact.user.accountId!),
                style: TextStyle(fontSize: 12, color: '#666666'.toColor()),
              ),
              if (contact.friend?.alias?.isNotEmpty == true &&
                  contact.user.name?.isNotEmpty == true)
                Text(
                  S.of(context).contactAccount(contact.user.accountId!),
                  style: TextStyle(fontSize: 12, color: '#666666'.toColor()),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _deleteFriendConfirm(ContactInfo contact) {
    showCommonDialog(
      context: context,
      content: S.of(context).contactDeleteSpecificFriend(contact.getName()),
      positiveContent: S.of(context).contactDelete,
    ).then((value) async {
      if ((value ?? false) && await haveConnectivity()) {
        ContactRepo.deleteFriend(contact.user.accountId!).then((value) {
          Navigator.pop(context);
          if (!value.isSuccess) {
            ChatUIToast.show(value.errorDetails ?? '');
          }
        });
      }
    });
  }

  void _addFriend(BuildContext context, String userId) async {
    if (!await haveConnectivity()) {
      return;
    }

    if (IMKitClient.account() == userId) {}
    //先判断是否在黑名单,如果在黑名单则将其从黑名单移除
    var isInBlackList = ContactRepo.isBlockList(userId);
    if (isInBlackList == true) {
      await ContactRepo.removeBlocklist(userId);
    }
    ContactRepo.addFriend(userId, NIMFriendAddMode.nimFriendModeTypeApply).then(
      (value) {
        if (value.isSuccess) {
          Navigator.pop(context);
          ChatUIToast.show(S.of(context).contactHaveSendApply);
        } else {
          ChatUIToast.show(value.errorDetails ?? '');
        }
      },
    );
  }

  void _isFriend(String userId) async {
    if (!await haveConnectivity()) {
      final user = getIt<ContactProvider>().getContactInCache(userId);
      if (user != null) {
        setState(() {
          isFriend = user.friend != null;
        });
      }
      return;
    }

    ContactRepo.isFriend(userId).then((value) {
      setState(() {
        isFriend = value;
      });
    });
  }

  Future<ContactInfo?> _getFriend(String userId) async {
    final haveConnect = await haveConnectivity();
    return getIt<ContactProvider>().getContact(
      widget.accId,
      needRefresh: haveConnect,
    );
  }

  @override
  void initState() {
    super.initState();
    isBlackList = ContactRepo.isBlockList(widget.accId);

    _isFriend(widget.accId);

    isAIUser = AIUserManager.instance.isAIUser(widget.accId);

    subs.add(
      ContactRepo.registerFriendAddedObserver().listen((event) {
        if (event.accountId == widget.accId) {
          setState(() {
            isFriend = true;
          });
        }
      }),
    );

    subs.add(
      ContactRepo.registerFriendDeleteObserver().listen((event) {
        if (event.accountId == widget.accId) {
          setState(() {
            isFriend = false;
          });
        }
      }),
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (var sub in subs) {
      sub.cancel();
    }
  }

  /// 是否在桌面端 Dialog 模式下运行
  bool get _isDesktopMode =>
      widget.isDesktopDialog || ChatKitUtils.isDesktopOrWeb;

  Widget _buildBody(BuildContext context) {
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

    return FutureBuilder<ContactInfo?>(
      future: _getFriend(widget.accId),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    title: Text(S.of(context).contactComment),
                    trailing: arrow,
                    onTap: () {
                      Future<bool> _saveAlias(String alias) async {
                        if (await haveConnectivity()) {
                          return ContactRepo.updateAlias(
                            widget.accId,
                            alias.trim(),
                          ).then((value) => value.isSuccess);
                        }
                        return false;
                      }

                      if (_isDesktopMode) {
                        // 桌面端使用 Dialog 编辑别名
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 400,
                                height: 300,
                                child: UpdateTextInfoPage(
                                  title: S.of(context).contactComment,
                                  content: contact.friend?.alias,
                                  maxLength: 15,
                                  maxLines: 1,
                                  privilege: true,
                                  onSave: _saveAlias,
                                  sureStr: S.of(context).contactSave,
                                ),
                              ),
                            ),
                          ),
                        ).then((value) {
                          setState(() {});
                        });
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UpdateTextInfoPage(
                              title: S.of(context).contactComment,
                              content: contact.friend?.alias,
                              maxLength: 15,
                              maxLines: 1,
                              privilege: true,
                              onSave: _saveAlias,
                              sureStr: S.of(context).contactSave,
                            ),
                          ),
                        ).then((value) {
                          setState(() {});
                        });
                      }
                    },
                  ),
                  divider,
                  ..._buildUserInfo(contact),
                  divider,
                  ..._buildSetting(contact),
                  divider,
                  TextButton(
                    onPressed: () {
                      if (_isDesktopMode) {
                        Navigator.of(context).pop();
                      }
                      goToP2pChat(context, contact.user.accountId!);
                    },
                    child: Text(
                      S.of(context).contactChat,
                      style: TextStyle(
                        fontSize: 16,
                        color: '#337EFF'.toColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  dividerSmall,
                  TextButton(
                    onPressed: () {
                      _deleteFriendConfirm(contact);
                    },
                    child: Text(
                      S.of(context).contactDelete,
                      style: TextStyle(
                        fontSize: 16,
                        color: '#E6605C'.toColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (isAIUser) ...[
                  divider,
                  TextButton(
                    onPressed: () {
                      if (_isDesktopMode) {
                        Navigator.of(context).pop();
                      }
                      goToP2pChat(context, contact.user.accountId!);
                    },
                    child: Text(
                      S.of(context).contactChat,
                      style: TextStyle(
                        fontSize: 16,
                        color: '#337EFF'.toColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  dividerSmall,
                ] else if (!isFriend) ...[
                  divider,
                  TextButton(
                    onPressed: () {
                      _addFriend(context, contact.user.accountId!);
                    },
                    child: Text(
                      S.of(context).contactAddFriend,
                      style: TextStyle(
                        fontSize: 16,
                        color: '#337EFF'.toColor(),
                      ),
                    ),
                  ),
                  dividerSmall,
                ],
              ],
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesktopMode) {
      // 桌面端：无 AppBar 包装，直接返回内容
      return Material(
        color: Colors.white,
        child: Column(
          children: [
            // 桌面端顶栏：带关闭按钮
            Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFE8E8E8),
                    width: 0.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    S.of(context).contactTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const Spacer(),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(context)),
          ],
        ),
      );
    }

    // 移动端：使用 TransparentScaffold 包装
    return TransparentScaffold(
      backgroundColor: Colors.white,
      title: '',
      body: _buildBody(context),
    );
  }
}
