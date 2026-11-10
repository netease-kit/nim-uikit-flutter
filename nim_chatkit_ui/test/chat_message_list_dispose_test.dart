// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/chat_kit_message_list.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_item.dart';
import 'package:nim_chatkit_ui/view_model/chat_view_model.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:visibility_detector/visibility_detector.dart';

NIMMessage _message(String id, int createTime) => NIMMessage(isSelf: false)
  ..conversationId = 'conversation-a'
  ..messageClientId = id
  ..messageServerId = id
  ..senderId = 'other'
  ..createTime = createTime
  ..messageType = NIMMessageType.text
  ..text = id;

void main() {
  setUpAll(() {
    setupLocator();
    getIt<IMLoginService>().userInfo = NIMUserInfo(accountId: 'self');
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets(
    'disposed message list ignores later scroll controller notifications',
    (tester) async {
      final scrollController = AutoScrollController();
      final viewModel = ChatViewModel(
        'conversation-a',
        NIMConversationType.p2p,
        initializeRuntime: false,
      );
      addTearDown(scrollController.dispose);
      addTearDown(viewModel.dispose);
      viewModel.messageList = List.generate(
        20,
        (index) => ChatMessage(_message('message-$index', index + 1)),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ChatViewModel>.value(
          value: viewModel,
          child: MaterialApp(
            home: Scaffold(
              body: ChatKitMessageList(
                scrollController: scrollController,
                messageBuilder: ChatKitMessageBuilder()
                  ..textMessageBuilder = (message) => SizedBox(
                        height: 72,
                        child: Text(message.text!),
                      ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 移除消息列表，触发 State.dispose。scrollController 仍由测试持有，
      // 模拟聊天页切换后 scroll_to_index 异步动画继续通知的场景。
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      await tester.pumpAndSettle();

      // 复用同一个 controller 挂到新的滚动视图并触发滚动通知。
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              controller: scrollController,
              itemCount: 30,
              itemBuilder: (_, index) => SizedBox(
                height: 80,
                child: Text('item-$index'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
