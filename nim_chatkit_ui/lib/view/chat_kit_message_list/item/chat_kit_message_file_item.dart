// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/repo/chat_service_observer_repo.dart';
import 'package:nim_chatkit_ui/media/audio_player.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../../../chat_kit_client.dart';
import '../../../helper/text_utils.dart';

const _file_type_map = {
  'doc': 'ic_file_doc.svg',
  'docx': 'ic_file_doc.svg',
  'xls': 'ic_file_xls.svg',
  'xlsx': 'ic_file_xls.svg',
  'csv': 'ic_file_xls.svg',
  'ppt': 'ic_file_ppt.svg',
  'pptx': 'ic_file_ppt.svg',
  'jpeg': 'ic_file_pic.svg',
  'jpg': 'ic_file_pic.svg',
  'png': 'ic_file_pic.svg',
  'tiff': 'ic_file_pic.svg',
  'gif': 'ic_file_pic.svg',
  'zip': 'ic_file_zip.svg',
  '7z': 'ic_file_zip.svg',
  'rar': 'ic_file_zip.svg',
  'tar': 'ic_file_zip.svg',
  'pdf': 'ic_file_pdf.svg',
  'rtf': 'ic_file_pdf.svg',
  'txt': 'ic_file_txt.svg',
  'html': 'ic_file_html.svg',
  'htm': 'ic_file_html.svg',
  'mp4': 'ic_file_video.svg',
  'avi': 'ic_file_video.svg',
  'wmv': 'ic_file_video.svg',
  'mpeg': 'ic_file_video.svg',
  'm4v': 'ic_file_video.svg',
  'mov': 'ic_file_video.svg',
  'asf': 'ic_file_video.svg',
  'flv': 'ic_file_video.svg',
  'f4v': 'ic_file_video.svg',
  'rmvb': 'ic_file_video.svg',
  'rm': 'ic_file_video.svg',
  '3gp': 'ic_file_video.svg',
  'mp3': 'ic_file_audio.svg',
  'aac': 'ic_file_audio.svg',
  'wav': 'ic_file_audio.svg',
  'wma': 'ic_file_audio.svg',
  'flac': 'ic_file_audio.svg',
};

const support_type_map_android = {
  "3gp": "video/3gpp",
  "torrent": "application/x-bittorrent",
  "kml": "application/vnd.google-earth.kml+xml",
  "gpx": "application/gpx+xml",
  "csv": "application/vnd.ms-excel",
  "apk": "application/vnd.android.package-archive",
  "asf": "video/x-ms-asf",
  "avi": "video/x-msvideo",
  "bin": "application/octet-stream",
  "bmp": "image/bmp",
  "c": "text/plain",
  "class": "application/octet-stream",
  "conf": "text/plain",
  "cpp": "text/plain",
  "doc": "application/msword",
  "docx":
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  "xls": "application/vnd.ms-excel",
  "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  "exe": "application/octet-stream",
  "gif": "image/gif",
  "gtar": "application/x-gtar",
  "gz": "application/x-gzip",
  "h": "text/plain",
  "htm": "text/html",
  "html": "text/html",
  "jar": "application/java-archive",
  "java": "text/plain",
  "jpeg": "image/jpeg",
  "jpg": "image/jpeg",
  "js": "application/x-javascript",
  "log": "text/plain",
  "m3u": "audio/x-mpegurl",
  "m4a": "audio/mp4a-latm",
  "m4b": "audio/mp4a-latm",
  "m4p": "audio/mp4a-latm",
  "m4u": "video/vnd.mpegurl",
  "m4v": "video/x-m4v",
  "mov": "video/quicktime",
  "mp2": "audio/x-mpeg",
  "mp3": "audio/x-mpeg",
  "flac": "audio/x-mpeg",
  "aac": "audio/x-mpeg",
  "mp4": "video/mp4",
  "mpc": "application/vnd.mpohun.certificate",
  "mpe": "video/mpeg",
  "mpeg": "video/mpeg",
  "mpg": "video/mpeg",
  "mpg4": "video/mp4",
  "mpga": "audio/mpeg",
  "msg": "application/vnd.ms-outlook",
  "ogg": "audio/ogg",
  "pdf": "application/pdf",
  "png": "image/png",
  "pps": "application/vnd.ms-powerpoint",
  "ppt": "application/vnd.ms-powerpoint",
  "pptx":
      "application/vnd.openxmlformats-officedocument.presentationml.presentation",
  "prop": "text/plain",
  "rc": "text/plain",
  "rmvb": "audio/x-pn-realaudio",
  "rtf": "application/rtf",
  "sh": "text/plain",
  "tar": "application/x-tar",
  "tgz": "application/x-compressed",
  "txt": "text/plain",
  "wav": "audio/x-wav",
  "wma": "audio/x-ms-wma",
  "wmv": "audio/x-ms-wmv",
  "wps": "application/vnd.ms-works",
  "xml": "text/plain",
  "z": "application/x-compress",
  "zip": "application/x-zip-compressed",
  "": "*/*"
};

class ChatKitMessageFileItem extends StatefulWidget {
  final NIMMessage message;

  ///独立的文件，比如合并转发后的文件
  final bool independentFile;

  final Widget? trailing;

  final Color? backgroundColor;

  const ChatKitMessageFileItem(
      {Key? key,
      required this.message,
      this.independentFile = false,
      this.backgroundColor,
      this.trailing})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageFileState();
}

class ChatKitMessageFileState extends State<ChatKitMessageFileItem> {
  NIMMessageFileAttachment get attachment =>
      widget.message.attachment as NIMMessageFileAttachment;
  double? processValue = 0.0;
  bool processVisible = false;
  StreamSubscription<NIMDownloadMessageAttachmentProgress>? processStreamSub;

  //文件路径，赋值一次
  String? filePath;

  String _getIcon() {
    String? extension = attachment.ext?.toLowerCase();
    if (extension?.isNotEmpty != true) {
      extension = attachment.name?.split('.').last;
    }
    if (extension?.startsWith('.') == true) {
      extension = extension?.substring(1);
    }
    String fileType = _file_type_map[extension] ?? 'ic_file_unknown.svg';
    return "images/$fileType";
  }

  @override
  void initState() {
    super.initState();

    processStreamSub =
        ChatServiceObserverRepo.observeAttachmentProgress().listen((event) {
      Alog.d(
          tag: 'Download file',
          content:
              'observeAttachmentProgress = ${event.downloadParam?.messageClientId} progress = ${event.progress}');
      if (event.downloadParam?.messageClientId ==
          widget.message.messageClientId) {
        processValue = ((event.progress ?? 0) / 100).toDouble();
        processVisible = (processValue ?? 0) < 1.0;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    processStreamSub?.cancel();
    super.dispose();
  }

  String _getSizeFormat() {
    double size = attachment.size?.toDouble() ?? 0;
    if (size < 1000) {
      return "${size.toStringAsFixed(2)}B";
    } else if (size < 1000 * 1000) {
      return "${(size / 1000).toStringAsFixed(2)}KB";
    } else if (size < 1000 * 1000 * 1000) {
      return "${(size / 1000 / 1000).toStringAsFixed(2)}MB";
    } else {
      return "${(size / 1000 / 1000 / 1000).toStringAsFixed(2)}GB";
    }
  }

  bool _needAudioFocus() {
    String icon = _getIcon();
    return icon == 'images/ic_file_video.svg' ||
        icon == 'images/ic_file_audio.svg';
  }

  List<Widget> _getProcessArray() {
    return processVisible
        ? [
            SvgPicture.asset(
              _getIcon(),
              package: kPackage,
            ),
            Container(color: "#66000000".toColor()),
            Positioned(
              left: 11,
              top: 11,
              width: 10,
              height: 10,
              child: SvgPicture.asset(
                "images/ic_video_pause.svg",
                package: kPackage,
              ),
            ),
            Positioned(
              left: 6,
              top: 6,
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: processValue,
                color: Colors.white,
                backgroundColor: Colors.black38,
                strokeWidth: 2.0,
              ),
            ),
          ]
        : [
            SvgPicture.asset(
              _getIcon(),
              package: kPackage,
            )
          ];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (filePath?.isNotEmpty != true) {
          if (widget.independentFile) {
            var directory;
            if (Platform.isIOS) {
              directory = await getApplicationDocumentsDirectory();
            } else {
              directory = await getExternalStorageDirectory();
            }
            filePath =
                '${directory?.path}/${widget.message.messageClientId}/${attachment.name}';
          } else {
            filePath = attachment.path ?? '';
          }
        }
        if (!File(filePath!).existsSync()) {
          processValue = 0.0;
          if (widget.independentFile) {
            Dio().download(attachment.url!, filePath,
                onReceiveProgress: (count, total) {
              processValue = count / total;
              processVisible = (processValue ?? 0) < 1.0;
              setState(() {});
            });
          } else {
            var params = NIMDownloadMessageAttachmentParams(
              attachment: widget.message.attachment!,
              type: NIMDownloadAttachmentType.nimDownloadAttachmentTypeSource,
              thumbSize: NIMSize(),
              messageClientId: widget.message.messageClientId,
            );
            Alog.d(
                tag: 'Download file',
                content: 'messageClientId = ${widget.message.messageClientId}');
            ChatMessageRepo.downloadAttachment(params).then((result) {
              filePath = result.data;
              processValue = 1;
              processVisible = false;
              setState(() {});
              Alog.d(
                  tag: 'ChatKitMessageFileItem',
                  content: 'downloadAttachment result is $result');
            });
          }
        } else {
          if (_needAudioFocus()) {
            ChatAudioPlayer.instance.stopAll();
          }
          if (Platform.isAndroid) {
            OpenFilex.open(filePath!,
                type: support_type_map_android[attachment.ext?.toLowerCase()]);
          } else {
            OpenFilex.open(filePath!);
          }
        }
      },
      child: Container(
          padding:
              const EdgeInsets.only(left: 12, top: 10, right: 8, bottom: 10),
          decoration: BoxDecoration(
              color: widget.backgroundColor ?? Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CommonColors.color_dbe0e8, width: 0.5)),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  children: _getProcessArray(),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      getSingleMiddleEllipsisText(
                        attachment.name,
                        style: TextStyle(
                            fontSize: 14, color: CommonColors.color_333333),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          _getSizeFormat(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10, color: CommonColors.color_999999),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          )),
    );
  }
}
