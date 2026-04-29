// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// Stub implementation for non-web platforms.
// On non-web builds this file is imported instead of video_metadata_web_impl.dart.

/// Returns [width, height, durationMs]. Always [0, 0, 0] on non-web platforms.
Future<List<int>> fetchWebVideoMetadata(List<int> bytes) async {
  return [0, 0, 0];
}
