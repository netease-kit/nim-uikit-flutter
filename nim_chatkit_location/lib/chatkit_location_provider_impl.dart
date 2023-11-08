// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_corekit_im/router/imkit_router_constants.dart';
import 'package:nim_chatkit/chatkit_location_provider.dart';
import 'package:nim_chatkit/location.dart';
import 'package:nim_core/nim_core.dart';

import 'chat_kit_location.dart';
import 'chat_kit_message_location_item.dart';

class ChatKitLocationProviderImpl extends ChatKitLocationProvider {
  ChatKitLocationProviderImpl._();

  static ChatKitLocationProviderImpl instance = ChatKitLocationProviderImpl._();

  @override
  Widget buildLocationItem(NIMMessage message) {
    return ChatKitMessageLocationItem(message: message);
  }

  @override
  Future<T?> goToLocationMapPage<T extends Object?>(BuildContext context,
      {LocationInfo? locationInfo,
      bool needLocate = false,
      bool showOpenMap = false}) {
    return Navigator.pushNamed(context, RouterConstants.pathChatLocationPage,
        arguments: {
          'locationInfo': locationInfo,
          'needLocate': needLocate,
          'showOpenMap': showOpenMap
        });
  }

  @override
  void initLocationMap(
      {String? aMapAndroidKey, String? aMapIOSKey, String? aMapWebKey}) {
    //初始化定位组件
    ChatKitLocation.instance.aMapAndroidKey = aMapAndroidKey;
    ChatKitLocation.instance.aMapIOSKey = aMapIOSKey;
    ChatKitLocation.instance.aMapWebKey = aMapWebKey;
    ChatKitLocation.instance.init();
    //高德地图合规设置，并初始化地图
    if (aMapAndroidKey?.isNotEmpty == true && aMapIOSKey?.isNotEmpty == true) {
      //由于个人信息保护法的实施，请务必确保调用SDK任何接口前先调用更新隐私合规updatePrivacyShow、updatePrivacyAgree两个接口
      AMapFlutterLocation.updatePrivacyAgree(true);
      AMapFlutterLocation.updatePrivacyShow(true, true);
      AMapFlutterLocation.setApiKey(aMapAndroidKey!, aMapIOSKey!);
    } else {
      Fluttertoast.showToast(msg: 'aMapAndroidKey or aMapIOSKey is null');
    }
  }
}
