// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/extension.dart';
import 'package:netease_common_ui/widgets/neListView/frame_separate_widget.dart';
import 'package:nim_chatkit/extension.dart';
import 'package:nim_chatkit/repo/chat_service_observer_repo.dart';
import 'package:nim_chatkit_ui/media/audio_player.dart';
import 'package:nim_chatkit_ui/media/video.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/widgets/chat_thumb_view.dart';
import 'package:nim_core/nim_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../../../chat_kit_client.dart';

class ChatKitMessageVideoItem extends StatefulWidget {
  final NIMMessage message;

  ///独立的文件，比如合并转发后的文件
  final bool independentFile;

  const ChatKitMessageVideoItem(
      {Key? key, required this.message, this.independentFile = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChatKitMessageVideoState();
}

class _ChatKitMessageVideoState extends State<ChatKitMessageVideoItem> {
  StreamSubscription? _subscriptionMsgDownload;
  late StreamController<double> _progress;

  NIMVideoAttachment get attachment =>
      widget.message.messageAttachment as NIMVideoAttachment;

  String _videoDuration() {
    if (attachment.duration != null) {
      int sec = (attachment.duration! / 1000).ceil();
      return sec.formatTimeMMSS();
    }
    return '';
  }

  Size _getVideoSize() {
    if (attachment.width != null && attachment.height != null) {
      var ratio = attachment.width! / attachment.height!;
      double rat;
      if (ratio > 1) {
        rat = attachment.width! / 190;
      } else {
        rat = attachment.height! / 190;
      }
      return Size(attachment.width! / rat, attachment.height! / rat);
    }
    return Size(110, 190);
  }

  Widget _buildLoading() {
    return StreamBuilder<double>(
        stream: _progress.stream,
        initialData: 1,
        builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
          _log(
              'buildLoading file downloaded:${widget.message.isFileDownload()}, progress:${snapshot.data}');
          if (widget.message.isFileDownload() || snapshot.data == 1) {
            return SvgPicture.asset(
              'images/ic_video_player.svg',
              package: kPackage,
              width: 60,
              height: 60,
            );
          }
          return Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.asset(
                'images/ic_video_pause_thumb.svg',
                package: kPackage,
                width: 13,
                height: 18,
              ),
              SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(
                  value: snapshot.data,
                  color: Colors.white,
                  backgroundColor: const Color(0x4d000000),
                ),
              )
            ],
          );
        });
  }

  void _goVideoViewer(String? path) {
    var msg;
    if (path != null) {
      var map = widget.message.toMap();
      // iOS需要将下载后的path更新到message中，提供给VideoViewer播放
      map['messageAttachment']['path'] = path;
      msg = NIMMessage.fromMap(map);
    } else {
      msg = widget.message;
    }

    //播放视频前停止播放语音消息
    ChatAudioPlayer.instance.stopAll();

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => VideoViewer(
                  message: msg,
                )));
  }

  void _videoOnTap() async {
    if (Platform.isIOS || widget.independentFile) {
      // SDK不提供下载功能，需要手动下载
      var appDocDir = await getTemporaryDirectory();
      String savePath = "${appDocDir.path}/${attachment.md5}.mp4";
      bool exist = await File(savePath).exists();
      if (!exist) {
        await Dio().download(attachment.url!, savePath,
            onReceiveProgress: (count, total) {
          _progress.add(count / total);
        });
      } else {
        _goVideoViewer(savePath);
      }
      return;
    }
    if (widget.message.isFileDownload()) {
      _goVideoViewer(null);
    } else {
      NimCore.instance.messageService
          .downloadAttachment(message: widget.message, thumb: false);
    }
  }

  @override
  void initState() {
    super.initState();
    _progress = StreamController<double>.broadcast();

    _subscriptionMsgDownload =
        ChatServiceObserverRepo.observeAttachmentProgress().listen((event) {
      if (event.id == widget.message.uuid) {
        _log('onAttachmentProgress -->> ${event.id} : ${event.progress}');
        if (event.progress != null) {
          _progress.add(event.progress!);
        }
      }
    });
  }

  @override
  void dispose() {
    _progress.close();
    _subscriptionMsgDownload?.cancel();
    super.dispose();
  }

  void _log(String content) {
    Alog.d(tag: 'ChatKit', moduleName: 'video item -->> ', content: content);
  }

  @override
  Widget build(BuildContext context) {
    String path = attachment.thumbPath ?? '';
    _log(
        'build video item ${widget.message.uuid} -->> thumbPath:${attachment.thumbPath}, path:${attachment.path}');
    if (attachment.thumbPath == null) {
      NimCore.instance.messageService
          .downloadAttachment(message: widget.message, thumb: true);
    }
    return FrameSeparateWidget.builder(
      id: widget.message.uuid,
      placeHolder: Container(
        width: _getVideoSize().width,
        height: _getVideoSize().height,
      ),
      builder: (context) {
        return GestureDetector(
          onTap: _videoOnTap,
          child: Stack(
            children: [
              ChatThumbView(
                message: widget.message,
                radius: const BorderRadius.all(Radius.circular(12)),
                thumbFromRemote: widget.independentFile,
              ),
              Positioned.fill(
                child: Visibility(
                  visible: path.isNotEmpty,
                  child: Center(
                    child: _buildLoading(),
                  ),
                ),
              ),
              Visibility(
                visible: path.isNotEmpty && attachment.duration != null,
                child: Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          color: Color(0x99000000)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 1, horizontal: 2),
                        child: Text(
                          _videoDuration(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                      ),
                    )),
              )
            ],
          ),
        );
      },
    );
  }
}
