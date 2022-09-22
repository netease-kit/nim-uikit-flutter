// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:im_common_ui/widgets/permission_request.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class ActionItem {
  String type;
  Widget icon;
  String? title;
  Function(BuildContext context)? onTap;
  List<Permission>? permissions;

  ActionItem(
      {required this.type,
      required this.icon,
      this.title,
      this.onTap,
      this.permissions});
}

class ActionConstants {
  /// input text action type
  static const String none = 'none';
  static const String input = 'input';
  static const String record = 'record';
  static const String image = 'image';
  static const String file = 'file';
  static const String emoji = 'emoji';
  static const String more = 'more';

  /// more panel action type
  static const String shoot = "shoot";
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
              PermissionsHelper.requestPermission(action.permissions!)
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
