// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_corekit_im/router/imkit_router.dart';
import 'package:nim_core_v2/nim_core.dart';
import '../../../chat_kit_client.dart';
import '../../../media/audio_player.dart';

class ChatKitMessageAudioItem extends StatefulWidget {
  final NIMMessage message;

  final bool isPin;

  const ChatKitMessageAudioItem(
      {Key? key, required this.message, this.isPin = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageAudioState();
}

class ChatKitMessageAudioState extends State<ChatKitMessageAudioItem>
    with RouteAware {
  final List<String> toAniList = [
    'images/ic_sound_to_1.svg',
    'images/ic_sound_to_2.svg',
    'images/ic_sound_to_3.svg'
  ];

  final List<String> fromAniList = [
    'images/ic_sound_from_1.svg',
    'images/ic_sound_from_2.svg',
    'images/ic_sound_from_3.svg'
  ];

  StreamSubscription? _phoneStateSub;

  int aniIndex = 2;

  Timer? _timer;

  bool isPlaying = false;

  double _getWidth(NIMMessage message) {
    int dur = _getAudioLen(message);
    double baseLen = 78.0;
    double maxLen = 265.0;
    if (dur <= 2) {
      return baseLen;
    } else {
      return min(maxLen, baseLen + (dur - 2) * 8);
    }
  }

  int _getAudioLen(NIMMessage message) {
    NIMMessageAudioAttachment attachment =
        message.attachment as NIMMessageAudioAttachment;
    int len = attachment.duration == null ? 0 : attachment.duration!;
    return (len / 1000).truncate();
  }

  Widget _getAudioUI(NIMMessage message) {
    if (message.isSelf == true && !widget.isPin) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${_getAudioLen(message)}s',
            style: TextStyle(fontSize: 14, color: '#333333'.toColor()),
          ),
          SvgPicture.asset(
            isPlaying ? toAniList[aniIndex] : toAniList[2],
            package: kPackage,
            width: 28,
            height: 28,
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SvgPicture.asset(
            isPlaying ? fromAniList[aniIndex] : fromAniList[2],
            package: kPackage,
            width: 28,
            height: 28,
          ),
          Text(
            '${_getAudioLen(message)}s',
            style: TextStyle(fontSize: 14, color: '#333333'.toColor()),
          ),
        ],
      );
    }
  }

  void _startAudioPlay(NIMMessage message) {
    isPlaying = true;
    _timer?.cancel();
    var attachment = message.attachment as NIMMessageAudioAttachment;
    if (attachment.url?.isNotEmpty == true) {
      _playAudio(UrlSource(attachment.url!), attachment.duration!);
    } else if (attachment.path != null && File(attachment.path!).existsSync()) {
      _playAudio(DeviceFileSource(attachment.path!), attachment.duration!);
    }
  }

  void _playAudio(Source source, int duration) async {
    if (isPlaying == false) {
      return;
    }
    ChatAudioPlayer.instance
        .play(widget.message.messageClientId!, source, stopAction: _stopPlayAni)
        .then((value) {
      if (value) {
        _startPlayAni(duration);
      } else {
        isPlaying = false;
      }
    });
  }

  void _stopAudioPlay() {
    ChatAudioPlayer.instance.stop(widget.message.messageClientId!);
    _stopPlayAni();
  }

  void _startPlayAni(int duration) {
    if (isPlaying == false) {
      _stopAudioPlay();
      return;
    }
    isPlaying = true;
    if (mounted) {
      setState(() {});
    }

    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        if (aniIndex >= 2) {
          aniIndex = 0;
        } else {
          aniIndex++;
        }
      });
      if (200 * timer.tick >= duration) {
        _stopAudioPlay();
      }
    });
  }

  void _stopPlayAni() {
    _timer?.cancel();
    if (isPlaying && mounted) {
      setState(() {
        isPlaying = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    ChatAudioPlayer.instance
        .getCurrentPosition(widget.message.messageClientId!)
        .then((value) {
      //如果消息未播放完成则恢复动画
      if (value != null) {
        var attachment = widget.message.attachment as NIMMessageAudioAttachment;
        var durLast = attachment.duration! - value.inMilliseconds;
        isPlaying = true;
        _startPlayAni(durLast);
      }
    });
    Future.delayed(Duration.zero, () {
      IMKitRouter.instance.routeObserver
          .subscribe(this, ModalRoute.of(context)!);
    });
  }

  @override
  void didPushNext() {
    //打开其他页面之前停止播放
    super.didPushNext();
    _stopAudioPlay();
    _timer?.cancel();
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    IMKitRouter.instance.routeObserver.unsubscribe(this);
    _phoneStateSub?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isPlaying) {
          _stopAudioPlay();
        } else {
          _startAudioPlay(widget.message);
        }
      },
      child: Container(
        width: _getWidth(widget.message),
        color: Color.fromRGBO(0, 0, 0, 0.0),
        padding:
            const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 12),
        child: _getAudioUI(widget.message),
      ),
    );
  }
}
