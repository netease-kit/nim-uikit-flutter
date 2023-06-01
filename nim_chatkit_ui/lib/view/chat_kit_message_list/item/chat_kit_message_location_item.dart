// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/location.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_core/nim_core.dart';

import '../../page/location_map_page.dart';

class ChatKitMessageLocationItem extends StatefulWidget {
  final NIMMessage message;

  final ChatUIConfig? chatUIConfig;

  const ChatKitMessageLocationItem(
      {Key? key, required this.message, this.chatUIConfig})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageLocationState();
}

class ChatKitMessageLocationState extends State<ChatKitMessageLocationItem> {
  late bool _isReceive;

  late NIMLocationAttachment _attachment =
      widget.message.messageAttachment as NIMLocationAttachment;

  BitmapDescriptor? _icon;

  @override
  void initState() {
    super.initState();
    _isReceive =
        widget.message.messageDirection == NIMMessageDirection.received;
    BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(24, 40)),
            'images/2x/ic_location_marker.png',
            package: kPackage)
        .then((value) {
      _icon = value;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    address: _attachment.address, name: widget.message.content),
                showOpenMap: true,
              );
            }));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.message.content?.isNotEmpty == true)
                Padding(
                  padding: EdgeInsets.only(top: 11, left: 16, right: 16),
                  child: Text(widget.message.content!,
                      style:
                          TextStyle(fontSize: 16, color: '#333333'.toColor()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              Padding(
                padding: EdgeInsets.only(left: 16, right: 16, bottom: 3),
                child: Text(_attachment.address,
                    style: TextStyle(fontSize: 12, color: '#999999'.toColor()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              AbsorbPointer(
                absorbing: true,
                child: SizedBox(
                  height: 90,
                  child: AMapWidget(
                      apiKey: AMapApiKey(
                          androidKey: ChatKitClient.instance.aMapAndroidKey,
                          iosKey: ChatKitClient.instance.aMapIOSKey),
                      privacyStatement: AMapPrivacyStatement(
                          hasContains: true, hasAgree: true, hasShow: true),
                      initialCameraPosition: CameraPosition(
                          target: LatLng(
                              _attachment.latitude, _attachment.longitude),
                          zoom: 17),
                      markers: {
                        Marker(
                            position: LatLng(
                                _attachment.latitude, _attachment.longitude),
                            icon: _icon ?? BitmapDescriptor.defaultMarker)
                      },
                      scaleEnabled: false,
                      scrollGesturesEnabled: false,
                      touchPoiEnabled: false,
                      rotateGesturesEnabled: false,
                      zoomGesturesEnabled: false),
                ),
              )
            ],
          ),
        ));
  }
}
