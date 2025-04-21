// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = "nim_kit_ait.db";
  static const _databaseVersion = 1;

  static const table = 'session_messages';

  static const sessionIdColumn = 'session_id';
  static const messageIdColumn = 'message_id';
  static const myAccId = 'my_acc_id';

  // 单例模式
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // 保存数据库实例
  static Database? _database;
  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  // 初始化数据库
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = documentsDirectory.path.endsWith('/')
        ? documentsDirectory.path
        : ('${documentsDirectory.path}/') + _databaseName;
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // 创建表
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $sessionIdColumn TEXT NOT NULL,
            $messageIdColumn TEXT NOT NULL,
            $myAccId TEXT NOT NULL
          )
          ''');
  }

  // 插入数据
  Future<int> insert(Map<String, dynamic> row) async {
    Database? db = await instance.database;
    return await db!.insert(table, row);
  }

  // 删除@消息
  Future<int> deleteMessage(
      String sessionId, String messageId, String accId) async {
    Database? db = await instance.database;
    return await db!.delete(table,
        where: '$sessionIdColumn = ? AND $messageIdColumn = ? AND $myAccId = ?',
        whereArgs: [sessionId, messageId, accId]);
  }

  //清除sessionId对应的所有messageId
  Future<int> clearSessionAitMessage(String sessionId, String accId) async {
    Database? db = await instance.database;
    return await db!.delete(table,
        where: '$sessionIdColumn = ? AND $myAccId = ?',
        whereArgs: [sessionId, accId]);
  }

  // 添加@消息
  Future<int> insertAitMessage(
      String conversationId, String messageId, String accId) async {
    Database? db = await instance.database;
    return await db!.insert(table, {
      sessionIdColumn: conversationId,
      messageIdColumn: messageId,
      myAccId: accId
    });
  }

  /// 查询session中对应的@消息
  Future<List<String>> queryMessageIdsBySessionId(
      String conversationId, String accId) async {
    Database? db = await instance.database;
    List<Map<String, dynamic>> result = await db!.query(table,
        columns: [messageIdColumn],
        where: '$sessionIdColumn = ? AND $myAccId = ?',
        whereArgs: [conversationId, accId]);
    return result.map((row) => row[messageIdColumn] as String).toList();
  }

  /// 查询对应账号中所有@的sessionId
  Future<List<String>> queryAllAitSession(String accId) async {
    Database? db = await instance.database;
    List<Map<String, dynamic>> result = await db!.query(table,
        columns: [sessionIdColumn], where: '$myAccId = ?', whereArgs: [accId]);
    return result.map((row) => row[sessionIdColumn] as String).toList();
  }
}
