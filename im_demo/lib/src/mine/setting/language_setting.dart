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
    // 语言切换会重建整个路由栈，这里必须使用整屏路由，不能用 DuoPageRoute。
    //
    // DuoPageRoute 是右侧抽屉（详情页）路由：它会把页面放进
    // _DuoRightPaneLayout，按抽屉宽度给页面加 left/toolbar 内边距，同时
    // 让页面参与 detailDepth/chrome 注册。把 HomePage 作为根页面塞进抽屉
    // 后：
    // - 双屏下首页会被按“左侧列表 + 右侧欢迎页”的宽度再次压缩，左侧留下
    //   一块没有内容的黑边，右侧工具栏也和首页自身预留的宽度重复；
    // - 单屏下 HomePage 会先按抽屉布局构建，随后又因 DuoShell 状态被切回
    //   整屏，页面结构在两种布局间来回切换；HomePage dispose 时还会把
    //   DuoShell 重置为关闭，最终右侧一级导航消失、页面无法操作，严重时
    //   整屏持续闪烁。
    //
    // 首页根路由必须是不参与 Duo 抽屉布局的整屏路由，与 MaterialApp.home 的
    // 初始首页保持一致。
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
        ),
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
                  color: CommonColors.color_333333,
                  fontSize: 16,
                ),
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
              title: Text(
                S.of(context).languageEnglish,
                style: const TextStyle(
                  color: CommonColors.color_333333,
                  fontSize: 16,
                ),
              ),
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
