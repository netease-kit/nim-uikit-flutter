// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// 通讯录分类枚举
enum ContactCategory {
  /// 未选中任何分类
  none,

  /// 验证消息
  verifyMessage,

  /// 黑名单
  blackList,

  /// 我的好友
  myFriends,

  /// 我的群聊
  myTeams,

  /// 我的数字人
  myAIUsers,
}

/// 桌面端内容面板状态控制器
///
/// 管理桌面端三栏布局中的导航状态和右侧内容面板切换。
/// 通过 [ChangeNotifier] 通知 UI 更新，避免使用 Navigator.push 进行页面跳转。
class DesktopContentController extends ChangeNotifier {
  /// 当前侧边栏导航索引: 0=会话, 1=通讯录
  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  /// 当前选中的会话 ID，null 表示未选中任何会话
  String? _currentConversationId;
  String? get currentConversationId => _currentConversationId;

  /// 当前选中的通讯录分类
  ContactCategory _currentContactCategory = ContactCategory.none;
  ContactCategory get currentContactCategory => _currentContactCategory;

  /// 切换侧边栏导航
  void switchNav(int index) {
    if (_currentNavIndex != index) {
      _currentNavIndex = index;
      notifyListeners();
    }
  }

  /// 选中一个会话，右侧面板展示对应的聊天页
  void selectConversation(String conversationId) {
    if (_currentConversationId != conversationId) {
      _currentConversationId = conversationId;
      notifyListeners();
    }
  }

  /// 选中通讯录分类，右侧面板展示对应的列表
  void selectContactCategory(ContactCategory category) {
    if (_currentContactCategory != category) {
      _currentContactCategory = category;
      notifyListeners();
    }
  }

  /// 清除当前选中的会话，右侧面板回到欢迎页
  void clearContent() {
    if (_currentConversationId != null) {
      _currentConversationId = null;
      notifyListeners();
    }
  }

  /// 清除通讯录分类选择
  void clearContactCategory() {
    if (_currentContactCategory != ContactCategory.none) {
      _currentContactCategory = ContactCategory.none;
      notifyListeners();
    }
  }

  /// 导航到聊天页面（供桌面端全局回调使用）
  ///
  /// 原子性地切换到会话 Tab 并选中指定会话，只触发一次 notifyListeners()。
  void navigateToChat(String conversationId) {
    _currentNavIndex = 0;
    _currentConversationId = conversationId;
    notifyListeners();
  }
}
