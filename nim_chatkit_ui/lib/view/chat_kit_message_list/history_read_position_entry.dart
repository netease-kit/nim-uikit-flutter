// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../model/history_read_position_tracker.dart';

bool shouldShowHistoryReadPositionEntry({
  required HistoryReadPositionState state,
  required int count,
  required bool isMultiSelected,
}) {
  return !isMultiSelected &&
      count > 0 &&
      (state == HistoryReadPositionState.ready ||
          state == HistoryReadPositionState.locating);
}

class HistoryReadPositionEntry extends StatelessWidget {
  const HistoryReadPositionEntry({
    Key? key,
    required this.label,
    required this.locating,
    this.loading,
    required this.isDesktopOrWeb,
    required this.onTap,
  }) : super(key: key);

  final String label;
  final bool locating;
  final bool? loading;
  final bool isDesktopOrWeb;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(isDesktopOrWeb ? 6 : 18);
    final showLoading = loading ?? locating;
    return Material(
      color: Colors.white,
      elevation: isDesktopOrWeb ? 2 : 3,
      borderRadius: borderRadius,
      child: InkWell(
        key: const ValueKey('history-read-position-entry'),
        borderRadius: borderRadius,
        onTap: locating ? null : onTap,
        child: Opacity(
          opacity: locating ? 0.55 : 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktopOrWeb ? 10 : 12,
                vertical: 9,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 16,
                    child: showLoading
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1861DF),
                          )
                        : const Icon(
                            Icons.keyboard_double_arrow_up,
                            size: 16,
                            color: Color(0xFF1861DF),
                          ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1861DF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
