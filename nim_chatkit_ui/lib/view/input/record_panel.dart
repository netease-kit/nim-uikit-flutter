// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_sound/flutter_sound.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common/netease_common.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_chatkit_ui/media/audio_player.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../chat_kit_client.dart';
import '../../l10n/S.dart';
import '../../view_model/chat_view_model.dart';

class RecordPanel extends StatefulWidget {
  const RecordPanel(
      {Key? key,
      required this.onPressedDown,
      required this.onEnd,
      required this.onCancel})
      : super(key: key);

  final VoidCallback onPressedDown;
  final VoidCallback onEnd;
  final VoidCallback onCancel;

  @override
  State<StatefulWidget> createState() => _RecordPanelState();
}

class _RecordPanelState extends State<RecordPanel> {
  bool _recordOnPressed = false;
  OverlayEntry? _overlayEntry;
  StreamSubscription? _streamSubscription;

  //最大录制时间60，单位s
  int _maxLength = 60;

  //最小录制时间1000,单位ms
  int _minLength = 1000;

  int duration = 0;

  //录制状态
  RecordPlayState _state = RecordPlayState.init;

  FlutterSoundRecorder recorderModule = FlutterSoundRecorder();

  void buildOverlay(BuildContext context) {
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: (context) {
        return Container(
          color: Colors.transparent,
        );
      });
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  @override
  void initState() {
    super.initState();
    initRecoder();
  }

  initRecoder() async {
    await recorderModule.openRecorder();
    await recorderModule
        .setSubscriptionDuration(const Duration(milliseconds: 10));
  }

  /// 开始录音
  Future<void> _startRecorder() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      var time = DateTime.now().millisecondsSinceEpoch;
      String path = '${tempDir.path}/$time${ext[Codec.aacADTS.index]}';

      //这里录制的是aac格式
      await recorderModule.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
        bitRate: 64000,
        numChannels: 1,
        sampleRate: 48000,
      );
      _state = RecordPlayState.recording;

      /// 监听录音
      _streamSubscription = recorderModule.onProgress!.listen((e) {
        duration = e.duration.inMilliseconds;
        //设置了最大录音时长
        if (e.duration.inSeconds >= _maxLength) {
          _recordOnPressed = false;
          removeOverlay();
          widget.onEnd();
          _stopRecorder(true);
          setState(() {});
          return;
        }
      });
    } catch (err) {
      setState(() {
        _stopRecorder(false, durationDuje: false);
        _cancelRecorderSubscriptions();
      });
    }
  }

  /// 结束录音
  _stopRecorder(bool sendMessage, {bool durationDuje = true}) async {
    try {
      await recorderModule.stopRecorder().then((value) {
        Alog.d(
            tag: 'RecordPanel :',
            content:
                'stopRecorder usl: $value duration = $duration sendMessage : $sendMessage');
        _state = RecordPlayState.stop;
        if (sendMessage && duration > _minLength) {
          context
              .read<ChatViewModel>()
              .sendAudioMessage(value!, null, duration);
        }
        if (durationDuje && duration <= _minLength) {
          Fluttertoast.showToast(msg: S.of(context).chatSpeakTooShort);
        }
        _cancelRecorderSubscriptions();
      });
    } catch (err) {}
  }

  ///销毁录音
  void dispose() {
    super.dispose();
    _cancelRecorderSubscriptions();
    _releaseRecoder();
  }

  /// 取消录音监听
  void _cancelRecorderSubscriptions() {
    if (_streamSubscription != null) {
      _streamSubscription!.cancel();
      _streamSubscription = null;
    }
  }

  /// 释放录音
  Future<void> _releaseRecoder() async {
    try {
      await recorderModule.closeRecorder();
    } catch (e) {}
  }

  /// 判断文件是否存在
  Future<bool> _fileExists(String path) async {
    return await File(path).exists();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 30,
          child: Visibility(
              visible: _recordOnPressed, child: const RecordButtonWave()),
        ),
        Positioned(
          top: 30,
          child: Column(
            children: [
              GestureDetector(
                onLongPressCancel: () {
                  _recordOnPressed = false;
                  removeOverlay();
                  _state = RecordPlayState.canceled;
                  _stopRecorder(false);
                  widget.onCancel();
                  setState(() {});
                },
                onLongPressDown: (LongPressDownDetails details) {
                  _recordOnPressed = true;
                  _startRecorder();
                  ChatAudioPlayer.instance.stopAll();
                  buildOverlay(context);
                  widget.onPressedDown();
                  setState(() {});
                },
                onLongPressEnd: (LongPressEndDetails details) {
                  _recordOnPressed = false;
                  removeOverlay();
                  final needStopRecord = _state == RecordPlayState.recording;
                  double r = 51.5;
                  double dx = (details.localPosition.dx - r).abs();
                  double dy = (details.localPosition.dy - r).abs();
                  if (dx * dx + dy * dy > r * r) {
                    if (needStopRecord) {
                      _stopRecorder(false, durationDuje: false);
                    }

                    widget.onCancel();
                  } else {
                    if (needStopRecord) {
                      _stopRecorder(true);
                    }
                    widget.onEnd();
                  }
                  _state = RecordPlayState.stop;

                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(33.5),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(51.5),
                      gradient: const LinearGradient(
                          colors: [Color(0xff6aa1ff), Color(0xff3479ee)])),
                  child: SvgPicture.asset(
                    'images/ic_record.svg',
                    package: kPackage,
                    width: 36,
                    height: 36,
                    colorFilter: ColorFilter.mode(
                        _recordOnPressed
                            ? const Color(0x7fffffff)
                            : Colors.white,
                        BlendMode.srcIn),
                  ),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                _recordOnPressed ? "" : S.of(context).chatPressedToSpeak,
                style: const TextStyle(
                    fontSize: 12, color: CommonColors.color_999999),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class RecordButtonWave extends StatefulWidget {
  const RecordButtonWave({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RecordButtonWaveState();
}

class _RecordButtonWaveState extends State<RecordButtonWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat();

    _widthAnimation = Tween(begin: 1.0, end: 1.5)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.ease));

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _widthAnimation,
      child: Container(
        height: 103,
        width: 103,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(51.5),
            color: const Color(0x4d518ef8)),
      ),
    );
  }
}

enum RecordPlayState { init, recording, stop, canceled }
