// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_conversationkit_ui/model/conversation_info.dart';
import 'package:nim_conversationkit_ui/widgets/conversation_item.dart';
import 'package:nim_core_v2/nim_core.dart';

void main() {
  setUpAll(() {
    setupLocator();
    IMKitClient.enableAi = false;
    IMKitClient.enableRobot = false;
  });

  testWidgets('conversation name uses space left by the actual time text', (
    tester,
  ) async {
    final enableOnlineStatus = IMKitConfigCenter.enableOnlineStatus;
    IMKitConfigCenter.enableOnlineStatus = false;
    addTearDown(() {
      IMKitConfigCenter.enableOnlineStatus = enableOnlineStatus;
    });

    const name = 'A very long conversation name for the available width';
    final now = DateTime.now().millisecondsSinceEpoch;
    final conversation = ConversationInfo(
      NIMConversation(
        conversationId: 'conversation-a',
        type: NIMConversationType.p2p,
        name: name,
        mute: false,
        stickTop: false,
        createTime: now,
        updateTime: now,
        lastMessage: NIMLastMessage(
          messageRefer: NIMMessageRefer(createTime: now),
          messageType: NIMMessageType.text,
          text: 'last message',
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 320,
              child: ConversationItem(
                conversationInfo: conversation,
                config: const ConversationItemConfig(),
                index: 0,
              ),
            ),
          ),
        ),
      ),
    );

    final titleRect = tester.getRect(find.text(name));
    final timeRect = tester.getRect(find.textContaining(':'));
    expect(titleRect.width, greaterThan(150));
    expect(titleRect.right + 8, lessThanOrEqualTo(timeRect.left));
  });
}
