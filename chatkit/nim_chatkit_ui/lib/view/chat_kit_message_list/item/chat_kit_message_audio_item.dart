// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_corekit_im/repo/config_repo.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_core/nim_core.dart';

class ChatKitMessageAudioItem extends StatefulWidget {
  final NIMMessage message;

  const ChatKitMessageAudioItem({Key? key, required this.message})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageAudioState();
}

class ChatKitMessageAudioState extends State<ChatKitMessageAudioItem> {
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

  int aniIndex = 2;

  Timer? _timer;

  bool isPlaying = false;

  late AudioPlayer _audioPlayer;

  StreamSubscription? _playSub;

  double _getWidth(NIMMessage message) {
    int dur = _getAudioLen(message);
    double baseLen = 77.0;
    double maxLen = 265.0;
    if (dur <= 2) {
      return baseLen;
    } else {
      return min(maxLen, baseLen + (dur - 2) * 8);
    }
  }

  int _getAudioLen(NIMMessage message) {
    NIMAudioAttachment attachment =
        message.messageAttachment as NIMAudioAttachment;
    int len = attachment.duration == null ? 0 : attachment.duration!;
    return (len / 1000).truncate();
  }

  Widget _getAudioUI(NIMMessage message) {
    if (message.messageDirection == NIMMessageDirection.outgoing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${_getAudioLen(message)}s',
            style: TextStyle(fontSize: 14, color: '#333333'.toColor()),
          ),
          SvgPicture.asset(
            isPlaying ? toAniList[aniIndex] : toAniList[2],
            package: 'nim_chatkit_ui',
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
            package: 'nim_chatkit_ui',
            width: 28,
            height: 28,
          ),
          if (!isPlaying)
            Text(
              '${_getAudioLen(message)}s',
              style: TextStyle(fontSize: 14, color: '#333333'.toColor()),
            ),
        ],
      );
    }
  }

  void _startAudioPlay(NIMMessage message) {
    _timer?.cancel();
    var attachment = message.messageAttachment as NIMAudioAttachment;
    if (attachment.path != null) {
      _playAudio(attachment.path!, attachment.duration!);
    } else {
      NimCore.instance.messageService
          .downloadAttachment(message: message, thumb: false)
          .then((value) {
        if (value.isSuccess) {
          _playAudio(attachment.path!, attachment.duration!);
        }
      });
    }
  }

  void _playAudio(String path, int duration) async {
    var value = await ConfigRepo.getAudioPlayModel();
    bool isSpeakerphoneOn = value != ConfigRepo.audioPlayEarpiece;
    if (Platform.isAndroid) {
      _setSpeakerphoneOnAndroid(isSpeakerphoneOn);
    } else if (Platform.isIOS) {
      var config = AudioContext(
          android: AudioContextConfig().buildAndroid(),
          iOS: AudioContextIOS(
              defaultToSpeaker: false,
              category: isSpeakerphoneOn
                  ? AVAudioSessionCategory.playback
                  : AVAudioSessionCategory.playAndRecord,
              options: [AVAudioSessionOptions.mixWithOthers]));
      await AudioPlayer.global.setGlobalAudioContext(config);
    }
    _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
    _audioPlayer.play(DeviceFileSource(path)).then((value) {
      _startPlayAni(duration);
    });
  }

  void _setSpeakerphoneOnAndroid(bool isSpeakerphoneOn) {
    ChatKitClient.instance.setSpeakerphoneOnAndroid(isSpeakerphoneOn);
  }

  void _stopAudioPlay() {
    _audioPlayer.stop();
    _stopPlayAni();
  }

  void _startPlayAni(int duration) {
    setState(() {
      isPlaying = true;
    });

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
    setState(() {
      isPlaying = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer(playerId: widget.message.messageId);
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    _audioPlayer.release();
    _playSub?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _getWidth(widget.message),
      child: GestureDetector(
        onTap: () {
          if (isPlaying) {
            _stopAudioPlay();
          } else {
            _startAudioPlay(widget.message);
          }
        },
        child: Container(
          padding:
              const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 12),
          child: _getAudioUI(widget.message),
        ),
      ),
    );
  }
}
