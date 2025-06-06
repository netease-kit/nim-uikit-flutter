// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit/message/message_helper.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_pop_actions.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../../chat_kit_client.dart';
import '../../../helper/chat_message_helper.dart';
import 'chat_kit_super_tooltip.dart';

class ChatKitMessagePopMenu {
  static const String copyMessageId = 'copyMessage';
  static const String replyMessageId = 'replyMessage';
  static const String collectMessageId = 'collectMessage';
  static const String forwardMessageId = 'forwardMessage';
  static const String pinMessageId = 'pinMessage';
  static const String cancelPinMessageId = 'cancelPinMessage';
  static const String multiSelectId = 'multiSelect';
  static const String deleteMessageId = 'deleteMessage';
  static const String revokeMessageId = 'revokeMessage';

  SuperTooltip? _tooltip;

  BuildContext context;

  ChatMessage message;

  PopMenuAction? popMenuAction;

  ChatUIConfig? chatUIConfig;

  ChatKitMessagePopMenu(this.message, this.context,
      {this.popMenuAction, this.chatUIConfig}) {
    double arrowTipDistance = 30;
    TooltipDirection popupDirection = TooltipDirection.up;

    //重设arrowTipDistance
    var resetDistance = true;

    RenderBox? box = context.findRenderObject() as RenderBox?;
    bool isTargetHeadVisible = true;
    if (box != null) {
      Offset position = box.localToGlobal(Offset.zero);
      if (position.dy < 240) {
        popupDirection = TooltipDirection.down;
      }
      // 获取 Widget 的全局坐标
      final size = box.size;
      final widgetTop = position.dy;
      final widgetBottom = widgetTop + size.height;
      // 检查是否在可滚动容器内
      final scrollable = Scrollable.of(context);
      if (scrollable != null) {
        final scrollPosition = scrollable.position;
        final scrollOffset = scrollPosition.pixels;
        final viewportHeight = scrollPosition.viewportDimension;

        // 计算视口边界
        final viewportTop = scrollOffset;
        final viewportBottom = scrollOffset + viewportHeight;

        // 获取 Widget 在滚动容器内的相对位置
        final scrollableRenderBox =
            scrollable.context.findRenderObject() as RenderBox;
        final localOffset =
            box.localToGlobal(Offset.zero, ancestor: scrollableRenderBox);
        final widgetScrollTop = scrollOffset + localOffset.dy;
        final widgetScrollBottom = widgetScrollTop + size.height;

        // 判断可见性
        if (popupDirection == TooltipDirection.down &&
            (widgetScrollBottom + 30) > viewportBottom) {
          resetDistance = false;
          arrowTipDistance = (context.size!.height / 2).roundToDouble() -
              ((widgetScrollBottom + 200) - viewportBottom);
          if (arrowTipDistance < 0) {
            popupDirection = TooltipDirection.up;
            arrowTipDistance = 0 - arrowTipDistance;
          }
          isTargetHeadVisible = false;
        }
      }
    }
    if (resetDistance) {
      arrowTipDistance = (context.size!.height / 2).roundToDouble() + 10;
    }

    _tooltip = SuperTooltip(
      popupDirection: popupDirection,
      minimumOutSidePadding: 0,
      arrowTipDistance: arrowTipDistance,
      arrowBaseWidth: 10.0,
      arrowLength: 10.0,
      right: _isSelf(message.nimMessage) ? 60 : null,
      left: _isSelf(message.nimMessage) ? null : 60,
      borderColor: Colors.white,
      backgroundColor: Colors.white,
      shadowColor: Colors.black26,
      hasShadow: true,
      borderWidth: 1.0,
      isTargetHeadVisible: isTargetHeadVisible,
      showCloseButton: ShowCloseButton.none,
      touchThroughAreaShape: ClipAreaShape.rectangle,
      content: _getTooltipAction(context, chatUIConfig, message),
    );
  }

  Widget _getTooltipAction(
      BuildContext context, ChatUIConfig? config, ChatMessage message) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 250,
          ),
          child: Wrap(
            direction: Axis.horizontal,
            alignment: WrapAlignment.start,
            // crossAxisAlignment: crossAxisAlignment.st,
            spacing: 4,
            runSpacing: 24,
            children: [
              ..._buildLongPressTipItem(context, config, message),
            ],
          ),
        ));
  }

  bool _messageHavePined(ChatMessage message) {
    return message.getPinAccId() != null;
  }

  bool _showCopy(ChatUIConfig? config, ChatMessage message) {
    if (config?.popMenuConfig?.enableCopy != false) {
      if (message.nimMessage.messageType == NIMMessageType.text) {
        return true;
      }
      var multiLineMap =
          MessageHelper.parseMultiLineMessage(message.nimMessage);
      if (multiLineMap != null &&
          multiLineMap[ChatMessage.keyMultiLineBody]?.isNotEmpty == true) {
        return true;
      }
    }
    return false;
  }

  bool _showForward(ChatUIConfig? config, ChatMessage message) {
    if (config?.popMenuConfig?.enableForward != false &&
        _enableStatus(message)) {
      if (message.nimMessage.messageType != NIMMessageType.audio) {
        return true;
      }
    }
    return false;
  }

  bool _enableStatus(ChatMessage message) {
    return message.nimMessage.sendingState != NIMMessageSendingState.sending &&
        message.nimMessage.sendingState != NIMMessageSendingState.failed;
  }

  bool _isSelf(NIMMessage message) {
    if (ChatMessageHelper.isReceivedMessageFromAi(message)) {
      return false;
    }
    return message.isSelf == true;
  }

  _buildLongPressTipItem(
      BuildContext context, ChatUIConfig? config, ChatMessage message) {
    final shouldShowRevokeAction = _isSelf(message.nimMessage);
    final firstRowList = [
      if (_showCopy(config, message))
        {
          "label": S.of(context).chatMessageActionCopy,
          "id": copyMessageId,
          "icon": "images/ic_chat_copy.svg"
        },
      if (config?.popMenuConfig?.enableReply != false && _enableStatus(message))
        {
          "label": S.of(context).chatMessageActionReply,
          "id": replyMessageId,
          "icon": "images/ic_chat_reply.svg"
        },
      if (_showForward(config, message))
        {
          "label": S.of(context).chatMessageActionForward,
          "id": forwardMessageId,
          "icon": "images/ic_chat_forward.svg"
        },
      if (config?.popMenuConfig?.enablePin != false && _enableStatus(message))
        {
          "label": _messageHavePined(message)
              ? S.of(context).chatMessageActionUnPin
              : S.of(context).chatMessageActionPin,
          "id": _messageHavePined(message) ? cancelPinMessageId : pinMessageId,
          "icon": "images/ic_chat_pin.svg"
        },
      // if (config?.popMenuConfig?.enableCollect != false &&
      //     _enableStatus(message))
      //   {
      //     "label": S.of(context).chatMessageActionCollect,
      //     "id": collectMessageId,
      //     "icon": "images/ic_chat_collect.svg"
      //   },
      if (config?.popMenuConfig?.enableDelete != false)
        {
          "label": S.of(context).chatMessageActionDelete,
          "id": deleteMessageId,
          "icon": "images/ic_chat_delete.svg"
        },
      if (config?.popMenuConfig?.enableMultiSelect != false)
        {
          "label": S.of(context).chatMessageActionMultiSelect,
          "id": multiSelectId,
          "icon": "images/ic_chat_select.svg"
        },
      if (shouldShowRevokeAction &&
          config?.popMenuConfig?.enableRevoke != false &&
          _enableStatus(message))
        {
          "label": S.of(context).chatMessageActionRevoke,
          "id": revokeMessageId,
          "icon": "images/ic_chat_revoke.svg"
        }
    ];
    return firstRowList
        .map(
          (item) => Material(
            child: itemInkWell(
              onTap: () {
                _onTap(message, item['id']!);
              },
              child: Column(
                children: [
                  SvgPicture.asset(
                    item["icon"]!,
                    package: kPackage,
                    width: 18,
                    height: 18,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    item["label"]!,
                    style: TextStyle(
                        decoration: TextDecoration.none,
                        fontSize: 14,
                        color: '#333333'.toColor()),
                  )
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  void close() {
    if (_tooltip?.isOpen == true) {
      _tooltip?.close();
    }
  }

  void clean() {
    close();
  }

  void show() {
    _tooltip?.show(context);
  }

  void _onTap(ChatMessage message, String actionId) {
    _tooltip?.close();
    if (popMenuAction == null) {
      return;
    }
    switch (actionId) {
      case copyMessageId:
        if (popMenuAction?.onMessageCopy != null) {
          popMenuAction?.onMessageCopy!(message);
        }
        break;
      case replyMessageId:
        if (popMenuAction?.onMessageReply != null) {
          popMenuAction?.onMessageReply!(message);
        }
        break;
      case revokeMessageId:
        if (popMenuAction?.onMessageRevoke != null) {
          popMenuAction?.onMessageRevoke!(message);
        }
        break;
      case forwardMessageId:
        if (popMenuAction?.onMessageForward != null) {
          popMenuAction?.onMessageForward!(message);
        }
        break;
      case pinMessageId:
        if (popMenuAction?.onMessagePin != null) {
          popMenuAction?.onMessagePin!(message, false);
        }
        break;
      case cancelPinMessageId:
        if (popMenuAction?.onMessagePin != null) {
          popMenuAction?.onMessagePin!(message, true);
        }
        break;
      case collectMessageId:
        if (popMenuAction?.onMessageCollect != null) {
          popMenuAction?.onMessageCollect!(message);
        }
        break;
      case deleteMessageId:
        if (popMenuAction?.onMessageDelete != null) {
          popMenuAction?.onMessageDelete!(message);
        }
        break;
      case multiSelectId:
        if (popMenuAction?.onMessageMultiSelect != null) {
          popMenuAction?.onMessageMultiSelect!(message);
        }
        break;
    }
  }

  Widget itemInkWell({
    Widget? child,
    GestureTapCallback? onTap,
  }) {
    return SizedBox(
      width: 58,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: child,
        ),
      ),
    );
  }
}
