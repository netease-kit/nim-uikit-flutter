// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/contact/contact_provider.dart';
import 'package:netease_corekit_im/services/message/nim_chat_cache.dart';
import 'package:nim_core_v2/nim_core.dart';

extension MessageUserHelper on String {
  Future<String> getUserName({bool needAlias = true}) async {
    return getIt<ContactProvider>().getContact(this).then((value) {
      if (value != null) {
        return value.getName(needAlias: needAlias);
      } else {
        return this;
      }
    });
  }

  Future<String?> getAvatar() async {
    return getIt<ContactProvider>()
        .getContact(this, needFriend: false)
        .then((value) {
      if (value != null) {
        return value.user.avatar;
      } else {
        return null;
      }
    });
  }

  Future<UserAvatarInfo> getUserInfo() async {
    String name = await getUserName();
    String? avatar = await getAvatar();
    return UserAvatarInfo(name, avatar: avatar);
  }

  UserAvatarInfo getCacheAvatar(String nick) {
    var contact = getIt<ContactProvider>().getContactInCache(this);
    if (contact != null) {
      return UserAvatarInfo(contact.getName(),
          avatar: contact.user.avatar,
          avatarName: contact.getName(needAlias: false));
    }
    return UserAvatarInfo(nick, avatarName: nick);
  }
}

Future<String> getUserNickInTeam(String tId, String accId,
    {bool showAlias = true}) async {
  var teamUserInfo = NIMChatCache.instance.getTeamMember(accId, tId);
  if (teamUserInfo != null) {
    return teamUserInfo.getName(needAlias: showAlias);
  } else {
    var teamMember = await NimCore.instance.teamService
        .getTeamMemberListByIds(tId, NIMTeamType.typeNormal, [accId]);
    var userInfo = await getIt<ContactProvider>().getContact(accId);
    if (showAlias && userInfo?.friend?.alias?.isNotEmpty == true) {
      return userInfo!.friend!.alias!;
    } else if (teamMember.data?.isNotEmpty == true &&
        teamMember.data?[0].teamNick?.isNotEmpty == true) {
      return teamMember.data![0].teamNick!;
    } else {
      return userInfo?.user.name?.isNotEmpty == true
          ? userInfo!.user.name!
          : accId;
    }
  }
}

class UserAvatarInfo {
  String name;

  String? avatar;

  String? avatarName;

  UserAvatarInfo(this.name, {this.avatar, this.avatarName});
}
