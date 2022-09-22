// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:corekit_im/services/message/chat_message.dart';

class PopMenuAction {
  void Function(ChatMessage message)? onMessageCopy;

  void Function(ChatMessage message)? onMessageReply;

  void Function(ChatMessage message)? onMessageForward;

  void Function(ChatMessage message, bool isCancel)? onMessagePin;

  void Function(ChatMessage message)? onMessageMultiSelect;

  void Function(ChatMessage message)? onMessageCollect;

  void Function(ChatMessage message)? onMessageDelete;

  void Function(ChatMessage message)? onMessageRevoke;

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
