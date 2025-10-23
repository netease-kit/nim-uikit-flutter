// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/helper/thumb_helper.dart';
import 'package:nim_core_v2/nim_core.dart';

class ChatThumbView extends StatefulWidget {
  const ChatThumbView(
      {Key? key,
      required this.message,
      required this.radius,
      this.onTap,
      this.thumbFromRemote = true})
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
    return widget.message.isSelf == true;
  }

  //发送的时候本地路径保存，Android 端在发送成功后会将文件copy到缓存，
  // 导致本地Path变更，图片会闪烁，此字段不更新，解决发送消息后闪烁问题
  String? _localPath;

  double _getImageRatio() {
    var attachment;
    if (widget.message.attachment is NIMMessageImageAttachment) {
      attachment = widget.message.attachment as NIMMessageImageAttachment;
    } else if (widget.message.attachment is NIMMessageVideoAttachment) {
      attachment = widget.message.attachment as NIMMessageVideoAttachment;
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
          decoration: const BoxDecoration(color: Colors.black26),
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
            tag:
                '${widget.message.messageServerId}${widget.message.messageClientId}',
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
    if (widget.message.attachment is NIMMessageImageAttachment) {
      return _imageBuilderForPicture();
    } else if (widget.message.attachment is NIMMessageVideoAttachment) {
      return _imageBuilderForVideo();
    }
    return _placeHolder(1);
  }

  Widget _imageBuilderForVideo() {
    if (widget.thumbFromRemote && _getUrlForVideo().isNotEmpty) {
      return _networkImage(_getUrlForVideo());
    }
    return _placeHolder(_getImageRatio());
  }

  Widget _imageBuilderForPicture() {
    String path = _getPathForImage();
    if (_fileExistCheck(path)) {
      return _localImage(path);
    }
    var url = _getUrlForImage();
    return _networkImage(url);
  }

  String _getPathForImage() {
    if (_localPath?.isNotEmpty == true) {
      return _localPath!;
    }
    if (widget.message.attachment is NIMMessageImageAttachment) {
      NIMMessageImageAttachment attachment =
          widget.message.attachment as NIMMessageImageAttachment;
      var path = attachment.path ?? "";
      if (widget.message.isSelf == true) {
        _localPath = path;
      }
      return path;
    }
    return "";
  }

  String _getUrlForImage() {
    if (widget.message.attachment is NIMMessageImageAttachment) {
      NIMMessageImageAttachment attachment =
          widget.message.attachment as NIMMessageImageAttachment;
      var thumbUrl = ThumbHelper.makeImageThumbUrl(context,
          attachment.url ?? '', attachment.width ?? 0, attachment.height ?? 0);
      return thumbUrl ?? "";
    }
    return "";
  }

  String _getUrlForVideo() {
    if (widget.message.attachment is NIMMessageVideoAttachment) {
      NIMMessageVideoAttachment attachment =
          widget.message.attachment as NIMMessageVideoAttachment;
      var thumbUrl = ThumbHelper.makeVideoThumbUrl(attachment.url);
      return thumbUrl ?? "";
    }
    return "";
  }

  bool _fileExistCheck(String path) {
    bool exist = path.isNotEmpty && File(path).existsSync();
    //localPath置为无效
    if (!exist) {
      _localPath = '';
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
