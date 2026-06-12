// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nim_chatkit_pushkit/nim_chatkit_pushkit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  // ignore: use_super_parameters
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<PushKitMessage>? _subscription;
  PushKitMessage? _lastMessage;

  @override
  void initState() {
    super.initState();
    _initPushKit();
  }

  Future<void> _initPushKit() async {
    await PushKit.instance.init();
    _subscription = PushKit.instance.onNotificationClick.listen((message) {
      if (!mounted) return;
      setState(() {
        _lastMessage = message;
      });
    });
    final initialMessage = await PushKit.instance.getInitialNotification();
    if (!mounted || initialMessage == null) return;
    setState(() {
      _lastMessage = initialMessage;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('PushKit example')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Last push click: ${_lastMessage?.toMap()}'),
        ),
      ),
    );
  }
}
