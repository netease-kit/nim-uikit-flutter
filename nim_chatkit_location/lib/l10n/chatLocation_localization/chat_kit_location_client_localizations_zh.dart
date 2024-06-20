// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'chat_kit_location_client_localizations.dart';

/// The translations for Chinese (`zh`).
class ChatKitLocationClientLocalizationsZh
    extends ChatKitLocationClientLocalizations {
  ChatKitLocationClientLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get messageCancel => '取消';

  @override
  String get chatMessageSend => '发送';

  @override
  String get chatMessageAMapNotFound => '未检测到高德地图';

  @override
  String get chatMessageTencentMapNotFound => '未检测到腾讯地图';

  @override
  String get chatMessageAMap => '高德地图';

  @override
  String get chatMessageTencentMap => '腾讯地图';

  @override
  String get locationDeniedTips => '请在设置页面添加定位权限';

  @override
  String get locationTitle => '位置';
}
