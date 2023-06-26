// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:im_demo/src/home/home_page.dart';
import 'package:netease_corekit_im/router/imkit_router.dart';
import 'package:netease_corekit_im/router/imkit_router_constants.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:netease_common_ui/common_ui.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_contactkit_ui/contact_kit_client.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:netease_corekit_im/im_kit_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:im_demo/l10n/S.dart';
import 'package:im_demo/src/home/splash_page.dart';
import 'package:im_demo/src/mine/user_info_page.dart';
import 'package:provider/provider.dart';
import 'package:nim_searchkit_ui/search_kit_client.dart';
import 'package:nim_teamkit_ui/team_kit_client.dart';
import 'package:yunxin_alog/yunxin_alog.dart';
import 'dart:io';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ///init all plugin here
  void _initPlugins() {
    Alog.init(ALogLevel.verbose, '', 'logReport');
    ChatKitClient.init();
    TeamKitClient.init();
    ConversationKitClient.init();
    ContactKitClient.init();
    SearchKitClient.init();

    IMKitRouter.instance.registerRouter(
        RouterConstants.PATH_MINE_INFO_PAGE, (context) => UserInfoPage());
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

  @override
  void initState() {
    super.initState();
    _updateTokenIOS();
    _initPlugins();
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
            ...GlobalMaterialLocalizations.delegates,
          ],
          navigatorObservers: [IMKitRouter.instance.routeObserver],
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
          ),
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
