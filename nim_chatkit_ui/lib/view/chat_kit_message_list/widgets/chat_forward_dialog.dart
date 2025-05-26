// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/text_untils.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../../l10n/S.dart';

///弹出转发消息的对话框
///[context] 上下文
///[contentStr] 转发的消息内容
///[contacts] 转发的联系人
///[team] 转发的群组
Future<ForwardResult?> showChatForwardDialog(
    {required BuildContext context,
    required String contentStr,
    List<ContactInfo>? contacts,
    NIMTeam? team}) async {
  TextEditingController _inputControl = TextEditingController();

  Widget _getTargetUser() {
    if (team != null) {
      return Row(children: [
        Avatar(
          height: 32,
          width: 32,
          avatar: team.avatar,
          name: team.name,
          bgCode: AvatarColor.avatarColor(content: team.teamId),
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
          bgCode: AvatarColor.avatarColor(content: user.user.accountId),
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
                  bgCode: AvatarColor.avatarColor(content: user.user.accountId),
                ),
              );
            }),
      );
    }

    return Container();
  }

  Widget _getContent(double width) {
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
          height: 38,
          width: width,
          child: getSingleMiddleEllipsisText(contentStr,
              endLen: 5,
              style: TextStyle(fontSize: 14, color: '#333333'.toColor())),
        ),
        Container(
            margin: EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: _inputControl,
              placeholder: S.of(context).chatMessagePostScript,
              placeholderStyle: TextStyle(
                  color: '#A6ADB6'.toColor(),
                  fontSize: 16,
                  fontWeight: FontWeight.w400),
              style: TextStyle(
                  color: '#333333'.toColor(),
                  fontSize: 16,
                  fontWeight: FontWeight.w400),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: '#A6ADB6'.toColor())),
            ))
      ],
    );
  }

  return showDialog(
      context: context,
      builder: (context) {
        double dialogWidth = MediaQuery.of(context).size.width;
        return SimpleDialog(
            backgroundColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            children: [
              Padding(
                padding: EdgeInsets.all(14),
                child: _getContent(dialogWidth - 28),
              ),
              Container(height: 1, color: '#E1E6E8'.toColor()),
              SizedBox(
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                        child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop<ForwardResult>(
                                  ForwardResult(result: false));
                            },
                            child: Text(
                              S.of(context).messageCancel,
                              style: const TextStyle(
                                  fontSize: 17,
                                  color: CommonColors.color_666666),
                            ))),
                    Container(
                      width: 1,
                      height: 50,
                      color: '#E1E6E8'.toColor(),
                    ),
                    Expanded(
                        child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop<ForwardResult>(
                                  ForwardResult(
                                      result: true,
                                      postScript: _inputControl.text));
                            },
                            child: Text(
                              S.of(context).chatMessageSend,
                              style: const TextStyle(
                                  fontSize: 17,
                                  color: CommonColors.color_007aff),
                            ))),
                  ],
                ),
              ),
            ]);
      });
}

class ForwardResult {
  bool result; //是否转发
  String? postScript; //附言
  ForwardResult({required this.result, this.postScript});
}
