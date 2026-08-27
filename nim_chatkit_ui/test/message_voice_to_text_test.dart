// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit/message/message_voice_to_text.dart';
import 'package:nim_core_v2/nim_core.dart';

void main() {
  const persistedInfo = MessageVoiceToTextInfo(
    text: 'persisted voice text',
    convertedAt: 100,
    source: 'manual',
  );

  test('does not restore voice-to-text state from message local extension', () {
    final message = NIMMessage(messageType: NIMMessageType.audio)
      ..localExtension = MessageVoiceToTextHelper.mergeVoiceToText(
        null,
        persistedInfo,
      );

    final state = MessageVoiceToTextHelper.resolveVoiceToTextState(message);

    expect(state, isNull);
  });

  test('uses current chat page memory state instead of local extension', () {
    final message = NIMMessage(messageType: NIMMessageType.audio)
      ..localExtension = MessageVoiceToTextHelper.mergeVoiceToText(
        null,
        persistedInfo,
      );
    const memoryState = MessageVoiceToTextState(
      voiceToText: MessageVoiceToTextInfo(
        text: 'stale memory text',
        convertedAt: 1,
        source: 'manual',
      ),
    );

    final state = MessageVoiceToTextHelper.resolveVoiceToTextState(
      message,
      memoryState: memoryState,
    );

    expect(state, same(memoryState));
  });

  test('uses memory state when local extension has no persisted content', () {
    final message = NIMMessage(messageType: NIMMessageType.audio);
    const memoryState = MessageVoiceToTextState(
      voiceToText: MessageVoiceToTextInfo(
        text: 'web memory text',
        convertedAt: 1,
        source: 'manual',
      ),
    );

    final state = MessageVoiceToTextHelper.resolveVoiceToTextState(
      message,
      memoryState: memoryState,
    );

    expect(state, same(memoryState));
  });
}
