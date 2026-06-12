// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        LocalServerManager.instance.startServer()
        GeneratedPluginRegistrant.register(with: self)
        UNUserNotificationCenter.current().delegate = self
        // 注册远程通知 - 只需要这一步！
        application.registerForRemoteNotifications()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func applicationWillEnterForeground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        super.applicationWillEnterForeground(application)
    }

   override func application(
       _ application: UIApplication,
       didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
   ) {
       super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
   }
    
    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        NELog.infoLog("app delegate : ", desc: error.localizedDescription)
        super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
}
