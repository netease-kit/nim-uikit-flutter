// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/router/imkit_router_constants.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/pinMessage/chat_kit_pin_message_item.dart';
import 'package:nim_chatkit_ui/view_model/chat_pin_view_model.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';

import '../../chat_kit_client.dart';
import '../../l10n/S.dart';
import '../../media/audio_player.dart';
import '../chat_kit_message_list/item/chat_kit_message_item.dart';

///消息标记列表页面
class ChatPinPage extends StatefulWidget {
  final String conversationId;

  final NIMConversationType conversationType;

  final String chatTitle;

  final ChatUIConfig? chatUIConfig;

  final ChatKitMessageBuilder? messageBuilder;

  ChatPinPage(
      {Key? key,
      required this.conversationId,
      required this.conversationType,
      required this.chatTitle,
      this.chatUIConfig,
      this.messageBuilder})
      : super(key: key);

  @override
  _ChatPinPageState createState() => _ChatPinPageState();
}

class _ChatPinPageState extends BaseState<ChatPinPage> {
  ChatUIConfig? chatUIConfig;

  ChatKitMessageBuilder? messageBuilder;

  @override
  void initState() {
    super.initState();
    messageBuilder = widget.messageBuilder ??
        ChatKitClient.instance.chatUIConfig.messageBuilder;

    chatUIConfig = widget.chatUIConfig ?? ChatKitClient.instance.chatUIConfig;
  }

  @override
  void dispose() {
    ChatAudioPlayer.instance.stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) =>
            ChatPinViewModel(widget.conversationId, widget.conversationType),
        builder: (context, child) {
          return TransparentScaffold(
            title: S.of(context).chatMessageSignal,
            body: Consumer<ChatPinViewModel>(
              builder: (context, model, child) {
                if (model.isEmpty) {
                  return Container(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 68,
                        ),
                        SvgPicture.asset(
                          'images/ic_list_empty.svg',
                          package: kPackage,
                        ),
                        const SizedBox(
                          height: 18,
                        ),
                        Text(
                          S.of(context).chatHaveNoPinMessage,
                          style:
                              TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
                        )
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: model.pinnedMessages.length,
                  itemBuilder: (context, index) {
                    var message = model.pinnedMessages[index];
                    return InkWell(
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(
                            context,
                            RouterConstants.PATH_CHAT_PAGE,
                            ModalRoute.withName('/'),
                            arguments: {
                              'conversationId': widget.conversationId,
                              'conversationType': widget.conversationType,
                              'anchor': message.nimMessage
                            });
                      },
                      child: ChatKitPinMessageItem(
                        chatMessage: message,
                        chatTitle: widget.chatTitle,
                        messageBuilder: messageBuilder,
                        chatUIConfig: chatUIConfig,
                      ),
                    );
                  },
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  separatorBuilder: (BuildContext context, int index) {
                    return SizedBox(height: 10);
                  },
                );
              },
            ),
          );
        });
  }
}
