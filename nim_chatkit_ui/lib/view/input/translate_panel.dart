// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_chatkit/utils/preference_utils.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';

import '../../chat_kit_client.dart';
import '../../view_model/chat_view_model.dart';
import 'emoji/emoji.dart';

class TranslatePanel extends StatefulWidget {
  const TranslatePanel(
      {Key? key,
      required this.onTranslateCloseClick,
      required this.onTranslateSureClick,
      required this.onTranslateUseClick})
      : super(key: key);

  final VoidCallback onTranslateCloseClick;
  final Function(String language, Function(bool textEmpty))
      onTranslateSureClick;
  final Function(String result) onTranslateUseClick;

  @override
  State<StatefulWidget> createState() => _TranslatePanelState();
}

class _TranslatePanelState extends State<TranslatePanel> {
  late ChatViewModel _viewModel;
  late List<String> _languages = [];
  String _selectedLanguageKey =
      (getIt<IMLoginService>().userInfo?.accountId ?? "") + "_language";
  late String _selectedLanguage = "";
  String _translateResult = "";
  bool _isTranslating = false;
  bool _translateComplete = false;
  bool _translateUsed = true;
  final subscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<ChatViewModel>();
    _languages = AIUserManager.instance.getAITranslateLanguages();

    PreferenceUtils.getString(
            _selectedLanguageKey,
            _languages.first.length > 0
                ? _languages.first[0]
                : _languages.first)
        .then((value) {
      setState(() {
        _selectedLanguage = value;
      });
    });

    subscriptions
        .add(NimCore.instance.aiService.onProxyAIModelCall.listen((event) {
      if (event.code == _viewModel.aiUserRequestSuccess) {
        if (event.requestId == _viewModel.translationLanguageRequestId) {
          String? result = event.content?.msg;
          if (result != null) {
            _translateResult = result;
          }
          setState(() {
            _isTranslating = false;
            _translateComplete = true;
            _translateUsed = false;
          });
        }
      }
    }));
  }

  onInputTextChange() {
    setState(() {
      _translateComplete = false;
    });
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            children: [
              Stack(
                children: [
                  // 取消按钮
                  Positioned(
                    left: 2,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        S.of(context).messageCancel,
                        style: const TextStyle(
                            color: CommonColors.color_666666, fontSize: 16),
                      ),
                    ),
                  ),

                  // 标题按钮（严格居中）
                  Center(
                    child: TextButton(
                      onPressed: null,
                      child: Text(
                        S.of(context).chatTranslateLanguageTitle,
                        style: const TextStyle(
                            color: CommonColors.color_333333,
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _languages.length,
                  itemBuilder: (context, index) {
                    final language = _languages[index];
                    return InkWell(
                      onTap: () async {
                        setState(() {
                          _selectedLanguage =
                              language.length > 0 ? language[0] : language;
                          _translateComplete = false;
                          _translateUsed = true;
                        });
                        await PreferenceUtils.saveString(_selectedLanguageKey,
                            language.length > 0 ? language[0] : language);
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: 20, right: 20, top: 16, bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              language,
                              style: const TextStyle(
                                  color: CommonColors.color_333333,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                            _selectedLanguage == language
                                ? SvgPicture.asset(
                                    'images/ic_chat_translate_language_cancel.svg',
                                    package: kPackage,
                                  )
                                : Container()
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _onTranslateSureClick() async {
    if (!(await haveConnectivity(gravity: ToastGravity.CENTER))) {
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    widget.onTranslateSureClick(_selectedLanguage, (bool textEmpty) {
      if (textEmpty) {
        setState(() {
          _isTranslating = false;
          _translateComplete = false;
          _translateUsed = true;
        });
      }
    });
  }

  _onTranslateUseClick() {
    widget.onTranslateUseClick(_translateResult);
    setState(() {
      _translateComplete = false;
      _translateUsed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(left: 12),
            height: 34,
            color: Color(0xffEFF1F3),
            child: InkWell(
              onTap: _showLanguageSelector,
              child: Container(
                height: 26,
                width: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xffDBDFE2), width: 1),
                ),
                child: Text(
                  _selectedLanguage,
                  style: const TextStyle(
                      color: CommonColors.color_333333, fontSize: 12),
                ),
              ),
            ),
          ),
          Expanded(child: Container()),
          Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(right: 12),
            height: 34,
            color: Color(0xffEFF1F3),
            child: InkWell(
              onTap: widget.onTranslateCloseClick,
              child: Container(
                height: 18,
                width: 28,
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'images/ic_chat_translate_close.svg',
                  package: kPackage,
                ),
              ),
            ),
          ),
        ]),
        const Divider(
          indent: 12,
          endIndent: 12,
          height: 1,
          color: Color(0xffDBDFE2),
        ),
        Row(children: [
          Expanded(
            child: Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.only(left: 12),
              // height: 60,
              constraints: BoxConstraints(
                maxHeight: 60,
                minHeight: 42,
              ),
              color: Color(0xffEFF1F3),
              child: _translateUsed
                  ? Container(
                      // height: 18,
                      width: 60,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        S.of(context).chatTranslateTo,
                        style: const TextStyle(
                          color: CommonColors.color_b3b7bc,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : SizedBox(
                      width: MediaQuery.of(context).size.width - 100,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              _translateResult,
                              style: const TextStyle(
                                  color: CommonColors.color_333333,
                                  fontSize: 16,
                                  height: 1.25, // 行高倍数（基于字体大小）
                                  leadingDistribution:
                                      TextLeadingDistribution.even),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
          Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(right: 12),
            // height: 42,
            color: Color(0xffEFF1F3),
            child: _isTranslating
                ? Row(children: [
                    Container(
                        child: Lottie.asset('lottie/ani_ai_stream_holder.json',
                            package: kPackage, width: 12, height: 12)),
                    Container(
                      height: 18,
                      width: 80,
                      alignment: Alignment.center,
                      child: Text(
                        S.of(context).chatTranslating,
                        style: const TextStyle(
                            color: CommonColors.color_337eff, fontSize: 14),
                      ),
                    ),
                  ])
                : _translateComplete
                    ? InkWell(
                        onTap: _onTranslateUseClick,
                        child: Container(
                          height: 18,
                          width: 54,
                          alignment: Alignment.center,
                          child: Text(
                            S.of(context).chatTranslateUse,
                            style: const TextStyle(
                                color: CommonColors.color_337eff, fontSize: 14),
                          ),
                        ),
                      )
                    : InkWell(
                        onTap: _onTranslateSureClick,
                        child: Container(
                          height: 18,
                          width: 54,
                          alignment: Alignment.center,
                          child: Text(
                            S.of(context).chatTranslateSure,
                            style: const TextStyle(
                                color: CommonColors.color_337eff, fontSize: 14),
                          ),
                        ),
                      ),
          ),
        ]),
      ],
    );
  }
}
