// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_core/nim_core.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n.dart';
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
  late StreamSubscription _streamSubscription;

  AudioService get _audioService => NimCore.instance.audioService;

  void buildOverlay(BuildContext context) {
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: (context) {
        return Container(
          color: Colors.transparent,
        );
      });
      Overlay.of(context)!.insert(_overlayEntry!);
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
    _streamSubscription =
        _audioService.onAudioRecordStatus.listen((recordInfo) {
      if (recordInfo.recordState == RecordState.REACHED_MAX ||
          recordInfo.recordState == RecordState.SUCCESS) {
        // reached max time or success
        _recordOnPressed = false;
        widget.onEnd();
        setState(() {});
      }
      if (recordInfo.recordState == RecordState.SUCCESS &&
          recordInfo.filePath != null &&
          recordInfo.fileSize != null &&
          recordInfo.duration != null) {
        context.read<ChatViewModel>().sendAudioMessage(
            recordInfo.filePath!, recordInfo.fileSize!, recordInfo.duration!);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscription.cancel();
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
                  _audioService.cancelRecord();
                  widget.onCancel();
                  setState(() {});
                },
                onLongPressDown: (LongPressDownDetails details) {
                  _recordOnPressed = true;
                  _audioService.startRecord(AudioOutputFormat.AAC, 60);
                  buildOverlay(context);
                  widget.onPressedDown();
                  setState(() {});
                },
                onLongPressEnd: (LongPressEndDetails details) {
                  _recordOnPressed = false;
                  removeOverlay();
                  double r = 51.5;
                  double dx = (details.localPosition.dx - r).abs();
                  double dy = (details.localPosition.dy - r).abs();
                  if (dx * dx + dy * dy > r * r) {
                    _audioService.cancelRecord();
                    widget.onCancel();
                  } else {
                    _audioService.stopRecord();
                    widget.onEnd();
                  }
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
                    package: 'nim_chatkit_ui',
                    width: 36,
                    height: 36,
                    color: _recordOnPressed
                        ? const Color(0x7fffffff)
                        : Colors.white,
                  ),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                _recordOnPressed ? "" : S.of(context).chat_pressed_to_speak,
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
