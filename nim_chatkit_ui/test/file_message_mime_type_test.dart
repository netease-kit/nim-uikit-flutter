// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_file_item.dart'
    as chat_file;
import 'package:nim_chatkit_ui/view/history/item/chat_history_file_message_item.dart'
    as history_file;

void main() {
  test('Android file message entry points open WebP as an image', () {
    expect(chat_file.support_type_map_android['webp'], 'image/webp');
    expect(history_file.support_type_map_android['webp'], 'image/webp');
  });
}
