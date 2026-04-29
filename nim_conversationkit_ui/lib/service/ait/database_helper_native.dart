// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelperImpl {
  static const _databaseName = "nim_kit_ait.db";
  static const _databaseVersion = 1;

  static const table = 'session_messages';
  static const sessionIdColumn = 'session_id';
  static const messageIdColumn = 'message_id';
  static const myAccId = 'my_acc_id';

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    // 桌面平台（Windows/Linux/macOS）需要初始化 sqflite_common_ffi
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = documentsDirectory.path.endsWith('/')
        ? documentsDirectory.path
        : ('${documentsDirectory.path}/') + _databaseName;
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $sessionIdColumn TEXT NOT NULL,
            $messageIdColumn TEXT NOT NULL,
            $myAccId TEXT NOT NULL
          )
          ''');
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database? db = await database;
    return await db!.insert(table, row);
  }

  Future<int> deleteMessage(
    String sessionId,
    String messageId,
    String accId,
  ) async {
    Database? db = await database;
    return await db!.delete(
      table,
      where: '$sessionIdColumn = ? AND $messageIdColumn = ? AND $myAccId = ?',
      whereArgs: [sessionId, messageId, accId],
    );
  }

  Future<int> clearSessionAitMessage(String sessionId, String accId) async {
    Database? db = await database;
    return await db!.delete(
      table,
      where: '$sessionIdColumn = ? AND $myAccId = ?',
      whereArgs: [sessionId, accId],
    );
  }

  Future<int> insertAitMessage(
    String conversationId,
    String messageId,
    String accId,
  ) async {
    Database? db = await database;
    return await db!.insert(table, {
      sessionIdColumn: conversationId,
      messageIdColumn: messageId,
      myAccId: accId,
    });
  }

  Future<List<String>> queryMessageIdsBySessionId(
    String conversationId,
    String accId,
  ) async {
    Database? db = await database;
    List<Map<String, dynamic>> result = await db!.query(
      table,
      columns: [messageIdColumn],
      where: '$sessionIdColumn = ? AND $myAccId = ?',
      whereArgs: [conversationId, accId],
    );
    return result.map((row) => row[messageIdColumn] as String).toList();
  }

  Future<List<String>> queryAllAitSession(String accId) async {
    Database? db = await database;
    List<Map<String, dynamic>> result = await db!.query(
      table,
      columns: [sessionIdColumn],
      where: '$myAccId = ?',
      whereArgs: [accId],
    );
    return result.map((row) => row[sessionIdColumn] as String).toList();
  }
}
