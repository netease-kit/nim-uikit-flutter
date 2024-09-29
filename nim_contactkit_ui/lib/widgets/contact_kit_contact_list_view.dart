// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:azlistview_plus/azlistview_plus.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/radio_button.dart';
import 'package:nim_contactkit_ui/widgets/az_lsit_view_container.dart';
import 'package:netease_corekit_im/model/contact_info.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:flutter_svg/svg.dart';

import '../contact_kit_client.dart';
import '../l10n/S.dart';
import '../page/contact_kit_detail_page.dart';

class ContactListView extends StatefulWidget {
  final List<ContactInfo> contactList;
  final bool isCanSelectMemberItem;

  /// 通讯录及好友选择界面都使用了该组件，这里config不再读取全局配置，
  /// 自定义配置请以入参形式传入。
  final ContactUIConfig? config;

  final List<ContactInfo>? selectedUser;

  /// 选择回调
  final ContactItemSelect? onSelectedMemberItemChange;

  /// 顶部列表
  final List<TopListItem>? topList;

  /// 顶部列表项构造器
  final TopListItemBuilder? topListItemBuilder;

  final int? maxSelectNum;

  const ContactListView(
      {Key? key,
      required this.contactList,
      this.config,
      this.isCanSelectMemberItem = false,
      this.onSelectedMemberItemChange,
      this.topList,
      this.topListItemBuilder,
      this.selectedUser,
      this.maxSelectNum})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ContactListViewState();
}

class ContactListViewState extends State<ContactListView> {
  ContactListConfig? get listConfig => widget.config?.contactListConfig;

  Widget _buildItem(BuildContext context, ContactInfo contact, bool select) {
    List<Widget> item = [];
    if (widget.config != null && widget.config!.contactItemBuilder != null) {
      item.add(widget.config!.contactItemBuilder!(contact));
    } else {
      item.addAll([
        Avatar(
          avatar: contact.user.avatar,
          name: contact.getName(needAlias: false),
          width: select ? 42 : 36,
          height: select ? 42 : 36,
          bgCode: AvatarColor.avatarColor(content: contact.user.userId),
          radius: listConfig?.avatarCornerRadius,
        ),
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 12),
          width: MediaQuery.of(context).size.width - 100,
          child: Text(
            contact.getName(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: listConfig?.nameTextSize ?? 16,
                color: listConfig?.nameTextColor ?? CommonColors.color_333333),
          ),
        )
      ]);
    }
    return Container(
      padding: const EdgeInsets.only(left: 20, top: 16),
      child: Row(
        children: [
          if (listConfig?.showSelector ?? widget.isCanSelectMemberItem)
            Container(
              margin: const EdgeInsets.only(right: 10),
              // 选择框
              child: CheckBoxButton(
                isChecked: widget.selectedUser?.contains(contact) == true,
                clickable: false,
              ),
            ),
          ...item
        ],
      ),
    );
  }

  Widget _buildTop(BuildContext context, TopListItem top, int index) {
    return Container(
      padding: const EdgeInsets.only(left: 20, top: 16, right: 20),
      child: InkWell(
        onTap: () {
          bool handle = false;
          if (widget.config?.topEntranceClick != null) {
            handle = widget.config!.topEntranceClick!(index, top);
          }
          if (top.onTap != null && !handle) {
            top.onTap!();
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            top.icon,
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                top.name,
                style: TextStyle(
                    fontSize: listConfig?.nameTextSize ?? 14,
                    color:
                        listConfig?.nameTextColor ?? CommonColors.color_333333),
              ),
            ),
            Expanded(child: Container()),
            if (top.tips != null)
              Container(
                padding: EdgeInsets.all(4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  top.tips!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            SvgPicture.asset(
              'images/ic_right_arrow.svg',
              package: kPackage,
              height: 16,
              width: 16,
            )
          ],
        ),
      ),
    );
  }

  List<ISuspensionBeanImpl> _getSusList(List<ContactInfo> contactList) {
    List<ISuspensionBeanImpl> susList = List.empty(growable: true);
    for (var contact in contactList) {
      final name = contact.getName();
      String tag = PinyinHelper.getPinyinE(name).substring(0, 1).toUpperCase();
      if (RegExp('[A-Z]').hasMatch(tag)) {
        susList.add(ISuspensionBeanImpl(tagIndex: tag, contactInfo: contact));
      } else {
        susList.add(ISuspensionBeanImpl(tagIndex: '#', contactInfo: contact));
      }
    }
    SuspensionUtil.sortListBySuspensionTag(susList);
    return susList;
  }

  @override
  Widget build(BuildContext context) {
    final items = _getSusList(widget.contactList);
    final topList = widget.topList ?? widget.config?.headerData;
    if (widget.config?.showHeader == true && topList?.isNotEmpty == true) {
      final topItems = topList!
          .map((e) => ISuspensionBeanImpl(tagIndex: '@', contactInfo: e))
          .toList();
      items.insertAll(0, topItems);
    }
    final topListItemBuilder =
        widget.topListItemBuilder ?? widget.config?.topListItemBuilder;

    final selectable = listConfig?.showSelector ?? widget.isCanSelectMemberItem;

    final onSelectedMemberItemChange =
        widget.onSelectedMemberItemChange ?? widget.config?.contactItemSelect;

    return AZListViewContainer(
        memberList: items,
        isShowIndexBar: listConfig?.showIndexBar ?? true,
        divideLineColor: listConfig?.divideLineColor,
        textSize: listConfig?.indexTextSize,
        textColor: listConfig?.indexTextColor ?? '#B3B7BC'.toColor(),
        itemBuilder: (context, index) {
          final showItem = items[index].contactInfo;
          if (showItem is TopListItem) {
            if (topListItemBuilder != null) {
              final customTop = topListItemBuilder(showItem);
              if (customTop != null) {
                return customTop;
              }
            }
            return Column(
              children: [
                _buildTop(context, showItem, index),
                if (index < topList!.length - 1)
                  Container(
                    height: 1,
                    color: '#F5F8FC'.toColor(),
                  ),
                if (index == topList.length - 1)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    height: 6,
                    color: '#EFF1F4'.toColor(),
                  )
              ],
            );
          } else {
            return InkWell(
              onTap: () {
                if (selectable) {
                  final isChecked =
                      widget.selectedUser?.contains(showItem) != true;
                  if (isChecked &&
                      widget.selectedUser != null &&
                      widget.maxSelectNum != null &&
                      widget.selectedUser!.length >= widget.maxSelectNum!) {
                    Fluttertoast.showToast(
                        msg: S.of(context).contactSelectAsMost);
                    return;
                  }
                  if (onSelectedMemberItemChange != null) {
                    onSelectedMemberItemChange(isChecked, showItem);
                  }
                  setState(() {});
                  return;
                }
                bool handle = false;
                if (widget.config?.contactItemClick != null) {
                  handle = widget.config!.contactItemClick!(index, showItem);
                }
                if (!handle) {
                  // default to detail
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return ContactKitDetailPage(accId: showItem.user.userId!);
                  }));
                }
              },
              child: _buildItem(context, showItem, selectable),
            );
          }
        });
  }
}

class TopListItem {
  final String name;
  final Widget icon;
  final Function()? onTap;
  final String? tips;

  TopListItem({required this.name, required this.icon, this.onTap, this.tips});
}
