// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/model/team_default_icon.dart';
import 'package:nim_chatkit/router/imkit_router.dart';
import 'package:nim_chatkit/router/imkit_router_constants.dart';
import 'package:nim_chatkit/services/team/team_provider.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';

import '../../l10n/S.dart';

/// 创建群组对话框返回的结果
class CreateGroupResult {
  /// 群名称
  final String groupName;

  /// 群头像 URL（预设头像或自定义上传的 URL）
  final String? avatarUrl;

  /// 选中的联系人列表
  final List<ContactInfo> contacts;

  CreateGroupResult({
    required this.groupName,
    this.avatarUrl,
    required this.contacts,
  });
}

/// 创建群组对话框
///
/// 桌面端专用。包含群名称输入、预设头像选择和人员选择器。
class CreateGroupDialog extends StatefulWidget {
  /// 过滤的用户 ID 列表（例如当前聊天对象，因为会自动加入）
  final List<String>? filterUsers;

  /// 当前聊天对象的名称（用于生成默认群名）
  final String? currentChatName;

  const CreateGroupDialog({
    Key? key,
    this.filterUsers,
    this.currentChatName,
  }) : super(key: key);

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  late TextEditingController _nameController;
  int _selectedAvatarIndex = 0;
  List<ContactInfo> _selectedContacts = [];
  bool _isNameManuallyEdited = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _updateDefaultName();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateDefaultName() {
    if (_isNameManuallyEdited) return;

    List<String> names = [];
    if (IMKitClient.getUserInfo()?.name?.isNotEmpty == true) {
      names.add(IMKitClient.getUserInfo()?.name ?? '');
    }
    if (widget.currentChatName != null && widget.currentChatName!.isNotEmpty) {
      names.add(widget.currentChatName!);
    }
    names.addAll(_selectedContacts.map((e) => e.getName()));

    if (names.isEmpty) {
      _nameController.text = '';
      return;
    }

    var defaultName = names.join('、');
    if (defaultName.length > 20) {
      defaultName = '${defaultName.substring(0, 20)}...';
    }
    _nameController.text = defaultName;
  }

  void _showAvatarSelector() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).chatCreateGroupSelectAvatar,
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children:
                      List.generate(TeamDefaultIcons.icons.length, (index) {
                    final isSelected = _selectedAvatarIndex == index;
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAvatarIndex = index;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: CommonColors.color_337eff,
                                    width: 2,
                                  )
                                : null,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Avatar(
                            width: 48,
                            height: 48,
                            avatar: TeamDefaultIcons.getIconByIndex(index),
                            name: '',
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 520,
        height: 630,
        color: Colors.white,
        child: Column(
          children: [
            // 顶栏
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF0F1F5), width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.of(context).chatCreateGroupTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF656A72),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 群信息输入区：群名称在上，群头像在下
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                children: [
                  // 群名称行
                  Row(
                    children: [
                      Text(
                        S.of(context).chatCreateGroupNameLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 260,
                        height: 32,
                        child: TextField(
                          controller: _nameController,
                          maxLength: 30,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: S.of(context).chatCreateGroupNameHint,
                            hintStyle: const TextStyle(
                              color: Color(0xFFCCCCCC),
                              fontSize: 14,
                            ),
                            counterText: '',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF0F1F5)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF0F1F5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: CommonColors.color_337eff,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            _isNameManuallyEdited = true;
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 群头像行
                  Row(
                    children: [
                      Text(
                        S.of(context).chatCreateGroupAvatarLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(width: 12),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _showAvatarSelector,
                          child: Avatar(
                            width: 32,
                            height: 32,
                            avatar: TeamDefaultIcons.getIconByIndex(
                                _selectedAvatarIndex),
                            name: _nameController.text.isNotEmpty
                                ? _nameController.text
                                : S.of(context).chatCreateGroupTitle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF0F1F5)),

            // 人员选择器
            Expanded(
              child: Navigator(
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    settings: RouteSettings(
                      arguments: {
                        'mostCount': TeamProvider.createTeamInviteLimit,
                        'filterUser': widget.filterUsers,
                        'returnContact': true,
                        'includeAIUser': true,
                        'isEmbed': true,
                        'onSelectionChanged': (List<ContactInfo> contacts) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _selectedContacts = contacts;
                                _updateDefaultName();
                              });
                            }
                          });
                        },
                      },
                    ),
                    builder: (context) => IMKitRouter.instance.routes[
                        RouterConstants.PATH_CONTACT_SELECTOR_PAGE]!(context),
                  );
                },
              ),
            ),

            // 底部按钮
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFF0F1F5), width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 取消按钮
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 72,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFD9D9D9),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          S.of(context).chatCreateGroupCancel,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 创建按钮
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedContacts.isEmpty) {
                          ChatUIToast.show(
                            S.of(context).chatCreateGroupSelectContact,
                            context: context,
                          );
                          return;
                        }
                        Navigator.of(context).pop(
                          CreateGroupResult(
                            groupName: _nameController.text.trim(),
                            avatarUrl: TeamDefaultIcons.getIconByIndex(
                              _selectedAvatarIndex,
                            ),
                            contacts: _selectedContacts,
                          ),
                        );
                      },
                      child: Container(
                        width: 72,
                        height: 32,
                        decoration: BoxDecoration(
                          color: CommonColors.color_337eff,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          S.of(context).chatCreateGroupConfirm,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
}
