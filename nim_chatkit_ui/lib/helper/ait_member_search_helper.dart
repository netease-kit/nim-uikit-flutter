// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// The UTF-16 code unit range matched in an @ member display name.
class AitMemberMatchRange {
  /// Inclusive start offset.
  final int start;

  /// Exclusive end offset.
  final int end;

  const AitMemberMatchRange(this.start, this.end);
}

/// Finds the literal display-name range matched by [query].
AitMemberMatchRange? findAitMemberDisplayNameMatch(
  String displayName,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return null;
  }

  final literalStart = displayName.toLowerCase().indexOf(normalizedQuery);
  if (literalStart >= 0) {
    return AitMemberMatchRange(
      literalStart,
      literalStart + normalizedQuery.length,
    );
  }

  return null;
}

/// Finds all non-overlapping case-insensitive matches in a display name.
List<AitMemberMatchRange> findAitMemberDisplayNameMatches(
  String displayName,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return const [];
  }
  final normalizedName = displayName.toLowerCase();
  final matches = <AitMemberMatchRange>[];
  var offset = 0;
  while (offset <= normalizedName.length - normalizedQuery.length) {
    final index = normalizedName.indexOf(normalizedQuery, offset);
    if (index < 0) {
      break;
    }
    matches.add(AitMemberMatchRange(
      index,
      index + normalizedQuery.length,
    ));
    offset = index + normalizedQuery.length;
  }
  return matches;
}

/// Returns whether [value] contains [query] using case-insensitive matching.
bool matchesAitMemberValue(String? value, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return true;
  }
  return value?.toLowerCase().contains(normalizedQuery) == true;
}

/// Returns whether any searchable member field contains [query].
bool matchesAitMemberFields(Map<String, String?> fields, String query) {
  final normalizedQuery = query.trim();
  if (normalizedQuery.isEmpty) {
    return true;
  }
  return fields.values
      .any((value) => matchesAitMemberValue(value, normalizedQuery));
}

/// Returns at most one matched secondary name in the order of [fields].
///
/// The primary [displayName] and duplicate values are not repeated. Callers
/// must provide fields in product priority order: alias, team nickname, user
/// name, then account ID.
List<String> findAitMemberSubtitles(
  Map<String, String?> fields,
  String displayName,
  String query,
) {
  if (query.trim().isEmpty) {
    return const [];
  }
  final normalizedDisplayName = displayName.trim();
  if (matchesAitMemberValue(normalizedDisplayName, query)) {
    return const [];
  }
  for (final value in fields.values) {
    final normalizedValue = value?.trim();
    if (normalizedValue == null ||
        normalizedValue.isEmpty ||
        normalizedValue == normalizedDisplayName ||
        !matchesAitMemberValue(normalizedValue, query)) {
      continue;
    }
    return [normalizedValue];
  }
  return const [];
}
