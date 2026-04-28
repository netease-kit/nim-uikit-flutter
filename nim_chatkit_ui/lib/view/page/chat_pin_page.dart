// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
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

  final bool isEmbedded;
  final VoidCallback? onClose;

  /// 桌面/Web 端"定位到聊天"回调，由外层 ChatPage 注入，触发聊天列表滚动定位
  /// 若不传，则默认使用 goToChatAndKeepHome 跳转
  final void Function(NIMMessage)? onLocateMessage;

  ChatPinPage({
    Key? key,
    required this.conversationId,
    required this.conversationType,
    required this.chatTitle,
    this.chatUIConfig,
    this.messageBuilder,
    this.isEmbedded = false,
    this.onClose,
    this.onLocateMessage,
  }) : super(key: key);

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
        final listBody = Consumer<ChatPinViewModel>(
          builder: (context, model, child) {
            if (model.isEmpty) {
              return Container(
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const SizedBox(height: 68),
                    SvgPicture.asset(
                      'images/ic_list_empty.svg',
                      package: kPackage,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      S.of(context).chatHaveNoPinMessage,
                      style: const TextStyle(
                        color: Color(0xffb3b7bc),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              itemCount: model.pinnedMessages.length,
              itemBuilder: (context, index) {
                var message = model.pinnedMessages[index];
                return InkWell(
                  // 桌面/Web 端：点击消息 item 无反应，定位通过右侧下拉菜单触发
                  // 移动端：点击消息 item 直接跳转聊天页并定位到消息
                  onTap: ChatKitUtils.isDesktopOrWeb
                      ? null
                      : () {
                          goToChatAndKeepHome(
                            context,
                            widget.conversationId,
                            widget.conversationType,
                            message: message.nimMessage,
                          );
                        },
                  child: ChatKitPinMessageItem(
                    chatMessage: message,
                    chatTitle: widget.chatTitle,
                    messageBuilder: messageBuilder,
                    chatUIConfig: chatUIConfig,
                    onLocateMessage: widget.onLocateMessage,
                  ),
                );
              },
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(height: 10);
              },
            );
          },
        );

        if (widget.isEmbedded) {
          // 嵌入模式：自定义标题栏 + 内容
          return Material(
            color: Colors.white,
            child: Column(
              children: [
                // 嵌入模式标题栏
                Container(
                  height: 48,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE8E8E8), width: 0.5),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          S.of(context).chatMessageSignal,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: widget.onClose,
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: listBody),
              ],
            ),
          );
        }

        return TransparentScaffold(
          title: S.of(context).chatMessageSignal,
          body: listBody,
        );
      },
    );
  }
}
