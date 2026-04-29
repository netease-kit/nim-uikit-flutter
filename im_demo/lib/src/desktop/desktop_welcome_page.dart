// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../l10n/S.dart';

/// 桌面端欢迎页
///
/// 当右侧 ContentPanel 未选中任何会话时展示。
/// 居中显示欢迎图标和欢迎文字。
class DesktopWelcomePage extends StatelessWidget {
  const DesktopWelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/ic_welcome_desktop.svg',
              width: 119,
              height: 90,
            ),
            const SizedBox(height: 20),
            Text(
              S.of(context).desktopWelcomeTitle,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
