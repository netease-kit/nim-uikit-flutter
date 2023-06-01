// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:nim_chatkit/extension.dart';
import 'package:nim_chatkit_ui/media/media_bottom_actions.dart';
import 'package:flutter/material.dart';
import 'package:nim_core/nim_core.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

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
  late StreamSubscription _subscription;
  late List<NIMMessage> _galleryItems;
  late int _currentIndex;

  void _logI(String content) {
    Alog.i(tag: 'ChatKit', moduleName: 'picture view', content: content);
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    NIMMessage message = _galleryItems[index];
    NIMImageAttachment attachment =
        message.messageAttachment as NIMImageAttachment;
    String path = attachment.path ?? attachment.thumbPath ?? "";
    _logI('build item index:$index ${message.uuid}');
    ImageProvider imageProvider;
    //如果不存在则下载，下载成功之后会调用onMessageStatusChange 的回调，然后更新
    if (!message.isFileDownload()) {
      _logI('to download image -->> ${message.uuid}');
      NimCore.instance.messageService
          .downloadAttachment(message: message, thumb: false);
    }
    String? url = attachment.url ?? attachment.thumbUrl;
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
        heroAttributes:
            PhotoViewHeroAttributes(tag: '${message.messageId}${message.uuid}'),
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
    _subscription =
        NimCore.instance.messageService.onMessageStatus.listen((event) {
      _logI('onMessageStatus ${event.uuid} ${event.attachmentStatus}');
      if (event.isFileDownload()) {
        int pos = -1;
        for (int i = 0; i < _galleryItems.length; ++i) {
          if (_galleryItems[i].isSameMessage(event)) {
            pos = i;
            break;
          }
        }
        if (pos > -1) {
          _galleryItems[pos] = event;
          setState(() {});
          _logI('download finish, update $pos');
        }
      }
    });
    _galleryItems = widget.messages;
    _currentIndex = widget.showIndex > 0 ? widget.showIndex : 0;
  }

  @override
  void dispose() {
    _subscription.cancel();
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
