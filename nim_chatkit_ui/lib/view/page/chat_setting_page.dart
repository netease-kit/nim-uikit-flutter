// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter_svg/svg.dart';
import 'package:netease_corekit_im/router/imkit_router_constants.dart';
import 'package:netease_corekit_im/router/imkit_router_factory.dart';
import 'package:netease_corekit_im/services/team/team_provider.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/background.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:netease_corekit_im/model/contact_info.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/message/message_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nim_core/nim_core.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../../chat_kit_client.dart';
import '../../l10n/S.dart';

class ChatSettingPage extends StatefulWidget {
  const ChatSettingPage(this.contactInfo, {Key? key}) : super(key: key);

  final ContactInfo contactInfo;

  @override
  State<StatefulWidget> createState() => _ChatSettingPageState();
}

class _ChatSettingPageState extends State<ChatSettingPage> {
  bool isNotify = false;
  bool isStick = false;

  String get userId => widget.contactInfo.user.userId!;

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
          GestureDetector(
            onTap: () {
              goToContactSelector(context,
                      mostCount: 198, filter: [userId], returnContact: true)
                  .then((contacts) {
                if (contacts is List<ContactInfo> && contacts.isNotEmpty) {
                  // add current friend
                  contacts.add(widget.contactInfo);

                  var selectName = contacts
                      .map((e) => e.user.nick ?? e.user.userId!)
                      .toList();
                  getIt<TeamProvider>()
                      .createTeam(contacts.map((e) => e.user.userId!).toList(),
                          selectNames: selectName, isGroup: true)
                      .then((teamResult) {
                    Alog.i(
                        tag: 'ChatKit',
                        moduleName: 'Chat Setting',
                        content: 'create team ${teamResult?.toMap()}');
                    if (teamResult != null && teamResult.team != null) {
                      // pop and jump
                      Navigator.pushNamedAndRemoveUntil(
                          context,
                          RouterConstants.PATH_CHAT_PAGE,
                          ModalRoute.withName(RouterConstants.PATH_CHAT_PAGE),
                          arguments: {
                            'sessionId': teamResult.team!.id!,
                            'sessionType': NIMSessionType.team,
                          });
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

  Widget _setting() {
    TextStyle style =
        const TextStyle(color: CommonColors.color_333333, fontSize: 16);
    return Column(
      children: ListTile.divideTiles(context: context, tiles: [
        ListTile(
          title: Text(
            S.of(context).chatMessageSignal,
            style: style,
          ),
          trailing: const Icon(Icons.keyboard_arrow_right_outlined),
          onTap: () {
            Navigator.pushNamed(context, RouterConstants.PATH_CHAT_PIN_PAGE,
                arguments: {
                  'sessionId': userId,
                  'sessionType': NIMSessionType.p2p,
                  'chatTitle': widget.contactInfo.getName()
                });
          },
        ),
        ListTile(
          title: Text(
            S.of(context).chatMessageOpenMessageNotice,
            style: style,
          ),
          trailing: CupertinoSwitch(
            activeColor: CommonColors.color_337eff,
            onChanged: (bool value) {
              ChatMessageRepo.setNotify(userId, value).then((suc) {
                if (!suc) {
                  setState(() {
                    isNotify = !value;
                  });
                }
              });
              setState(() {
                isNotify = value;
              });
            },
            value: isNotify,
          ),
        ),
        ListTile(
          title: Text(
            S.of(context).chatMessageSetTop,
            style: style,
          ),
          trailing: CupertinoSwitch(
            activeColor: CommonColors.color_337eff,
            onChanged: (bool value) {
              if (value) {
                getIt<MessageProvider>()
                    .addStickTop(userId, NIMSessionType.p2p, '')
                    .then((info) {
                  if (info == null) {
                    setState(() {
                      isStick = false;
                    });
                  }
                });
              } else {
                getIt<MessageProvider>()
                    .removeStick(userId, NIMSessionType.p2p, '')
                    .then((removed) {
                  if (!removed) {
                    setState(() {
                      isStick = true;
                    });
                  }
                });
              }
              setState(() {
                isStick = value;
              });
            },
            value: isStick,
          ),
        ),
      ]).toList(),
    );
  }

  @override
  void initState() {
    super.initState();
    ChatMessageRepo.isNeedNotify(userId).then((value) {
      setState(() {
        isNotify = value;
      });
    });
    getIt<MessageProvider>()
        .isStickSession(userId, NIMSessionType.p2p)
        .then((value) => isStick = value);
  }

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
      title: S.of(context).chatSetting,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(
              height: 16,
            ),
            CardBackground(child: _member()),
            const SizedBox(
              height: 16,
            ),
            CardBackground(child: _setting())
          ],
        ),
      ),
    );
  }
}
