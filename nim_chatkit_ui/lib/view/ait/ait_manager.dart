// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_corekit_im/im_kit_client.dart';
import 'package:netease_corekit_im/model/ait/ait_contacts_model.dart';
import 'package:netease_corekit_im/model/ait/ait_msg.dart';
import 'package:netease_corekit_im/model/team_models.dart';
import 'package:netease_corekit_im/services/message/nim_chat_cache.dart';

import '../../chat_kit_client.dart';
import '../../l10n/S.dart';

///@消息管理类
class AitManager {
  final AitContactsModel _aitContactsModel = AitContactsModel();

  get aitContactsModel => _aitContactsModel;

  final String teamId;

  StreamSubscription? _teamSub;

  ValueNotifier<List<UserInfoWithTeam>?> _teamMemberList = ValueNotifier(null);

  AitManager(this.teamId) {
    _teamMemberList.value = List.from(NIMChatCache.instance.teamMembers);
    _teamSub = NIMChatCache.instance.teamMembersNotifier.listen((event) {
      if (_teamMemberList.value?.isNotEmpty != true) {
        _teamMemberList.value = event;
      }
    });
  }

  ///通过@文本添加@用户
  void addAitWithText(String account, String name, int startIndex) {
    _aitContactsModel.addAitMember(account, name, startIndex);
  }

  ///清理@用户，在发送之后调用
  void cleanAit() {
    _aitContactsModel.reset();
  }

  ///复制@用户信息，用户撤回消息使用
  void forkAit(AitContactsModel aitContactsModel) {
    _aitContactsModel.fork(aitContactsModel);
  }

  ///@用户 是否在文本最后，如果在文本最后，需要在文本后面添加空格
  bool aitEnd(String text) {
    int len = text.length;
    for (var element in _aitContactsModel.aitBlocks.values) {
      for (AitSegment segment in element.segments) {
        if (segment.start < len && segment.endIndex >= len) {
          return true;
        }
      }
    }
    return false;
  }

  ///根据插入后的Text 文案, segment 移位或者删除。
  ///返回被删除的AitMsg信息
  ///[deletedText] 删除后的字符串
  ///[endIndex] 删除的结束位置
  ///[length] 删除的长度
  AitMsg? deleteAitWithText(String deletedText, int endIndex, int length) {
    return _aitContactsModel.deleteAitUser(deletedText, endIndex, length);
  }

  ///新增Text输入，但输入的不是@
  ///会进行移位或者删除，如果在@XXX 中插入文本 @XXX 会被删除
  ///[changeText] 输入后的文案
  ///[endIndex] 输入的结束位置
  ///[length] 输入的长度
  void addTextWithoutAit(String changeText, int endIndex, int length) {
    _aitContactsModel.insertText(changeText, endIndex, length);
  }

  ///后去需要推送的用户列表
  List<String> getPushList() {
    List<String> pushList = [];
    _aitContactsModel.aitBlocks.forEach((key, value) {
      if (key == AitContactsModel.accountAll) {
        pushList.clear();
        List<UserInfoWithTeam> _teamMembers = NIMChatCache.instance.teamMembers;
        pushList.addAll(_teamMembers.map((e) => e.teamInfo.account ?? ''));
        return pushList;
      } else {
        pushList.add(key);
      }
    });
    return pushList;
  }

  ///是否已经在@列表中
  bool haveBeAit(String account) {
    return _aitContactsModel.aitBlocks.containsKey(account);
  }

  ///是否有@成员
  bool haveAitMember() {
    return _aitContactsModel.aitBlocks.isNotEmpty;
  }

  ///光标移动到@后自动到后面
  int resetAitCursor(int baseIndex) {
    for (AitMsg element in _aitContactsModel.aitBlocks.values) {
      for (AitSegment segment in element.segments) {
        if (segment.start < baseIndex && segment.endIndex + 1 > baseIndex) {
          return segment.endIndex + 1;
        }
      }
    }
    return baseIndex;
  }

  void dispose() {
    _teamSub?.cancel();
  }

  ///选择@的成员
  Future<dynamic> selectMember(BuildContext context) async {
    return showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8), topRight: Radius.circular(8))),
        builder: (context) {
          return ValueListenableBuilder(
            valueListenable: _teamMemberList,
            builder: (BuildContext context, List<UserInfoWithTeam>? value,
                Widget? child) {
              var _teamMembers = value
                  ?.where((element) =>
                      element.userInfo?.userId != IMKitClient.account())
                  .toList();
              return Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: CommonColors.color_999999,
                            )),
                        Align(
                            alignment: Alignment.center,
                            child:
                                Text(S.of(context).chatMessageAitContactTitle))
                      ],
                    ),
                  ),
                  if (NIMChatCache.instance.haveAitAllPrivilege())
                    ListTile(
                      leading: SvgPicture.asset(
                        'images/ic_team_all.svg',
                        package: kPackage,
                        height: 42,
                        width: 42,
                      ),
                      title: Text(S.of(context).chatTeamAitAll),
                      onTap: () {
                        Navigator.pop(context, AitContactsModel.accountAll);
                      },
                    ),
                  if (_teamMembers?.isNotEmpty == true)
                    Expanded(
                        child: ListView.builder(
                            itemCount: _teamMembers!.length,
                            itemBuilder: (context, index) {
                              var user = _teamMembers[index];
                              return ListTile(
                                leading: Avatar(
                                  avatar: user.getAvatar(),
                                  name: user.getName(
                                      needAlias: false, needTeamNick: false),
                                  height: 42,
                                  width: 42,
                                ),
                                title: Text(
                                  user.getName(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  Navigator.pop(context, user);
                                },
                              );
                            }))
                ],
              );
            },
          );
        });
  }
}
