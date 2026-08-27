// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit_ui/helper/reply_message_display_helper.dart';

void main() {
  test('normal chat displays a reply that is also the thread root', () {
    expect(
      shouldDisplayReplyMessage(
        replyMessageClientId: 'message-1',
        threadRootMessageClientId: 'message-1',
      ),
      isTrue,
    );
  });

  test('topic chat hides a reply that points to the topic root', () {
    expect(
      shouldDisplayReplyMessage(
        replyMessageClientId: 'message-1',
        threadRootMessageClientId: 'message-1',
        hideThreadRootReply: true,
      ),
      isFalse,
    );
  });

  test('topic chat still displays replies to another message', () {
    expect(
      shouldDisplayReplyMessage(
        replyMessageClientId: 'message-2',
        threadRootMessageClientId: 'message-1',
        hideThreadRootReply: true,
      ),
      isTrue,
    );
  });

  test('empty reply id is not displayed', () {
    expect(
      shouldDisplayReplyMessage(replyMessageClientId: null),
      isFalse,
    );
  });
}
