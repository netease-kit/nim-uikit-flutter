// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:im_demo/generated/l10n.dart';
import 'package:im_demo/src/home/splash_page.dart';
import 'package:im_demo/src/mine/user_info_page.dart';
import 'package:netease_common_ui/common_ui.dart';
import 'package:netease_common_ui/router/imkit_router.dart';
import 'package:netease_common_ui/router/imkit_router_constants.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_corekit_im/im_kit_client.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_contactkit_ui/contact_kit_client.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_searchkit_ui/search_kit_client.dart';
import 'package:nim_teamkit_ui/team_kit_client.dart';
import 'package:provider/provider.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  ///init all plugin here
  void initPlugins() {
    ChatKitClient.init();
    TeamKitClient.init();
    ConversationKitClient.init();
    ContactKitClient.init();
    SearchKitClient.init();

    IMKitRouter.instance.registerRouter(
        RouterConstants.PATH_MINE_INFO_PAGE, (context) => UserInfoPage());
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    initPlugins();
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
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
      child: const SplashPage(),
    );
  }
}
