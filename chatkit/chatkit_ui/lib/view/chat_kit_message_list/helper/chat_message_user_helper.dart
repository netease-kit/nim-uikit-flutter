// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:corekit_im/service_locator.dart';
import 'package:corekit_im/services/contact/contact_provider.dart';
import 'package:nim_core/nim_core.dart';

extension MessageUserHelper on String {
  Future<String> getUserName() async {
    return getIt<ContactProvider>().getContact(this).then((value) {
      if (value != null) {
        return value.getName();
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
}

Future<String> getUserNickInTeam(String tId, String accId) async {
  var friend = await NimCore.instance.userService.getFriend(accId);
  if (friend.data?.alias?.isNotEmpty == true) {
    return friend.data!.alias!;
  } else {
    var teamMember =
        await NimCore.instance.teamService.queryTeamMember(tId, accId);
    if (teamMember.data?.teamNick?.isNotEmpty == true) {
      return teamMember.data!.teamNick!;
    } else {
      var userInfo = await NimCore.instance.userService.getUserInfo(accId);
      return userInfo.data?.nick ?? accId;
    }
  }
}

class UserAvatarInfo {
  String name;

  String? avatar;

  UserAvatarInfo(this.name, {this.avatar});
}
