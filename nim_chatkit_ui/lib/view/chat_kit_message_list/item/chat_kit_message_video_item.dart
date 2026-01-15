// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/extension.dart';
import 'package:nim_chatkit/extension.dart';
import 'package:nim_chatkit/repo/chat_service_observer_repo.dart';
import 'package:nim_chatkit_ui/media/audio_player.dart';
import 'package:nim_chatkit_ui/media/video.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/widgets/chat_thumb_view.dart';
import 'package:nim_core_v2/nim_core.dart';

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

  String? _localPath;

  NIMMessageVideoAttachment get attachment =>
      widget.message.attachment as NIMMessageVideoAttachment;

  String _videoDuration() {
    if (attachment.duration != null) {
      int sec = (attachment.duration! / 1000).ceil();
      return sec.formatTimeMMSS();
    }
    return '';
  }

  Size _getVideoSize() {
    // 检查 width 和 height 是否为有效正数
    if (attachment.width != null &&
        attachment.width! > 0 &&
        attachment.height != null &&
        attachment.height! > 0) {
      var ratio = attachment.width! / attachment.height!;
      double rat;
      if (ratio > 1) {
        rat = attachment.width! / 190;
      } else {
        rat = attachment.height! / 190;
      }
      // 再次检查，防止 rat 为 0 导致除法错误
      if (rat == 0) {
        return Size(110, 190);
      }
      return Size(attachment.width! / rat, attachment.height! / rat);
    }
    // 如果 width 或 height 无效，返回一个默认的安全尺寸
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
    var attachment = widget.message.attachment as NIMMessageVideoAttachment;
    if (attachment.path?.isNotEmpty != true) {
      attachment.path = path;
    }

    //播放视频前停止播放语音消息
    ChatAudioPlayer.instance.stopAll();

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => VideoViewer(
                  message: widget.message,
                )));
  }

  void _videoOnTap() async {
    if (attachment.path?.isNotEmpty == true) {
      _localPath = attachment.path;
    }
    if (_localPath?.isNotEmpty == true &&
        await File(_localPath!).existsSync()) {
      _goVideoViewer(_localPath);
    } else {
      var params = NIMDownloadMessageAttachmentParams(
          attachment: attachment,
          type: NIMDownloadAttachmentType.nimDownloadAttachmentTypeSource,
          thumbSize:
              NIMSize(width: attachment.width, height: attachment.height),
          messageClientId: widget.message.messageClientId);
      NimCore.instance.storageService.downloadAttachment(params).then((result) {
        if (!mounted) return;
        if (result.data?.isNotEmpty == true) {
          _localPath = result.data;
          _progress.add(1);
          if (ModalRoute.of(context)?.isCurrent == true) {
            _goVideoViewer(_localPath);
          }
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _progress = StreamController<double>.broadcast();

    _subscriptionMsgDownload =
        ChatServiceObserverRepo.observeAttachmentProgress().listen((event) {
      if (event.downloadParam?.messageClientId ==
          widget.message.messageClientId) {
        _log(
            'onAttachmentProgress -->> ${event.downloadParam?.messageClientId} : ${event.progress}');
        if (event.progress != null) {
          _progress.add(event.progress! / 100);
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
    String url = attachment.url ?? '';
    // _log(
    //     'build video item ${widget.message.messageClientId} -->> thumbPath:${attachment.thumbPath}, path:${attachment.path}');
    // if (attachment.thumbPath == null) {
    //   NimCore.instance.messageService
    //       .downloadAttachment(message: widget.message, thumb: true);
    // }
    return GestureDetector(
      onTap: _videoOnTap,
      child: Stack(
        children: [
          ChatThumbView(
            message: widget.message,
            radius: const BorderRadius.all(Radius.circular(12)),
            thumbFromRemote: true,
          ),
          Positioned.fill(
            child: Visibility(
              visible: url.isNotEmpty,
              child: Center(
                child: _buildLoading(),
              ),
            ),
          ),
          Visibility(
            visible: url.isNotEmpty && attachment.duration != null,
            child: Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      color: Color(0x99000000)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
                    child: Text(
                      _videoDuration(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                )),
          )
        ],
      ),
    );
  }
}
