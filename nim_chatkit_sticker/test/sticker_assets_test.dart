// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const counts = <String, int>{'ajmd': 48, 'lt': 20, 'xxy': 40};

  test('default Sticker resources are complete and use expected dimensions',
      () async {
    for (final entry in counts.entries) {
      final directory = Directory('assets/sticker/${entry.key}');
      final files = directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.png'))
          .toList();
      expect(files, hasLength(entry.value));

      for (var index = 1; index <= entry.value; index++) {
        final number = index.toString().padLeft(3, '0');
        final file =
            File('assets/sticker/${entry.key}/${entry.key}$number.png');
        expect(file.existsSync(), isTrue, reason: file.path);
        final codec = await ui.instantiateImageCodec(await file.readAsBytes());
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 230, reason: file.path);
        expect(frame.image.height, 230, reason: file.path);
        frame.image.dispose();
        codec.dispose();
      }
    }

    for (final pack in counts.keys) {
      for (final state in <String>['normal', 'pressed']) {
        final file = File('assets/sticker/${pack}_s_$state.png');
        expect(file.existsSync(), isTrue, reason: file.path);
        final codec = await ui.instantiateImageCodec(await file.readAsBytes());
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 58, reason: file.path);
        expect(frame.image.height, 58, reason: file.path);
        frame.image.dispose();
        codec.dispose();
      }
    }

    final bundled = await rootBundle.load(
      'packages/nim_chatkit_sticker/assets/sticker/ajmd/ajmd001.png',
    );
    expect(bundled.lengthInBytes, greaterThan(0));
  });
}
