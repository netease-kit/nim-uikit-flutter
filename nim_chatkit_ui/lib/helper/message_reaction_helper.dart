// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_core_v2/nim_core.dart';

///消息表情快捷回复的身份与支持规则
class MessageReactionHelper {
  MessageReactionHelper._();

  static String? messageIdentity(NIMMessageRefer message) {
    final serverId = message.messageServerId;
    if (serverId?.isNotEmpty == true && serverId != '-1') {
      return 'server:$serverId';
    }
    final clientId = message.messageClientId;
    if (clientId?.isNotEmpty == true) {
      return 'client:$clientId';
    }
    return null;
  }

  static bool refersToSameMessage(
    NIMMessageRefer first,
    NIMMessageRefer second,
  ) {
    final firstServerId = first.messageServerId;
    final secondServerId = second.messageServerId;
    if (firstServerId?.isNotEmpty == true &&
        firstServerId != '-1' &&
        secondServerId?.isNotEmpty == true &&
        secondServerId != '-1') {
      return firstServerId == secondServerId;
    }
    return first.messageClientId?.isNotEmpty == true &&
        first.messageClientId == second.messageClientId;
  }

  static bool isSupported(ChatMessage message) {
    if (message.isRevoke) {
      return false;
    }
    final nimMessage = message.nimMessage;
    if (messageIdentity(nimMessage) == null) {
      return false;
    }
    if (nimMessage.sendingState == NIMMessageSendingState.sending ||
        nimMessage.sendingState == NIMMessageSendingState.failed) {
      return false;
    }
    // A successful message can carry the SDK's HTTP-style status code (200).
    // Only the explicit local anti-spam failure makes reactions unavailable;
    // sending/failed states are handled above.
    final errorCode = nimMessage.messageStatus?.errorCode;
    if (errorCode == ChatMessage.SERVER_ANTISPAM) {
      return false;
    }
    final aiStreamStatus = nimMessage.aiConfig?.aiStreamStatus;
    if (aiStreamStatus ==
            V2NIMMessageAIStreamStatus
                .V2NIM_MESSAGE_AI_STREAM_STATUS_STREAMING ||
        aiStreamStatus ==
            V2NIMMessageAIStreamStatus
                .V2NIM_MESSAGE_AI_STREAM_STATUS_PLACEHOLDER) {
      return false;
    }
    return const <NIMMessageType>{
      NIMMessageType.text,
      NIMMessageType.image,
      NIMMessageType.audio,
      NIMMessageType.video,
      NIMMessageType.file,
      NIMMessageType.location,
      NIMMessageType.call,
      NIMMessageType.custom,
    }.contains(nimMessage.messageType);
  }
}
