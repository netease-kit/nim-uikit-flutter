/*
 * Copyright (c) 2022 NetEase, Inc. All rights reserved.
 * Use of this source code is governed by a MIT license that can be
 * found in the LICENSE file.
 */

package com.netease.yunxin.kit.nimChatkitPushkit

import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.annotation.NonNull
import com.huawei.hms.support.common.ActivityMgr
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.NewIntentListener
import org.json.JSONArray
import org.json.JSONObject

private const val CHANNEL_NAME = "nim_chatkit_pushkit"
private const val METHOD_INITIALIZE = "initialize"
private const val METHOD_GET_INITIAL_NOTIFICATION = "getInitialNotification"
private const val METHOD_GET_ENTRANCE_CLASS_NAME = "getAndroidNotificationEntranceClassName"
private const val METHOD_GET_PUSH_ACTION = "getAndroidPushAction"
private const val METHOD_ON_NOTIFICATION_CLICK = "onNotificationClick"

private const val SESSION_ID = "sessionId"
private const val SESSION_TYPE = "sessionType"
private const val SOURCE = "source"
private const val RAW_PAYLOAD = "rawPayload"
private const val EXTRA_NOTIFY_SESSION_CONTENT = "com.netease.nim.EXTRA.NOTIFY_SESSION_CONTENT"

/** PushKit plugin for NIM ChatKit push notification click handling. */
class NimChatkitPushkitPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    NewIntentListener {

    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null
    private var binding: ActivityPluginBinding? = null
    private var initialNotification: Map<String, Any?>? = null
    private var initialized = false
    private var customPushAction: String? = null
    private var customEntranceClassName: String? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        initializeVendorPush(flutterPluginBinding.applicationContext)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            METHOD_INITIALIZE -> {
                customPushAction = call.argument<String>("androidPushAction")
                customEntranceClassName =
                    call.argument<String>("androidNotificationEntranceClassName")
                initialized = true
                activity?.intent?.let { consumeIntent(it, false) }
                result.success(null)
            }

            METHOD_GET_INITIAL_NOTIFICATION -> {
                result.success(initialNotification ?: emptyMap<String, Any?>())
                initialNotification = null
            }

            METHOD_GET_ENTRANCE_CLASS_NAME -> result.success(getEntranceClassName())
            METHOD_GET_PUSH_ACTION -> result.success(getPushAction())
            else -> result.notImplemented()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.binding = binding
        this.activity = binding.activity
        binding.addOnNewIntentListener(this)
        consumeIntent(binding.activity.intent, false)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        binding?.removeOnNewIntentListener(this)
        binding = null
        activity = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        consumeIntent(intent, true)
        return false
    }

    private fun consumeIntent(intent: Intent?, hotStart: Boolean) {
        if (intent == null) return
        val message = parseOnlineIntent(intent) ?: parseOfflineIntent(intent)
        if (message != null) {
            if (hotStart && initialized) {
                channel.invokeMethod(METHOD_ON_NOTIFICATION_CLICK, message)
            } else {
                initialNotification = message
            }
        }
    }

    private fun parseOfflineIntent(intent: Intent): Map<String, Any?>? {
        val payload = collectIntentExtras(intent)
        val sessionId = payload[SESSION_ID]?.toString()
        val sessionType = normalizeSessionType(payload[SESSION_TYPE])
        if (sessionId.isNullOrEmpty() || sessionType.isNullOrEmpty()) {
            return null
        }
        intent.removeExtra(SESSION_ID)
        intent.removeExtra(SESSION_TYPE)
        return buildMessage(sessionId, sessionType, "androidOffline", payload)
    }

    private fun parseOnlineIntent(intent: Intent): Map<String, Any?>? {
        val messageStr = intent.getStringExtra(EXTRA_NOTIFY_SESSION_CONTENT) ?: return null
        intent.removeExtra(EXTRA_NOTIFY_SESSION_CONTENT)
        return try {
            val array = JSONArray(messageStr)
            if (array.length() == 0) return null
            val firstObj = array.getJSONObject(0)
            val payload = jsonObjectToMap(firstObj)
            val sessionId = payload[SESSION_ID]?.toString()
            val sessionType = normalizeSessionType(payload[SESSION_TYPE])
            if (sessionId.isNullOrEmpty() || sessionType.isNullOrEmpty()) {
                null
            } else {
                buildMessage(sessionId, sessionType, "androidOnline", payload)
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun buildMessage(
        sessionId: String,
        sessionType: String,
        source: String,
        rawPayload: Map<String, Any?>
    ): Map<String, Any?> {
        return mapOf(
            SESSION_ID to sessionId,
            SESSION_TYPE to sessionType,
            SOURCE to source,
            RAW_PAYLOAD to rawPayload
        )
    }

    private fun normalizeSessionType(value: Any?): String? {
        return when (value) {
            null -> null
            is Number -> if (value.toInt() == 0) "p2p" else "team"
            is String -> when {
                value.equals("p2p", ignoreCase = true) -> "p2p"
                value.equals("team", ignoreCase = true) -> "team"
                value == "0" -> "p2p"
                value == "1" || value == "2" -> "team"
                else -> value
            }

            else -> value.toString()
        }
    }

    private fun collectIntentExtras(intent: Intent): Map<String, Any?> {
        val extras = intent.extras ?: return emptyMap()
        val payload = mutableMapOf<String, Any?>()
        for (key in extras.keySet()) {
            payload[key] = getBundleValue(extras, key)
        }
        parseJsonString(payload["data"]?.toString())?.let { payload.putAll(it) }
        parseJsonString(payload["androidConfig"]?.toString())?.let { payload.putAll(it) }
        return payload
    }

    private fun parseJsonString(value: String?): Map<String, Any?>? {
        if (value.isNullOrEmpty()) return null
        return try {
            jsonObjectToMap(JSONObject(value))
        } catch (_: Exception) {
            null
        }
    }

    private fun getBundleValue(bundle: Bundle, key: String): Any? {
        @Suppress("DEPRECATION")
        return bundle.get(key)
    }

    private fun jsonObjectToMap(json: JSONObject): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        val keys = json.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val value = json.opt(key)
            map[key] = if (value is JSONObject) {
                jsonObjectToMap(value)
            } else if (value is JSONArray) {
                jsonArrayToList(value)
            } else {
                value
            }
        }
        return map
    }

    private fun jsonArrayToList(json: JSONArray): List<Any?> {
        val list = mutableListOf<Any?>()
        for (index in 0 until json.length()) {
            val value = json.opt(index)
            list.add(
                when (value) {
                    is JSONObject -> jsonObjectToMap(value)
                    is JSONArray -> jsonArrayToList(value)
                    else -> value
                }
            )
        }
        return list
    }

    private fun getEntranceClassName(): String? {
        customEntranceClassName?.let { return it }
        activity?.javaClass?.name?.let { return it }
        val appContext = context ?: return null
        val launchIntent = appContext.packageManager.getLaunchIntentForPackage(appContext.packageName)
        return launchIntent?.component?.className
    }

    private fun getPushAction(): String? {
        customPushAction?.let { return it }
        return context?.packageName?.let { "$it.push" }
    }

    private fun initializeVendorPush(context: Context) {
        // Vendor SDKs are optional. Reflection keeps the plugin buildable when
        // an app excludes a vendor dependency from its Gradle configuration.
        try {
            val application = context.applicationContext as? Application
            if (application != null) {
                ActivityMgr.INST.init(application)
            }
        } catch (_: Throwable) {
        }
        invokeStatic("com.heytap.msp.push.HeytapPushManager", "init", context, true)
        try {
            val pushClientClass = Class.forName("com.vivo.push.PushClient")
            val getInstance = pushClientClass.getMethod("getInstance", Context::class.java)
            val pushClient = getInstance.invoke(null, context)
            pushClientClass.getMethod("initialize").invoke(pushClient)
        } catch (_: Throwable) {
        }
    }

    private fun invokeStatic(
        className: String,
        methodName: String,
        context: Context,
        enabled: Boolean
    ) {
        try {
            val clazz = Class.forName(className)
            clazz.getMethod(methodName, Context::class.java, Boolean::class.javaPrimitiveType)
                .invoke(null, context, enabled)
        } catch (_: Throwable) {
        }
    }
}
