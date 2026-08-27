// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:netease_common_ui/ui/background.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/message/message_translation.dart';
import 'package:nim_chatkit/repo/config_repo.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';

import '../../l10n/S.dart';
import 'message_translation_language_page.dart';

class MessageTranslationSettingPage extends StatefulWidget {
  const MessageTranslationSettingPage({Key? key}) : super(key: key);

  @override
  State<MessageTranslationSettingPage> createState() =>
      _MessageTranslationSettingPageState();
}

class _MessageTranslationSettingPageState
    extends State<MessageTranslationSettingPage> {
  String _targetLanguage = MessageTranslationHelper.defaultLanguages.first.code;
  bool _autoTranslate = false;

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  Future<void> _initSettings() async {
    final targetLanguage = await ConfigRepo.getMessageTranslateTargetLanguage();
    final autoTranslate = await ConfigRepo.getMessageAutoTranslate();
    if (!mounted) {
      return;
    }
    setState(() {
      _targetLanguage = targetLanguage;
      _autoTranslate = autoTranslate;
    });
  }

  Future<void> _openLanguagePage() async {
    final languagePage = MessageTranslationLanguagePage(
      selectedLanguage: _targetLanguage,
    );
    final result = ChatKitUtils.isDesktopOrWeb
        ? await showDesktopDialog<String>(context, languagePage)
        : await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (context) => languagePage,
            ),
          );
    if (result?.isNotEmpty == true && mounted) {
      setState(() {
        _targetLanguage = result!;
      });
    }
  }

  Future<void> _updateAutoTranslate(bool value) async {
    await ConfigRepo.updateMessageAutoTranslate(value);
    if (value) {
      await ConfigRepo.updateMessageAutoTranslateEnabledAt(
        DateTime.now().millisecondsSinceEpoch,
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _autoTranslate = value;
    });
  }

  String _languageName(BuildContext context, String code) {
    return MessageTranslationHelper.languageName(
      code,
      S.of(context).localeName,
    );
  }

  Widget _buildTextTile({
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: CommonColors.color_333333, fontSize: 16),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: const TextStyle(
            color: CommonColors.color_999999,
            fontSize: 13,
          ),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
      title: S.of(context).messageTranslationSettingTitle,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            CardBackground(
              child: Column(
                children: ListTile.divideTiles(
                  context: context,
                  tiles: [
                    _buildTextTile(
                      title: S.of(context).messageTranslationTarget,
                      subtitle: S.of(context).messageTranslationTargetDesc,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _languageName(context, _targetLanguage),
                            style: const TextStyle(
                              color: CommonColors.color_999999,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_right_outlined),
                        ],
                      ),
                      onTap: _openLanguagePage,
                    ),
                    _buildTextTile(
                      title: S.of(context).messageTranslationAutoTranslate,
                      subtitle:
                          S.of(context).messageTranslationAutoTranslateDesc,
                      trailing: Switch(
                        value: _autoTranslate,
                        activeColor: CommonColors.color_337eff,
                        onChanged: _updateAutoTranslate,
                      ),
                    ),
                  ],
                ).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
