// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:netease_corekit_im/repo/config_repo.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

//终止操作，播放下一个，上一个会被迫终止
typedef StopAction = void Function();

class ChatAudioPlayer {
  ChatAudioPlayer._();

  static final ChatAudioPlayer instance = ChatAudioPlayer._();

  AudioContext? audioContextDefault;

  var players = <String, AudioPlayer>{};

  StopAction? _stopAction;

  StreamSubscription? _subscription;

  void initAudioPlayer() {
    _setupSpeaker();
  }

  //初始化设置播放器属性
  void _setupSpeaker() async {
    audioContextDefault = await _getAudioContext();
    await AudioPlayer.global.setAudioContext(audioContextDefault!);
  }

  //获取播放器属性
  Future<AudioContext> _getAudioContext() async {
    var value = await ConfigRepo.getAudioPlayModel();
    bool isSpeakerphoneOn = value != ConfigRepo.audioPlayEarpiece;
    Alog.d(
        tag: 'ChatAudioPlayer',
        content: 'isSpeakerphoneOn is = $isSpeakerphoneOn');
    return AudioContext(
        android: AudioContextAndroid(
            usageType: isSpeakerphoneOn
                ? AndroidUsageType.media
                : AndroidUsageType.voiceCommunication,
            audioMode: isSpeakerphoneOn
                ? AndroidAudioMode.normal
                : AndroidAudioMode.inCommunication,
            isSpeakerphoneOn: isSpeakerphoneOn),
        iOS: AudioContextIOS(
            category: isSpeakerphoneOn
                ? AVAudioSessionCategory.playback
                : AVAudioSessionCategory.playAndRecord,
            options: [AVAudioSessionOptions.mixWithOthers]));
  }

  Future<bool> play(
      String id,
      Source source, {
        required StopAction stopAction,
        double? volume,
        double? balance,
        AudioContext? ctx,
        Duration? position,
        PlayerMode? mode,
      }) async {
    _setupSpeaker();
    //回掉之前的停止操作
    _stopAction?.call();

    //构建新的播放器
    if (players[id] == null) {
      players[id] = AudioPlayer(playerId: id);
    }
    //移除之前的播放器

    players.forEach((key, value) async {
      if (key != id) {
        await value.dispose();
      }
    });
    _subscription?.cancel();
    players.removeWhere((key, value) => key != id);
    //使用默认的context
    var audioContext = ctx ?? audioContextDefault;

    _stopAction = stopAction;
    var audioPlayer = players[id];
    _subscription = audioPlayer!.onPlayerStateChanged.listen((event) {
      if (event == PlayerState.stopped || event == PlayerState.completed) {
        _stopAction?.call();
        _stopAction = null;
      }
    });
    return audioPlayer
        .play(source,
            volume: volume,
            balance: balance,
            ctx: audioContext,
            position: position,
            mode: mode)
        .then((value) => true);
  }

  bool isPlaying(String playerId) {
    return players[playerId]?.state == PlayerState.playing;
  }

  Future<Duration?> getCurrentPosition(String playerId) async {
    if (players[playerId]?.state == PlayerState.playing) {
      return players[playerId]!.getCurrentPosition();
    }
    return null;
  }

  void stop(String id) {
    players[id]?.stop();
  }

  void stopAll() {
    for (var player in players.values) {
      player.stop();
    }
  }

  void release() {
    players.forEach((key, value) {
      value.dispose();
    });
    players.clear();
    _stopAction = null;
    _subscription?.cancel();
  }
}
