// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:netease_common/netease_common.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/router/imkit_router_constants.dart';
import 'package:nim_chatkit/manager/ai_error_code.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../../l10n/S.dart';

class ChatKitMessageTipsItem extends StatefulWidget {
  final NIMMessage message;

  const ChatKitMessageTipsItem({Key? key, required this.message})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageTipsState();
}

class ChatKitMessageTipsState extends State<ChatKitMessageTipsItem> {
  String _getTips(NIMMessage message) {
    var remoteExtension = null;
    if (widget.message.serverExtension?.isNotEmpty == true) {
      try {
        remoteExtension = jsonDecode(widget.message.serverExtension!);
      } catch (e) {
        Alog.e(tag: 'ChatKitMessageTipsItem', content: 'e : ${e.toString()}');
      }
    }
    if (remoteExtension != null &&
        remoteExtension[RouterConstants.keyTeamCreatedTip] != null) {
      return remoteExtension[RouterConstants.keyTeamCreatedTip];
    }

    //处理AI错误码
    if (message.messageStatus?.errorCode != null) {
      switch (message.messageStatus?.errorCode) {
        case AIErrorCode.errorTipsCode:
          return S.of(context).chatAiMessageTypeUnsupport;
        case AIErrorCode.errorCodeFailedToRequestLlm:
          return S.of(context).chatAiErrorFailedRequestToTheLlm;
        case AIErrorCode.errorCodeAiMessagesFunctionDisabled:
          return S.of(context).chatAiErrorAiMessagesFunctionDisabled;
        case AIErrorCode.errorCodeIsNotAiAccount:
          return S.of(context).chatAiErrorNotAnAiAccount;
        case AIErrorCode.errorCodeAiAccountBlocklistOperationNotAllowed:
          return S.of(context).chatAiErrorCannotBlocklistAnAiAccount;
        case AIErrorCode.errorCodeParameterError:
          return S.of(context).chatAiErrorParameter;
        case AIErrorCode.errorCodeAccountNotExist:
        case AIErrorCode.errorCodeFriendNotExist:
          return S.of(context).chatAiErrorUserNotExist;
        case AIErrorCode.errorCodeAccountBanned:
          return S.of(context).chatAiErrorUserBanned;
        case AIErrorCode.errorCodeAccountChatBanned:
          return S.of(context).chatAiErrorUserChatBanned;
        case AIErrorCode.errorCodeMessageHitAntispam:
          return S.of(context).chatAiErrorMessageHitAntispam;
        case AIErrorCode.errorCodeTeamMemberNotExist:
          return S.of(context).chatAiErrorTeamMemberNotExist;
        case AIErrorCode.errorCodeTeamNormalMemberChatBanned:
          return S.of(context).chatAiErrorTeamNormalMemberChatBanned;
        case AIErrorCode.errorCodeTeamMemberChatBanned:
          return S.of(context).chatAiErrorTeamMemberChatBanned;
        case AIErrorCode.errorCodeRateLimit:
          return S.of(context).chatAiErrorRateLimitExceeded;
        default:
          break;
      }
    }

    return message.text ?? 'unknown tips';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 8),
      child: Text(
        _getTips(widget.message),
        maxLines: null,
        style: TextStyle(fontSize: 12, color: '#999999'.toColor()),
      ),
    );
  }
}
