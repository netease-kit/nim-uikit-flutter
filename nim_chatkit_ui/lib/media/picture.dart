// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nim_chatkit/extension.dart';
import 'package:nim_chatkit_ui/media/media_bottom_actions.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class PictureViewer extends StatefulWidget {
  const PictureViewer(
      {Key? key, required this.messages, required this.showIndex})
      : super(key: key);

  final List<NIMMessage> messages;
  final int showIndex;

  @override
  State<StatefulWidget> createState() => _PictureViewerState();
}

class _PictureViewerState extends State<PictureViewer> {
  late List<NIMMessage> _galleryItems;
  late int _currentIndex;

  void _logI(String content) {
    Alog.i(tag: 'ChatKit', moduleName: 'picture view', content: content);
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    NIMMessage message = _galleryItems[index];
    NIMMessageImageAttachment attachment =
        message.attachment as NIMMessageImageAttachment;
    String path = attachment.path ?? "";
    _logI('build item index:$index ${message.messageClientId}');
    ImageProvider imageProvider;
    //如果不存在则下载，下载成功之后会调用onMessageStatusChange 的回调，然后更新
    if (!message.isFileDownload()) {
      _logI('to download image -->> ${message.messageClientId}');
      NIMDownloadMessageAttachmentParams params =
          NIMDownloadMessageAttachmentParams(
        attachment: message.attachment!,
        type: NIMDownloadAttachmentType.nimDownloadAttachmentTypeSource,
        thumbSize: NIMSize(),
        messageClientId: message.messageClientId,
      );

      NimCore.instance.storageService.downloadAttachment(params).then((result) {
        if (result.isSuccess) {
          int pos = index;

          if (pos > -1) {
            var attachment = message.attachment as NIMMessageImageAttachment;
            attachment.path = result.data;
            _galleryItems[pos].attachment = attachment;
            setState(() {});
            _logI('download finish, update $pos');
          }
        }
      });
    }
    String? url = attachment.url;
    _logI('load from url:$url, path:$path');
    if (url != null) {
      imageProvider = CachedNetworkImageProvider(url);
    } else {
      imageProvider = FileImage(File(path));
    }
    return PhotoViewGalleryPageOptions(
        imageProvider: imageProvider,
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.contained * 2,
        heroAttributes: PhotoViewHeroAttributes(
            tag: '${message.messageServerId}${message.messageClientId}'),
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return Container();
        });
  }

  @override
  void initState() {
    super.initState();
    _galleryItems = widget.messages;
    _currentIndex = widget.showIndex > 0 ? widget.showIndex : 0;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            gaplessPlayback: true,
            reverse: true,
            builder: _buildItem,
            itemCount: _galleryItems.length,
            pageController: PageController(initialPage: _currentIndex),
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          MediaBottomActionOverlay(_galleryItems[_currentIndex]),
        ],
      ),
    );
  }
}
