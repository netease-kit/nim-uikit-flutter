// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nim_chatkit_pushkit/nim_chatkit_pushkit.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PushKit initializes', (tester) async {
    await PushKit.instance.init();
    final message = await PushKit.instance.getInitialNotification();
    expect(message == null || message.rawPayload.isNotEmpty, isTrue);
  });
}
