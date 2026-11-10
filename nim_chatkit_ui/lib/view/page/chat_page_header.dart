// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:netease_common_ui/utils/color_utils.dart';

/// 聊天页顶部标题栏。
///
/// 默认左对齐，供桌面/Web 聊天页使用；Duo 双屏聊天页传入 [centerTitle]，
/// 让标题（含副标题、状态图标）在右侧面板内水平居中。存在 [trailing] 时
/// 保持左对齐，避免长标题与右侧按钮互相压盖。
class ChatPageHeader extends StatelessWidget {
  const ChatPageHeader({
    Key? key,
    required this.title,
    this.subTitle,
    this.subTitleWidget,
    this.centerTitle = false,
    this.trailing,
  }) : super(key: key);

  /// 主标题（会话名称、输入中提示等）。
  final String title;

  /// 副标题（在线状态等）。
  final String? subTitle;

  /// 副标题位置的图标（如听筒图标）。
  final Widget? subTitleWidget;

  /// 是否在标题栏内水平居中。
  final bool centerTitle;

  /// 标题栏右侧操作（如多选取消按钮）。
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final bool center = centerTitle && trailing == null;
    final Widget titleRow = Row(
      mainAxisSize: center ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        if (subTitle != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              subTitle!,
              style: TextStyle(
                fontSize: 13,
                color: '#999999'.toColor(),
              ),
            ),
          ),
        if (subTitleWidget != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: subTitleWidget,
          ),
      ],
    );
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: '#E8E8E8'.toColor(), width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: center
          ? Center(child: titleRow)
          : Row(
              children: [
                Expanded(child: titleRow),
                if (trailing != null) trailing!,
              ],
            ),
    );
  }
}
