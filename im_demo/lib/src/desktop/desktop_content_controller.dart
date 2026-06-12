// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/manager/ai_robot_manager.dart';
import 'package:nim_chatkit/model/bot_subsession_models.dart';

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

  /// 我的机器人
  myRobots,

  /// 我的数字人
  myAIUsers,
}

/// 桌面端内容面板状态控制器
///
/// 管理桌面端三栏布局中的导航状态和右侧内容面板切换。
/// 通过 [ChangeNotifier] 通知 UI 更新，避免使用 Navigator.push 进行页面跳转。
enum ConversationContentKind {
  chat,
  botSubsessionList,
  topicChat,
}

class DesktopContentController extends ChangeNotifier {
  /// 当前侧边栏导航索引: 0=会话, 1=通讯录
  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  /// 当前选中的会话 ID，null 表示未选中任何会话
  String? _currentConversationId;
  String? get currentConversationId => _currentConversationId;

  ConversationContentKind _conversationContentKind =
      ConversationContentKind.chat;
  ConversationContentKind get conversationContentKind =>
      _conversationContentKind;

  BotSubsessionTopicContext? _currentTopicContext;
  BotSubsessionTopicContext? get currentTopicContext => _currentTopicContext;

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

  bool _isBotConversation(String conversationId) {
    final targetId = ChatKitUtils.getConversationTargetId(conversationId);
    return AIRobotManager.instance.isRobot(targetId);
  }

  /// 选中一个会话，右侧面板展示对应内容页
  void selectConversation(
    String conversationId, {
    bool forceLinearChat = false,
    BotSubsessionTopicContext? topicContext,
  }) {
    _currentConversationId = conversationId;
    _currentTopicContext = topicContext;
    if (topicContext != null) {
      _conversationContentKind = ConversationContentKind.topicChat;
    } else {
      _conversationContentKind =
          (!forceLinearChat && _isBotConversation(conversationId))
              ? ConversationContentKind.botSubsessionList
              : ConversationContentKind.chat;
    }
    notifyListeners();
  }

  void selectBotSubsessionTopic(BotSubsessionTopicContext topicContext) {
    _currentConversationId ??= topicContext.conversationId;
    _currentTopicContext = topicContext;
    _conversationContentKind = ConversationContentKind.botSubsessionList;
    notifyListeners();
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
      _currentTopicContext = null;
      _conversationContentKind = ConversationContentKind.chat;
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
  void navigateToChat(
    String conversationId, {
    bool forceLinearChat = false,
    BotSubsessionTopicContext? topicContext,
  }) {
    _currentNavIndex = 0;
    selectConversation(
      conversationId,
      forceLinearChat: forceLinearChat,
      topicContext: topicContext,
    );
  }
}
