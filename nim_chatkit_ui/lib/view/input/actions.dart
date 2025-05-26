// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:netease_common_ui/widgets/permission_request.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:permission_handler/permission_handler.dart';

typedef NIMMessageSender = Function(NIMMessage session);

class ActionItem {
  String type;
  Widget icon;
  String? title;
  Function(BuildContext context, String conversationId,
          NIMConversationType sessionType, {NIMMessageSender? messageSender})?
      onTap;
  List<Permission>? permissions;
  //权限拒绝后的提示
  String? deniedTip;

  bool enable;

  ActionItem(
      {required this.type,
      required this.icon,
      this.title,
      this.onTap,
      this.permissions,
      this.enable = true,
      this.deniedTip});
}

class ActionConstants {
  /// input text action type
  static const String none = 'none';
  static const String input = 'input';
  static const String record = 'record';
  static const String image = 'image';
  static const String file = 'file';
  static const String translate = 'translate';
  static const String emoji = 'emoji';
  static const String more = 'more';

  /// more panel action type
  static const String shoot = "shoot";
  static const String location = 'location';
}

class InputTextAction extends StatelessWidget {
  const InputTextAction(
      {Key? key,
      required this.action,
      required this.onTap,
      required this.enable})
      : super(key: key);

  final ActionItem action;
  final VoidCallback onTap;
  final bool enable;

  @override
  Widget build(BuildContext context) {
    var _tap;
    if (enable) {
      _tap = action.permissions != null
          ? () {
              PermissionsHelper.requestPermission(action.permissions!,
                      deniedTip: action.deniedTip)
                  .then((value) {
                if (value) {
                  onTap();
                }
              });
            }
          : onTap;
    }
    return GestureDetector(
      onTap: _tap,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 15),
        child: action.icon,
      ),
    );
  }
}
