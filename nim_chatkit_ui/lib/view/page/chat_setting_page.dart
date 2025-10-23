// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/router/imkit_router_constants.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit/services/team/team_provider.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/background.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import 'package:nim_chatkit/repo/conversation_repo.dart';
import 'package:nim_chatkit_ui/view_model/chat_setting_view_model.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../../chat_kit_client.dart';
import '../../l10n/S.dart';

class ChatSettingPage extends StatefulWidget {
  const ChatSettingPage(this.contactInfo, this.conversationId, {Key? key})
      : super(key: key);

  final ContactInfo contactInfo;

  //会话ID
  final String conversationId;

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
              const SizedBox(
                height: 6,
              ),
              SizedBox(
                width: 42,
                child: Text(
                  widget.contactInfo.getName(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: CommonColors.color_333333),
                ),
              ),
            ],
          ),
          const SizedBox(
            width: 16,
          ),
          if (IMKitConfigCenter.enableTeam)
            GestureDetector(
              onTap: () {
                goToContactSelector(context,
                        mostCount: TeamProvider.createTeamInviteLimit,
                        filter: [accountId],
                        returnContact: true,
                        includeAIUser: true)
                    .then((contacts) {
                  if (contacts is List<ContactInfo> && contacts.isNotEmpty) {
                    // add current friend
                    contacts.add(widget.contactInfo);
                    var selectName = contacts
                        .map((e) => e.user.name ?? e.user.accountId!)
                        .toList();
                    getIt<TeamProvider>()
                        .createTeam(
                            contacts.map((e) => e.user.accountId!).toList(),
                            selectNames: selectName,
                            isGroup: true)
                        .then((teamResult) {
                      Alog.i(
                          tag: 'ChatKit',
                          moduleName: 'Chat Setting',
                          content: 'create team ${teamResult?.team?.teamId}');
                      if (teamResult != null && teamResult.team != null) {
                        // pop and jump
                        var teamConversationId = ChatKitUtils.conversationId(
                            teamResult.team!.teamId, NIMConversationType.team);
                        goToChatAndClearStack(context, teamConversationId!,
                            NIMConversationType.team);
                      }
                    });
                  }
                });
              },
              child: SvgPicture.asset(
                'images/ic_member_add.svg',
                package: kPackage,
                height: 42,
                width: 42,
              ),
            )
        ],
      ),
    );
  }

  Widget _setting(BuildContext context) {
    TextStyle style =
        const TextStyle(color: CommonColors.color_333333, fontSize: 16);
    bool stick = context.watch<ChatSettingViewModel>().isStick;
    bool notify = context.watch<ChatSettingViewModel>().isNotify;
    bool hasAIPin = context.watch<ChatSettingViewModel>().hasPin;
    bool pin = context.watch<ChatSettingViewModel>().isPin;
    return Column(
      children: ListTile.divideTiles(context: context, tiles: [
        ListTile(
            title: Text(
              S.of(context).chatMessageSignal,
              style: style,
            ),
            trailing: const Icon(Icons.keyboard_arrow_right_outlined),
            onTap: () {
              goToPinPage(
                context,
                widget.conversationId,
                NIMConversationType.p2p,
                widget.contactInfo.getName(),
              );
            }),
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
          title: Text(
            S.of(context).chatMessageSetTop,
            style: style,
          ),
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
            title: Text(
              S.of(context).chatMessageSetPin,
              style: style,
            ),
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
      ]).toList(),
    );
  }

  @override
  void initState() {
    super.initState();
    accountId = ChatKitUtils.getConversationTargetId(widget.conversationId);
  }

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
        title: S.of(context).chatSetting,
        body: ChangeNotifierProvider(
            create: (context) => ChatSettingViewModel(widget.conversationId),
            builder: (context, child) {
              const TextStyle(color: CommonColors.color_333333, fontSize: 16);
              return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    const SizedBox(
                      height: 16,
                    ),
                    CardBackground(child: _member()),
                    const SizedBox(
                      height: 16,
                    ),
                    CardBackground(child: _setting(context)),
                  ]));
            }));
  }
}
