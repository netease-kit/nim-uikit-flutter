// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:netease_common_ui/base/default_language.dart';

import 'package:nim_chatkit_callkit/l10n/S.dart';

void main() {
  tearDown(() {
    CommonUIDefaultLanguage.commonDefaultLanguage = null;
  });

  test('uses the configured language for the call action title', () {
    CommonUIDefaultLanguage.commonDefaultLanguage = languageEn;
    expect(S.of().chatMessageCallTitle, 'Call');

    CommonUIDefaultLanguage.commonDefaultLanguage = languageZh;
    expect(S.of().chatMessageCallTitle, '音视频通话');
  });
}
