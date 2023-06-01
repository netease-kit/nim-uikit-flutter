// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_corekit_im/model/contact_info.dart';
import 'package:flutter/material.dart';
import 'package:nim_core/nim_core.dart';

import '../../../l10n/S.dart';

Future<bool?> showChatForwardDialog(
    {required BuildContext context,
    required String contentStr,
    List<ContactInfo>? contacts,
    NIMTeam? team}) async {
  Widget _getTargetUser() {
    if (team != null) {
      return Row(children: [
        Avatar(
          height: 32,
          width: 32,
          avatar: team.icon,
          name: team.name,
          bgCode: AvatarColor.avatarColor(content: team.id),
        ),
        Expanded(
            child: Container(
          margin: EdgeInsets.only(left: 8),
          alignment: Alignment.centerLeft,
          child: Text(
            team.name!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: '#333333'.toColor()),
          ),
        ))
      ]);
    }
    if (contacts != null && contacts.length == 1) {
      var user = contacts[0];
      return Row(children: [
        Avatar(
          height: 32,
          width: 32,
          avatar: user.user.avatar,
          name: user.getName(),
          bgCode: AvatarColor.avatarColor(content: user.user.userId),
        ),
        Expanded(
            child: Container(
          margin: EdgeInsets.only(left: 8),
          alignment: Alignment.centerLeft,
          child: Text(
            user.getName(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: '#333333'.toColor()),
          ),
        ))
      ]);
    }
    if (contacts?.isNotEmpty == true) {
      return Container(
        height: 40,
        width: 300,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: contacts!.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              var user = contacts[index];
              return Container(
                padding: EdgeInsets.only(right: 10),
                child: Avatar(
                  height: 32,
                  width: 32,
                  avatar: user.user.avatar,
                  name: user.getName(),
                  bgCode: AvatarColor.avatarColor(content: user.user.userId),
                ),
              );
            }),
      );
    }

    return Container();
  }

  Widget _getContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          S.of(context).messageForwardTo,
          style: TextStyle(fontSize: 16, color: '#333333'.toColor()),
        ),
        Container(height: 16),
        _getTargetUser(),
        Container(height: 12),
        Container(
          padding: EdgeInsets.only(left: 12, right: 12, top: 7, bottom: 9),
          color: '#F2F4F5'.toColor(),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  contentStr,
                  style: TextStyle(fontSize: 14, color: '#333333'.toColor()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: _getContent(),
          actions: [
            Row(
              children: [
                Expanded(
                    child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          S.of(context).messageCancel,
                          style: const TextStyle(
                              fontSize: 17, color: CommonColors.color_666666),
                        ))),
                Expanded(
                    child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: Text(
                          S.of(context).chatMessageSend,
                          style: const TextStyle(
                              fontSize: 17, color: CommonColors.color_007aff),
                        ))),
              ],
            )
          ],
        );
      });
}
