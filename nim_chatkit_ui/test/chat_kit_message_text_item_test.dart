// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit/message/message_translation.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_text_item.dart';
import 'package:nim_core_v2/nim_core.dart';

void main() {
  const robotId = 'robot-account';

  testWidgets('robot message displays translated content', (tester) async {
    final message = NIMMessage(
      messageType: NIMMessageType.text,
      text: '**Robot message**',
      aiConfig: NIMMessageAIConfig(
        accountId: robotId,
        aiStatus: NIMMessageAIStatus.response,
      ),
    )..senderId = robotId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatKitMessageTextItem(
            message: message,
            translationState: const MessageTranslationState(
              translation: MessageTranslationInfo(
                targetLanguage: 'zh-CHS',
                sourceLanguage: 'en',
                text: '机器人消息',
                translatedAt: 1,
                source: MessageTranslationSource.manual,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Robot message'), findsOneWidget);
    expect(find.text('机器人消息'), findsOneWidget);
  });

  testWidgets('AI message displays translated content', (tester) async {
    final message = NIMMessage(
      messageType: NIMMessageType.text,
      text: 'AI response',
      aiConfig: NIMMessageAIConfig(
        accountId: 'ai-account',
        aiStatus: NIMMessageAIStatus.response,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatKitMessageTextItem(
            message: message,
            translationState: const MessageTranslationState(
              translation: MessageTranslationInfo(
                targetLanguage: 'zh-CHS',
                sourceLanguage: 'en',
                text: 'AI 回复',
                translatedAt: 1,
                source: MessageTranslationSource.manual,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('AI response'), findsOneWidget);
    expect(find.text('AI 回复'), findsOneWidget);
  });

  testWidgets('mention-only message does not display translation content', (
    tester,
  ) async {
    final message = NIMMessage(
      messageType: NIMMessageType.text,
      text: '@Alice ',
      serverExtension: jsonEncode({
        'yxAitMsg': {
          'alice': {
            'text': '@Alice ',
            'segments': [
              {'start': 0, 'end': 6, 'broken': false},
            ],
          },
        },
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatKitMessageTextItem(message: message),
        ),
      ),
    );

    expect(find.text('@Alice ', findRichText: true), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets('secondary tap on translation reports translated text',
      (tester) async {
    const translatedText = 'Translated text';
    String? selectedText;
    final message = NIMMessage(
      messageType: NIMMessageType.text,
      text: 'Original text',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatKitMessageTextItem(
            message: message,
            translationState: const MessageTranslationState(
              translation: MessageTranslationInfo(
                targetLanguage: 'en',
                sourceLanguage: 'zh-CHS',
                text: translatedText,
                translatedAt: 1,
                source: MessageTranslationSource.manual,
              ),
            ),
            onTranslationSecondaryTap: (context, details, text) {
              selectedText = text;
            },
          ),
        ),
      ),
    );

    await tester.tap(
      find.text(translatedText),
      buttons: kSecondaryMouseButton,
    );

    expect(selectedText, translatedText);
  });
}
