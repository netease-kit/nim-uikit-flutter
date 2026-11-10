// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:nim_chatkit_ui/helper/ait_member_search_helper.dart';

void main() {
  group('findAitMemberDisplayNameMatch', () {
    test('returns the literal keyword range', () {
      final match = findAitMemberDisplayNameMatch('哈利波特', '利波');

      expect(match, isNotNull);
      expect(match!.start, 1);
      expect(match.end, 3);
    });

    test('returns the original case-insensitive literal range', () {
      final match = findAitMemberDisplayNameMatch('YUN', 'u');

      expect(match, isNotNull);
      expect(match!.start, 1);
      expect(match.end, 2);
    });

    test('returns null for empty or unmatched queries', () {
      expect(findAitMemberDisplayNameMatch('小云', ' '), isNull);
      expect(findAitMemberDisplayNameMatch('小云', 'z'), isNull);
    });
  });

  test('returns every repeated match for highlighting', () {
    final matches = findAitMemberDisplayNameMatches('YunYUN', 'yun');

    expect(matches, hasLength(2));
    expect(matches[0].start, 0);
    expect(matches[0].end, 3);
    expect(matches[1].start, 3);
    expect(matches[1].end, 6);
  });

  group('matchesAitMemberValue', () {
    test('matches Chinese keyword', () {
      expect(matchesAitMemberValue('哈利波特', '哈利'), isTrue);
      expect(matchesAitMemberValue('哈利波特', '波特'), isTrue);
      expect(matchesAitMemberValue('哈利波特', '云'), isFalse);
    });

    test('matches case-insensitively and uses literal matching', () {
      expect(matchesAitMemberValue('YUN', 'yun'), isTrue);
      expect(matchesAitMemberValue('小云', 'yun'), isFalse);
      expect(matchesAitMemberValue('哈利波特', 'hlbt'), isFalse);
    });

    test('normalizes surrounding whitespace and empty queries', () {
      expect(matchesAitMemberValue('小云', ' 云 '), isTrue);
      expect(matchesAitMemberValue('小云', ''), isTrue);
      expect(matchesAitMemberValue('小云', '   '), isTrue);
      expect(matchesAitMemberValue('', 'y'), isFalse);
    });

    test('uses literal matching for numbers and symbols', () {
      expect(matchesAitMemberValue('用户-01', '01'), isTrue);
      expect(matchesAitMemberValue('用户-01', '-'), isTrue);
      expect(matchesAitMemberValue('用户-01', '02'), isFalse);
    });
  });

  test('matches any searchable field', () {
    final fields = <String, String?>{
      'friendAlias': '老张',
      'teamNick': '前端小分队',
      'userName': 'lisi',
      'accountId': 'u_aaa',
    };
    expect(matchesAitMemberFields(fields, '前端'), isTrue);
    expect(matchesAitMemberFields(fields, 'u_aaa'), isTrue);
    expect(matchesAitMemberFields(fields, '不存在'), isFalse);
  });

  group('findAitMemberSubtitles', () {
    test('shows only the highest-priority matched secondary name', () {
      final fields = <String, String?>{
        'friendAlias': '主要名称',
        'teamNick': '命中群昵称',
        'userName': '命中用户名',
        'accountId': '命中账号',
      };

      expect(
        findAitMemberSubtitles(fields, '主要名称', '命中'),
        ['命中群昵称'],
      );
    });

    test('does not add a secondary line when the primary name matches', () {
      final fields = <String, String?>{
        'friendAlias': '命中主要名称',
        'teamNick': '命中群昵称',
        'userName': '命中用户名',
        'accountId': '命中账号',
      };

      expect(
        findAitMemberSubtitles(fields, '命中主要名称', '命中'),
        isEmpty,
      );
    });

    test('does not repeat the primary value as a subtitle', () {
      final fields = <String, String?>{
        'friendAlias': '主要名称',
        'teamNick': '主要名称',
        'userName': '命中用户名',
        'accountId': '命中账号',
      };

      expect(
        findAitMemberSubtitles(fields, '主要名称', '主要'),
        isEmpty,
      );
    });
  });
}
