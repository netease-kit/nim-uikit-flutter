// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/widgets/chat_thumb_view.dart';
import 'package:nim_core_v2/nim_core.dart';

void main() {
  Widget buildThumb(NIMMessage message, {Key? key}) {
    return MaterialApp(
      home: Scaffold(
        body: ChatThumbView(
          key: key,
          message: message,
          radius: BorderRadius.zero,
        ),
      ),
    );
  }

  NIMMessage buildMessage({
    required bool isSelf,
    int width = 100,
    int height = 100,
  }) {
    final attachment = NIMMessageImageAttachment(width: width, height: height)
      ..path = 'emoji/default/emoji_50.png'
      ..url = 'https://example.invalid/image'
      ..ext = 'gif';
    return NIMMessage(
      isSelf: isSelf,
      messageType: NIMMessageType.image,
      attachment: attachment,
    );
  }

  testWidgets('received image keeps using its remote thumbnail after download',
      (tester) async {
    await tester.pumpWidget(buildThumb(buildMessage(isSelf: false)));

    expect(find.byType(CachedNetworkImage), findsOneWidget);
  });

  testWidgets('sent image still uses its local image', (tester) async {
    await tester.pumpWidget(buildThumb(buildMessage(isSelf: true)));

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('sent and received copies use the same attachment-based size',
      (tester) async {
    const sentKey = ValueKey('sent-image');
    const receivedKey = ValueKey('received-image');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              ChatThumbView(
                key: sentKey,
                message: buildMessage(
                  isSelf: true,
                  width: 400,
                  height: 200,
                ),
                radius: BorderRadius.zero,
              ),
              ChatThumbView(
                key: receivedKey,
                message: buildMessage(
                  isSelf: false,
                  width: 400,
                  height: 200,
                ),
                radius: BorderRadius.zero,
              ),
            ],
          ),
        ),
      ),
    );

    final sentSize = tester.getSize(find.byKey(sentKey));
    final receivedSize = tester.getSize(find.byKey(receivedKey));
    expect(sentSize.width, receivedSize.width);
    expect(sentSize.height, receivedSize.height);
    expect(sentSize.width, closeTo(222, 0.001));
    expect(sentSize.height, closeTo(111, 0.001));
  });
}
