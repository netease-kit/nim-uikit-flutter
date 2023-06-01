// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:nim_chatkit/location.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../../chat_kit_client.dart';
import '../../l10n/S.dart';

class LocationMapPage extends StatefulWidget {
  //显示中心定位位置
  final LocationInfo? locationInfo;

  //是否需要定位
  final bool needLocate;

  //是否展示吊起地图应用
  final bool showOpenMap;

  const LocationMapPage(
      {this.locationInfo, this.needLocate = false, this.showOpenMap = false});

  @override
  State<StatefulWidget> createState() => LocationMapPageState();
}

class LocationMapPageState extends State<LocationMapPage> {
  //高德默认的位置
  CameraPosition _position =
      CameraPosition(target: LatLng(39.909187, 116.397451), zoom: 18);

  AMapFlutterLocation? _location;

  StreamSubscription? _locationSub;

  //位置，省市县等
  String? _address;

  //具体位置描述
  String? _description;

  AMapController? _mapController;

  var _markers = const <Marker>{};

  void onMapCreated(AMapController controller) {
    _mapController = controller;
    if (widget.needLocate) {
      _location?.setLocationOption(AMapLocationOption());
      _location?.startLocation();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.locationInfo != null) {
      _position = CameraPosition(
          target: LatLng(
              widget.locationInfo!.latitude, widget.locationInfo!.longitude),
          zoom: 18);
      _updateMarker(
          widget.locationInfo!.latitude, widget.locationInfo!.longitude);
    }
    _initLocate();
  }

  Future<BitmapDescriptor> _getMarkerIcon() {
    return BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(24, 40)), 'images/2x/ic_my_location.png',
        package: kPackage);
  }

  void _initLocate() async {
    if (ChatKitClient.instance.aMapAndroidKey != null &&
        ChatKitClient.instance.aMapIOSKey != null) {
      AMapFlutterLocation.setApiKey(ChatKitClient.instance.aMapAndroidKey!,
          ChatKitClient.instance.aMapIOSKey!);
      _location = AMapFlutterLocation();
      _locationSub = _location?.onLocationChanged().listen((event) async {
        var longitude = (event['longitude'] is double)
            ? event['longitude'] as double
            : double.parse(event['longitude'] as String);
        var latitude = (event['latitude'] is double)
            ? event['latitude'] as double
            : double.parse(event['latitude'] as String);
        _address = event['address'] as String?;
        _description = event['description'] as String?;
        _position = CameraPosition(target: LatLng(latitude, longitude));
        _mapController?.moveCamera(
            CameraUpdate.newLatLngZoom(LatLng(latitude, longitude), 18));
        _updateMarker(latitude, longitude);
        if (_address != null && _description != null) {
          _location?.stopLocation();
        }
      });
    }
  }

  void _updateMarker(double latitude, double longitude) async {
    var icon = await _getMarkerIcon();
    Marker marker = Marker(position: LatLng(latitude, longitude), icon: icon);
    _markers = Set<Marker>.of([marker]);
    if (mounted) {
      setState(() {});
    }
  }

  //点击发送位置消息
  void _sendMessage(BuildContext context) {
    if (_description?.substring(0, 1) == '在') {
      _description = _description?.substring(1);
    }
    Navigator.pop(
        context,
        _address?.isNotEmpty == true
            ? LocationInfo(
                _position.target.latitude, _position.target.longitude,
                address: _address, name: _description)
            : null);
  }

  AppBar _getAppBar() {
    if (widget.needLocate) {
      return AppBar(
        backgroundColor: '#00000000'.toColor(),
        elevation: 0,
        leading: TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            S.of(context).messageCancel,
            style: TextStyle(fontSize: 16, color: '#FFFFFF'.toColor()),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () async {
                if (await haveConnectivity()) {
                  _sendMessage(context);
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 7, horizontal: 16),
                decoration: BoxDecoration(
                    color: '#337EFF'.toColor(),
                    borderRadius: BorderRadius.all(Radius.circular(4))),
                child: Text(S.of(context).chatMessageSend,
                    style: TextStyle(
                      fontSize: 16,
                      color: '#ffffff'.toColor(),
                    )),
              ))
        ],
      );
    } else {
      return AppBar(
        backgroundColor: '#00000000'.toColor(),
        elevation: 0,
        leading: IconButton(
          iconSize: 32,
          onPressed: () {
            Navigator.pop(context);
          },
          icon: SvgPicture.asset(
            'images/ic_map_back.svg',
            package: kPackage,
          ),
        ),
      );
    }
  }

  void _showMapSelector() {
    var style = const TextStyle(fontSize: 16, color: CommonColors.color_333333);
    showBottomChoose<int>(context: context, actions: [
      CupertinoActionSheetAction(
        onPressed: () {
          Navigator.pop(context, 1);
        },
        child: Text(
          S.of(context).chatMessageAMap,
          style: style,
        ),
      ),
      CupertinoActionSheetAction(
        onPressed: () {
          Navigator.pop(context, 2);
        },
        child: Text(
          S.of(context).chatMessageTencentMap,
          style: style,
        ),
      )
    ]).then((result) {
      if (result == 1) {
        _openAMap(_position.target.longitude, _position.target.latitude,
            address: widget.locationInfo?.address);
      } else if (result == 2) {
        _openTencentMap(_position.target.longitude, _position.target.latitude,
            address: widget.locationInfo?.address);
      }
    });
  }

  //跳转打开高德地图
  void _openAMap(double longitude, double latitude, {String? address}) async {
    var url =
        '${Platform.isAndroid ? 'android' : 'ios'}amap://viewMap?sourceApplication=NIMUIKit&poiname=$address&lat=$latitude&lon=$longitude&dev=0';
    if (Platform.isIOS) url = Uri.encodeFull(url);
    try {
      launchUrlString(url, mode: LaunchMode.externalApplication).then((value) {
        if (!value) {
          Fluttertoast.showToast(msg: S.of(context).chatMessageAMapNotFound);
        }
      });
    } on Exception catch (e) {
      Alog.e(tag: 'LocationPage', content: 'jump A Map error ${e.toString()}');
    }
  }

  //打开腾讯地图
  void _openTencentMap(double longitude, double latitude, {String? address}) {
    var baseUrl = 'qqmap://map/';
    String drivePlan =
        "routeplan?type=drive&from=我的位置&fromcoord=&to=$address&tocoord=$latitude,$longitude&policy=1";
    String tencentUri = baseUrl + drivePlan + "&referer=imuikit";
    if (Platform.isIOS) tencentUri = Uri.encodeFull(tencentUri);
    try {
      launchUrlString(tencentUri, mode: LaunchMode.externalApplication)
          .then((value) {
        if (!value) {
          Fluttertoast.showToast(
              msg: S.of(context).chatMessageTencentMapNotFound);
        }
      });
    } on Exception catch (e) {
      Alog.e(
          tag: 'LocationPage',
          content: 'jump Tencent Map error ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _getAppBar(),
      body: Stack(
        children: [
          AMapWidget(
            apiKey: AMapApiKey(
                androidKey: ChatKitClient.instance.aMapAndroidKey,
                iosKey: ChatKitClient.instance.aMapIOSKey),
            privacyStatement: AMapPrivacyStatement(
                hasShow: true, hasAgree: true, hasContains: true),
            onMapCreated: onMapCreated,
            initialCameraPosition: _position,
            scaleEnabled: false,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
            markers: _markers,
          ),
          if (widget.locationInfo != null)
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      EdgeInsets.only(top: 10, left: 12, right: 12, bottom: 10),
                  constraints: BoxConstraints(maxHeight: 70),
                  color: '#ffffff'.toColor(),
                  child: Stack(
                    children: [
                      Positioned(
                          child: Padding(
                        padding: EdgeInsets.only(right: 50),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.locationInfo?.name?.isNotEmpty == true)
                              Text(widget.locationInfo!.name!,
                                  style: TextStyle(
                                      color: '#333333'.toColor(), fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            if (widget.locationInfo?.address?.isNotEmpty ==
                                true)
                              Text(widget.locationInfo!.address!,
                                  style: TextStyle(
                                      color: '#B3B7BC'.toColor(), fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      )),
                      Positioned(
                        right: 0,
                        child: IconButton(
                            onPressed: _showMapSelector,
                            icon: SvgPicture.asset(
                              'images/ic_jump_to_map.svg',
                              package: kPackage,
                            )),
                      )
                    ],
                  ),
                ))
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    //停止定位
    _location?.stopLocation();
    _location?.destroy();
    _locationSub?.cancel();
  }
}
