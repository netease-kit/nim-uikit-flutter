// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:netease_corekit_im/repo/config_repo.dart';
import 'package:nim_core/nim_core.dart';
import 'package:path_provider/path_provider.dart';

class IMDemoConfig {
  //云信IM appKey
  static const AppKey = 'your app key';

  //高德Android Key
  static const AMapAndroid = 'your amap android key';

  //高德IOS Key
  static const AMapIOS = 'your amap ios key';
}

class NIMSDKOptionsConfig {
  static Future<NIMSDKOptions?> getSDKOptions(String appKey,
      {NIMLoginInfo? loginInfo}) async {
    NIMSDKOptions? options;
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      NIMStatusBarNotificationConfig config = loadStatusBarNotificationConfig();
      options = NIMAndroidSDKOptions(
        appKey: appKey,
        shouldSyncStickTopSessionInfos: true,
        enableTeamMessageReadReceipt: true,
        autoLoginInfo: loginInfo,
        enableFcs: false,
        sdkRootDir: directory != null ? '${directory.path}/NIMFlutter' : null,
        notificationConfig: config,
        preLoadServers: true,
        shouldConsiderRevokedMessageUnreadCount: true,
        shouldSyncUnreadCount: true,
        enablePreloadMessageAttachment: true,
        mixPushConfig: _buildMixPushConfig(),
      );
      ConfigRepo.saveStatusBarNotificationConfig(config, saveToNative: false);
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      options = NIMIOSSDKOptions(
        appKey: appKey,
        shouldSyncStickTopSessionInfos: true,
        enableTeamMessageReadReceipt: true,
        autoLoginInfo: loginInfo,
        sdkRootDir: '${directory.path}/NIMFlutter',
        apnsCername: 'dis_im_flutter',
        pkCername: '',
        shouldConsiderRevokedMessageUnreadCount: true,
        shouldSyncUnreadCount: true,
        enableTeamReceipt: true,
        enablePreloadMessageAttachment: true,
      );
    }
    return options;
  }

  static NIMStatusBarNotificationConfig loadStatusBarNotificationConfig() {
    //todo 设置Android通知栏点击跳转类
    return NIMStatusBarNotificationConfig(
        notificationEntranceClassName:
            'com.netease.yunxin.app.flutter.im.MainActivity',
        notificationExtraType: NIMNotificationExtraType.jsonArrStr);
  }

  static NIMMixPushConfig? _buildMixPushConfig() {
    //todo Android推送配置，请这是自己的信息
    return NIMMixPushConfig(
      // xiaomi
      xmAppId: 'xmAppId',
      xmAppKey: 'xmAppKey',
      xmCertificateName: 'xmCertificateName',
      // huawei
      hwAppId: 'hwAppId',
      hwCertificateName: 'hwCertificateName',
      // meizu
      mzAppId: 'mzAppId',
      mzAppKey: 'mzAppKey',
      mzCertificateName: 'mzCertificateName',
      // fcm
      // fcmCertificateName: 'DEMO_FCM_PUSH',
      // vivo
      vivoCertificateName: 'vivoCertificateName',
      // oppo
      oppoAppId: 'oppoAppId',
      oppoAppKey: 'oppoAppKey',
      oppoAppSecret: 'oppoAppSecret',
      oppoCertificateName: 'oppoCertificateName',
    );
  }
}
