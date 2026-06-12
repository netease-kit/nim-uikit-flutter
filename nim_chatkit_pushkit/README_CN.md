# NIM ChatKit PushKit 接入文档

`nim_chatkit_pushkit` 用于补齐 IM UIKit 在移动端的推送点击链路。它负责把
Android 状态栏通知、Android 厂商离线推送、iOS APNS 通知的点击事件统一转换成
`PushKitMessage`，业务层只需要根据会话类型和会话 ID 跳转到对应聊天页。

当前插件只支持 Android 和 iOS。桌面端和 Web 不需要接入。

## 一、接入前准备

接入前需要先完成以下准备：

- 已接入 `nim_chatkit`、`nim_chatkit_ui` 和 `nim_core_v2`。
- 已完成 NIM SDK 初始化和登录。
- 云信控制台已配置 Android 混合推送证书、iOS APNS 证书。
- Android 已按实际需要申请并配置厂商推送应用信息。
- iOS 已开启 Push Notifications 和 Background Modes > Remote notifications。

PushKit 不负责向云信控制台创建证书，也不替代厂商推送 SDK 的工程配置。

## 二、添加依赖

在业务 App 的 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  nim_chatkit_pushkit: ^10.8.0
```

如果是在本仓库 Demo 中联调，可以使用 path 依赖：

```yaml
dependencies:
  nim_chatkit_pushkit:
    path: ../nim_chatkit_pushkit
```

执行：

```bash
flutter pub get
```

## 三、Dart 侧接入

### 1. 初始化 PushKit

建议在应用壳层页面初始化，例如登录完成并进入首页后：

```dart
import 'dart:async';

import 'package:nim_chatkit_pushkit/nim_chatkit_pushkit.dart';

StreamSubscription<PushKitMessage>? _pushClickSub;

Future<void> initPushKit() async {
  await PushKit.instance.init();

  _pushClickSub = PushKit.instance.onNotificationClick.listen((message) {
    dispatchPushMessage(message);
  });

  final initialMessage = await PushKit.instance.getInitialNotification();
  dispatchPushMessage(initialMessage);
}

void disposePushKit() {
  _pushClickSub?.cancel();
}
```

`onNotificationClick` 用于处理 App 已启动时的通知点击。
`getInitialNotification()` 用于处理冷启动场景，即 App 被通知点击拉起后获取首个点击事件。

### 2. 根据点击事件跳转聊天页

`PushKitMessage.sessionType` 内置取值：

- `p2p`：单聊。
- `team`：群聊。

`PushKitMessage.sessionId` 表示目标会话 ID：

- 单聊时为对方账号 ID。
- 群聊时为群 ID。

示例：

```dart
void dispatchPushMessage(PushKitMessage? message) {
  final sessionType = message?.sessionType;
  final sessionId = message?.sessionId;
  if (sessionType == null || sessionId == null || sessionId.isEmpty) {
    return;
  }

  if (sessionType == 'p2p') {
    goToP2pChat(context, sessionId);
  } else if (sessionType == 'team') {
    goToTeamChat(context, sessionId);
  }
}
```

在 IM UIKit 中，Demo 使用 `goToP2pChat` 和 `goToTeamChat` 进入聊天页。业务应用如果
有自定义路由，可以在这里替换为自己的页面跳转逻辑。

### 3. 配置默认推送 Payload

发送消息时，需要让消息的推送 payload 携带 PushKit 可解析的会话信息：

```dart
ChatKitClient.instance.chatUIConfig.getPushPayload =
    PushKit.instance.buildDefaultPushPayload;
```

默认 payload 会写入以下关键字段：

- `sessionId`：单聊对方账号 ID 或群 ID。
- `sessionType`：`p2p` 或 `team`。
- `senderId`：发送方账号 ID。
- `conversationId`：NIM conversation ID。

其中 `senderId` 和 `conversationId` 会用于修正单聊点击场景，避免 iOS/Android 在某些
payload 中只拿到当前登录账号导致跳转到自己的会话。

## 四、Android 接入

### 1. SDK Options 中配置状态栏通知

初始化 NIM Android SDK 时，需要把 PushKit 生成的通知配置传给
`NIMAndroidSDKOptions.notificationConfig`：

```dart
NIMStatusBarNotificationConfig config =
    await loadStatusBarNotificationConfig();

config = await PushKit.instance.buildDefaultAndroidNotificationConfig(
  baseConfig: config,
);

final options = NIMAndroidSDKOptions(
  appKey: appKey,
  notificationConfig: config,
  mixPushConfig: buildMixPushConfig(),
);
```

`buildDefaultAndroidNotificationConfig` 会设置：

- `notificationEntranceClassName`：通知点击入口 Activity。
- `notificationExtraType`：`NIMNotificationExtraType.jsonArrStr`。

如果业务已有自定义通知配置，使用 `baseConfig` 传入即可，PushKit 只补充点击解析所需字段。

### 2. 配置混合推送参数

按实际使用的厂商填写 `NIMMixPushConfig`：

```dart
NIMMixPushConfig buildMixPushConfig() {
  return NIMMixPushConfig(
    xmAppId: 'your-xiaomi-app-id',
    xmAppKey: 'your-xiaomi-app-key',
    xmCertificateName: 'your-xiaomi-certificate',
    hwAppId: 'your-huawei-app-id',
    hwCertificateName: 'your-huawei-certificate',
    mzAppId: 'your-meizu-app-id',
    mzAppKey: 'your-meizu-app-key',
    mzCertificateName: 'your-meizu-certificate',
    vivoCertificateName: 'your-vivo-certificate',
    oppoAppId: 'your-oppo-app-id',
    oppoAppKey: 'your-oppo-app-key',
    oppoAppSecret: 'your-oppo-app-secret',
    oppoCertificateName: 'your-oppo-certificate',
    fcmCertificateName: 'your-fcm-certificate',
  );
}
```

证书名必须和云信控制台中配置的证书名一致。

### 3. Gradle 仓库和依赖

项目级 `android/build.gradle` 需要包含 Maven 仓库：

```gradle
buildscript {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://developer.huawei.com/repo/' }
    }

    dependencies {
        classpath 'com.huawei.agconnect:agcp:1.6.5.300'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://developer.huawei.com/repo/' }
    }
}
```

应用模块 `android/app/build.gradle` 按需添加厂商 SDK：

```gradle
apply plugin: 'com.huawei.agconnect'

dependencies {
    implementation fileTree(dir: 'libs', include: ['*.jar', '*.aar'])
    implementation 'com.huawei.hms:push:6.10.0.300'
    implementation 'com.huawei.agconnect:agconnect-core:1.7.2.300'
    implementation 'com.meizu.flyme.internet:push-internal:4.1.0'
}
```

小米、OPPO、vivo 如果使用本地 `jar`/`aar`，放到 `android/app/libs` 并保留
`fileTree` 依赖。如果使用 Maven 坐标，按厂商官方文档接入。

### 4. AndroidManifest 配置

Launcher Activity 需要设置 `singleTop`，并接收默认点击 action：

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop">
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>

    <intent-filter>
        <action android:name="${applicationId}.push" />
        <category android:name="android.intent.category.DEFAULT" />
    </intent-filter>
</activity>
```

Android 13 及以上需要通知权限：

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

各厂商 receiver/service 需要按实际启用的推送通道配置。可以参考
`im_demo/android/app/src/main/AndroidManifest.xml` 中的小米、华为、魅族、vivo、OPPO
配置示例。

vivo 需要配置应用自己的 `api_key` 和 `app_id`：

```xml
<meta-data
    android:name="com.vivo.push.api_key"
    android:value="your-vivo-api-key" />
<meta-data
    android:name="com.vivo.push.app_id"
    android:value="your-vivo-app-id" />
```

华为需要开启自动初始化：

```xml
<meta-data
    android:name="push_kit_auto_init_enabled"
    android:value="true" />
```

### 5. 自定义 Android 点击 Action

默认 action 为：

```text
${applicationId}.push
```

如果业务需要使用自定义 action，需要 Dart 初始化和 Manifest 保持一致：

```dart
await PushKit.instance.init(
  config: const PushKitConfig(
    androidPushAction: 'com.example.app.CUSTOM_PUSH',
  ),
);
```

```xml
<intent-filter>
    <action android:name="com.example.app.CUSTOM_PUSH" />
    <category android:name="android.intent.category.DEFAULT" />
</intent-filter>
```

### 6. 自定义通知入口 Activity

默认入口为当前 Activity 或 launcher Activity。若业务使用特殊 Activity 栈，可显式指定：

```dart
await PushKit.instance.init(
  config: const PushKitConfig(
    androidNotificationEntranceClassName:
        'com.example.app.MainActivity',
  ),
);
```

## 五、iOS 接入

### 1. 开启系统能力

在 Xcode 的 Runner target 中开启：

- Signing & Capabilities > Push Notifications。
- Signing & Capabilities > Background Modes > Remote notifications。

同时确认 provisioning profile 包含 APNS 能力。

### 2. 配置 APNS 证书名

初始化 NIM iOS SDK 时配置 APNS 证书名：

```dart
final options = NIMIOSSDKOptions(
  appKey: appKey,
  apnsCername: 'your-apns-certificate',
  pkCername: 'your-pushkit-certificate',
);
```

`apnsCername` 必须和云信控制台中上传的 iOS APNS 证书名一致。

### 3. 初始化 PushKit

```dart
await PushKit.instance.init();
```

默认情况下，PushKit 会请求通知权限并调用
`UIApplication.shared.registerForRemoteNotifications()`。
APNS token 的上传由 `nim_core_v2` 处理，PushKit 不会直接调用 `updateApnsToken`。

如果业务已经自行处理 iOS 通知权限和 APNS 注册，可以关闭 PushKit 的自动注册：

```dart
await PushKit.instance.init(
  config: const PushKitConfig(
    registerIOSRemoteNotifications: false,
  ),
);
```

### 4. AppDelegate 注意事项

如果 AppDelegate 继承 `FlutterAppDelegate`，通常只需要正常注册插件：

```swift
GeneratedPluginRegistrant.register(with: self)
UNUserNotificationCenter.current().delegate = self
```

如果业务或其他插件接管了 `UNUserNotificationCenter.delegate`，需要确保通知点击回调仍能转发到
Flutter 插件链路，否则 PushKit 收不到 iOS 点击事件。重点关注：

```swift
userNotificationCenter(_:didReceive:withCompletionHandler:)
```

## 六、自定义 Payload 解析

如果业务服务端下发的 payload 不使用 `sessionId` 和 `sessionType`，可以通过
`customParsers` 注册自定义解析器：

```dart
await PushKit.instance.init(
  config: PushKitConfig(
    customParsers: [
      (payload) {
        final chat = payload['chat'];
        if (chat is! Map) {
          return null;
        }
        return PushKitMessage(
          sessionId: chat['id']?.toString(),
          sessionType: chat['type']?.toString(),
          conversationId: payload['conversationId']?.toString(),
          rawPayload: payload,
          source: PushKitSource.custom,
        );
      },
    ],
  ),
);
```

解析器按顺序执行，返回第一个非空 `PushKitMessage`。

## 七、推荐接入顺序

1. 添加 `nim_chatkit_pushkit` 依赖。
2. Android 配置厂商 SDK、Manifest、`NIMMixPushConfig`。
3. iOS 配置 APNS 能力和 `apnsCername`。
4. 在应用首页或登录后初始化 `PushKit.instance.init()`。
5. 设置 `ChatKitClient.instance.chatUIConfig.getPushPayload`。
6. 监听 `onNotificationClick` 和 `getInitialNotification()`。
7. Android 真机、iOS 真机分别验证在线通知点击和离线推送点击。

## 八、常见问题排查

### 1. Android 在线通知点击无响应

检查：

- `NIMStatusBarNotificationConfig.notificationExtraType` 是否为
  `NIMNotificationExtraType.jsonArrStr`。
- `notificationEntranceClassName` 是否是正确 Activity。
- Activity 是否配置 `android:launchMode="singleTop"`。
- 是否监听了 `PushKit.instance.onNotificationClick`。

### 2. Android 离线厂商推送点击无响应

检查：

- Manifest 中是否配置 `${applicationId}.push` intent-filter。
- 厂商推送 SDK 是否接入完整。
- `NIMMixPushConfig` 中证书名、AppId、AppKey 是否正确。
- 云信控制台证书名是否和客户端配置一致。
- Android 13 及以上是否已授予通知权限。

### 3. iOS 收到通知但点击无响应

检查：

- App 是否开启 Push Notifications 和 Remote notifications。
- `apnsCername` 是否正确。
- `UNUserNotificationCenter.current().delegate` 是否被其他对象覆盖。
- AppDelegate 是否继承 `FlutterAppDelegate` 或正确转发通知点击回调。

### 4. 点击后进入了错误的单聊对象

检查 payload 中是否包含：

- `sessionId`
- `sessionType`
- `senderId`
- `conversationId`

默认 `buildDefaultPushPayload` 已包含这些字段。单聊场景下，如果原始 `sessionId`
是当前登录账号，PushKit 会优先使用 `senderId` 或 `conversationId` 推导真正的聊天对象。

### 5. 只想 Android/iOS 接入，桌面端和 Web 不接入

业务层应只在移动端初始化 PushKit。可使用项目内已有平台判断工具，例如：

```dart
if (ChatKitUtils.isMobleClient) {
  await PushKit.instance.init();
}
```

桌面端和 Web 不需要设置 PushKit，也不会注册原生推送插件。
