// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_common_ui/widgets/keepalive_wrapper.dart';
import 'package:netease_common_ui/widgets/radio_button.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
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

  /// Dialog 模式：隐藏 TransparentScaffold，使用自定义 Dialog 顶栏和底部按钮
  final bool isDialog;

  /// Dialog 模式下的自定义标题
  final String? dialogTitle;

  /// 嵌入模式：只返回主体内容，不包含 Scaffold 或 Dialog 外框
  final bool isEmbed;

  /// 选中成员变化时的回调（用于嵌入模式）
  final ValueChanged<List<ContactInfo>>? onSelectionChanged;

  ContactKitSelectorPage({
    Key? key,
    this.mostSelectedCount,
    this.filterUsers,
    this.returnContact,
    this.includeBlackList = false,
    this.includeAIUser = false,
    this.includeSelf = false,
    this.isDialog = false,
    this.isEmbed = false,
    this.dialogTitle,
    this.onSelectionChanged,
  }) : super(key: key);

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
    widget.onSelectionChanged?.call(List.from(selectedUser));
  }

  _removeSelectedUser(ContactInfo contact) {
    setState(() {
      selectedUser.remove(contact);
    });
    widget.onSelectionChanged?.call(List.from(selectedUser));
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
      ChatUIToast.show(S.of(context).contactSelectAsMost);
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
            isCanSelectMemberItem: true,
          )
        : Column(
            children: [
              SizedBox(height: 170),
              SvgPicture.asset('images/ic_search_empty.svg', package: kPackage),
              const SizedBox(height: 18),
              Text(
                S.of(context).contactFriendEmpty,
                style: TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
              ),
              Expanded(child: Container(), flex: 1),
            ],
          );
  }

  ///获取数字人列表
  Widget getAIUserList() {
    final List<NIMAIUser> aiUsers = AIUserManager.instance.getAllAIUsers();
    aiUsers.removeWhere(
      (e) => widget.filterUsers?.contains(e.accountId) == true,
    );
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
                        bgCode: AvatarColor.avatarColor(
                          content: aiUser.accountId,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            aiUser.name ?? aiUser.accountId!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              color: CommonColors.color_333333,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        : Column(
            children: [
              SizedBox(height: 170),
              SvgPicture.asset('images/ic_search_empty.svg', package: kPackage),
              const SizedBox(height: 18),
              Text(
                S.of(context).aiUsersEmpty,
                style: TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
              ),
              Expanded(child: Container(), flex: 1),
            ],
          );
  }

  /// 构建选中成员的水平列表（移动端使用）
  Widget _buildSelectedUserList() {
    return selectedUser.isEmpty
        ? Container()
        : SizedBox(
            height: 52,
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
                      top: 7,
                      bottom: 9,
                      left: 6,
                      right: 5,
                    ),
                    child: Avatar(
                      height: 36,
                      width: 36,
                      avatar: member.user.avatar,
                      name: member.getName(),
                      bgCode: AvatarColor.avatarColor(
                        content: member.user.accountId!,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
  }

  /// 构建右侧已选成员纵向列表（Dialog 模式使用）
  Widget _buildSelectedMemberPanel() {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE8E8E8), width: 0.5),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              '${S.of(context).contactSelectedMembers}(${selectedUser.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ),
          // 已选列表
          Expanded(
            child: selectedUser.isEmpty
                ? Center(
                    child: Text(
                      S.of(context).contactSelectEmptyTip,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFB3B7BC),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: selectedUser.length,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemBuilder: (context, index) {
                      final member = selectedUser[index];
                      return Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Avatar(
                              height: 28,
                              width: 28,
                              avatar: member.user.avatar,
                              name: member.getName(),
                              fontSize: 12,
                              bgCode: AvatarColor.avatarColor(
                                content: member.user.accountId!,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                member.getName(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => _removeSelectedUser(member),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 构建联系人列表主体（TabBar + TabBarView 或纯列表）
  Widget _buildContactBody() {
    return Column(
      children: [
        if (showAIPage)
          TabBar(
            controller: _tabController,
            unselectedLabelColor: '#333333'.toColor(),
            labelColor: '#337EFF'.toColor(),
            tabs: [
              Text(S.of(context).myFriend),
              Text(S.of(context).aiUsers),
            ],
          ),
        Expanded(
          child: showAIPage
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    KeepAliveWrapper(child: getContactListView()),
                    KeepAliveWrapper(child: getAIUserList()),
                  ],
                )
              : getContactListView(),
        ),
      ],
    );
  }

  /// Dialog 模式下确认操作
  void _onDialogConfirm() async {
    if (selectedUser.isEmpty) {
      ChatUIToast.show(S.of(context).contactSelectEmptyTip);
      return;
    }
    if (!(await haveConnectivity())) {
      return;
    }
    Navigator.pop(
      context,
      widget.returnContact == true
          ? selectedUser
          : selectedUser.map((e) => e.user.accountId!).toList(),
    );
  }

  /// 构建 Dialog 模式的布局（左右分栏：左侧联系人列表，右侧已选成员）
  Widget _buildDialogLayout() {
    final title = widget.dialogTitle ?? S.of(context).contactUserSelector;
    return SizedBox(
      width: 600,
      height: 510,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // 顶栏：标题 + 关闭按钮
            Container(
              height: 48,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE8E8E8), width: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    title,
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
                      onTap: () => Navigator.pop(context, null),
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
            // 主体：左侧联系人列表 + 分割线 + 右侧已选成员
            Expanded(
              child: Row(
                children: [
                  // 左侧：联系人列表
                  Expanded(child: _buildContactBody()),
                  // 垂直分割线
                  Container(
                    width: 0.5,
                    color: const Color(0xFFE8E8E8),
                  ),
                  // 右侧：已选成员面板
                  _buildSelectedMemberPanel(),
                ],
              ),
            ),
            // 底部操作栏
            Container(
              height: 56,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE8E8E8), width: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: Text(
                      S.of(context).contactCancel,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _onDialogConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF337EFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      S.of(context).contactSureWithCount(
                            '${selectedUser.length}',
                          ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbed) {
      return Row(
        children: [
          // 左侧：联系人列表
          Expanded(child: _buildContactBody()),
          // 垂直分割线
          Container(
            width: 0.5,
            color: const Color(0xFFE8E8E8),
          ),
          // 右侧：已选成员面板
          _buildSelectedMemberPanel(),
        ],
      );
    }

    if (widget.isDialog) {
      return _buildDialogLayout();
    }

    return TransparentScaffold(
      backgroundColor: Colors.white,
      title: S.of(context).contactUserSelector,
      centerTitle: true,
      elevation: 0,
      actions: [
        InkWell(
          onTap: () async {
            if (selectedUser.isEmpty) {
              ChatUIToast.show(S.of(context).contactSelectEmptyTip);
              return;
            }
            if (!(await haveConnectivity())) {
              return;
            }
            Navigator.pop(
              context,
              widget.returnContact == true
                  ? selectedUser
                  : selectedUser.map((e) => e.user.accountId!).toList(),
            );
          },
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.only(right: 20),
            child: Text(
              S.of(context).contactSureWithCount('${selectedUser.length}'),
              style: TextStyle(fontSize: 16, color: '#337EFF'.toColor()),
            ),
          ),
        ),
      ],
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildSelectedUserList(),
          Expanded(child: _buildContactBody()),
        ],
      ),
    );
  }
}
