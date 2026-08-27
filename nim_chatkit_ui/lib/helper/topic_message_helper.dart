// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:nim_chatkit/repo/topic_repo.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_core_v2/nim_core.dart';

class TopicMessageHelper {
  TopicMessageHelper._();

  /// Returns the newest message regardless of the SDK list order.
  static NIMMessage? findLatestMessage(Iterable<NIMMessage?> messages) {
    NIMMessage? latestMessage;
    for (final message in messages) {
      if (message == null) {
        continue;
      }
      if (latestMessage == null ||
          (message.createTime ?? 0) >= (latestMessage.createTime ?? 0)) {
        latestMessage = message;
      }
    }
    return latestMessage;
  }

  /// Checks whether a message matches a referenced message identity.
  static bool matchesMessageRefer(
    NIMMessage message,
    NIMMessageRefer messageRefer,
  ) {
    final messageServerId = messageRefer.messageServerId;
    if (messageServerId?.isNotEmpty == true && messageServerId != '-1') {
      return message.messageServerId == messageServerId;
    }
    final messageClientId = messageRefer.messageClientId;
    return messageClientId?.isNotEmpty == true &&
        message.messageClientId == messageClientId;
  }

  static String resolveTopicTitle(
    V2NIMTopic? topic, {
    String? fallback,
  }) {
    final titleInfo = TopicRepo.instance.parseTitleInfo(topic);
    return titleInfo.title ?? fallback ?? S.of().botSubsessionNewSession;
  }

  static String buildSummaryText(NIMMessage? message) {
    if (message == null) {
      return '';
    }
    switch (message.messageType) {
      case NIMMessageType.text:
        final text = message.text ?? '';
        return text.length > 30 ? text.substring(0, 30) : text;
      case NIMMessageType.image:
        return S.of().chatMessageBriefImage;
      case NIMMessageType.file:
        final attachment = message.attachment;
        final fileBrief = S.of().chatMessageBriefFile;
        if (attachment is NIMMessageFileAttachment &&
            attachment.name?.isNotEmpty == true) {
          return '$fileBrief ${attachment.name}';
        }
        return fileBrief;
      case NIMMessageType.audio:
        return S.of().chatMessageBriefAudio;
      case NIMMessageType.video:
        return S.of().chatMessageBriefVideo;
      default:
        return S.of().chatMessageBriefMessage;
    }
  }

  static String buildAutoTitleFromMessage(
    NIMMessage message, {
    NIMMessage? fallbackMessage,
  }) {
    final source =
        message.messageType == NIMMessageType.text || fallbackMessage == null
            ? message
            : fallbackMessage;
    switch (source.messageType) {
      case NIMMessageType.text:
        final text =
            (source.text ?? fallbackMessage?.text ?? message.text ?? '').trim();
        if (text.isEmpty) {
          return S.of().botSubsessionNewSession;
        }
        return text.length > 20 ? text.substring(0, 20) : text;
      default:
        return buildSummaryText(source);
    }
  }
}
