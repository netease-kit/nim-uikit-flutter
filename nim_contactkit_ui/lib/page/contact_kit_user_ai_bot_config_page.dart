// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';

import '../l10n/S.dart';
import 'user_ai_bot_common.dart';

class ContactKitUserAIBotConfigPage extends StatelessWidget {
  final String config;

  const ContactKitUserAIBotConfigPage({Key? key, required this.config})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final body = _UserAIBotConfigContent(config: config);
    if (ChatKitUtils.isDesktopOrWeb) {
      return Scaffold(
        backgroundColor: const Color(0xFFEFF1F4),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(S.of(context).contactRobotConfigTitle),
          centerTitle: false,
          backgroundColor: Colors.white,
          elevation: 0.5,
        ),
        body: body,
      );
    }
    return TransparentScaffold(
      backgroundColor: const Color(0xFFEFF1F4),
      title: S.of(context).contactRobotConfigTitle,
      body: body,
    );
  }
}

/// Desktop and Web dialog for displaying a robot configuration string.
class ContactKitUserAIBotConfigDialog extends StatelessWidget {
  final String config;

  const ContactKitUserAIBotConfigDialog({Key? key, required this.config})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      S.of(context).contactRobotConfigTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: const Color(0xFF999999),
                    tooltip: S.of(context).contactCancel,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            _UserAIBotConfigContent(config: config),
          ],
        ),
      ),
    );
  }
}

class _UserAIBotConfigContent extends StatelessWidget {
  final String config;

  const _UserAIBotConfigContent({required this.config});

  @override
  Widget build(BuildContext context) {
    final maskedConfig = maskUserAIBotConfigString(config);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).contactRobotConfigLabel,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  maskedConfig,
                  style: TextStyle(fontSize: 14, color: '#999999'.toColor()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: config));
                ChatUIToast.show(S.of(context).contactRobotConfigCopied);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF337EFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                S.of(context).contactRobotCopy,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            S.of(context).contactRobotConfigNotice,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: '#FF9000'.toColor()),
          ),
        ],
      ),
    );
  }
}
