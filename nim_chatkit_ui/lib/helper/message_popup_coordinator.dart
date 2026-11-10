// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Keeps message action menus and reaction pickers mutually exclusive.
class MessagePopupCoordinator {
  MessagePopupCoordinator._();

  static Object? _owner;
  static VoidCallback? _close;
  static final Map<GlobalKey, VoidCallback> _reactionTargets = {};

  /// Registers a reaction add button while its widget is mounted.
  static void registerReactionTarget(GlobalKey key, VoidCallback open) {
    _reactionTargets[key] = open;
  }

  /// Removes a reaction add button when its widget is disposed.
  static void unregisterReactionTarget(GlobalKey key) {
    _reactionTargets.remove(key);
  }

  /// Opens the visible add button hit by a dismissed menu's outside tap.
  static void openReactionAt(Offset position, OverlayState overlay) {
    for (final entry in _reactionTargets.entries) {
      final context = entry.key.currentContext;
      if (context == null ||
          ModalRoute.of(context)?.isCurrent == false ||
          Overlay.maybeOf(context) != overlay) {
        continue;
      }
      final box = context.findRenderObject();
      if (box is RenderBox &&
          box.attached &&
          box.hasSize &&
          (box.localToGlobal(Offset.zero) & box.size).contains(position)) {
        entry.value();
        return;
      }
    }
  }

  /// Closes the previous popup before registering [owner].
  static void activate(Object owner, VoidCallback close) {
    final previousClose = _close;
    _owner = null;
    _close = null;
    previousClose?.call();
    _owner = owner;
    _close = close;
  }

  /// Releases a closing popup without affecting a newer popup.
  static void release(Object owner) {
    if (identical(_owner, owner)) {
      _owner = null;
      _close = null;
    }
  }
}
