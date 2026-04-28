// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/background.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/team/team_provider.dart';
import 'package:nim_chatkit_ui/view_model/chat_setting_view_model.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';

import '../../chat_kit_client.dart';
import '../../l10n/S.dart';
import 'create_group_dialog.dart';

class ChatSettingPage extends StatefulWidget {
  const ChatSettingPage(
    this.contactInfo,
    this.conversationId, {
    Key? key,
    this.isDesktopDialog = false,
    this.onClose,
  }) : super(key: key);

  final ContactInfo contactInfo;

  //会话ID
  final String conversationId;

  /// 桌面端 Dialog 模式：隐藏 AppBar
  final bool isDesktopDialog;

  /// 面板模式下的关闭回调，优先于 Navigator.pop()
  final VoidCallback? onClose;

  @override
  State<StatefulWidget> createState() => _ChatSettingPageState();
}

class _ChatSettingPageState extends State<ChatSettingPage> {
  late String accountId;
  // AI数字人PIN置顶信息KEY
  String KEY_UNPIN_AI_USERS = "unpinAIUsers";

  Widget _member() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Avatar(
                avatar: widget.contactInfo.user.avatar,
                name: widget.contactInfo.getName(),
                bgCode: AvatarColor.avatarColor(content: accountId),
                fontSize: 16,
                height: 42,
                width: 42,
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 42,
                child: Text(
                  widget.contactInfo.getName(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CommonColors.color_333333,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          if (IMKitConfigCenter.enableTeam)
            GestureDetector(
              onTap: () {
                if (_isDesktopMode) {
                  _handleDesktopCreateGroup();
                } else {
                  _handleMobileCreateGroup();
                }
              },
              child: SvgPicture.asset(
                'images/ic_member_add.svg',
                package: kPackage,
                height: 42,
                width: 42,
              ),
            ),
        ],
      ),
    );
  }

  /// 移动端创建群组流程：跳转联系人选择器，选完后直接创建
  void _handleMobileCreateGroup() {
    goToContactSelector(
      context,
      mostCount: TeamProvider.createTeamInviteLimit,
      filter: [accountId],
      returnContact: true,
      includeAIUser: true,
    ).then((contacts) {
      if (contacts is List<ContactInfo> && contacts.isNotEmpty) {
        // add current friend
        contacts.add(widget.contactInfo);
        var selectName =
            contacts.map((e) => e.user.name ?? e.user.accountId!).toList();
        getIt<TeamProvider>()
            .createTeam(
          contacts.map((e) => e.user.accountId!).toList(),
          selectNames: selectName,
          isGroup: true,
        )
            .then((teamResult) {
          if (teamResult != null && teamResult.team != null) {
            var teamConversationId = ChatKitUtils.conversationId(
              teamResult.team!.teamId,
              NIMConversationType.team,
            );
            goToChatAndClearStack(
              context,
              teamConversationId!,
              NIMConversationType.team,
            );
          }
        });
      }
    });
  }

  /// 桌面端创建群组流程：
  /// 弹出 CreateGroupDialog，包含群名/头像设置和人员选择器
  /// 创建群组并跳转
  void _handleDesktopCreateGroup() async {
    final result = await showDialog<CreateGroupResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateGroupDialog(
        filterUsers: [accountId],
        currentChatName: widget.contactInfo.getName(),
      ),
    );

    if (result == null || !mounted) return;

    final contacts = result.contacts;
    if (contacts.isEmpty) return;

    // 加入当前聊天对象
    contacts.add(widget.contactInfo);

    var selectNames =
        contacts.map((e) => e.user.name ?? e.user.accountId!).toList();

    // 创建群组，优先使用用户在对话框中填写的群名
    final groupName =
        result.groupName.isNotEmpty ? result.groupName : selectNames.join('、');
    final teamResult = await getIt<TeamProvider>().createTeam(
      contacts.map((e) => e.user.accountId!).toList(),
      selectNames: selectNames,
      isGroup: true,
      iconUrl: result.avatarUrl,
      teamName: groupName,
    );

    if (teamResult != null && teamResult.team != null) {
      if (!mounted) return;

      var teamConversationId = ChatKitUtils.conversationId(
        teamResult.team!.teamId,
        NIMConversationType.team,
      );
      // 桌面端通过 _desktopChatNavigator 回调切换会话，同步高亮会话列表
      // 移动端保持原有的清栈跳转行为
      if (ChatKitUtils.isDesktopOrWeb) {
        goToChatPage(
          context,
          teamConversationId!,
          NIMConversationType.team,
        );
      } else {
        goToChatAndClearStack(
          context,
          teamConversationId!,
          NIMConversationType.team,
        );
      }
    }
  }

  Widget _setting(BuildContext context) {
    TextStyle style = const TextStyle(
      color: CommonColors.color_333333,
      fontSize: 16,
    );
    bool stick = context.watch<ChatSettingViewModel>().isStick;
    bool notify = context.watch<ChatSettingViewModel>().isNotify;
    bool hasAIPin = context.watch<ChatSettingViewModel>().hasPin;
    bool pin = context.watch<ChatSettingViewModel>().isPin;
    return Column(
      children: ListTile.divideTiles(
        context: context,
        tiles: [
          // 桌面/Web 端：标记 & 查找聊天内容已移至侧边工具栏，此处仅移动端显示
          if (!_isDesktopMode)
            ListTile(
              title: Text(S.of(context).chatMessageSignal, style: style),
              trailing: const Icon(Icons.keyboard_arrow_right_outlined),
              onTap: () {
                goToPinPage(
                  context,
                  widget.conversationId,
                  NIMConversationType.p2p,
                  widget.contactInfo.getName(),
                );
              },
            ),
          if (!_isDesktopMode)
            ListTile(
              title: Text(S.of(context).messageSearchTitle, style: style),
              trailing: const Icon(Icons.keyboard_arrow_right_outlined),
              onTap: () {
                goToChatHistoryPage(
                  context,
                  widget.conversationId,
                  NIMConversationType.p2p,
                );
              },
            ),
          ListTile(
            title: Text(
              S.of(context).chatMessageOpenMessageNotice,
              style: style,
            ),
            trailing: CupertinoSwitch(
              activeColor: CommonColors.color_337eff,
              onChanged: (bool value) async {
                if (!(await haveConnectivity())) {
                  return;
                }
                context.read<ChatSettingViewModel>().setNotify(value);
              },
              value: notify,
            ),
          ),
          ListTile(
            title: Text(S.of(context).chatMessageSetTop, style: style),
            trailing: CupertinoSwitch(
              activeColor: CommonColors.color_337eff,
              onChanged: (bool value) async {
                if (!(await haveConnectivity())) {
                  return;
                }
                context.read<ChatSettingViewModel>().setStick(value);
              },
              value: stick,
            ),
          ),
          if (hasAIPin)
            ListTile(
              title: Text(S.of(context).chatMessageSetPin, style: style),
              trailing: CupertinoSwitch(
                activeColor: CommonColors.color_337eff,
                onChanged: (bool value) async {
                  if (!(await haveConnectivity())) {
                    return;
                  }
                  context.read<ChatSettingViewModel>().setAIUserPin(value);
                },
                value: pin,
              ),
            ),
        ],
      ).toList(),
    );
  }

  @override
  void initState() {
    super.initState();
    accountId = ChatKitUtils.getConversationTargetId(widget.conversationId);
  }

  bool get _isDesktopMode =>
      widget.isDesktopDialog || ChatKitUtils.isDesktopOrWeb;

  Widget _buildContent(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatSettingViewModel(widget.conversationId),
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              CardBackground(child: _member()),
              const SizedBox(height: 16),
              CardBackground(child: _setting(context)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesktopMode) {
      return Material(
        color: Colors.white,
        child: Column(
          children: [
            // 桌面端顶栏
            Container(
              height: 48,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE8E8E8),
                    width: 0.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    S.of(context).chatSetting,
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
                      onTap: () {
                        if (widget.onClose != null) {
                          widget.onClose!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
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
            Expanded(
              child: SingleChildScrollView(
                child: _buildContent(context),
              ),
            ),
          ],
        ),
      );
    }

    return TransparentScaffold(
      title: S.of(context).chatSetting,
      body: _buildContent(context),
    );
  }
}
