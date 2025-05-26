// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:nim_chatkit/model/team_models.dart';
import 'package:nim_core_v2/nim_core.dart';

///包装的@信息
class AitBean {
  UserInfoWithTeam? teamMember;

  NIMAIUser? aiUser;

  AitBean({this.teamMember, this.aiUser});

  ///获取用户id
  String? getAccountId() {
    return teamMember?.userInfo?.accountId ?? aiUser?.accountId;
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

  ///获取图像显示的昵称
  String? getAvatarName() {
    if (teamMember != null) {
      return teamMember!.getName(needAlias: false, needTeamNick: false);
    }
    return aiUser?.name ?? aiUser?.accountId;
  }
}
