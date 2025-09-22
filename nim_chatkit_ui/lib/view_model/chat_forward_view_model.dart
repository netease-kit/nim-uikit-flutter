// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:netease_common_ui/utils/text_search.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/model/recent_forward.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import 'package:nim_chatkit/repo/conversation_repo.dart';
import 'package:nim_chatkit/repo/team_repo.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/contact/contact_provider.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../model/forward/forward_selected_beam.dart';

class ChatForwardViewModel extends ChangeNotifier {
  ///是否多选
  bool isMultiSelect = false;

  /// 最近转发列表
  List<RecentForward> recentForwards = [];

  /// 会话显示列表
  List<SearchResult<NIMConversation>> conversationShowList = [];

  /// 好友显示列表
  List<SearchResult<ContactInfo>> contactShowList = [];

  ///群组显示列表
  List<SearchResult<NIMTeam>> teamShowList = [];

  /// 会话列表
  List<NIMConversation> conversationList = [];

  /// 好友列表
  List<ContactInfo> contactList = [];

  ///  所有的群组
  List<NIMTeam> teamList = [];

  /// 选中列表
  List<SelectedBeam> selectedList = [];

  int conversationOffset = 0;

  final int conversationLimit = 100;

  bool hasMoreConversation = true;

  List<String>? filterSessions;

  ChatForwardViewModel(List<String>? filterSessions) {
    this.filterSessions = filterSessions;
    _init();
  }

  void setMultiSelect(bool isMultiSelect) {
    if (this.isMultiSelect == false) {
      this.isMultiSelect = isMultiSelect;
      notifyListeners();
    }
  }

  void addSelected(SelectedBeam selected) {
    if (selectedList.contains(selected)) {
      return;
    }
    if (selected.type == NIMConversationType.team) {
      final team = teamList
          .firstWhereOrNull((element) => element.teamId == selected.sessionId);
      selected.count = team?.memberCount;
    }
    selectedList.add(selected);
    notifyListeners();
  }

  void removeSelected(SelectedBeam selected) {
    selectedList.remove(selected);
    notifyListeners();
  }

  /// 加载初始化数据，最近转发和会话列表
  void _loadData() async {
    recentForwards = await ChatMessageRepo.getRecentForward();

    teamList = (await TeamRepo.getJoinedTeamList()).data ?? [];

    teamList.sort((a, b) => b.createTime.compareTo(a.createTime));

    teamShowList = teamList
        .where((team) => filterSessions?.contains(team.teamId) != true)
        .map((team) => SearchResult<NIMTeam>(data: team))
        .toList();

    final conversationResult = await ConversationRepo.getConversationList(
        conversationOffset, conversationLimit);

    conversationList = conversationResult?.conversationList ?? [];

    conversationShowList = conversationList
        .where((conversation) =>
            filterSessions?.contains(ChatKitUtils.getConversationTargetId(
                conversation.conversationId)) !=
            true)
        .map(
            (conversation) => SearchResult<NIMConversation>(data: conversation))
        .toList();

    conversationOffset = conversationResult?.offset ?? 0;

    hasMoreConversation = conversationResult?.finished == false;

    notifyListeners();
  }

  void _init() async {
    _loadData();
  }

  int? getConversationCount(String conversationId) {
    final targetId = ChatKitUtils.getConversationTargetId(conversationId);
    final team =
        teamList.firstWhereOrNull((element) => element.teamId == targetId);
    if (team != null) {
      return team.memberCount;
    }
    return null;
  }

  ///搜索联系人
  void searchContactByKeyword(String? keyword) {
    if (keyword?.isNotEmpty != true) {
      contactShowList = contactList
          .where((contact) =>
              filterSessions?.contains(contact.user.accountId) != true)
          .map((contact) => SearchResult<ContactInfo>(data: contact))
          .toList();
      notifyListeners();
      return;
    }
    contactShowList.clear();
    for (ContactInfo contact in contactList) {
      final res = TextSearcher.search(contact.getName(), keyword!);
      if (res != null &&
          filterSessions?.contains(contact.user.accountId) != true) {
        contactShowList.add(SearchResult(data: contact, searchInfo: res));
      }
    }
    notifyListeners();
  }

  ///搜索群组
  void searchTeamByKeyword(String? keyword) {
    if (keyword?.isNotEmpty != true) {
      teamShowList = teamList
          .where((team) => filterSessions?.contains(team.teamId) != true)
          .map((team) => SearchResult<NIMTeam>(data: team))
          .toList();
      notifyListeners();
      return;
    }
    teamShowList.clear();
    for (NIMTeam team in teamList) {
      final res = TextSearcher.search(team.name, keyword!);
      if (res != null) {
        teamShowList.add(SearchResult(data: team, searchInfo: res));
      }
    }
    notifyListeners();
  }

  ///搜索会话
  void searchConversationByKeyword(String? keyword) {
    if (keyword?.isNotEmpty != true) {
      conversationShowList = conversationList
          .where((conversation) =>
              filterSessions?.contains(ChatKitUtils.getConversationTargetId(
                  conversation.conversationId)) !=
              true)
          .map((conversation) =>
              SearchResult<NIMConversation>(data: conversation))
          .toList();
      notifyListeners();
      return;
    }
    conversationShowList.clear();
    for (NIMConversation conversation in conversationList) {
      final res = TextSearcher.search(
          conversation.name ??
              ChatKitUtils.getConversationTargetId(conversation.conversationId),
          keyword!);
      if (res != null) {
        conversationShowList
            .add(SearchResult(data: conversation, searchInfo: res));
      }
    }
    notifyListeners();
  }

  ///获取联系人列表
  void getContactList(String? keyword) async {
    if (contactList.isEmpty) {
      contactList = await ContactRepo.getContactList(userCache: true);
      searchContactByKeyword(keyword);
      return;
    }
    searchContactByKeyword(keyword);
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class SearchResult<T> {
  T data;

  RecordHitInfo? searchInfo;

  SearchResult({required this.data, this.searchInfo});
}
