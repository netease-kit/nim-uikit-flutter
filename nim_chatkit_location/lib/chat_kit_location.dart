// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_corekit/report/xkit_report.dart';
import 'package:netease_plugin_core_kit/netease_plugin_core_kit.dart';
import 'package:nim_chatkit/location.dart';
import 'package:nim_chatkit_location/location_map_page.dart';
import 'package:nim_core/nim_core.dart' as nim;
import 'package:permission_handler/permission_handler.dart';

import 'chat_kit_message_location_item.dart';
import 'l10n/S.dart';

class ChatKitLocation {
  static const String kPackage = 'nim_chatkit_location';

  static const String _kVersion = '9.7.3';

  static const String _kName = 'ChatKitLocation';

  final String locationMessageType = 'location';

  ///高德地图Android 端的key
  ///如果要使用默认的地图消息，必须设置
  String? aMapAndroidKey;

  ///高德地图iOS端的key
  String? aMapIOSKey;

  ///高德地图Web服务端端的key
  String? aMapWebKey;

  Map<String, dynamic>? pushPayload;

  ChatKitLocation._();

  static final ChatKitLocation instance = ChatKitLocation._();

  void init(
      {required String aMapAndroidKey,
      required String aMapIOSKey,
      required String aMapWebKey,
      Map<String, dynamic>? pushPayload}) {
    this.pushPayload = pushPayload;

    ///埋点上报
    XKitReporter().register(moduleName: _kName, moduleVersion: _kVersion);

    ///注册位置消息入口
    NimPluginCoreKit().itemPool.registerMoreAction(MessageInputAction(
        type: 'location',
        icon: SvgPicture.asset(
          'images/ic_location.svg',
          package: kPackage,
        ),
        title: S.of().locationTitle,
        permissions: [Permission.locationWhenInUse],
        onTap: (context, sessionId, sessionType, {messageSender}) {
          ///去位置消息页面
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return LocationMapPage(
              needLocate: true,
              showOpenMap: false,
            );
          })).then((location) {
            if (location != null && location is LocationInfo) {
              ///构建位置消息
              nim.MessageBuilder.createLocationMessage(
                      sessionId: sessionId,
                      sessionType: sessionType,
                      latitude: location.latitude,
                      longitude: location.longitude,
                      address: location.address ?? '')
                  .then((ret) {
                if (ret.isSuccess && ret.data != null) {
                  ret.data!.content = location.name;

                  ///发送位置消息
                  messageSender?.call(ret.data!);
                }
              });
            }
          });
        },
        deniedTip: S.of().locationDeniedTips));

    ///注册位置消息解析
    NimPluginCoreKit().messageBuilderPool.registerMessageTypeDecoder(
        nim.NIMMessageType.location, (message) => locationMessageType);

    ///注册位置消息构建
    NimPluginCoreKit().messageBuilderPool.registerMessageContentBuilder(
        locationMessageType,
        (context, message) => ChatKitMessageLocationItem(
              message: message,
            ));

    ///初始化高德地图
    initLocationMap(
        aMapAndroidKey: aMapAndroidKey,
        aMapIOSKey: aMapIOSKey,
        aMapWebKey: aMapWebKey);
  }

  ///初始化高德地图
  void initLocationMap(
      {required String aMapAndroidKey,
      required String aMapIOSKey,
      required String aMapWebKey}) {
    //初始化定位组件
    ChatKitLocation.instance.aMapAndroidKey = aMapAndroidKey;
    ChatKitLocation.instance.aMapIOSKey = aMapIOSKey;
    ChatKitLocation.instance.aMapWebKey = aMapWebKey;
    //高德地图合规设置，并初始化地图
    //由于个人信息保护法的实施，请务必确保调用SDK任何接口前先调用更新隐私合规updatePrivacyShow、updatePrivacyAgree两个接口
    AMapFlutterLocation.updatePrivacyAgree(true);
    AMapFlutterLocation.updatePrivacyShow(true, true);
    AMapFlutterLocation.setApiKey(aMapAndroidKey, aMapIOSKey);
  }
}
