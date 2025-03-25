// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:netease_common/netease_common.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_corekit_im/router/imkit_router_constants.dart';
import 'package:nim_core_v2/nim_core.dart';

class ChatKitMessageTipsItem extends StatefulWidget {
  final NIMMessage message;

  const ChatKitMessageTipsItem({Key? key, required this.message})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageTipsState();
}

class ChatKitMessageTipsState extends State<ChatKitMessageTipsItem> {
  String _getTips(NIMMessage message) {
    var remoteExtension = null;
    if (widget.message.serverExtension?.isNotEmpty == true) {
      try {
        remoteExtension = jsonDecode(widget.message.serverExtension!);
      } catch (e) {
        Alog.e(tag: 'ChatKitMessageTipsItem', content: 'e : ${e.toString()}');
      }
    }
    if (remoteExtension != null &&
        remoteExtension[RouterConstants.keyTeamCreatedTip] != null) {
      return remoteExtension[RouterConstants.keyTeamCreatedTip];
    } else {
      return message.text ?? 'unknown tips';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 8),
      child: Text(
        _getTips(widget.message),
        maxLines: null,
        style: TextStyle(fontSize: 12, color: '#999999'.toColor()),
      ),
    );
  }
}
