// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:netease_common_ui/base/default_language.dart';
import 'package:nim_chatkit/repo/config_repo.dart';

import '../../../l10n/S.dart';
import '../../home/home_page.dart';

class LanguageSettingPage extends StatefulWidget {
  const LanguageSettingPage({Key? key}) : super(key: key);

  @override
  State<LanguageSettingPage> createState() => _LanguageSettingPageState();
}

class _LanguageSettingPageState extends State<LanguageSettingPage> {
  String? selectedLanguage;

  void initLanguage() async {
    if (CommonUIDefaultLanguage.commonDefaultLanguage?.isNotEmpty == true) {
      selectedLanguage = CommonUIDefaultLanguage.commonDefaultLanguage!;
    } else {
      final saveLanguage = await ConfigRepo.getLanguage();
      if (saveLanguage != null) {
        selectedLanguage = saveLanguage;
      } else {
        selectedLanguage = PlatformDispatcher.instance.locale.languageCode;
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    initLanguage();
    super.initState();
  }

  void saveLanguage() {
    CommonUIDefaultLanguage.commonDefaultLanguage = selectedLanguage;
    ConfigRepo.updateLanguage(selectedLanguage!);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
      title: S.of(context).language,
      actions: [
        TextButton(
          onPressed: () {
            saveLanguage();
          },
          child: Text(S.of(context).save),
        )
      ],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                S.of(context).languageChinese,
                style: const TextStyle(
                    color: CommonColors.color_333333, fontSize: 16),
              ),
              trailing: Radio<String>(
                value: languageZh,
                groupValue: selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    selectedLanguage = value!;
                  });
                },
              ),
            ),
            ListTile(
              title: Text(S.of(context).languageEnglish,
                  style: const TextStyle(
                      color: CommonColors.color_333333, fontSize: 16)),
              trailing: Radio<String>(
                value: languageEn,
                groupValue: selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    selectedLanguage = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
