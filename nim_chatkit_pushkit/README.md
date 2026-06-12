# NIM ChatKit PushKit

完整中文接入指南见 [README_CN.md](README_CN.md)。

PushKit 将推送通知点击桥接能力从 `im_demo` 中拆出，封装为可复用的
Flutter 插件。业务应用通常只需要在 Dart 侧处理点击后的路由跳转。
Android 的 Gradle/Manifest 配置，以及 iOS 的推送能力和证书配置，仍需要
按照各厂商推送平台要求完成。

## 支持范围

首个版本支持：

- Android 和 iOS。
- Android 厂商推送：小米、华为、魅族、vivo、OPPO、FCM。
- NIM 默认推送 payload 构造器，支持 `sessionId` 和 `sessionType`。
- iOS APNS token 上传由 `nim_core_v2` 处理；PushKit 不会调用
  `updateApnsToken`。

## Dart 接入

添加依赖：

```yaml
dependencies:
  nim_chatkit_pushkit: ^10.8.0
```

在应用壳层初始化 PushKit，并处理推送点击路由：

```dart
await PushKit.instance.init(
  onClick: (message) {
    if (message.sessionType == 'p2p') {
      // 跳转到你的单聊页面。
    } else if (message.sessionType == 'team') {
      // 跳转到你的群聊页面。
    }
  },
);

final initial = await PushKit.instance.getInitialNotification();
if (initial != null) {
  // 处理冷启动时的推送点击。
}
```

使用默认的 NIM 推送 payload 构造器：

```dart
ChatKitClient.instance.chatUIConfig.getPushPayload =
    PushKit.instance.buildDefaultPushPayload;
```

使用 PushKit 构造 Android 状态栏通知配置：

```dart
final notificationConfig =
    await PushKit.instance.buildDefaultAndroidNotificationConfig();

final options = NIMAndroidSDKOptions(
  appKey: appKey,
  notificationConfig: notificationConfig,
  mixPushConfig: mixPushConfig,
);
```

如果你的应用已经加载并持久化了 `NIMStatusBarNotificationConfig`，可以通过
`baseConfig` 传入已有配置。

## Android Gradle 配置

在项目级 Gradle 文件中添加 Maven 仓库：

```gradle
buildscript {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://developer.huawei.com/repo/' }
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

如果使用华为推送，应用模块需要接入 AGConnect 插件：

```gradle
buildscript {
    dependencies {
        classpath 'com.huawei.agconnect:agcp:1.6.5.300'
    }
}
```

```gradle
apply plugin: 'com.huawei.agconnect'
```

添加厂商推送 SDK 依赖：

```gradle
dependencies {
    // 华为和魅族可通过 Maven 获取。
    implementation 'com.huawei.hms:push:6.10.0.300'
    implementation 'com.meizu.flyme.internet:push-internal:4.1.0'

    // 如果你的项目有小米/OPPO/vivo 的 Maven 坐标，优先使用 Maven。
    // 否则将厂商 jar/aar 放到 android/app/libs 下，并保留：
    implementation fileTree(dir: 'libs', include: ['*.jar', '*.aar'])
}
```

业务应用可以在自己的 Gradle 文件中覆盖依赖版本。PushKit 对 OPPO/vivo
初始化使用反射，因此应用只需要集成实际启用的厂商 SDK。

## Android Manifest 配置

你的 launcher Activity 必须设置为 exported、singleTop，并接收 PushKit
action：

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

根据实际启用的厂商 SDK 添加对应 receiver/service。Demo 应用中保留了小米、
华为、魅族、vivo 和 OPPO 的完整示例。vivo metadata 需要替换为你自己的值：

```xml
<meta-data
    android:name="com.vivo.push.api_key"
    android:value="${vivoPushApiKey}" />
<meta-data
    android:name="com.vivo.push.app_id"
    android:value="${vivoPushAppId}" />
```

当 targetSdk >= 33 时，需要添加 Android 13 通知权限：

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

## Android 混合推送配置

将你的厂商证书名和 app key 传给 NIM SDK：

```dart
final mixPushConfig = NIMMixPushConfig(
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
```

## iOS 接入

在 Xcode 中开启 Push Notifications，以及 Background Modes >
Remote notifications。

初始化 PushKit：

```dart
await PushKit.instance.init();
```

PushKit 会请求通知权限，并调用 `registerForRemoteNotifications()`。
`nim_core_v2` 会监听 APNS token，并自动更新到 NIM SDK。

在 `NIMIOSSDKOptions` 中配置 APNS 证书名：

```dart
final options = NIMIOSSDKOptions(
  appKey: appKey,
  apnsCername: 'your-apns-certificate',
  pkCername: 'your-pushkit-certificate',
);
```

如果你的应用或其他插件接管了 `UNUserNotificationCenter.delegate`，需要将
`userNotificationCenter(_:didReceive:withCompletionHandler:)` 转发给
Flutter 的 `FlutterAppDelegate`，或通过一个小型原生桥接手动调用 Dart 路由。

## 自定义 Payload

如果你的服务端 payload 没有使用 `sessionId` 和 `sessionType`，可以注册自定义
解析器：

```dart
await PushKit.instance.init(
  config: PushKitConfig(
    customParsers: [
      (payload) {
        final chat = payload['chat'];
        if (chat is! Map) return null;
        return PushKitMessage(
          sessionId: chat['id']?.toString(),
          sessionType: chat['type']?.toString(),
          rawPayload: payload,
          source: PushKitSource.custom,
        );
      },
    ],
  ),
);
```

## 原生代码扩展

大多数应用不需要编写 Kotlin 或 Swift。只有以下场景通常需要原生代码：

- 厂商 SDK 要求自定义 Application/AppDelegate 处理。
- 其他插件接管了 `UNUserNotificationCenter.delegate`。
- 应用使用了非标准 Android Activity 栈。
- 需要自定义通知点击 action。

当使用自定义 Android 点击 action 时，需要将同一个值传给 PushKit：

```dart
await PushKit.instance.init(
  config: const PushKitConfig(
    androidPushAction: 'com.example.myapp.CUSTOM_PUSH',
  ),
);
```
