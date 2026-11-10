// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netease_common_ui/duo/duo_shell_controller.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_message_pop_menu.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/reaction/message_reaction_quick_bar.dart';
import 'package:nim_chatkit_ui/view_model/chat_view_model.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';

const double _windowWidth = 890;
const double _windowHeight = 420;
const double _duoLeftWidth = 318;
const double _duoToolbarWidth = 76;

ChatMessage _message({required bool isSelf}) {
  return ChatMessage(
    NIMMessage(
      messageType: NIMMessageType.text,
      isSelf: isSelf,
    )
      ..messageServerId = 'server-1'
      ..messageClientId = 'client-1'
      ..conversationId = 'conversation-1',
  );
}

ChatViewModel _viewModel() {
  return ChatViewModel(
    'conversation-1',
    NIMConversationType.p2p,
    initializeRuntime: false,
    currentAccountIdProvider: () => 'me',
  );
}

Widget _duoApp({
  required ChatViewModel viewModel,
  required void Function(BuildContext) onTargetContext,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const <Locale>[Locale('en'), Locale('zh')],
    home: ChangeNotifierProvider<ChatViewModel>.value(
      value: viewModel,
      child: Scaffold(
        body: Row(
          children: [
            // 左侧会话列表
            SizedBox(
              width: _duoLeftWidth,
              child: Container(
                key: const ValueKey<String>('duo-conversation-list'),
              ),
            ),
            // 右侧聊天页面
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: _duoToolbarWidth),
                child: Stack(
                  children: [
                    Positioned(
                      top: 320,
                      left: 0,
                      child: Builder(
                        builder: (context) {
                          onTargetContext(context);
                          return SizedBox(
                            key: const ValueKey<String>('duo-message-target'),
                            width: 120,
                            height: 40,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 右侧工具栏
            const SizedBox(width: _duoToolbarWidth),
          ],
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    setupLocator();
    getIt<IMLoginService>().userInfo = NIMUserInfo(accountId: 'me');
  });

  setUp(() {
    IMKitConfigCenter.enableMessageReaction = true;
    DuoShellController.instance
      ..enabled = true
      ..dual = true
      ..leftWidth = _duoLeftWidth
      ..toolbarWidth = _duoToolbarWidth;
  });

  tearDown(() {
    IMKitConfigCenter.enableMessageReaction = true;
    DuoShellController.instance
      ..enabled = false
      ..dual = false
      ..leftWidth = 0
      ..toolbarWidth = 0;
  });

  for (final isSelf in [false, true]) {
    testWidgets(
        'Duo dual-pane ${isSelf ? 'self' : 'received'} message menu stays in the chat pane',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(_windowWidth, _windowHeight);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final viewModel = _viewModel();
      addTearDown(viewModel.dispose);
      late BuildContext targetContext;
      await tester.pumpWidget(
        _duoApp(
          viewModel: viewModel,
          onTargetContext: (context) => targetContext = context,
        ),
      );

      final targetRect = tester.getRect(
        find.byKey(const ValueKey<String>('duo-message-target')),
      );
      final menu = ChatKitMessagePopMenu(
        _message(isSelf: isSelf),
        true,
        targetContext,
        globalPosition: targetRect.center,
      );
      menu.show();
      await tester.pump();

      final menuRect = tester.getRect(find.byType(MessageReactionQuickBar));
      final double paneLeft = _duoLeftWidth;
      final double paneRight = _windowWidth - _duoToolbarWidth;
      expect(menuRect.left, greaterThanOrEqualTo(paneLeft));
      expect(menuRect.right, lessThanOrEqualTo(paneRight));
      menu.close();
    });
  }
}
