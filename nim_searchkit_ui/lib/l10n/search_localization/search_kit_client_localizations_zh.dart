// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'search_kit_client_localizations.dart';

/// The translations for Chinese (`zh`).
class SearchKitClientLocalizationsZh extends SearchKitClientLocalizations {
  SearchKitClientLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get searchSearch => '搜索';

  @override
  String get searchSearchHit => '请输入你要搜索的关键字';

  @override
  String get searchSearchFriend => '好友';

  @override
  String get searchSearchNormalTeam => '讨论组';

  @override
  String get searchSearchAdvanceTeam => '高级群';

  @override
  String get searchEmptyTips => '该用户不存在';

  @override
  String get searchTeamLeave => '离开群聊';

  @override
  String get searchTeamDismissOrLeave => '您已被移除群聊或群聊已解散';
}
