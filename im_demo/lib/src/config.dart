// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:nim_chatkit/repo/config_repo.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yunxin_alog/yunxin_alog.dart';
import 'package:nim_chatkit/im_kit_client.dart';

class IMDemoConfig {
  //云信IM appKey
  static const AppKey = '3e215d27b6a6a9e27dad7ef36dd5b65c';

  //高德Android Key
  static const AMapAndroid = 'ff1b6763d4cc688d9cc3670ad5363a3a';

  //高德IOS Key
  static const AMapIOS = '42a4c444bb7090955b6dd03e20848710';

  //高德Web服务端 Key，用于生成静态图
  static const AMapWeb = '378d41cccf6b1253672ff69393ad70da';
}

class NIMSDKOptionsConfig {
  static Future<NIMSDKOptions?> getSDKOptions(String appKey,
      {NIMLoginInfo? loginInfo}) async {
    NIMSDKOptions? options;
    final enableCloudConversation = await IMKitClient.enableCloudConversation;
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      NIMStatusBarNotificationConfig config =
          await loadStatusBarNotificationConfig();
      options = NIMAndroidSDKOptions(
        appKey: appKey,
        shouldSyncStickTopSessionInfos: true,
        enableTeamMessageReadReceipt: true,
        enableFcs: false,
        sdkRootDir: directory != null ? '${directory.path}/NIMFlutter' : null,
        notificationConfig: config,
        preLoadServers: true,
        shouldConsiderRevokedMessageUnreadCount: true,
        shouldSyncUnreadCount: true,
        enablePreloadMessageAttachment: true,
        enableV2CloudConversation: enableCloudConversation,
        mixPushConfig: _buildMixPushConfig(),
      );
      ConfigRepo.saveStatusBarNotificationConfig(config, saveToNative: false);
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      options = NIMIOSSDKOptions(
        appKey: appKey,
        shouldSyncStickTopSessionInfos: true,
        enableTeamMessageReadReceipt: true,
        sdkRootDir: '${directory.path}/NIMFlutter',
        apnsCername: 'dis_im_flutter',
        pkCername: '',
        shouldConsiderRevokedMessageUnreadCount: true,
        shouldSyncUnreadCount: true,
        enableTeamReceipt: true,
        enablePreloadMessageAttachment: true,
        enableV2CloudConversation: enableCloudConversation,
      );
    }
    return options;
  }

  static Future<NIMStatusBarNotificationConfig>
      loadStatusBarNotificationConfig() async {
    final config = await ConfigRepo.getStatusBarNotificationConfig();
    if (config == null) {
      return NIMStatusBarNotificationConfig(
          notificationEntranceClassName:
              'com.netease.yunxin.app.flutter.im.MainActivity',
          notificationExtraType: NIMNotificationExtraType.jsonArrStr);
    } else {
      config.notificationEntranceClassName =
          'com.netease.yunxin.app.flutter.im.MainActivity';
      config.notificationExtraType = NIMNotificationExtraType.jsonArrStr;
      return config;
    }
  }

  static NIMMixPushConfig? _buildMixPushConfig() {
    return NIMMixPushConfig(
      // xiaomi
      xmAppId: '2882303761520055541',
      xmAppKey: '5222005592541',
      xmCertificateName: 'KIT_FLUTTER_MI_PUSH',
      // huawei
      hwAppId: '106776305',
      hwCertificateName: 'KIT_FLUTTER_HW_PUSH',
      // meizu
      mzAppId: '149497',
      mzAppKey: '59aea173afc94791ad271f7d51e4bded',
      mzCertificateName: 'KIT_FLUTTER_MEIZU_PUSH',
      // fcm
      // fcmCertificateName: 'DEMO_FCM_PUSH',
      // vivo
      vivoCertificateName: 'KIT_FLUTTER_VIVO_PUSH',
      // oppo
      oppoAppId: '30853511',
      oppoAppKey: 'b2fe114b4f744f0ca6855731d18a2d54',
      oppoAppSecret: 'dc093c8c4d154722a75cc3a69af73ce9',
      oppoCertificateName: 'KIT_FLUTTER_OPPO_PUSH',
    );
  }
}

///获取当前环境, true: 测试环境，false: 正式环境
///todo 发布前删除，此方法不对外
Future<bool> isDebugModel() async {
  bool isDebug = false;
  try {
    var value = await rootBundle.loadString('assets/config.properties');
    var list = value.split('\n');
    Alog.i(tag: 'isDebugModel', content: 'list: $list');
    for (var element in list) {
      if (element.contains('=')) {
        var key = element.substring(0, element.indexOf('='));
        var value = element.substring(element.indexOf('=') + 1);
        if (key == 'ENV') {
          isDebug = value != 'ONLINE';
        }
      }
    }
  } catch (e) {
    Alog.e(tag: 'isDebugModel', content: e.toString());
  }
  return isDebug;
}
