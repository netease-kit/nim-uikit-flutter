// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:im_demo/l10n/S.dart';
import 'package:im_demo/src/home/home_page.dart';
import 'package:im_demo/src/home/splash_page.dart';
import 'package:im_demo/src/mine/user_info_page.dart';
import 'package:netease_common_ui/common_ui.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/router/imkit_router.dart';
import 'package:nim_chatkit/router/imkit_router_constants.dart';
// import 'package:nim_chatkit_location/chat_kit_location.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_contactkit_ui/contact_kit_client.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_searchkit_ui/search_kit_client.dart';
import 'package:nim_teamkit_ui/team_kit_client.dart';
import 'package:provider/provider.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:netease_common_ui/base/default_language.dart';
import 'package:nim_chatkit/repo/config_repo.dart';
import 'package:netease_callkit_ui/ne_callkit_ui.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  // WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((timeStamp) {
  //   //初始化位置消息插件
  //   ChatKitLocation.instance.init(
  //       aMapAndroidKey: IMDemoConfig.AMapAndroid,
  //       aMapIOSKey: IMDemoConfig.AMapIOS,
  //       aMapWebKey: IMDemoConfig.AMapWeb);
  // });
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // AI搜索数字人账号
  final String AI_SEARCH_USER_ACCOUNT = "search";

  // AI翻译数字人账号
  final String AI_TRANSLATION_USER_ACCOUNT = "translation";

  ///init all plugin here
  void _initPlugins() {
    ChatKitClient.init();
    TeamKitClient.init();
    ConversationKitClient.init();
    ContactKitClient.init();
    SearchKitClient.init();

    IMKitRouter.instance.registerRouter(
        RouterConstants.PATH_MINE_INFO_PAGE, (context) => UserInfoPage());
  }

  ///初始化AI数字人相关配置
  void _initAIUser() {
    AIUserManager.instance.init();
    AIUserManager.instance.aiSearchUserProvider = (List<NIMAIUser> users) {
      for (var user in users) {
        if (user.accountId == AI_SEARCH_USER_ACCOUNT) {
          return user;
        }
      }
      return null;
    };
    AIUserManager.instance.aiTranslateUserProvider = (List<NIMAIUser> users) {
      for (var user in users) {
        if (user.accountId == AI_TRANSLATION_USER_ACCOUNT) {
          return user;
        }
      }
      return null;
    };
    AIUserManager.instance.aiTranslateLanguagesProvider =
        (List<NIMAIUser> users) {
      return ["英语", "日语", "韩语", "俄语", "法语", "德语"];
    };
  }

  Uint8List? _deviceToken;

  void _updateTokenIOS() {
    if (Platform.isIOS) {
      MethodChannel(channelName).setMethodCallHandler((call) async {
        if (call.method == 'updateAPNsToken') {
          setState(() {
            _deviceToken = call.arguments as Uint8List;
          });
        }
        return null;
      });
    }
  }

  ///设置默认的语言，不设置则根据系统语言
  void _setDefaultLanguage() async {
    CommonUIDefaultLanguage.commonDefaultLanguage =
        await ConfigRepo.getLanguage();
  }

  @override
  void initState() {
    super.initState();
    _setDefaultLanguage();
    _updateTokenIOS();
    _initPlugins();
    _initAIUser();
    GestureBinding.instance.resamplingEnabled = true;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      useInheritedMediaQuery: true,
      builder: (context, child) {
        return MaterialApp(
          onGenerateTitle: (BuildContext context) => S.of(context).appName,
          localizationsDelegates: [
            S.delegate,
            CommonUILocalizations.delegate,
            ConversationKitClient.delegate,
            ChatKitClient.delegate,
            ContactKitClient.delegate,
            TeamKitClient.delegate,
            SearchKitClient.delegate,
            NECallKitUI.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          navigatorObservers: [
            IMKitRouter.instance.routeObserver,
            NECallKitUI.navigatorObserver
          ],
          supportedLocales: IMKitClient.supportedLocales,
          theme: ThemeData(
              primaryColor: CommonColors.color_337eff,
              pageTransitionsTheme: PageTransitionsTheme(builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              }),
              appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.white,
                  elevation: 1,
                  iconTheme: IconThemeData(color: CommonColors.color_333333),
                  titleTextStyle:
                      TextStyle(fontSize: 16, color: CommonColors.color_333333),
                  systemOverlayStyle: SystemUiOverlayStyle.dark),
              useMaterial3: false),
          routes: IMKitRouter.instance.routes,
          home: child,
        );
      },
      child: SplashPage(
        deviceToken: _deviceToken,
      ),
    );
  }
}
