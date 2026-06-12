// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/chatkit_utils.dart';

import '../l10n/S.dart';
import 'user_ai_bot_common.dart';

class ContactKitUserAIBotLimitPage extends StatelessWidget {
  const ContactKitUserAIBotLimitPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.of(context).contactRobotLimitTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).contactRobotLimitContent,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(
                context,
                const UserAIBotLimitAction(keepOnList: true),
              );
            },
            child: Text(S.of(context).contactRobotSelectExisting),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                const UserAIBotLimitAction(keepOnList: false),
              );
            },
            child: Text(S.of(context).contactRobotGoDelete),
          ),
        ],
      ),
    );
    if (ChatKitUtils.isDesktopOrWeb) {
      return Scaffold(
        backgroundColor: const Color(0xFFEFF1F4),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(S.of(context).contactRobotLimitTitle),
          centerTitle: false,
          backgroundColor: Colors.white,
          elevation: 0.5,
        ),
        body: body,
      );
    }
    return TransparentScaffold(
      backgroundColor: const Color(0xFFEFF1F4),
      title: S.of(context).contactRobotLimitTitle,
      body: body,
    );
  }
}
