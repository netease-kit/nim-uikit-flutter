// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/message/message_translation.dart';
import 'package:nim_chatkit/repo/config_repo.dart';

import '../../l10n/S.dart';

class MessageTranslationLanguagePage extends StatefulWidget {
  const MessageTranslationLanguagePage({
    Key? key,
    required this.selectedLanguage,
  }) : super(key: key);

  final String selectedLanguage;

  @override
  State<MessageTranslationLanguagePage> createState() =>
      _MessageTranslationLanguagePageState();
}

class _MessageTranslationLanguagePageState
    extends State<MessageTranslationLanguagePage> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
  }

  Future<void> _save() async {
    await ConfigRepo.updateMessageTranslateTargetLanguage(_selectedLanguage);
    if (!mounted) {
      return;
    }
    Navigator.pop(context, _selectedLanguage);
  }

  String _languageName(BuildContext context, String code) {
    return MessageTranslationHelper.languageName(
      code,
      S.of(context).localeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
      title: S.of(context).messageTranslationTarget,
      actions: [
        TextButton(
          onPressed: _save,
          child: Text(S.of(context).messageTranslationSave),
        ),
      ],
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: MessageTranslationHelper.defaultLanguages.length,
        separatorBuilder: (context, index) {
          return const Divider(height: 1);
        },
        itemBuilder: (context, index) {
          final language = MessageTranslationHelper.defaultLanguages[index];
          final isSelected = language.code == _selectedLanguage;
          return ListTile(
            title: Text(
              _languageName(context, language.code),
              style: TextStyle(
                color: isSelected
                    ? CommonColors.color_337eff
                    : CommonColors.color_333333,
                fontSize: 16,
              ),
            ),
            trailing: isSelected
                ? const SizedBox.square(
                    dimension: 20,
                    child: Icon(
                      Icons.check,
                      size: 20,
                      color: CommonColors.color_337eff,
                    ),
                  )
                : null,
            onTap: () {
              setState(() {
                _selectedLanguage = language.code;
              });
            },
          );
        },
      ),
    );
  }
}
