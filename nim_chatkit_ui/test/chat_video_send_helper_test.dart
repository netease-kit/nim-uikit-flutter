// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:nim_chatkit_ui/helper/chat_video_send_helper.dart';

class _MetadataController extends VideoPlayerController {
  final Size metadataSize;
  final Future<void>? initialization;
  bool released = false;

  _MetadataController({
    this.metadataSize = Size.zero,
    this.initialization,
  }) : super.file(File('unused.mp4'));

  @override
  Future<void> initialize() async {
    await initialization;
    if (released) return;
    value = VideoPlayerValue(
      duration: const Duration(seconds: 1),
      size: metadataSize,
      isInitialized: true,
    );
  }

  @override
  Future<void> dispose() async {
    released = true;
    await super.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final file = File('album-video.mp4');

  test('prefers actual file dimensions over inaccurate album dimensions',
      () async {
    final controller = _MetadataController(
      metadataSize: const Size(1080, 1920),
    );
    final size = await ChatVideoSendHelper.resolveAlbumVideoSize(
      file,
      fallbackSize: const Size(1920, 1080),
      controller: controller,
    );
    expect(size, const Size(1080, 1920));
    expect(controller.released, isTrue);
  });

  for (final orientation in [0, 90, 180, 270]) {
    test('uses orientation-corrected album fallback for $orientation degrees',
        () async {
      final asset = AssetEntity(
        id: 'video',
        typeInt: 2,
        width: 1920,
        height: 1080,
        orientation: orientation,
      );
      final controller = _MetadataController();
      final size = await ChatVideoSendHelper.resolveAlbumVideoSize(
        file,
        fallbackSize: asset.orientatedSize,
        controller: controller,
      );
      expect(
        size,
        orientation == 90 || orientation == 270
            ? const Size(1080, 1920)
            : const Size(1920, 1080),
      );
      expect(controller.released, isTrue);
    });
  }

  test('uses file dimensions even when album dimensions are missing', () async {
    final size = await ChatVideoSendHelper.resolveAlbumVideoSize(
      file,
      fallbackSize: Size.zero,
      controller: _MetadataController(metadataSize: const Size(1280, 720)),
    );
    expect(size, const Size(1280, 720));
  });

  test('falls back and releases the player after initialization fails',
      () async {
    final completer = Completer<void>();
    final controller = _MetadataController(initialization: completer.future);
    final pending = ChatVideoSendHelper.resolveAlbumVideoSize(
      file,
      fallbackSize: const Size(1080, 1920),
      controller: controller,
    );
    completer.completeError(StateError('unsupported video'));
    expect(await pending, const Size(1080, 1920));
    expect(controller.released, isTrue);
  });

  test('falls back on timeout and releases the player', () async {
    final completer = Completer<void>();
    final controller = _MetadataController(initialization: completer.future);
    final size = await ChatVideoSendHelper.resolveAlbumVideoSize(
      file,
      fallbackSize: const Size(1080, 1920),
      controller: controller,
      timeout: const Duration(milliseconds: 10),
    );
    expect(size, const Size(1080, 1920));
    expect(controller.released, isTrue);
    completer.complete();
  });

  for (final invalidSize in [
    Size.zero,
    const Size(0, 1080),
    const Size(1920, -1),
    const Size(double.nan, 1080),
    const Size(1920, double.infinity),
  ]) {
    test('rejects invalid dimensions $invalidSize from both sources', () async {
      final controller = _MetadataController(metadataSize: invalidSize);
      final size = await ChatVideoSendHelper.resolveAlbumVideoSize(
        file,
        fallbackSize: invalidSize,
        controller: controller,
      );
      expect(size, isNull);
      expect(controller.released, isTrue);
    });
  }
}
