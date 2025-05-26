// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:im_demo/src/config.dart';
import 'package:im_demo/src/home/home_page.dart';
import 'package:im_demo/src/home/welcome_page.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

class SplashPage extends StatefulWidget {
  final Uint8List? deviceToken;

  const SplashPage({Key? key, this.deviceToken}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SplashState();
}

class _SplashState extends State<SplashPage> {
  bool toLogin = false;

  bool haveLogin = false;

  @override
  Widget build(BuildContext context) {
    if(haveLogin){
      return const HomePage();
    }else{
      return Scaffold(
        body: Center(
          child: Text("will go to homePage after login...",style: TextStyle(fontSize: 16),),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    //init IM SDK
    _doInit(IMDemoConfig.AppKey);
  }

  void updateAPNsToken() {
    if (NimCore.instance.isInitialized &&
        Platform.isIOS &&
        widget.deviceToken != null) {
      NimCore.instance.apnsService.updateApnsToken(widget.deviceToken!);
    }
  }

  /// init depends package for app
  void _doInit(String appKey) async {

    var options =
        await NIMSDKOptionsConfig.getSDKOptions(appKey);

    IMKitClient.init(appKey, options).then((success) {
      if (success) {
        startLogin();
      } else {
        Alog.d(content: "im init failed");
      }
    }).catchError((e) {
      Alog.d(content: 'im init failed with error ${e.toString()}');
    });
  }

  void startLogin(){
    //fixme 将您的云信IM账号(accid)和Token设置在这里即可
    String account = "your account";
    String token = "your token";
    IMKitClient.loginIM(
         account,
        token)
        .then((value) {
      if(value){
        updateAPNsToken();
        setState((){
          haveLogin = true;
        });
      }
    });
  }
}
