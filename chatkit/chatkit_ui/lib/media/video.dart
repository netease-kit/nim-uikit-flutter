// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:im_common_ui/extension.dart';
import 'package:chatkit_ui/media/media_bottom_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_core/nim_core.dart';
import 'package:video_player/video_player.dart';

class VideoViewer extends StatefulWidget {
  const VideoViewer({Key? key, required this.message}) : super(key: key);

  final NIMMessage message;

  @override
  State<StatefulWidget> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  late VideoPlayerController _controller;
  bool _progressShow = true;
  Timer? _timer;

  void _playProgressAutoHide() {
    _timer?.cancel();
    if (_progressShow) {
      _timer = Timer(const Duration(seconds: 3), () {
        if (_progressShow) {
          setState(() {
            _progressShow = false;
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    NIMVideoAttachment attachment =
        widget.message.messageAttachment as NIMVideoAttachment;
    _controller = VideoPlayerController.file(File(attachment.path!));
    _controller.addListener(() {
      setState(() {});
    });
    _controller.setLooping(false);
    _controller.initialize().then((_) {
      setState(() {});
    });
    _controller.play();
    _playProgressAutoHide();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(alignment: Alignment.bottomCenter, children: [
        Center(
          child: Hero(
            tag: '${widget.message.messageId}${widget.message.uuid}',
            child: _controller.value.isInitialized
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        _progressShow = !_progressShow;
                        _playProgressAutoHide();
                      });
                    },
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  )
                : Container(),
          ),
        ),
        Visibility(
          visible: !_controller.value.isPlaying,
          child: GestureDetector(
            onTap: () {
              _controller.play();
            },
            child: Center(
              child: SvgPicture.asset(
                'images/ic_video_player.svg',
                package: 'chatkit_ui',
                height: 80,
                width: 80,
              ),
            ),
          ),
        ),
        Positioned(
            left: 20,
            right: 20,
            bottom: 75,
            child: Visibility(
              visible: _progressShow,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    },
                    child: SvgPicture.asset(
                      _controller.value.isPlaying
                          ? 'images/ic_video_pause.svg'
                          : 'images/ic_video_resume.svg',
                      package: 'chatkit_ui',
                      height: 26,
                      width: 26,
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Text(
                    _controller.value.position.inSeconds.formatTimeMMSS(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 2,
                      child: VideoProgressIndicator(_controller,
                          colors: const VideoProgressColors(
                              playedColor: Colors.white,
                              backgroundColor: Color(0x4d000000)),
                          padding: EdgeInsets.zero,
                          allowScrubbing: false),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    _controller.value.duration.inSeconds.formatTimeMMSS(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            )),
        MediaBottomActionOverlay(widget.message)
      ]),
    );
  }
}
