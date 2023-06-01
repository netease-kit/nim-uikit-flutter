// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common_ui/extension.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:nim_contactkit/repo/contact_repo.dart';
import 'package:nim_contactkit_ui/widgets/contact_kit_contact_list_view.dart';
import 'package:netease_corekit_im/model/contact_info.dart';
import 'package:flutter/material.dart';

import '../contact_kit_client.dart';
import '../l10n/S.dart';

class ContactKitSelectorPage extends StatefulWidget {
  final int? mostSelectedCount;

  final bool? returnContact;

  final List<String>? filterUsers;

  final includeBlackList;

  final bool includeSelf;

  ContactKitSelectorPage(
      {Key? key,
      this.mostSelectedCount,
      this.filterUsers,
      this.returnContact,
      this.includeBlackList = false,
      this.includeSelf = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ContactSelectorState();
}

class _ContactSelectorState extends State<ContactKitSelectorPage> {
  List<ContactInfo> selectedUser = List.empty(growable: true);

  List<ContactInfo> contacts = [];

  _fetchContact() {
    ContactRepo.getContactList(userCache: true).then((value) {
      setState(() {
        value.removeWhere((e) {
          var result = false;
          if (widget.filterUsers != null) {
            result = result || widget.filterUsers!.contains(e.user.userId);
          }
          if (!widget.includeBlackList) {
            result = result || e.isInBlack == true;
          }
          if (!widget.includeSelf) {
            result = result ||
                e.user.userId == getIt<LoginService>().userInfo?.userId;
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
          S.of(context).contactUserSelector,
          style: TextStyle(fontSize: 16, color: '#333333'.toColor()),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          InkWell(
            onTap: () async {
              if (selectedUser.isEmpty) {
                Fluttertoast.showToast(
                    msg: S.of(context).contactSelectEmptyTip);
                return;
              }
              if (!(await Connectivity().checkNetwork(context))) {
                return;
              }
              Navigator.pop(
                  context,
                  widget.returnContact == true
                      ? selectedUser
                      : selectedUser.map((e) => e.user.userId!).toList());
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
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (selectedUser.isNotEmpty)
            Expanded(
              flex: 1,
              child: ListView.builder(
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
                          height: 42,
                          width: 42,
                          avatar: member.user.avatar,
                          name: member.getName(),
                          bgCode: AvatarColor.avatarColor(
                              content: member.user.userId!),
                        ),
                      ),
                    );
                  }),
            ),
          contacts.isNotEmpty
              ? Expanded(
                  flex: 10,
                  child: ContactListView(
                      contactList: contacts,
                      maxSelectNum: widget.mostSelectedCount,
                      onSelectedMemberItemChange: _onSelectedItemChange,
                      selectedUser: selectedUser,
                      isCanSelectMemberItem: true))
              : Expanded(
                  flex: 10,
                  child: Column(
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
                        style:
                            TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
                      ),
                      Expanded(
                        child: Container(),
                        flex: 1,
                      ),
                    ],
                  )),
        ],
      ),
    );
  }
}
