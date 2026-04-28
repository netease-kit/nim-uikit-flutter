// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Flutter
import UIKit
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    var isForeground = false
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        LocalServerManager.instance.startServer()
        // 注册空方法，防止dart调用时报错找不到方法
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let methodChannel = FlutterMethodChannel(name: "com.netease.yunxin.app.flutter.im/channel",
                                                 binaryMessenger: controller.binaryMessenger)

        methodChannel.setMethodCallHandler{ (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "pushMessage" {
                let ret = [String: String]()
               result(ret)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        
        registerAPNS()
        GeneratedPluginRegistrant.register(with: self)
        UNUserNotificationCenter.current().delegate = self
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    
    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle the notification tap event here
        
        let content = response.notification.request.content

            // 获取推送信息
            if let userInfo = content.userInfo as? [String: AnyObject] {
                // 获取SessionId 和 type
                if let sessionId = userInfo["sessionId"] as? String,
                let sessionType = userInfo["sessionType"] as? String{
                    print("userNotificationCenter sessionId: \(sessionId) sessionType : \(sessionType)")
                    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
                    let methodChannel = FlutterMethodChannel(name: "com.netease.yunxin.app.flutter.im/channel",
                                                             binaryMessenger: controller.binaryMessenger)

                    //热启动，此时Flutter 页面已经存在，直接调用Flutter的接口
                    if isForeground {
                        // The app is in the foreground (hot start)
                        methodChannel.invokeMethod("pushMessage", arguments: [
                            "sessionId":sessionId,
                            "sessionType":sessionType
                        ],result: {ret in
                            print("methodChannel.invokeMethod \(String(describing: ret))")
                        })
                            
                        //冷启动，注册接口供Flutter 起来后调用
                        } else {
                            // The app was in the background or not running (cold start)
                            methodChannel.setMethodCallHandler{ (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                                if call.method == "pushMessage" {
                                    let ret = [
                                        "sessionId":sessionId,
                                        "sessionType":sessionType
                                        ]
                                   result(ret)
                                } else {
                                    result(FlutterMethodNotImplemented)
                                }
                            }
                        }
                }
            }
        completionHandler()
    }
    
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
     
        //将deviceToken传到dart层
        let flutterData = FlutterStandardTypedData.init(bytes: deviceToken)
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let methodChannel = FlutterMethodChannel(name: "com.netease.yunxin.app.flutter.im/channel",
                                                  binaryMessenger: controller.binaryMessenger)
        methodChannel.invokeMethod("updateAPNsToken", arguments: flutterData)
    }
    
    func registerAPNS(){
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            
            center.requestAuthorization(options: [.badge, .sound, .alert]) { grant, error in
                if grant == false {
                    print("please open push switch in setting")
                }
            }
        } else {
            let setting = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(setting)
        }
        UIApplication.shared.registerForRemoteNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    override func applicationWillEnterForeground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        isForeground = true
    }
    
    
    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        NELog.infoLog("app delegate : ", desc: error.localizedDescription)
    }
}
