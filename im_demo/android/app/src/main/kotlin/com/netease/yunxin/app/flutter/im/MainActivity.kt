/*
 * Copyright (c) 2022 NetEase, Inc. All rights reserved.
 * Use of this source code is governed by a MIT license that can be
 * found in the LICENSE file.
 */

package com.netease.yunxin.app.flutter.im

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private fun setSpeakerphoneOn(isSpeakerphoneOn: Boolean) {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager.isSpeakerphoneOn = isSpeakerphoneOn
        if (!isSpeakerphoneOn) {
            audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
            volumeControlStream = AudioManager.STREAM_VOICE_CALL
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "audioChannel")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSpeakerphoneOn" -> {
                        val isSpeakerphoneOn = call.argument<Boolean>("isSpeakerphoneOn")
                        setSpeakerphoneOn(isSpeakerphoneOn ?: false)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
