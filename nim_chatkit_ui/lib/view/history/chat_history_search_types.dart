// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// 桌面/Web 端历史消息搜索 Tab 类型枚举
enum SearchTabType { file, image, video, date, teamMember }

/// 日期选择弹框返回结果
class DatePickerResult {
  final int startTime;
  final int? endTime;
  final String label;

  const DatePickerResult({
    required this.startTime,
    this.endTime,
    required this.label,
  });
}

/// Tab 描述，包含标签文字、类型和点击回调
class TabItem {
  final String label;
  final SearchTabType type;
  final VoidCallback onTap;

  const TabItem({
    required this.label,
    required this.type,
    required this.onTap,
  });
}
