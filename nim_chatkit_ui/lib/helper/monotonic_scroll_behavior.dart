// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 过滤时间戳倒序采样的滚动行为。
///
/// 开启指针事件重采样（`GestureBinding.instance.resamplingEnabled = true`）后，
/// Flutter 会先派发带真实时间戳的指针事件，再派发时间戳略早的重采样事件。
/// [IOSScrollViewFlingVelocityTracker] 会因此触发
/// “The position being added has a smaller timestamp than its predecessor” 断言。
///
/// 这里只丢弃时间戳严格倒序的采样点，速度估计仍使用其余采样，滚动、点击和
/// 惯性效果都不受影响；未开启重采样或非 iOS 平台保持 Flutter 默认实现。
class MonotonicScrollBehavior extends MaterialScrollBehavior {
  const MonotonicScrollBehavior();

  @override
  GestureVelocityTrackerBuilder velocityTrackerBuilder(BuildContext context) {
    final GestureVelocityTrackerBuilder builder =
        super.velocityTrackerBuilder(context);
    return (PointerEvent event) {
      final VelocityTracker tracker = builder(event);
      if (tracker is MacOSScrollViewFlingVelocityTracker) {
        return _MonotonicMacOSVelocityTracker(tracker.kind);
      }
      if (tracker is IOSScrollViewFlingVelocityTracker) {
        return _MonotonicIOSVelocityTracker(tracker.kind);
      }
      return tracker;
    };
  }
}

class _MonotonicIOSVelocityTracker extends IOSScrollViewFlingVelocityTracker {
  _MonotonicIOSVelocityTracker(super.kind);

  Duration? _lastSampleTime;

  @override
  void addPosition(Duration time, Offset position) {
    final Duration? lastSampleTime = _lastSampleTime;
    if (lastSampleTime != null && time < lastSampleTime) {
      return;
    }
    _lastSampleTime = time;
    super.addPosition(time, position);
  }
}

class _MonotonicMacOSVelocityTracker
    extends MacOSScrollViewFlingVelocityTracker {
  _MonotonicMacOSVelocityTracker(super.kind);

  Duration? _lastSampleTime;

  @override
  void addPosition(Duration time, Offset position) {
    final Duration? lastSampleTime = _lastSampleTime;
    if (lastSampleTime != null && time < lastSampleTime) {
      return;
    }
    _lastSampleTime = time;
    super.addPosition(time, position);
  }
}
