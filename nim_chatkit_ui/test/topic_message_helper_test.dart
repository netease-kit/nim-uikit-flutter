// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit_ui/helper/topic_message_helper.dart';
import 'package:nim_chatkit_ui/view_model/bot_subsession_list_view_model.dart';
import 'package:nim_core_v2/nim_core.dart';

void main() {
  NIMMessage message(String text, int createTime) {
    return NIMMessage(
      messageType: NIMMessageType.text,
      text: text,
    )..createTime = createTime;
  }

  test('finds latest message when local replies are oldest first', () {
    final sentMessage = message('question', 100);
    final robotReply = message('answer', 200);

    final latestMessage = TopicMessageHelper.findLatestMessage([
      sentMessage,
      robotReply,
    ]);

    expect(latestMessage, same(robotReply));
  });

  test('finds latest message when local replies are newest first', () {
    final sentMessage = message('question', 100);
    final robotReply = message('answer', 200);

    final latestMessage = TopicMessageHelper.findLatestMessage([
      robotReply,
      sentMessage,
    ]);

    expect(latestMessage, same(robotReply));
  });

  test('matches message reference by valid server id first', () {
    final targetMessage = NIMMessage()
      ..messageServerId = 'server-2'
      ..messageClientId = 'client-2';
    final messageRefer = NIMMessageRefer(
      messageServerId: 'server-2',
      messageClientId: 'different-client',
    );

    expect(
      TopicMessageHelper.matchesMessageRefer(targetMessage, messageRefer),
      isTrue,
    );
  });

  test('falls back to client id when server id is invalid', () {
    final targetMessage = NIMMessage()
      ..messageServerId = '-1'
      ..messageClientId = 'client-2';
    final messageRefer = NIMMessageRefer(
      messageServerId: '-1',
      messageClientId: 'client-2',
    );

    expect(
      TopicMessageHelper.matchesMessageRefer(targetMessage, messageRefer),
      isTrue,
    );
  });

  test('mobile queries latest Topic message from local storage first', () {
    expect(
      shouldLoadLatestTopicMessageFromLocal(
        isWeb: false,
      ),
      isTrue,
    );
  });

  test('desktop queries latest Topic message from local storage first', () {
    expect(
      shouldLoadLatestTopicMessageFromLocal(
        isWeb: false,
      ),
      isTrue,
    );
  });

  test('Web skips unsupported local thread query', () {
    expect(
      shouldLoadLatestTopicMessageFromLocal(
        isWeb: true,
      ),
      isFalse,
    );
  });
}
