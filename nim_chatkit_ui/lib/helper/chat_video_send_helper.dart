// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:video_player/video_player.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

/// Resolves display dimensions for mobile album video messages.
class ChatVideoSendHelper {
  ChatVideoSendHelper._();

  /// Reads the actual file, falling back to orientation-corrected album size.
  /// Returns null when neither source has valid positive dimensions.
  static Future<Size?> resolveAlbumVideoSize(
    File file, {
    required Size fallbackSize,
    Duration timeout = const Duration(seconds: 5),
    @visibleForTesting VideoPlayerController? controller,
  }) async {
    VideoPlayerController? player = controller;
    try {
      // Android platform-view metadata already swaps dimensions for 90/270
      // degree rotation; AVFoundation reports the video's presentation size.
      player ??= VideoPlayerController.file(
        file,
        viewType: Platform.isAndroid
            ? VideoViewType.platformView
            : VideoViewType.textureView,
      );
      await player.initialize().timeout(timeout);
      final size = _validatedSize(player.value.size);
      if (size != null) return size;
    } catch (error) {
      Alog.w(
        tag: 'ChatKit',
        moduleName: 'video send',
        content: 'read album video size failed: $error',
      );
    } finally {
      // Disposal may wait for a timed-out native creation to complete.
      // Do not block album fallback while ensuring eventual resource cleanup.
      if (player != null) {
        unawaited(player.dispose().catchError((Object error) {
          Alog.w(
            tag: 'ChatKit',
            moduleName: 'video send',
            content: 'dispose album video metadata player failed: $error',
          );
        }));
      }
    }
    return _validatedSize(fallbackSize);
  }

  static Size? _validatedSize(Size size) {
    if (!size.width.isFinite || !size.height.isFinite) return null;
    final width = size.width.round();
    final height = size.height.round();
    if (width <= 0 || height <= 0) return null;
    return Size(width.toDouble(), height.toDouble());
  }
}
