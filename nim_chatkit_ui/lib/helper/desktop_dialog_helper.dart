// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';

/// 桌面端/Web 端统一弹框辅助方法
/// 使用 showDialog 包裹内容，Dialog 居中显示，支持点击外部关闭和 ESC 关闭
Future<T?> showDesktopDialog<T>(BuildContext context, Widget child) {
  final size = MediaQuery.of(context).size;
  final dialogWidth = min(size.width * 0.8, 900.0);
  final dialogHeight = size.height * 0.85;

  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (BuildContext dialogContext) {
      return Center(
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Material(
              type: MaterialType.transparency,
              child: child,
            ),
          ),
        ),
      );
    },
  );
}
