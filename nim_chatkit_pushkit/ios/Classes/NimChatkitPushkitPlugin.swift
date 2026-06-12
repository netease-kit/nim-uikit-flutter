// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Flutter
import UIKit
import UserNotifications

private let channelName = "nim_chatkit_pushkit"
private let methodInitialize = "initialize"
private let methodGetInitialNotification = "getInitialNotification"
private let methodGetEntranceClassName = "getAndroidNotificationEntranceClassName"
private let methodGetPushAction = "getAndroidPushAction"
private let methodOnNotificationClick = "onNotificationClick"
private let sessionIdKey = "sessionId"
private let sessionTypeKey = "sessionType"
private let sourceKey = "source"
private let rawPayloadKey = "rawPayload"

public class NimChatkitPushkitPlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel?
  private var initialNotification: [String: Any?]?
  private var initialized = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = NimChatkitPushkitPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case methodInitialize:
      initialized = true
      if let arguments = call.arguments as? [String: Any],
         (arguments["registerIOSRemoteNotifications"] as? Bool) != false {
        registerRemoteNotifications()
      }
      result(nil)
    case methodGetInitialNotification:
      result(initialNotification ?? [:])
      initialNotification = nil
    case methodGetEntranceClassName:
      result(nil)
    case methodGetPushAction:
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func registerRemoteNotifications() {
    DispatchQueue.main.async {
      let center = UNUserNotificationCenter.current()
      center.requestAuthorization(options: [.badge, .sound, .alert]) { _, _ in
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
          UIApplication.shared.applicationIconBadgeNumber = 0
        }
      }
    }
  }

  private func handleNotificationPayload(_ userInfo: [AnyHashable: Any]) {
    let rawPayload = normalizeDictionary(userInfo)
    guard let message = buildMessage(rawPayload) else {
      return
    }
    if initialized {
      channel?.invokeMethod(methodOnNotificationClick, arguments: message)
    } else {
      initialNotification = message
    }
  }

  private func buildMessage(_ payload: [String: Any?]) -> [String: Any?]? {
    guard let sessionId = payload[sessionIdKey] as? String,
          let sessionType = normalizeSessionType(payload[sessionTypeKey]) else {
      return nil
    }
    return [
      sessionIdKey: sessionId,
      sessionTypeKey: sessionType,
      sourceKey: "iosApns",
      rawPayloadKey: payload,
    ]
  }

  private func normalizeSessionType(_ value: Any?) -> String? {
    if let value = value as? String {
      if value == "0" || value.lowercased() == "p2p" {
        return "p2p"
      }
      if value == "1" || value == "2" || value.lowercased() == "team" {
        return "team"
      }
      return value
    }
    if let value = value as? NSNumber {
      return value.intValue == 0 ? "p2p" : "team"
    }
    return nil
  }

  private func normalizeDictionary(_ dictionary: [AnyHashable: Any]) -> [String: Any?] {
    var result: [String: Any?] = [:]
    dictionary.forEach { key, value in
      result[String(describing: key)] = normalizeValue(value)
    }
    return result
  }

  private func normalizeValue(_ value: Any) -> Any? {
    if let dictionary = value as? [AnyHashable: Any] {
      return normalizeDictionary(dictionary)
    }
    if let array = value as? [Any] {
      return array.map { normalizeValue($0) }
    }
    return value
  }
}

public extension NimChatkitPushkitPlugin {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    if let response = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
      handleNotificationPayload(response)
    }
    return false
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    handleNotificationPayload(response.notification.request.content.userInfo)
    completionHandler()
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    UIApplication.shared.applicationIconBadgeNumber = 0
  }
}
