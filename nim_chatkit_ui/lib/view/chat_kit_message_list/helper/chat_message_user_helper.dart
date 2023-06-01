// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/contact/contact_provider.dart';
import 'package:nim_core/nim_core.dart';

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
    return getIt<ContactProvider>().getContact(this).then((value) {
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
  var contactInfo = await getIt<ContactProvider>().getContact(accId);
  if (showAlias && contactInfo?.friend?.alias?.isNotEmpty == true) {
    return contactInfo!.friend!.alias!;
  } else {
    var teamMember =
        await NimCore.instance.teamService.queryTeamMember(tId, accId);
    if (teamMember.data?.teamNick?.isNotEmpty == true) {
      return teamMember.data!.teamNick!;
    } else {
      return contactInfo?.user.nick?.isNotEmpty == true
          ? contactInfo!.user.nick!
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
