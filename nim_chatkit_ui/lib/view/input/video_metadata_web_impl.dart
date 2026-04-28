// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// Web implementation: reads video metadata via HTMLVideoElement + Blob URL.
// This file is only compiled on the web platform.
// Uses dart:html which is compatible with Dart 2.x and Flutter Web.

import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// Returns [width, height, durationMs]. Falls back to [0, 0, 0] on error.
Future<List<int>> fetchWebVideoMetadata(List<int> bytes) async {
  String? objectUrl;
  try {
    final uint8 = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final blob = html.Blob([uint8], 'video/*');
    objectUrl = html.Url.createObjectUrlFromBlob(blob);

    final video = html.VideoElement()
      ..preload = 'metadata'
      ..src = objectUrl;

    final completer = Completer<List<int>>();

    late StreamSubscription sub;
    sub = video.onLoadedMetadata.listen((_) {
      final w = video.videoWidth;
      final h = video.videoHeight;
      final durationMs = (video.duration * 1000).toInt();
      if (!completer.isCompleted) completer.complete([w, h, durationMs]);
      sub.cancel();
    });

    return await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => [0, 0, 0],
    );
  } catch (_) {
    return [0, 0, 0];
  } finally {
    if (objectUrl != null) {
      html.Url.revokeObjectUrl(objectUrl);
    }
  }
}
