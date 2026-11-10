// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit_ui/helper/message_reaction_helper.dart';
import 'package:nim_chatkit_ui/model/message_reaction.dart';
import 'package:nim_core_v2/nim_core.dart';

NIMMessage _message({
  String? serverId = '100',
  String? clientId = 'client-1',
  NIMMessageType type = NIMMessageType.text,
  bool isSelf = false,
  NIMMessageSendingState? sendingState,
  int? statusErrorCode,
}) {
  return NIMMessage(
    messageType: type,
    isSelf: isSelf,
    sendingState: sendingState,
    messageStatus: statusErrorCode == null
        ? null
        : NIMMessageStatus(errorCode: statusErrorCode),
  )
    ..messageServerId = serverId
    ..messageClientId = clientId
    ..conversationId = 'conversation-1';
}

void main() {
  test('reaction indexes and asset paths keep the product order', () {
    expect(
      MessageReactionConfig.quickIndexes,
      <int>[3, 5, 1, 21, 65, 19, 20],
    );
    expect(MessageReactionConfig.allIndexes, hasLength(112));
    expect(MessageReactionConfig.allIndexes.first, 1);
    expect(MessageReactionConfig.allIndexes.last, 112);
    expect(MessageReactionConfig.assetPath(3), 'reaction_emoji/003.png');
  });

  test('message identity prefers a valid server id and falls back to client',
      () {
    expect(
      MessageReactionHelper.messageIdentity(_message()),
      'server:100',
    );
    expect(
      MessageReactionHelper.messageIdentity(_message(serverId: '-1')),
      'client:client-1',
    );
    expect(
      MessageReactionHelper.messageIdentity(
        _message(serverId: null, clientId: null),
      ),
      isNull,
    );
  });

  test('reaction summary deduplicates operators and exposes selection', () {
    final summary = MessageReactionSummary(
      index: 3,
      operatorIds: const <String>['me', 'other', 'me'],
    );
    expect(summary.count, 2);
    expect(summary.contains('me'), isTrue);
    expect(summary.contains('missing'), isFalse);
  });

  test('historical self messages support reactions without a success state',
      () {
    expect(
      MessageReactionHelper.isSupported(
        ChatMessage(_message(isSelf: true)),
      ),
      isTrue,
    );
    expect(
      MessageReactionHelper.isSupported(
        ChatMessage(
          _message(
            isSelf: true,
            sendingState: NIMMessageSendingState.unknown,
          ),
        ),
      ),
      isTrue,
    );
    expect(MessageReactionHelper.isSupported(ChatMessage(_message())), isTrue);
    expect(
      MessageReactionHelper.isSupported(
        ChatMessage(_message(statusErrorCode: 200)),
      ),
      isTrue,
    );
    expect(
      MessageReactionHelper.isSupported(
        ChatMessage(
          _message(
            isSelf: true,
            sendingState: NIMMessageSendingState.succeeded,
          ),
        ),
      ),
      isTrue,
    );
    expect(
      MessageReactionHelper.isSupported(
        ChatMessage(
          _message(
            isSelf: true,
            sendingState: NIMMessageSendingState.sending,
          ),
        ),
      ),
      isFalse,
    );
    expect(
      MessageReactionHelper.isSupported(
        ChatMessage(
          _message(statusErrorCode: ChatMessage.SERVER_ANTISPAM),
        ),
      ),
      isFalse,
    );
    expect(
      MessageReactionHelper.isSupported(
        ChatMessage(
          _message(
            isSelf: true,
            sendingState: NIMMessageSendingState.failed,
          ),
        ),
      ),
      isFalse,
    );
  });

  test('supported message rules exclude unsupported messages', () {
    expect(
      MessageReactionHelper.isSupported(
        ChatMessage(_message(type: NIMMessageType.notification)),
      ),
      isFalse,
    );
  });
}
