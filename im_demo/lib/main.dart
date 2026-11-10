// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:foldable/foldable.dart';
import 'package:im_demo/l10n/S.dart';
import 'package:im_demo/src/home/splash_page.dart';
import 'package:im_demo/src/duo/duo_shell_overlay.dart';
import 'package:im_demo/src/mine/user_info_page.dart';
import 'package:netease_callkit_ui/ne_callkit_ui.dart';
import 'package:netease_common_ui/base/default_language.dart';
import 'package:netease_common_ui/common_ui.dart';
import 'package:netease_common_ui/duo/duo_modal_route_observer.dart';
import 'package:netease_common_ui/duo/duo_page_route.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/repo/config_repo.dart';
import 'package:nim_chatkit/router/imkit_router.dart';
import 'package:nim_chatkit/router/imkit_router_constants.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:nim_chatkit_callkit/nim_chatkit_callkit.dart';
// import 'package:nim_chatkit_location/chat_kit_location.dart';
import 'package:nim_chatkit_sticker/nim_chatkit_sticker.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/helper/duo_layout.dart';
import 'package:nim_chatkit_ui/helper/monotonic_scroll_behavior.dart';
import 'package:nim_contactkit_ui/contact_kit_client.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:nim_searchkit_ui/search_kit_client.dart';
import 'package:nim_teamkit_ui/team_kit_client.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

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
    StickerKitClient.init();
    TeamKitClient.init();
    ConversationKitClient.init();
    ContactKitClient.init();
    SearchKitClient.init();

    IMKitRouter.instance.registerRouter(
      RouterConstants.PATH_MINE_INFO_PAGE,
      (context) => UserInfoPage(),
    );

    // 注册桌面/Web 端用户信息页面 Builder，供 gotoMineInfoPage 以 Dialog 形式弹出
    setDesktopUserInfoBuilder(() => const UserInfoPage());
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

  AppLifecycleListener? _appLifecycleListener;

  bool _hasReleasedAlog = false;

  ///设置默认的语言，不设置则根据系统语言
  void _setDefaultLanguage() async {
    CommonUIDefaultLanguage.commonDefaultLanguage =
        await ConfigRepo.getLanguage();
  }

  @override
  void initState() {
    super.initState();
    _setDefaultLanguage();
    _initPlugins();
    _initAIUser();
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows)) {
      _appLifecycleListener = AppLifecycleListener(
        onExitRequested: _handleExitRequested,
      );
    }
    GestureBinding.instance.resamplingEnabled = true;
  }

  Future<AppExitResponse> _handleExitRequested() async {
    final released = await _releaseIMSDK();
    return released ? AppExitResponse.exit : AppExitResponse.cancel;
  }

  Future<bool> _releaseIMSDK() async {
    try {
      await _releaseCallKit();
      final shouldReleaseAlog = NimCore.instance.isInitialized;
      if (shouldReleaseAlog) {
        final result = await NimCore.instance.releaseDesktop();
        if (!result.isSuccess) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _releaseCallKit() async {
    try {
      await NECallEngine.instance.destroy();
    } catch (_) {}
  }

  @override
  void dispose() {
    _appLifecycleListener?.dispose();
    super.dispose();
  }

  Widget _buildMaterialApp(Widget home) {
    return MaterialApp(
        navigatorKey: ChatUIToast.navigatorKey,
        // 开启指针事件重采样后，iOS 速度采样可能收到时间戳倒序的事件，
        // 默认的速度跟踪器会因此触发断言；这里使用容错的滚动行为。
        scrollBehavior: const MonotonicScrollBehavior(),
        builder: (context, child) =>
            DuoShellOverlay(child: child ?? const SizedBox.shrink()),
        onGenerateTitle: (BuildContext context) => S.of(context).appName,
        localizationsDelegates: [
          S.delegate,
          CommonUILocalizations.delegate,
          ConversationKitClient.delegate,
          ChatKitClient.delegate,
          StickerKitClient.delegate,
          ContactKitClient.delegate,
          TeamKitClient.delegate,
          SearchKitClient.delegate,
          ChatKitCall.delegate,
          NECallKitUI.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        navigatorObservers: [
          IMKitRouter.instance.routeObserver,
          NECallKitUI.navigatorObserver,
          // Duo 工具栏位于 Navigator 之上，弹框展示时需要跟随遮罩一起禁用。
          DuoModalRouteObserver.instance,
        ],
        supportedLocales: IMKitClient.supportedLocales,
        theme: ThemeData(
          primaryColor: CommonColors.color_337eff,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 1,
            iconTheme: IconThemeData(color: CommonColors.color_333333),
            titleTextStyle: TextStyle(
              fontSize: 16,
              color: CommonColors.color_333333,
            ),
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
          useMaterial3: false,
        ),
        onGenerateRoute: (settings) {
          final builder = IMKitRouter.instance.routes[settings.name];
          if (builder == null) return null;
          return DuoPageRoute(builder: builder, settings: settings);
        },
        home: home,
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = View.maybeOf(context) ??
        WidgetsBinding.instance.platformDispatcher.views.first;
    // FoldableProvider 需要位于 MediaQuery 之下读取窗口尺寸，并位于 MaterialApp 之上，
    // 让所有路由都能读取 iPhone Duo 的折叠状态。非折叠设备上始终为 unsupported，不影响原有布局。
    return MediaQuery.fromView(
      view: view,
      child: FoldableProvider(
        bridgeMode: DisplayFeatureBridgeMode.none,
        child: Builder(builder: _buildApp),
      ),
    );
  }

  Widget _buildApp(BuildContext context) {
    final home = SplashPage();

    // 桌面端/Web 不使用 ScreenUtil 缩放，避免基于移动端设计尺寸的缩放导致 UI 异常
    if (ChatKitUtils.isDesktopOrWeb) {
      return _buildMaterialApp(home);
    }

    // iPhone Duo 展开为双屏时窗口接近平板尺寸，按 1:1 缩放，避免 ScreenUtil 放大 UI；
    // 折叠态仍保持移动端原有的 375 设计尺寸缩放，其他单屏 iPhone 不受影响。
    final bool duoExpanded = DuoLayout.isExpanded(context);
    // FIXME(duo-simulator): 折叠态预览开关下窗口仍是内屏尺寸，按窗口 1:1 缩放便于截图验证。
    final bool useWindowDesignSize = duoExpanded || DuoLayout.previewFolded;
    return ScreenUtilInit(
      designSize: useWindowDesignSize
          ? MediaQuery.sizeOf(context)
          : const Size(375, 812),
      minTextAdapt: true,
      useInheritedMediaQuery: true,
      builder: (context, child) {
        return _buildMaterialApp(child!);
      },
      child: home,
    );
  }
}
