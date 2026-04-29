// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../chat_kit_client.dart';

/// 搜索类型 Chip 标签组件
/// 白色背景 + 漏斗图标 + 文字 + × 关闭
class SearchTypeChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  /// 点击 Chip 正文区域（非 × 按钮）时的回调，为 null 时正文区域无点击响应
  final VoidCallback? onTap;

  const SearchTypeChip({
    Key? key,
    required this.label,
    required this.onRemove,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧漏斗过滤图标
          SvgPicture.asset(
            'images/ic_chat_history_filter.svg',
            package: kPackage,
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              Color(0xFF656A72),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 6),
          // 文字标签（可点击区域）
          Flexible(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // 右侧 × 关闭
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: const Icon(
              Icons.close,
              size: 14,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}
