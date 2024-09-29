// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:netease_corekit_im/services/message/chat_message.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_core/nim_core.dart';

class ChatThumbView extends StatefulWidget {
  const ChatThumbView(
      {Key? key,
      required this.message,
      required this.radius,
      this.onTap,
      this.thumbFromRemote = false})
      : super(key: key);

  final NIMMessage message;
  final BorderRadius radius;
  final Function()? onTap;

  final bool thumbFromRemote;

  @override
  State<StatefulWidget> createState() => _ChatThumbViewState();
}

class _ChatThumbViewState extends State<ChatThumbView> {
  static const String gifType = 'gif';

  _isSelf() {
    return widget.message.messageDirection == NIMMessageDirection.outgoing;
  }

  //发送的时候本地路径保存，Android 端在发送成功后会将文件copy到缓存，
  // 导致本地Path变更，图片会闪烁，此字段不更新，解决发送消息后闪烁问题
  String? _localPath;

  double _getImageRatio() {
    var attachment;
    if (widget.message.messageAttachment is NIMImageAttachment) {
      attachment = widget.message.messageAttachment as NIMImageAttachment;
    } else if (widget.message.messageAttachment is NIMVideoAttachment) {
      attachment = widget.message.messageAttachment as NIMVideoAttachment;
    }
    if (attachment.width != null &&
        attachment.width != 0 &&
        attachment.height != null &&
        attachment.height != 0) {
      return attachment.width! / attachment.height!;
    }
    return 1.0;
  }

  Widget _placeHolder(double aspectRatio, {double? width}) {
    final imagePlaceHolder =
        ChatKitClient.instance.chatUIConfig.imagePlaceHolder;
    if (imagePlaceHolder != null) {
      return imagePlaceHolder.call(aspectRatio, width: width);
    }
    return Container(
      width: width,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          decoration: const BoxDecoration(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget getImage(Widget image) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffe2e5e8), width: 1),
          borderRadius: widget.radius),
      child: ClipRRect(
        borderRadius: widget.radius,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Hero(
            tag: '${widget.message.messageId}${widget.message.uuid}',
            child: image,
          ),
        ),
      ),
    );
  }

  Widget _networkImage(String url) {
    return getImage(CachedNetworkImage(
      imageUrl: url,
      cacheKey: url,
      placeholder: (context, url) => _placeHolder(_getImageRatio()),
      fit: BoxFit.fitWidth,
      fadeInDuration: const Duration(milliseconds: 0),
    ));
  }

  Widget _localImage(String path) {
    return Stack(
      alignment: _isSelf()
          ? AlignmentDirectional.topEnd
          : AlignmentDirectional.topStart,
      children: [
        getImage(Image.file(
          File(path),
          fit: BoxFit.fitWidth,
        ))
      ],
    );
  }

  Widget _imageBuilder() {
    if (widget.message.messageAttachment is NIMImageAttachment) {
      return _imageBuilderForPicture();
    } else if (widget.message.messageAttachment is NIMVideoAttachment) {
      return _imageBuilderForVideo();
    }
    return _placeHolder(1);
  }

  Widget _imageBuilderForVideo() {
    String path = _getPathForVideo() ?? "";
    if (_fileExistCheck(path)) {
      return _localImage(path);
    }
    if (widget.thumbFromRemote && _getUrlForVideo().isNotEmpty) {
      return _networkImage(_getUrlForVideo());
    }
    return _placeHolder(_getImageRatio());
  }

  String? _getPathForVideo() {
    if (_localPath?.isNotEmpty == true) {
      return _localPath;
    }
    if (widget.message.messageAttachment is NIMVideoAttachment) {
      var thumbPath =
          (widget.message.messageAttachment as NIMVideoAttachment).thumbPath;
      if (widget.message.messageDirection == NIMMessageDirection.outgoing) {
        _localPath = thumbPath;
      }
      return thumbPath;
    }
    return "";
  }

  Widget _imageBuilderForPicture() {
    String path = _getPathForImage();
    if (_fileExistCheck(path)) {
      return _localImage(path);
    }
    if (_isGif() ||
        widget.thumbFromRemote ||
        (widget.message.attachmentStatus !=
                NIMMessageAttachmentStatus.transferred ||
            widget.message.attachmentStatus !=
                NIMMessageAttachmentStatus.failed)) {
      var url = _getUrlForImage();
      return _networkImage(url);
    }
    return _placeHolder(_getImageRatio());
  }

  String _getPathForImage() {
    if (_localPath?.isNotEmpty == true) {
      return _localPath!;
    }
    if (widget.message.messageAttachment is NIMImageAttachment) {
      NIMImageAttachment attachment =
          widget.message.messageAttachment as NIMImageAttachment;
      var path = attachment.path ?? attachment.thumbPath ?? "";
      //如果是gif图片，直接使用原图
      if (_isGif()) {
        path = attachment.path ?? "";
      }
      if (widget.message.messageDirection == NIMMessageDirection.outgoing) {
        _localPath = path;
      }
      return path;
    }
    return "";
  }

  String _getUrlForImage() {
    if (widget.message.messageAttachment is NIMImageAttachment) {
      NIMImageAttachment attachment =
          widget.message.messageAttachment as NIMImageAttachment;
      return attachment.url ?? attachment.thumbUrl ?? "";
    }
    return "";
  }

  String _getUrlForVideo() {
    if (widget.message.messageAttachment is NIMVideoAttachment) {
      NIMVideoAttachment attachment =
          widget.message.messageAttachment as NIMVideoAttachment;
      return attachment.thumbUrl ?? "";
    }
    return "";
  }

  bool _isGif() {
    //如果remoteExtension中有ImageType字段，且值为gif，则为gif图片
    if (widget.message.remoteExtension?[ChatMessage.keyImageType] == gifType) {
      return true;
    }
    if (widget.message.messageAttachment is NIMImageAttachment) {
      NIMImageAttachment attachment =
          widget.message.messageAttachment as NIMImageAttachment;
      //如果url或者path中包含gif，则为gif图片
      if (attachment.url != null &&
          attachment.url?.substring(attachment.url!.lastIndexOf('.') + 1) ==
              gifType) {
        return true;
      }
      if (attachment.path != null &&
          attachment.path?.substring(attachment.path!.lastIndexOf('.') + 1) ==
              gifType) {
        return true;
      }
    }
    return false;
  }

  bool _fileExistCheck(String path) {
    bool exist = path.isNotEmpty && File(path).existsSync();
    //localPath置为无效
    if (!exist) {
      _localPath = '';
    }
    // 本地文件不存在，下载
    // gif图片不下载缩略图
    // 如果已经下载完成或者失败，不重新下载
    if (!exist &&
        !_isGif() &&
        _getUrlForVideo().isNotEmpty &&
        !(widget.message.attachmentStatus ==
                NIMMessageAttachmentStatus.transferred ||
            widget.message.attachmentStatus ==
                NIMMessageAttachmentStatus.failed)) {
      NimCore.instance.messageService
          .downloadAttachment(message: widget.message, thumb: true);
    }
    return exist;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 222, maxHeight: 222),
      child: _imageBuilder(),
    );
  }
}
