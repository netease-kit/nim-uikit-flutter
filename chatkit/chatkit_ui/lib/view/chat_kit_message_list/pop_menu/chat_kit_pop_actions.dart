// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:corekit_im/services/message/chat_message.dart';

class PopMenuAction {
  bool Function(ChatMessage message)? onMessageCopy;

  bool Function(ChatMessage message)? onMessageReply;

  bool Function(ChatMessage message)? onMessageForward;

  bool Function(ChatMessage message, bool isCancel)? onMessagePin;

  bool Function(ChatMessage message)? onMessageMultiSelect;

  bool Function(ChatMessage message)? onMessageCollect;

  bool Function(ChatMessage message)? onMessageDelete;

  bool Function(ChatMessage message)? onMessageRevoke;

  PopMenuAction(
      {this.onMessageCollect,
      this.onMessageCopy,
      this.onMessageReply,
      this.onMessageForward,
      this.onMessagePin,
      this.onMessageMultiSelect,
      this.onMessageDelete,
      this.onMessageRevoke});
}
