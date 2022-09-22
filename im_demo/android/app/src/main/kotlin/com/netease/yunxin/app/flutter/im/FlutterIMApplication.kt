/*
 * Copyright (c) 2022 NetEase, Inc. All rights reserved.
 * Use of this source code is governed by a MIT license that can be
 * found in the LICENSE file.
 */

package com.netease.yunxin.app.flutter.im

import android.app.Application
import com.heytap.msp.push.HeytapPushManager
import com.huawei.hms.support.common.ActivityMgr
import com.vivo.push.PushClient
import com.vivo.push.util.VivoPushException

class FlutterIMApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        // huawei push
        ActivityMgr.INST.init(this)
        // oppo push
        HeytapPushManager.init(this, true)
        try {
            // vivo push
            PushClient.getInstance(this).initialize()
        } catch (e: VivoPushException) {
        }
    }
}
