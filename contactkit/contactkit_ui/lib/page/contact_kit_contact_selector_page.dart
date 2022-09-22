// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:im_common_ui/extension.dart';
import 'package:im_common_ui/ui/avatar.dart';
import 'package:im_common_ui/utils/color_utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:contactkit/repo/contact_repo.dart';
import 'package:contactkit_ui/widgets/contact_kit_contact_list_view.dart';
import 'package:corekit_im/model/contact_info.dart';
import 'package:flutter/material.dart';

import '../generated/l10n.dart';

class ContactKitSelectorPage extends StatefulWidget {
  final int? mostSelectedCount;

  final bool? returnContact;

  final List<String>? filterUsers;

  ContactKitSelectorPage(
      {Key? key, this.mostSelectedCount, this.filterUsers, this.returnContact})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ContactSelectorState();
}

class _ContactSelectorState extends State<ContactKitSelectorPage> {
  List<ContactInfo> selectedUser = List.empty(growable: true);

  List<ContactInfo> contacts = [];

  _fetchContact() {
    ContactRepo.getContactList().then((value) {
      setState(() {
        if (widget.filterUsers != null) {
          value.removeWhere((e) => widget.filterUsers!.contains(e.user.userId));
        }
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
          S.of(context).contact_user_selector,
          style: TextStyle(fontSize: 16, color: '#333333'.toColor()),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          InkWell(
            onTap: () async {
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
                S.of(context).contact_sure_with_count('${selectedUser.length}'),
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
          if (contacts.isNotEmpty)
            Expanded(
                flex: 10,
                child: ContactListView(
                    contactList: contacts,
                    maxSelectNum: widget.mostSelectedCount,
                    onSelectedMemberItemChange: _onSelectedItemChange,
                    selectedUser: selectedUser,
                    isCanSelectMemberItem: true))
        ],
      ),
    );
  }
}
