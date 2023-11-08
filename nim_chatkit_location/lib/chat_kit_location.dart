// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_corekit_im/router/imkit_router.dart';
import 'package:netease_corekit/report/xkit_report.dart';
import 'package:netease_corekit_im/router/imkit_router_constants.dart';
import 'package:nim_chatkit/location.dart';
import 'package:nim_chatkit_location/location_map_page.dart';

class ChatKitLocation {
  static const String kPackage = 'nim_chatkit_location';

  static const String _kVersion = '1.0.0';

  static const String _kName = 'ChatKitLocation';

  ///高德地图Android 端的key
  ///如果要使用默认的地图消息，必须设置
  String? aMapAndroidKey;

  ///高德地图iOS端的key
  String? aMapIOSKey;

  ///高德地图Web服务端端的key
  String? aMapWebKey;

  ChatKitLocation._() {
    init();
  }

  static final ChatKitLocation instance = ChatKitLocation._();

  void init() {
    IMKitRouter.instance.registerRouter(
        RouterConstants.pathChatLocationPage,
        (context) => LocationMapPage(
              locationInfo: IMKitRouter.getArgumentFormMap<LocationInfo>(
                  context, 'locationInfo'),
              needLocate:
                  IMKitRouter.getArgumentFormMap<bool>(context, 'needLocate') ??
                      false,
              showOpenMap: IMKitRouter.getArgumentFormMap<bool>(
                      context, 'showOpenMap') ??
                  false,
            ));

    XKitReporter().register(moduleName: _kName, moduleVersion: _kVersion);
  }
}
