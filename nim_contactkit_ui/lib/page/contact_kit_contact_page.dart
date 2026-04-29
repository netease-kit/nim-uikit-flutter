// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_contactkit_ui/page/contact_kit_ai_user_list_page.dart';
import 'package:nim_contactkit_ui/page/contact_kit_black_list_page.dart';
import 'package:nim_contactkit_ui/page/contact_kit_team_list_page.dart';
import 'package:nim_contactkit_ui/page/contact_kit_verify_message_page.dart';
import 'package:nim_contactkit_ui/page/viewmodel/contact_viewmodel.dart';
import 'package:provider/provider.dart';

import '../contact_kit_client.dart';
import '../l10n/S.dart';
import '../widgets/contact_kit_contact_list_view.dart';

class ContactKitContactPage extends StatefulWidget {
  final ContactUIConfig? config;

  /// 桌面端通讯录分类选中回调
  final DesktopContactCategorySelect? onDesktopCategorySelect;

  /// 桌面端当前选中的分类索引，用于高亮显示
  final int? desktopSelectedCategoryIndex;

  const ContactKitContactPage({
    Key? key,
    this.config,
    this.onDesktopCategorySelect,
    this.desktopSelectedCategoryIndex,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ContactKitContactState();
}

class _ContactKitContactState extends State<ContactKitContactPage> {
  ContactUIConfig get uiConfig =>
      widget.config ?? ContactKitClient.instance.contactUIConfig;

  String? _getTips(BuildContext context) {
    int unreadCount = context.watch<ContactViewModel>().unReadCount;
    if (unreadCount > 99) {
      return '99+';
    } else if (unreadCount > 0) {
      return '$unreadCount';
    } else {
      return null;
    }
  }

  List<TopListItem> _buildDefaultTopList(BuildContext context) {
    return [
      TopListItem(
        name: S.of(context).contactVerifyMessage,
        icon: SvgPicture.asset(
          'images/ic_verify.svg',
          package: kPackage,
          height: 36,
          width: 36,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return ContactKitSystemNotifyMessagePage(
                  listConfig: uiConfig.contactListConfig,
                );
              },
            ),
          ).then((value) {
            context.read<ContactViewModel>().cleanSystemUnreadCount();
          });
        },
        tips: _getTips(context),
      ),
      TopListItem(
        name: S.of(context).contactBlackList,
        icon: SvgPicture.asset(
          'images/ic_black_list.svg',
          package: kPackage,
          height: 36,
          width: 36,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return ContactKitBlackListPage(
                  listConfig: uiConfig.contactListConfig,
                );
              },
            ),
          );
        },
      ),
      if (IMKitConfigCenter.enableTeam)
        TopListItem(
          name: S.of(context).contactTeam,
          icon: SvgPicture.asset(
            'images/ic_team.svg',
            package: kPackage,
            height: 36,
            width: 36,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ContactKitTeamListPage(
                    listConfig: uiConfig.contactListConfig,
                  );
                },
              ),
            );
          },
        ),
      if (IMKitClient.enableAi)
        TopListItem(
          name: S.of(context).contactAIUserList,
          icon: SvgPicture.asset(
            'images/ic_ai_user_list.svg',
            package: kPackage,
            height: 36,
            width: 36,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ContactKitAIUserListPage(
                    listConfig: uiConfig.contactListConfig,
                  );
                },
              ),
            );
          },
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ChatKitUtils.isDesktopOrWeb;

    return ChangeNotifierProvider(
      create: (context) => ContactViewModel(),
      builder: (context, child) {
        if (isDesktop && widget.onDesktopCategorySelect != null) {
          // 桌面端：只显示分类菜单列表
          return _buildDesktopCategoryList(context);
        }

        // 移动端：保持原有行为
        return ContactListView(
          contactList: context
              .watch<ContactViewModel>()
              .contacts
              .where((e) => e.isInBlack != true)
              .toList(),
          config: uiConfig,
          topList: uiConfig.headerData ?? _buildDefaultTopList(context),
        );
      },
    );
  }

  /// 桌面端分类菜单列表
  Widget _buildDesktopCategoryList(BuildContext context) {
    final tips = _getTips(context);
    final friendCount = context
        .watch<ContactViewModel>()
        .contacts
        .where((e) => e.isInBlack != true)
        .length;

    // 分类项定义
    // categoryIndex: 0=验证消息, 1=黑名单, 2=我的好友, 3=我的群聊, 4=我的数字人
    final List<_DesktopCategoryItem> categories = [
      _DesktopCategoryItem(
        name: S.of(context).contactVerifyMessage,
        icon: SvgPicture.asset(
          'images/ic_verify.svg',
          package: kPackage,
          height: 36,
          width: 36,
        ),
        categoryIndex: 0,
        tips: tips,
      ),
      _DesktopCategoryItem(
        name: S.of(context).contactBlackList,
        icon: SvgPicture.asset(
          'images/ic_black_list.svg',
          package: kPackage,
          height: 36,
          width: 36,
        ),
        categoryIndex: 1,
      ),
      _DesktopCategoryItem(
        name: S.of(context).myFriend,
        icon: SvgPicture.asset(
          'images/ic_friend.svg',
          package: kPackage,
          height: 36,
          width: 36,
        ),
        categoryIndex: 2,
        count: friendCount > 0 ? friendCount : null,
      ),
      if (IMKitConfigCenter.enableTeam)
        _DesktopCategoryItem(
          name: S.of(context).contactTeam,
          icon: SvgPicture.asset(
            'images/ic_team.svg',
            package: kPackage,
            height: 36,
            width: 36,
          ),
          categoryIndex: 3,
        ),
      if (IMKitClient.enableAi)
        _DesktopCategoryItem(
          name: S.of(context).contactAIUserList,
          icon: SvgPicture.asset(
            'images/ic_ai_user_list.svg',
            package: kPackage,
            height: 36,
            width: 36,
          ),
          categoryIndex: 4,
        ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 0),
      itemBuilder: (context, index) {
        final item = categories[index];
        final isSelected =
            widget.desktopSelectedCategoryIndex == item.categoryIndex;
        return _DesktopCategoryTile(
          item: item,
          isSelected: isSelected,
          onTap: () {
            widget.onDesktopCategorySelect?.call(item.categoryIndex);
            // 桌面端：点击验证消息分类即视为已读，清除未读数
            // 移动端通过 Navigator.push 的 .then() 清除，桌面端无路由跳转需在此处理
            if (item.categoryIndex == 0) {
              context.read<ContactViewModel>().cleanSystemUnreadCount();
            }
          },
        );
      },
    );
  }

  /// 桌面端分类菜单项
  Widget _buildDesktopCategoryTile(
    _DesktopCategoryItem item,
    bool isSelected,
  ) {
    return _DesktopCategoryTile(
      item: item,
      isSelected: isSelected,
      onTap: () {
        widget.onDesktopCategorySelect?.call(item.categoryIndex);
      },
    );
  }
}

/// 桌面端分类项数据模型
class _DesktopCategoryItem {
  final String name;
  final Widget icon;
  final int categoryIndex;
  final String? tips;
  final int? count;

  _DesktopCategoryItem({
    required this.name,
    required this.icon,
    required this.categoryIndex,
    this.tips,
    this.count,
  });
}

/// 桌面端分类项 Widget（带 hover 效果）
class _DesktopCategoryTile extends StatefulWidget {
  final _DesktopCategoryItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _DesktopCategoryTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DesktopCategoryTile> createState() => _DesktopCategoryTileState();
}

class _DesktopCategoryTileState extends State<_DesktopCategoryTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isSelected
        ? const Color(0xFFE8F0FF)
        : _isHovered
            ? const Color(0xFFF2F3F5)
            : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              widget.item.icon,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.item.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isSelected
                        ? const Color(0xFF337EFF)
                        : const Color(0xFF333333),
                  ),
                ),
              ),
              // 未读角标
              if (widget.item.tips != null)
                Container(
                  padding: const EdgeInsets.all(4),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    widget.item.tips!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              // 好友数量
              if (widget.item.count != null && widget.item.tips == null)
                Text(
                  '${widget.item.count}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB3B7BC),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
