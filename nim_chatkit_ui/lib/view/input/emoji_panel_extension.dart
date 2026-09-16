// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Sends a prepared image through the current chat's normal image-message flow.
typedef ChatImageMessageSender = Future<bool> Function(
  ChatImageSendRequest request,
);

/// Builds an emoji-panel tab icon for its selected state.
typedef EmojiPanelTabIconBuilder = Widget Function(
  BuildContext context,
  bool selected,
);

/// Builds an emoji-panel tab's constrained content area.
typedef EmojiPanelTabContentBuilder = Widget Function(
  BuildContext context,
  EmojiPanelTabContext tabContext,
);

/// Builds one horizontally pageable mobile page for an emoji-panel tab.
typedef EmojiPanelTabMobilePageBuilder = Widget Function(
  BuildContext context,
  EmojiPanelTabContext tabContext,
  int pageIndex,
);

/// Identifies the presentation family used by the emoji panel.
enum EmojiPanelDisplayMode {
  /// Mobile bottom input panel.
  mobile,

  /// Desktop or Web anchored overlay.
  desktopOrWeb,
}

/// A generic extension that contributes one or more emoji-panel tabs.
abstract class EmojiPanelExtension {
  /// Stable application-wide extension identifier.
  String get id;

  /// Builds the tabs contributed by this extension in display order.
  List<EmojiPanelTab> buildTabs();
}

/// A tab contributed to the emoji panel by an optional package.
class EmojiPanelTab {
  /// Creates an emoji-panel tab.
  const EmojiPanelTab({
    required this.id,
    required this.iconBuilder,
    required this.contentBuilder,
    this.mobilePageCount = 1,
    this.mobilePageBuilder,
    this.semanticsLabel,
  })  : assert(mobilePageCount > 0),
        assert(mobilePageCount == 1 || mobilePageBuilder != null);

  /// Stable identifier within the owning extension.
  final String id;

  /// Builds the fixed-size footer icon.
  final EmojiPanelTabIconBuilder iconBuilder;

  /// Builds the tab content.
  final EmojiPanelTabContentBuilder contentBuilder;

  /// Number of pages contributed to the mobile panel's horizontal sequence.
  final int mobilePageCount;

  /// Builds a mobile page when the tab supplies pageable content.
  ///
  /// When omitted, [contentBuilder] is used as the tab's single mobile page.
  final EmojiPanelTabMobilePageBuilder? mobilePageBuilder;

  /// Optional accessibility label for the tab.
  final String? semanticsLabel;
}

/// Runtime capabilities supplied to an emoji-panel tab.
class EmojiPanelTabContext {
  /// Creates a tab context bound to the current chat input.
  const EmojiPanelTabContext({
    required this.displayMode,
    required this.sendImage,
  });

  /// Current panel presentation family.
  final EmojiPanelDisplayMode displayMode;

  /// Sends an image through the current chat.
  final ChatImageMessageSender sendImage;
}

/// Image data prepared by an optional emoji-panel extension.
class ChatImageSendRequest {
  /// Creates a normal image-message send request.
  const ChatImageSendRequest({
    required this.bytes,
    required this.fileName,
    required this.imageType,
    required this.width,
    required this.height,
    required this.cacheKey,
  });

  /// Encoded image bytes.
  final Uint8List bytes;

  /// Safe file name without directory components.
  final String fileName;

  /// Image extension without a leading dot.
  final String imageType;

  /// Decoded pixel width.
  final int width;

  /// Decoded pixel height.
  final int height;

  /// Stable, non-sensitive key used for native temporary-file reuse.
  final String cacheKey;

  /// Whether all fields can be passed to the normal image-message flow.
  bool get isValid {
    final safeName = fileName.isNotEmpty &&
        fileName != '.' &&
        fileName != '..' &&
        !fileName.contains('/') &&
        !fileName.contains(r'\');
    return bytes.isNotEmpty &&
        safeName &&
        imageType.isNotEmpty &&
        !imageType.contains('.') &&
        width > 0 &&
        height > 0 &&
        cacheKey.isNotEmpty;
  }
}
