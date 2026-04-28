// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/model/team_models.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/contact/contact_provider.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../chat_kit_client.dart';
import '../../l10n/S.dart';

/// 桌面端群成员选择浮层组件
///
/// 显示群成员列表和搜索框，点击成员后通过 [onMemberSelected] 回调通知父组件。
class ChatDesktopMemberPickerOverlay extends StatefulWidget {
  /// 群 ID
  final String teamId;

  /// 选中成员时的回调，参数为 (accountId, displayName)
  final void Function(String memberId, String memberName) onMemberSelected;

  const ChatDesktopMemberPickerOverlay({
    Key? key,
    required this.teamId,
    required this.onMemberSelected,
  }) : super(key: key);

  @override
  State<ChatDesktopMemberPickerOverlay> createState() =>
      _ChatDesktopMemberPickerOverlayState();
}

class _ChatDesktopMemberPickerOverlayState
    extends State<ChatDesktopMemberPickerOverlay> {
  final TextEditingController _searchController = TextEditingController();

  /// 与 [TeamKitMemberListPage] 对齐，使用统一的 [UserInfoWithTeam] 数据模型，
  /// 昵称/头像展示走同一套 `getName()` / `getAvatar()` 规则。
  List<UserInfoWithTeam> _allMembers = [];
  List<UserInfoWithTeam> _filteredMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _searchController.addListener(() {
      _applyFilter(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final option = NIMTeamMemberQueryOption(
      roleQueryType: NIMTeamMemberRoleQueryType.memberRoleQueryTypeAll,
    );
    final result = await NimCore.instance.teamService
        .getTeamMemberList(widget.teamId, NIMTeamType.typeNormal, option);
    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      final members = result.data!.memberList ?? [];
      final validMembers =
          members.where((m) => m.accountId.isNotEmpty).toList();

      // 拉取联系人信息（含好友备注 alias 与 userInfo），与 TeamKitMemberListPage 一致
      final items = <UserInfoWithTeam>[];
      for (final m in validMembers) {
        final contact = await getIt<ContactProvider>().getContact(m.accountId);
        items.add(UserInfoWithTeam(
          contact?.user,
          m,
          alias: contact?.friend?.alias,
        ));
      }

      if (mounted) {
        setState(() {
          _allMembers = items;
          _filteredMembers = items;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter(String text) {
    setState(() {
      if (text.isEmpty) {
        _filteredMembers = _allMembers;
      } else {
        final lower = text.toLowerCase();
        _filteredMembers = _allMembers
            .where((m) => m.getName().toLowerCase().contains(lower))
            .toList();
      }
    });
  }

  OutlineInputBorder _border() => const OutlineInputBorder(
        gapPadding: 0,
        borderSide: BorderSide(color: Colors.transparent),
      );

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: Container(
          width: 220,
          constraints: const BoxConstraints(maxHeight: 280),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 搜索框
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    fillColor: '#F2F4F5'.toColor(),
                    filled: true,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: _border(),
                    enabledBorder: _border(),
                    focusedBorder: _border(),
                    prefixIcon: Icon(Icons.search,
                        size: 16, color: '#A6ADB6'.toColor()),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    suffixIcon: ValueListenableBuilder(
                      valueListenable: _searchController,
                      builder: (ctx, TextEditingValue val, _) {
                        if (val.text.isEmpty) return const SizedBox.shrink();
                        return IconButton(
                          onPressed: _searchController.clear,
                          icon: Icon(Icons.clear,
                              size: 16, color: '#A6ADB6'.toColor()),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                        );
                      },
                    ),
                    hintText: S.of(context).chatMemberPickerSearchHint,
                    hintStyle:
                        TextStyle(fontSize: 14, color: '#A6ADB6'.toColor()),
                  ),
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                ),
              ),
              // 成员列表 / loading / 空态
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_filteredMembers.isEmpty)
                _buildEmptyState()
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredMembers.length,
                    itemExtent: 48.0,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemBuilder: (context, index) =>
                        _buildMemberItem(_filteredMembers[index]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset('images/ic_member_empty.svg', package: kPackage),
          const SizedBox(height: 12),
          Text(
            S.of(context).chatMemberPickerEmpty,
            style: TextStyle(fontSize: 14, color: '#B3B7BC'.toColor()),
          ),
        ],
      ),
    );
  }

  /// 成员行：头像 + 昵称
  ///
  /// 展示逻辑与 `TeamKitMemberListPage.TeamMemberListItem` 保持一致：
  /// - 头像：使用共通 [Avatar] 组件，URL 取 `member.getAvatar()`，
  ///   背景色由 [AvatarColor.avatarColor] 基于 accountId 计算
  ///   fallback 首字取 userInfo.name（不含 alias / teamNick）以保持稳定
  /// - 昵称：`member.getName()` — alias > teamNick > userInfo.name > accountId
  /// 仅尺寸因浮层布局受限保持为 32×32。
  Widget _buildMemberItem(UserInfoWithTeam member) {
    final accountId = member.teamInfo.accountId;
    final name = member.getName();
    return InkWell(
      onTap: () => widget.onMemberSelected(accountId, name),
      hoverColor: const Color(0xFFF6F8FA),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Avatar(
              width: 32,
              height: 32,
              avatar: member.getAvatar(),
              name: member.getName(needAlias: false, needTeamNick: false),
              bgCode: AvatarColor.avatarColor(content: accountId),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
