// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/neListView/frame_separate_widget.dart';
import 'package:nim_chatkit/location.dart';
import 'package:nim_chatkit_location/chat_kit_location.dart';
import 'package:nim_core/nim_core.dart';

import 'location_map_page.dart';

class ChatKitMessageLocationItem extends StatefulWidget {
  final NIMMessage message;

  const ChatKitMessageLocationItem({Key? key, required this.message})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageLocationState();
}

class ChatKitMessageLocationState extends State<ChatKitMessageLocationItem> {
  late bool _isReceive;

  late final NIMLocationAttachment _attachment =
      widget.message.messageAttachment as NIMLocationAttachment;

  @override
  void initState() {
    super.initState();
    _isReceive =
        widget.message.messageDirection == NIMMessageDirection.received;
  }

  Widget _placeHolder(double aspectRatio, {double? width}) {
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          decoration: const BoxDecoration(color: Colors.transparent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var locationStr =
        '${_attachment.longitude.toStringAsFixed(6)},${_attachment.latitude.toStringAsFixed(6)}';
    var appKey = ChatKitLocation.instance.aMapWebKey;
    var imageUrl =
        'https://restapi.amap.com/v3/staticmap?location=$locationStr&zoom=16&size=480*180&scale=2&key=$appKey';
    return FrameSeparateWidget.builder(
        id: widget.message.uuid,
        placeHolder: Container(
          width: 242,
          height: 140,
        ),
        builder: (context) => Container(
            width: 242,
            decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E5E8), width: 1),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(_isReceive ? 0 : 12),
                    topRight: Radius.circular(_isReceive ? 12 : 0),
                    bottomLeft: const Radius.circular(12),
                    bottomRight: const Radius.circular(12))),
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return LocationMapPage(
                    needLocate: false,
                    locationInfo: LocationInfo(
                        _attachment.latitude, _attachment.longitude,
                        address: _attachment.address,
                        name: widget.message.content),
                    showOpenMap: true,
                  );
                }));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.message.content?.isNotEmpty == true)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 11, left: 16, right: 16),
                      child: Text(widget.message.content!,
                          style: TextStyle(
                              fontSize: 16, color: '#333333'.toColor()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 3),
                    child: Text(_attachment.address,
                        style:
                            TextStyle(fontSize: 12, color: '#999999'.toColor()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  AbsorbPointer(
                    absorbing: true,
                    child: SizedBox(
                      height: 90,
                      width: 242,
                      child: Stack(alignment: Alignment.center, children: [
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          cacheKey: imageUrl,
                          placeholder: (context, url) => _placeHolder(24 / 9),
                          fit: BoxFit.fitWidth,
                          fadeInDuration: const Duration(milliseconds: 0),
                        ),
                        Positioned(
                            bottom: 45,
                            child: Image.asset(
                              'images/ic_location_marker.png',
                              width: 24,
                              height: 40,
                              package: ChatKitLocation.kPackage,
                            ))
                      ]),
                    ),
                  )
                ],
              ),
            )));
  }
}
