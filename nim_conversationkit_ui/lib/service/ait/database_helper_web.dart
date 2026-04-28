// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// Web platform stub — sqflite and path_provider are not available on Web.
// Uses in-memory storage instead.

/// Web 平台使用内存存储替代 sqflite 数据库，实现 @消息的增删查功能。
class DatabaseHelperImpl {
  // key: "$accId/$sessionId", value: Set<messageId>
  final Map<String, Set<String>> _store = {};

  String _key(String sessionId, String accId) => '$accId/$sessionId';

  Future<int> insert(Map<String, dynamic> row) async {
    final sessionId = row['session_id'] as String? ?? '';
    final messageId = row['message_id'] as String? ?? '';
    final accId = row['my_acc_id'] as String? ?? '';
    return insertAitMessage(sessionId, messageId, accId);
  }

  Future<int> deleteMessage(
    String sessionId,
    String messageId,
    String accId,
  ) async {
    final key = _key(sessionId, accId);
    final set = _store[key];
    if (set == null) return 0;
    final removed = set.remove(messageId);
    return removed ? 1 : 0;
  }

  Future<int> clearSessionAitMessage(String sessionId, String accId) async {
    final key = _key(sessionId, accId);
    final count = _store[key]?.length ?? 0;
    _store.remove(key);
    return count;
  }

  Future<int> insertAitMessage(
    String conversationId,
    String messageId,
    String accId,
  ) async {
    final key = _key(conversationId, accId);
    _store.putIfAbsent(key, () => {}).add(messageId);
    return 1;
  }

  Future<List<String>> queryMessageIdsBySessionId(
    String conversationId,
    String accId,
  ) async {
    final key = _key(conversationId, accId);
    return (_store[key] ?? {}).toList();
  }

  Future<List<String>> queryAllAitSession(String accId) async {
    final prefix = '$accId/';
    return _store.entries
        .where((e) => e.key.startsWith(prefix) && e.value.isNotEmpty)
        .map((e) => e.key.substring(prefix.length))
        .toList();
  }
}
