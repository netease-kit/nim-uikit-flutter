// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:chatkit_ui/chat_setting_page.dart';
import 'package:chatkit_ui/view/chat_kit_message_list/chat_kit_message_list.dart';
import 'package:chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_item.dart';
import 'package:chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_pop_actions.dart';
import 'package:chatkit_ui/view_model/chat_view_model.dart';
import 'package:im_common_ui/router/imkit_router_constants.dart';
import 'package:im_common_ui/router/imkit_router_factory.dart';
import 'package:im_common_ui/widgets/no_network_tip.dart';
import 'package:corekit_im/model/contact_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_core/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import 'chat_kit_client.dart';
import 'generated/l10n.dart';
import 'view/input/bottom_input_field.dart';

class ChatPage extends StatefulWidget {
  final String sessionId;

  final NIMSessionType sessionType;

  final NIMMessage? anchor;

  final PopMenuAction? customPopActions;

  final void Function(String? userID, {bool isSelf})? onTapAvatar;

  final ChatUIConfig? chatUIConfig;

  final ChatKitMessageBuilder? messageBuilder;

  ChatPage(
      {Key? key,
      required this.sessionId,
      required this.sessionType,
      this.anchor,
      this.customPopActions,
      this.onTapAvatar,
      this.chatUIConfig,
      this.messageBuilder})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  late AutoScrollController autoController;
  final GlobalKey<dynamic> _inputField = GlobalKey();

  Timer? _typingTimer;

  int _remainTime = 5;

  void _setTyping(BuildContext context) {
    _typingTimer?.cancel();
    _remainTime = 5;
    _typingTimer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (_remainTime <= 0) {
        _remainTime = 5;
        _typingTimer?.cancel();
        context.read<ChatViewModel>().resetTyping();
      } else {
        _remainTime--;
      }
    });
  }

  void defaultAvatarTap(String? userId, {bool isSelf = false}) {
    if (isSelf) {
      gotoMineInfoPage(context);
    } else {
      goToContactDetail(context, userId!);
    }
  }

  @override
  void initState() {
    super.initState();
    autoController = AutoScrollController(
      viewportBoundaryGetter: () =>
          Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
      axis: Axis.vertical,
    );
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) =>
            ChatViewModel(widget.sessionId, widget.sessionType),
        builder: (context, wg) {
          String title;
          if (context.watch<ChatViewModel>().isTyping) {
            _setTyping(context);
            title = S.of(context).chat_is_typing;
          } else {
            title = context.watch<ChatViewModel>().chatTitle;
          }
          var hasNetwork = context.watch<ChatViewModel>().hasNetWork;
          return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 26,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                centerTitle: true,
                title: Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                elevation: 0.5,
                actions: [
                  IconButton(
                      onPressed: () {
                        if (widget.sessionType == NIMSessionType.p2p) {
                          ContactInfo? info =
                              context.read<ChatViewModel>().contactInfo;
                          if (info != null) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ChatSettingPage(info)));
                          }
                        } else if (widget.sessionType == NIMSessionType.team) {
                          Navigator.pushNamed(
                              context, RouterConstants.PATH_TEAM_SETTING_PAGE,
                              arguments: {'teamId': widget.sessionId});
                        }
                      },
                      icon: SvgPicture.asset(
                        'images/ic_setting.svg',
                        width: 26,
                        height: 26,
                        package: 'chatkit_ui',
                      ))
                ],
              ),
              body: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!hasNetwork) NoNetWorkTip(),
                      Expanded(
                        child: Listener(
                          onPointerMove: (event) {
                            _inputField.currentState.hideAllPanel();
                          },
                          child: ChatKitMessageList(
                            scrollController: autoController,
                            popMenuAction: widget.customPopActions,
                            anchor: widget.anchor,
                            messageBuilder: widget.messageBuilder ??
                                widget.chatUIConfig?.messageBuilder ??
                                ChatKitClient
                                    .instance.chatUIConfig.messageBuilder,
                            onTapAvatar: widget.onTapAvatar ?? defaultAvatarTap,
                            chatUIConfig: widget.chatUIConfig ??
                                ChatKitClient.instance.chatUIConfig,
                            teamInfo: context.watch<ChatViewModel>().teamInfo,
                          ),
                        ),
                      ),
                      BottomInputField(
                        scrollController: autoController,
                        sessionType: widget.sessionType,
                        hint: S.of(context).chat_message_send_hint(title),
                        chatUIConfig: widget.chatUIConfig ??
                            ChatKitClient.instance.chatUIConfig,
                        key: _inputField,
                      )
                    ],
                  ),
                ],
              ));
        });
  }
}
