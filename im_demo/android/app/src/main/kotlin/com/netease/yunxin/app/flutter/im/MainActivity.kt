/*
 * Copyright (c) 2022 NetEase, Inc. All rights reserved.
 * Use of this source code is governed by a MIT license that can be
 * found in the LICENSE file.
 */

package com.netease.yunxin.app.flutter.im

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONException

const val SESSION_ID = "sessionId"
const val SESSION_TYPE = "sessionType"

// Intent 参数的key值
const val EXTRA_NOTIFY_SESSION_CONTENT = "com.netease.nim.EXTRA.NOTIFY_SESSION_CONTENT"

class MainActivity : FlutterActivity() {

    // MethodChannel的名称
    private val channelName = "com.netease.yunxin.app.flutter.im/channel"

    private val methodName = "pushMessage"

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        parseOnlineIntent(intent, false)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val handledOnline = parseOnlineIntent(intent, true)
        val handleOffline = parseOfflinePushIntent(intent)
        if (handledOnline.not() && handleOffline.not()) {
            addEmptyHandler()
        }
    }

    private fun parseOfflinePushIntent(intent: Intent): Boolean {
        if (intent.hasExtra(SESSION_ID) && intent.hasExtra(SESSION_TYPE)) {
            val sessionId = intent.getStringExtra(SESSION_ID)
            val sessionType = intent.getStringExtra(SESSION_TYPE)
            flutterEngine?.dartExecutor?.let {
                MethodChannel(it, channelName).setMethodCallHandler { call, result ->
                    if (call.method == methodName) {
                        result.success(
                            mapOf(
                                SESSION_ID to sessionId,
                                SESSION_TYPE to sessionType
                            )
                        )
                    }
                }
            }
            intent.removeExtra(SESSION_ID)
            intent.removeExtra(SESSION_TYPE)
            return true
        }
        return false
    }

    // 解析在线消息的点击Intent
    private fun parseOnlineIntent(intent: Intent, fromCreate: Boolean): Boolean {
        if (intent.hasExtra(EXTRA_NOTIFY_SESSION_CONTENT)) {
            val messageStr: String? =
                intent.getStringExtra(EXTRA_NOTIFY_SESSION_CONTENT)
            intent.removeExtra(EXTRA_NOTIFY_SESSION_CONTENT)
            messageStr?.let {
                try {
                    val jsonArray = JSONArray(messageStr)
                    val firstObj = jsonArray.getJSONObject(0)
                    val sessionId = firstObj[SESSION_ID] as String
                    val sessionType = firstObj[SESSION_TYPE] as Int
                    // 注意，此处需要将sessionType转成String传到dart层，示例仅考虑p2p 和 team，如有其他业务场景，请参考
                    // int P2P = 0; int Team = 1; int Ysf = 2;  int CUSTOM_PERSON = 2; int CUSTOM_TEAM = 3;
                    // int TEMP = 4; int SUPER_TEAM = 5;
                    val sessionTypeStr = if (sessionType == 0) "p2p" else "team"
                    // 将数据传递给Flutter端
                    flutterEngine?.dartExecutor?.let {
                        if (fromCreate) {
                            MethodChannel(it, channelName).setMethodCallHandler { call, result ->
                                if (call.method == methodName) {
                                    result.success(
                                        mapOf(
                                            SESSION_ID to sessionId,
                                            SESSION_TYPE to sessionTypeStr
                                        )
                                    )
                                }
                            }
                        } else {
                            MethodChannel(it, channelName).invokeMethod(
                                methodName,
                                mapOf(
                                    SESSION_ID to sessionId,
                                    SESSION_TYPE to sessionTypeStr
                                )
                            )
                        }
                    }
                    return true
                } catch (e: JSONException) {
                    e.printStackTrace()
                }
            }
        }
        return false
    }

    // 注册空的method，防止dart层抛出MissingPluginException
    private fun addEmptyHandler() {
        flutterEngine?.dartExecutor?.let {
            MethodChannel(it, channelName).setMethodCallHandler { call, result ->
                if (call.method == methodName) {
                    result.success(mapOf<String, String>())
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
    }
}
