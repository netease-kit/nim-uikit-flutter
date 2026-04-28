// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/pop_menu/chat_kit_pop_actions.dart';

import '../../../chat_kit_client.dart';
import 'chat_kit_menu_helper.dart';
import 'chat_kit_super_tooltip.dart';

class ChatKitMessagePopMenu {
  SuperTooltip? _tooltip;

  BuildContext context;

  ChatMessage message;

  PopMenuAction? popMenuAction;

  ChatUIConfig? chatUIConfig;

  bool isVoiceFromSpeaker = true;

  ChatKitMessagePopMenu(
    this.message,
    this.isVoiceFromSpeaker,
    this.context, {
    this.popMenuAction,
    this.chatUIConfig,
  }) {
    double arrowTipDistance = 30;
    TooltipDirection popupDirection = TooltipDirection.up;

    //重设arrowTipDistance
    var resetDistance = true;

    RenderBox? box = context.findRenderObject() as RenderBox?;
    bool isTargetHeadVisible = true;
    if (box != null) {
      Offset position = box.localToGlobal(Offset.zero);
      final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
      if (position.dy - topPadding < 240) {
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
        final localOffset = box.localToGlobal(
          Offset.zero,
          ancestor: scrollableRenderBox,
        );
        final widgetScrollTop = scrollOffset + localOffset.dy;
        final widgetScrollBottom = widgetScrollTop + size.height;

        // 判断可见性
        // 增加判断：只有当 viewportHeight 接近屏幕高度时（说明不是 shrinkWrap 导致的短列表），才执行这个逻辑
        // 或者当 viewportHeight 足够大时
        if (viewportHeight > MediaQuery.of(context).size.height * 0.8) {
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
      right: ChatKitMenuHelper.isSelf(message.nimMessage) ? 60 : null,
      left: ChatKitMenuHelper.isSelf(message.nimMessage) ? null : 60,
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
    BuildContext context,
    ChatUIConfig? config,
    ChatMessage message,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Wrap(
          direction: Axis.horizontal,
          alignment: WrapAlignment.start,
          // crossAxisAlignment: crossAxisAlignment.st,
          spacing: 4,
          runSpacing: 24,
          children: [..._buildLongPressTipItem(context, config, message)],
        ),
      ),
    );
  }

  _buildLongPressTipItem(
    BuildContext context,
    ChatUIConfig? config,
    ChatMessage message,
  ) {
    final firstRowList = ChatKitMenuHelper.buildMenuItems(
      context,
      message,
      config,
      isVoiceFromSpeaker,
    );
    return firstRowList
        .map(
          (item) => Material(
            child: itemInkWell(
              onTap: () {
                _tooltip?.close();
                ChatKitMenuHelper.handleAction(
                  message,
                  item['id']!,
                  popMenuAction,
                  isVoiceFromSpeaker,
                );
              },
              child: Column(
                children: [
                  SvgPicture.asset(
                    item["icon"]!,
                    package: kPackage,
                    width: 18,
                    height: 18,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item["label"]!,
                    style: TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: 14,
                      color: '#333333'.toColor(),
                    ),
                  ),
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

  Widget itemInkWell({Widget? child, GestureTapCallback? onTap}) {
    return SizedBox(
      width: 60,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: child,
        ),
      ),
    );
  }
}
