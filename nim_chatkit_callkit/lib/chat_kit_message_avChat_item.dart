// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_callkit_ui/ne_callkit_ui.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/message/message_helper.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:netease_callkit/netease_callkit.dart';
import 'package:netease_common_ui/base/base_state.dart';

import '../../../l10n/S.dart';
import 'nim_chatkit_callkit.dart';

class ChatKitMessageAvChatItem extends StatefulWidget {
  final NIMMessage message;

  /// 消息是否可操作
  final bool enableCallback;

  const ChatKitMessageAvChatItem(
      {Key? key, required this.message, this.enableCallback = true})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageAvChatState();
}

class ChatKitMessageAvChatState extends BaseState<ChatKitMessageAvChatItem> {
  NIMMessageCallAttachment get attachment =>
      widget.message.attachment as NIMMessageCallAttachment;

  // 通话完成：1
  //    * 通话取消：2
  //    * 通话拒绝：3
  //    * 超时未接听：4
  //    * 对方忙： 5
  String getShowText() {
    switch (attachment.status) {
      case BillMessage.callStatusFinished:
        String text = S.of(context).chatMessageCallCompleted;
        if (attachment.durations != null && attachment.durations!.isNotEmpty) {
          final duration = attachment.durations!.first;
          //时：分：秒
          text = '$text ${BillMessage.getCallDuration(duration!.duration!)}';
        }
        return text;
      case BillMessage.callStatusBusy:
        return S.of(context).chatMessageCallBusy;
      case BillMessage.callStatusCancel:
        return S.of(context).chatMessageCallCancel;
      case BillMessage.callStatusRefuse:
        return S.of(context).chatMessageCallRefused;
      case BillMessage.callStatusTimeout:
        return S.of(context).chatMessageCallTimeout;
    }
    return "";
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isSelf = widget.message.isSelf ?? false;
    bool isVideo = attachment.type == BillMessage.videoBill;
    return GestureDetector(
      onTap: () async {
        if (widget.enableCallback) {
          //判断网络
          if (!checkNetwork()) {
            return;
          }
          String targetId = ChatKitUtils.getConversationTargetId(
              widget.message.conversationId!);
          NECallKitUI.instance
              .call(
            targetId, // 被呼叫用户的 userID
            attachment.type == BillMessage.videoBill
                ? NECallType.video
                : NECallType.audio, // 通话类型：音频或视频
          )
              .then((result) {
            if (result.code == ChatMessageRepo.errorInBlackList) {
              Fluttertoast.showToast(msg: S.of(context).chatBeenBlockByOthers);
            }
          });
        }
      },
      child: Container(
          padding:
              const EdgeInsets.only(left: 12, top: 10, right: 8, bottom: 10),
          child: isSelf
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      getShowText(),
                      style: TextStyle(
                          fontSize: 16, color: CommonColors.color_333333),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    SvgPicture.asset(
                      isVideo
                          ? "images/ic_video_call.svg"
                          : "images/ic_voice_call.svg",
                      package: kPackage,
                      width: 24,
                      height: 24,
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      isVideo
                          ? "images/ic_video_call.svg"
                          : "images/ic_voice_call.svg",
                      package: kPackage,
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Text(
                      getShowText(),
                      style: TextStyle(
                          fontSize: 16, color: CommonColors.color_333333),
                    ),
                  ],
                )),
    );
  }
}
