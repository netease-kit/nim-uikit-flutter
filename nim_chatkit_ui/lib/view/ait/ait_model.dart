// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:nim_chatkit/model/team_models.dart';
import 'package:nim_core_v2/nim_core.dart';

///包装的@信息
class AitBean {
  UserInfoWithTeam? teamMember;

  NIMAIUser? aiUser;

  /// 数字人是否同时为当前群成员。
  final bool isAIUserTeamMember;

  AitBean({
    this.teamMember,
    this.aiUser,
    this.isAIUserTeamMember = false,
  });

  ///获取用户id
  String? getAccountId() {
    return teamMember?.teamInfo.accountId ?? aiUser?.accountId;
  }

  ///获取头像
  String? getAvatar() {
    return teamMember?.getAvatar() ?? aiUser?.avatar;
  }

  ///获取昵称
  String getName() {
    if (teamMember != null) {
      return teamMember!.getName();
    }
    return aiUser?.name ?? aiUser!.accountId!;
  }

  /// Searchable member fields in product-defined priority order.
  Map<String, String?> get searchableFields {
    final member = teamMember;
    if (member == null) {
      if (!isAIUserTeamMember) {
        return const <String, String?>{};
      }
      return <String, String?>{
        'userName': aiUser?.name,
        'accountId': aiUser?.accountId,
      };
    }
    return <String, String?>{
      'friendAlias': member.alias,
      'teamNick': member.teamInfo.teamNick,
      'userName': member.userInfo?.name,
      'accountId': member.teamInfo.accountId,
    };
  }

  /// The name inserted into the message when this member is selected.
  String get displayName {
    final fields = searchableFields;
    for (final value in fields.values) {
      if (value?.isNotEmpty == true) {
        return value!;
      }
    }
    return getName();
  }

  ///获取图像显示的昵称
  String? getAvatarName() {
    if (teamMember != null) {
      return teamMember!.getName(needAlias: false, needTeamNick: false);
    }
    return aiUser?.name ?? aiUser?.accountId;
  }
}
