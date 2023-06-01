// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nim_core/nim_core.dart';

class ChatThumbView extends StatefulWidget {
  const ChatThumbView(
      {Key? key, required this.message, required this.radius, this.onTap})
      : super(key: key);

  final NIMMessage message;
  final BorderRadius radius;
  final Function()? onTap;

  @override
  State<StatefulWidget> createState() => _ChatThumbViewState();
}

class _ChatThumbViewState extends State<ChatThumbView> {
  _isSelf() {
    return widget.message.messageDirection == NIMMessageDirection.outgoing;
  }

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

  Widget _localImage(String path) {
    double aspectRatio = _getImageRatio();
    return Stack(
      alignment: _isSelf()
          ? AlignmentDirectional.topEnd
          : AlignmentDirectional.topStart,
      children: [
        _placeHolder(aspectRatio),
        getImage(Image.file(
          File(path),
          fit: BoxFit.fitWidth,
        ))
      ],
    );
  }

  Widget _networkImage(String url) {
    return getImage(CachedNetworkImage(
      imageUrl: url,
      cacheKey: url,
      placeholder: (context, url) => _placeHolder(1),
      fit: BoxFit.fitWidth,
      fadeInDuration: const Duration(milliseconds: 0),
    ));
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
    String url = _getUrlForVideo() ?? "";
    return url.isNotEmpty ? _networkImage(url) : _placeHolder(_getImageRatio());
  }

  String? _getPathForVideo() {
    if (widget.message.messageAttachment is NIMVideoAttachment) {
      return (widget.message.messageAttachment as NIMVideoAttachment).thumbPath;
    }
    return "";
  }

  String? _getUrlForVideo() {
    if (widget.message.messageAttachment is NIMVideoAttachment) {
      return (widget.message.messageAttachment as NIMVideoAttachment).thumbUrl;
    }
    return "";
  }

  Widget _imageBuilderForPicture() {
    String url = _getUrlForImage();
    String path = _getPathForImage();
    if (path.isNotEmpty &&
        (widget.message.messageDirection == NIMMessageDirection.outgoing ||
            widget.message.attachmentStatus ==
                NIMMessageAttachmentStatus.transferred)) {
      return _localImage(path);
    }
    if (url.isNotEmpty &&
        widget.message.attachmentStatus ==
            NIMMessageAttachmentStatus.transferred) {
      return _networkImage(url);
    }
    return _placeHolder(_getImageRatio());
  }

  String _getPathForImage() {
    if (widget.message.messageAttachment is NIMImageAttachment) {
      NIMImageAttachment attachment =
          widget.message.messageAttachment as NIMImageAttachment;
      return attachment.path ?? attachment.thumbPath ?? "";
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

  bool _fileExistCheck(String path) {
    bool exist = path.isNotEmpty && File(path).existsSync();
    if (!exist) {
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
