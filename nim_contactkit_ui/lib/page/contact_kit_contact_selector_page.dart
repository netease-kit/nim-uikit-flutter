// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_common_ui/widgets/keepalive_wrapper.dart';
import 'package:netease_common_ui/widgets/radio_button.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import 'package:nim_contactkit_ui/widgets/contact_kit_contact_list_view.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../contact_kit_client.dart';
import '../l10n/S.dart';

class ContactKitSelectorPage extends StatefulWidget {
  final int? mostSelectedCount;

  final bool? returnContact;

  final List<String>? filterUsers;

  final includeBlackList;

  final bool includeSelf;

  final bool includeAIUser;

  ContactKitSelectorPage(
      {Key? key,
      this.mostSelectedCount,
      this.filterUsers,
      this.returnContact,
      this.includeBlackList = false,
      this.includeAIUser = false,
      this.includeSelf = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ContactSelectorState();
}

class _ContactSelectorState extends State<ContactKitSelectorPage>
    with TickerProviderStateMixin {
  List<ContactInfo> selectedUser = List.empty(growable: true);

  List<ContactInfo> contacts = [];

  TabController? _tabController;

  bool showAIPage = true;

  _fetchContact() {
    ContactRepo.getContactList(userCache: true).then((value) {
      setState(() {
        value.removeWhere((e) {
          var result = false;
          if (widget.filterUsers != null) {
            result = result || widget.filterUsers!.contains(e.user.accountId);
          }
          if (!widget.includeBlackList) {
            result = result || e.isInBlack == true;
          }
          if (!widget.includeSelf) {
            result = result || e.user.accountId == IMKitClient.account();
          }
          return result;
        });
        contacts = value;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchContact();
    showAIPage = widget.includeAIUser && IMKitClient.enableAi;
    if (showAIPage) {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  _addSelectedUser(ContactInfo contact) {
    setState(() {
      selectedUser.add(contact);
    });
  }

  _removeSelectedUser(ContactInfo contact) {
    setState(() {
      selectedUser.remove(contact);
    });
  }

  _onSelectedItemChange(bool isSelected, ContactInfo selectedMember) {
    if (isSelected) {
      _addSelectedUser(selectedMember);
    } else {
      _removeSelectedUser(selectedMember);
    }
  }

  bool _isSelectable(String accountId) {
    if (widget.mostSelectedCount != null &&
        selectedUser.length >= widget.mostSelectedCount!) {
      Fluttertoast.showToast(msg: S.of(context).contactSelectAsMost);
      return false;
    }
    return true;
  }

  ///获取联系人列表
  Widget getContactListView() {
    return contacts.isNotEmpty
        ? ContactListView(
            contactList: contacts,
            onSelectedMemberItemChange: _onSelectedItemChange,
            selectedUser: selectedUser,
            isSelectable: _isSelectable,
            isCanSelectMemberItem: true)
        : Column(
            children: [
              SizedBox(
                height: 170,
              ),
              SvgPicture.asset(
                'images/ic_search_empty.svg',
                package: kPackage,
              ),
              const SizedBox(
                height: 18,
              ),
              Text(
                S.of(context).contactFriendEmpty,
                style: TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
              ),
              Expanded(
                child: Container(),
                flex: 1,
              ),
            ],
          );
  }

  ///获取数字人列表
  Widget getAIUserList() {
    final List<NIMAIUser> aiUsers = AIUserManager.instance.getAllAIUsers();
    aiUsers
        .removeWhere((e) => widget.filterUsers?.contains(e.accountId) == true);
    return aiUsers.isNotEmpty
        ? ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: aiUsers.length,
            padding: EdgeInsets.only(left: 20),
            itemBuilder: (contact, index) {
              NIMAIUser aiUser = aiUsers[index];
              final contactInfo = ContactInfo(aiUser);
              return InkWell(
                onTap: () {
                  final isChecked = selectedUser.contains(contactInfo) != true;
                  if (_isSelectable(aiUser.accountId!)) {
                    _onSelectedItemChange(isChecked, contactInfo);
                    setState(() {});
                  }
                },
                child: Container(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        // 选择框
                        child: CheckBoxButton(
                          isChecked: selectedUser.contains(contactInfo) == true,
                          clickable: false,
                        ),
                      ),
                      Avatar(
                        avatar: aiUser.avatar,
                        name: aiUser.name ?? aiUser.accountId,
                        width: 42,
                        height: 42,
                        bgCode:
                            AvatarColor.avatarColor(content: aiUser.accountId),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 12),
                        width: MediaQuery.of(context).size.width - 100,
                        child: Text(
                          aiUser.name ?? aiUser.accountId!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 16, color: CommonColors.color_333333),
                        ),
                      )
                    ],
                  ),
                ),
              );
            })
        : Column(
            children: [
              SizedBox(
                height: 170,
              ),
              SvgPicture.asset(
                'images/ic_search_empty.svg',
                package: kPackage,
              ),
              const SizedBox(
                height: 18,
              ),
              Text(
                S.of(context).aiUsersEmpty,
                style: TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
              ),
              Expanded(
                child: Container(),
                flex: 1,
              ),
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
      backgroundColor: Colors.white,
      title: S.of(context).contactUserSelector,
      centerTitle: true,
      elevation: 0,
      actions: [
        InkWell(
          onTap: () async {
            if (selectedUser.isEmpty) {
              Fluttertoast.showToast(msg: S.of(context).contactSelectEmptyTip);
              return;
            }
            if (!(await haveConnectivity())) {
              return;
            }
            Navigator.pop(
                context,
                widget.returnContact == true
                    ? selectedUser
                    : selectedUser.map((e) => e.user.accountId!).toList());
          },
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.only(right: 20),
            child: Text(
              S.of(context).contactSureWithCount('${selectedUser.length}'),
              style: TextStyle(fontSize: 16, color: '#337EFF'.toColor()),
            ),
          ),
        )
      ],
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            flex: selectedUser.isEmpty ? 0 : 1,
            child: selectedUser.isEmpty
                ? Container()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedUser.length,
                    padding: EdgeInsets.only(left: 20),
                    itemBuilder: (contact, index) {
                      ContactInfo member = selectedUser[index];
                      return InkWell(
                        onTap: () {
                          _removeSelectedUser(member);
                        },
                        child: Container(
                          padding: EdgeInsets.only(
                              top: 7, bottom: 9, left: 6, right: 5),
                          child: Avatar(
                            height: 36,
                            width: 36,
                            avatar: member.user.avatar,
                            name: member.getName(),
                            bgCode: AvatarColor.avatarColor(
                                content: member.user.accountId!),
                          ),
                        ),
                      );
                    }),
          ),
          if (showAIPage)
            Expanded(
              flex: 1,
              child: TabBar(
                controller: _tabController,
                unselectedLabelColor: '#333333'.toColor(),
                labelColor: '#337EFF'.toColor(),
                tabs: [
                  Text(
                    S.of(context).myFriend,
                  ),
                  Text(
                    S.of(context).aiUsers,
                  )
                ],
              ),
            ),
          Expanded(
              flex: 10,
              child: showAIPage
                  ? TabBarView(controller: _tabController, children: [
                      KeepAliveWrapper(child: getContactListView()),
                      KeepAliveWrapper(child: getAIUserList()),
                    ])
                  : getContactListView()),
        ],
      ),
    );
  }
}
