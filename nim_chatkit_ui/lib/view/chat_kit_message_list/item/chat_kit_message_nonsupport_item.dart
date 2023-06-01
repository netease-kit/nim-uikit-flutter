// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';

class ChatKitMessageNonsupportItem extends StatelessWidget {
  const ChatKitMessageNonsupportItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding:
            const EdgeInsets.only(left: 12, top: 10, right: 12, bottom: 10),
        child: Text(
          S.of(context).chatMessageNonsupport,
          style: TextStyle(color: CommonColors.color_333333, fontSize: 16),
        ));
  }
}
