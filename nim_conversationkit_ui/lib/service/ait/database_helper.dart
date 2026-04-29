// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

// Non-web imports
import 'database_helper_native.dart'
    if (dart.library.html) 'database_helper_web.dart';

class DatabaseHelper {
  // 单例模式
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  final _impl = DatabaseHelperImpl();

  // 插入数据
  Future<int> insert(Map<String, dynamic> row) async {
    return _impl.insert(row);
  }

  // 删除@消息
  Future<int> deleteMessage(
    String sessionId,
    String messageId,
    String accId,
  ) async {
    return _impl.deleteMessage(sessionId, messageId, accId);
  }

  //清除sessionId对应的所有messageId
  Future<int> clearSessionAitMessage(String sessionId, String accId) async {
    return _impl.clearSessionAitMessage(sessionId, accId);
  }

  // 添加@消息
  Future<int> insertAitMessage(
    String conversationId,
    String messageId,
    String accId,
  ) async {
    return _impl.insertAitMessage(conversationId, messageId, accId);
  }

  /// 查询session中对应的@消息
  Future<List<String>> queryMessageIdsBySessionId(
    String conversationId,
    String accId,
  ) async {
    return _impl.queryMessageIdsBySessionId(conversationId, accId);
  }

  /// 查询对应账号中所有@的sessionId
  Future<List<String>> queryAllAitSession(String accId) async {
    return _impl.queryAllAitSession(accId);
  }
}
