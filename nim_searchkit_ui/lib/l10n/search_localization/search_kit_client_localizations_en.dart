// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'search_kit_client_localizations.dart';

/// The translations for English (`en`).
class SearchKitClientLocalizationsEn extends SearchKitClientLocalizations {
  SearchKitClientLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get searchSearch => 'Search';

  @override
  String get searchSearchHit => 'Please input your key word';

  @override
  String get searchSearchFriend => 'Friend';

  @override
  String get searchSearchNormalTeam => 'Normal team';

  @override
  String get searchSearchAdvanceTeam => 'Advance Team';

  @override
  String get searchEmptyTips => 'This user not exist';
}
