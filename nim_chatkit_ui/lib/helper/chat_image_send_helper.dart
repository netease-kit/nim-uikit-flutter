// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../view/input/emoji_panel_extension.dart';

/// Materializes extension-provided image bytes for native image-message APIs.
class ChatImageSendHelper {
  ChatImageSendHelper._();

  static final Map<String, Future<String?>> _pendingFiles =
      <String, Future<String?>>{};

  /// Returns a stable temporary path for [request], or null when writing fails.
  static Future<String?> materialize(ChatImageSendRequest request) {
    final existing = _pendingFiles[request.cacheKey];
    if (existing != null) {
      return existing;
    }

    final pending = _write(request);
    _pendingFiles[request.cacheKey] = pending;
    pending.then((path) {
      if (path == null) {
        _pendingFiles.remove(request.cacheKey);
      }
    });
    return pending;
  }

  static Future<String?> _write(ChatImageSendRequest request) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory(p.join(tempDir.path, 'nim_chatkit_ui_images'));
      await cacheDir.create(recursive: true);
      final safeName = request.fileName.replaceAll(
        RegExp(r'[^A-Za-z0-9._-]'),
        '_',
      );
      final cacheHash =
          request.cacheKey.hashCode.toUnsigned(32).toRadixString(16);
      final file = File(p.join(cacheDir.path, '${cacheHash}_$safeName'));
      if (!await file.exists() || await file.length() != request.bytes.length) {
        await file.writeAsBytes(request.bytes, flush: true);
      }
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
