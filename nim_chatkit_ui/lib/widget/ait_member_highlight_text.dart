// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/search_highlight.dart';

import '../helper/ait_member_search_helper.dart';

/// Displays an @ member name and highlights the matched search text.
class AitMemberHighlightText extends StatelessWidget {
  final String displayName;
  final String query;
  final TextStyle style;

  const AitMemberHighlightText({
    Key? key,
    required this.displayName,
    required this.query,
    required this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final matches = findAitMemberDisplayNameMatches(displayName, query)
        .map((match) => SearchHighlightRange(match.start, match.end))
        .toList();
    return SearchHighlightText(
      text: displayName,
      ranges: matches,
      style: style,
      highlightStyle: const TextStyle(color: CommonColors.color_337eff),
      maxLines: 1,
      maxVisibleLength: query.trim().isEmpty ? null : 16,
    );
  }
}
