// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/message/message_helper.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../../chat_kit_client.dart';
import '../../../helper/chat_message_helper.dart';
import 'chat_kit_pop_actions.dart';

/// 菜单项条件判断和回调分发的共享逻辑。
///
/// 供移动端 [ChatKitMessagePopMenu] 和桌面端 [ChatKitDesktopContextMenu] 共同使用，
/// 避免两套菜单各自维护一份相同的条件判断逻辑。
class ChatKitMenuHelper {
  // ---- Action ID 常量 ----
  static const String copyMessageId = 'copyMessage';
  static const String replyMessageId = 'replyMessage';
  static const String collectMessageId = 'collectMessage';
  static const String forwardMessageId = 'forwardMessage';
  static const String pinMessageId = 'pinMessage';
  static const String cancelPinMessageId = 'cancelPinMessage';
  static const String multiSelectId = 'multiSelect';
  static const String deleteMessageId = 'deleteMessage';
  static const String revokeMessageId = 'revokeMessage';
  static const String speakerMessageId = 'speakerMessage';

  // ---- 菜单项可见性判断 ----

  static bool messageHavePined(ChatMessage message) {
    return message.getPinAccId() != null;
  }

  static bool showCopy(ChatUIConfig? config, ChatMessage message) {
    if (config?.popMenuConfig?.enableCopy != false) {
      if (message.nimMessage.messageType == NIMMessageType.text) {
        return true;
      }
      var multiLineMap = MessageHelper.parseMultiLineMessage(
        message.nimMessage,
      );
      if (multiLineMap != null &&
          multiLineMap[ChatMessage.keyMultiLineBody]?.isNotEmpty == true) {
        return true;
      }
    }
    return false;
  }

  static bool showSpeaker(ChatUIConfig? config, ChatMessage message) {
    return !ChatKitUtils.isDesktopOrWeb &&
        config?.popMenuConfig?.enableVoiceSwitch != false &&
        message.nimMessage.messageType == NIMMessageType.audio;
  }

  static bool showForward(ChatUIConfig? config, ChatMessage message) {
    if (config?.popMenuConfig?.enableForward != false &&
        enableStatus(message)) {
      if (message.nimMessage.messageType != NIMMessageType.audio &&
          message.nimMessage.messageType != NIMMessageType.call) {
        return true;
      }
    }
    return false;
  }

  static bool enableStatus(ChatMessage message) {
    if (message.nimMessage.isSelf != true) {
      return true;
    }
    return message.nimMessage.sendingState != NIMMessageSendingState.sending &&
        message.nimMessage.sendingState != NIMMessageSendingState.failed &&
        message.nimMessage.messageStatus?.errorCode !=
            ChatMessage.SERVER_ANTISPAM;
  }

  static bool showReply(ChatUIConfig? config, ChatMessage message) {
    if (message.nimMessage.messageType == NIMMessageType.call) {
      return false;
    }
    return config?.popMenuConfig?.enableReply != false && enableStatus(message);
  }

  static bool showPin(ChatUIConfig? config, ChatMessage message) {
    if (message.nimMessage.messageType == NIMMessageType.call) {
      return false;
    }
    return config?.popMenuConfig?.enablePin != false && enableStatus(message);
  }

  static bool showCollection(ChatUIConfig? config, ChatMessage message) {
    if (message.nimMessage.messageType == NIMMessageType.call) {
      return false;
    }
    return config?.popMenuConfig?.enableCollect != false &&
        enableStatus(message);
  }

  static bool showRevoke(ChatUIConfig? config, ChatMessage message) {
    if (message.nimMessage.messageType == NIMMessageType.call) {
      return false;
    }
    return isSelf(message.nimMessage) &&
        config?.popMenuConfig?.enableRevoke != false &&
        enableStatus(message);
  }

  static bool isSelf(NIMMessage message) {
    if (ChatMessageHelper.isReceivedMessageFromAi(message)) {
      return false;
    }
    return message.isSelf == true;
  }

  // ---- 构建菜单项列表 ----

  /// 根据消息类型、状态和配置，构建可见的菜单项列表。
  ///
  /// 返回的每个 Map 包含 `id`、`label`、`icon` 三个键。
  static List<Map<String, String>> buildMenuItems(
    BuildContext context,
    ChatMessage message,
    ChatUIConfig? config,
    bool isVoiceFromSpeaker,
  ) {
    return [
      if (showSpeaker(config, message))
        {
          "label": !isVoiceFromSpeaker
              ? S.of(context).chatVoiceFromSpeaker
              : S.of(context).chatVoiceFromEarSpeaker,
          "id": speakerMessageId,
          "icon": !isVoiceFromSpeaker
              ? "images/ic_speaker.svg"
              : "images/ic_ear.svg",
        },
      if (showCopy(config, message))
        {
          "label": S.of(context).chatMessageActionCopy,
          "id": copyMessageId,
          "icon": "images/ic_chat_copy.svg",
        },
      if (showReply(config, message))
        {
          "label": S.of(context).chatMessageActionReply,
          "id": replyMessageId,
          "icon": "images/ic_chat_reply.svg",
        },
      if (showForward(config, message))
        {
          "label": S.of(context).chatMessageActionForward,
          "id": forwardMessageId,
          "icon": "images/ic_chat_forward.svg",
        },
      if (showPin(config, message))
        {
          "label": messageHavePined(message)
              ? S.of(context).chatMessageActionUnPin
              : S.of(context).chatMessageActionPin,
          "id": messageHavePined(message) ? cancelPinMessageId : pinMessageId,
          "icon": "images/ic_chat_pin.svg",
        },
      if (showCollection(config, message))
        {
          "label": S.of(context).chatMessageActionCollect,
          "id": collectMessageId,
          "icon": "images/ic_chat_collect.svg",
        },
      if (config?.popMenuConfig?.enableDelete != false)
        {
          "label": S.of(context).chatMessageActionDelete,
          "id": deleteMessageId,
          "icon": "images/ic_chat_delete.svg",
        },
      if (config?.popMenuConfig?.enableMultiSelect != false &&
          message.nimMessage.messageStatus?.errorCode !=
              ChatMessage.SERVER_ANTISPAM)
        {
          "label": S.of(context).chatMessageActionMultiSelect,
          "id": multiSelectId,
          "icon": "images/ic_chat_select.svg",
        },
      if (showRevoke(config, message))
        {
          "label": S.of(context).chatMessageActionRevoke,
          "id": revokeMessageId,
          "icon": "images/ic_chat_revoke.svg",
        },
    ];
  }

  // ---- 操作回调分发 ----

  /// 根据 [actionId] 分发到 [popMenuAction] 的对应回调。
  static void handleAction(
    ChatMessage message,
    String actionId,
    PopMenuAction? popMenuAction,
    bool isVoiceFromSpeaker,
  ) {
    if (popMenuAction == null) {
      return;
    }
    switch (actionId) {
      case copyMessageId:
        popMenuAction.onMessageCopy?.call(message);
        break;
      case replyMessageId:
        popMenuAction.onMessageReply?.call(message);
        break;
      case revokeMessageId:
        popMenuAction.onMessageRevoke?.call(message);
        break;
      case forwardMessageId:
        popMenuAction.onMessageForward?.call(message);
        break;
      case pinMessageId:
        popMenuAction.onMessagePin?.call(message, false);
        break;
      case cancelPinMessageId:
        popMenuAction.onMessagePin?.call(message, true);
        break;
      case collectMessageId:
        popMenuAction.onMessageCollect?.call(message);
        break;
      case deleteMessageId:
        popMenuAction.onMessageDelete?.call(message);
        break;
      case multiSelectId:
        popMenuAction.onMessageMultiSelect?.call(message);
        break;
      case speakerMessageId:
        popMenuAction.onVoiceSpeakerSwitch?.call(!isVoiceFromSpeaker);
        break;
    }
  }
}
