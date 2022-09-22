// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:im_common_ui/router/imkit_router_factory.dart';
import 'package:im_common_ui/ui/avatar.dart';
import 'package:im_common_ui/utils/color_utils.dart';
import 'package:im_common_ui/widgets/search_page.dart';
import 'package:corekit_im/model/contact_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_core/nim_core.dart';
import 'package:searchkit/model/friend_search_info.dart';
import 'package:searchkit/model/hit_type.dart';
import 'package:searchkit/model/search_info.dart';
import 'package:searchkit/model/team_search_info.dart';
import 'package:searchkit/repo/search_repo.dart';
import 'package:searchkit/repo/text_search.dart';

import '../generated/l10n.dart';

class SearchKitGlobalSearchPage extends StatefulWidget {
  const SearchKitGlobalSearchPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SearchKitGlobalState();
}

class _SearchKitGlobalState extends State<SearchKitGlobalSearchPage> {
  Future<List<SearchInfo>> _search(String text) async {
    return [
      ...(await SearchRepo.instance.searchFriend(text)),
      ...(await SearchRepo.instance.searchTeam(text))
    ];
  }

  Widget _buildItem(
      BuildContext context, SearchInfo currentItem, SearchInfo? lastItem) {
    RecordHitInfo record = currentItem.hitInfo!;
    TextStyle normalStyle = TextStyle(fontSize: 16, color: '#333333'.toColor());
    TextStyle highStyle = TextStyle(fontSize: 16, color: '#337EFF'.toColor());

    String _getTitle() {
      switch (currentItem.getType()) {
        case SearchType.contact:
          return S.of(context).search_search_friend;
        case SearchType.normalTeam:
          return S.of(context).search_search_normal_team;
        case SearchType.advancedTeam:
          return S.of(context).search_search_advance_team;
      }
    }

    Widget _getContactWidget() {
      ContactInfo contact = (currentItem as FriendSearchInfo).contact;

      String? _getHitName() {
        switch (currentItem.hitType) {
          case HitType.alias:
            return contact.friend?.alias;
          case HitType.userName:
            return contact.user.nick;
          case HitType.account:
            return contact.user.userId;
          default:
            return contact.getName();
        }
      }

      String _hitName = _getHitName()!;
      Widget _hitWidget(TextStyle textStyle, TextStyle hitStyle) {
        return RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(children: [
            if (record.start > 0)
              TextSpan(
                text: _hitName.substring(0, record.start),
                style: textStyle,
              ),
            TextSpan(
                text: _hitName.substring(record.start, record.end),
                style: hitStyle),
            if (record.end <= _hitName.length - 1)
              TextSpan(text: _hitName.substring(record.end), style: textStyle)
          ]),
        );
      }

      return InkWell(
        onTap: () {
          goToP2pChat(context, contact.user.userId!);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Avatar(
              avatar: contact.user.avatar,
              name: contact.getName(),
              width: 36,
              height: 36,
              bgCode: AvatarColor.avatarColor(content: contact.user.userId),
            ),
            Expanded(
              child: Container(
                  margin: const EdgeInsets.only(left: 12),
                  child: currentItem.hitType == HitType.account
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact.getName(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: normalStyle,
                            ),
                            SizedBox(
                              height: 4,
                            ),
                            _hitWidget(
                                TextStyle(
                                    fontSize: 12, color: '#333333'.toColor()),
                                TextStyle(
                                    fontSize: 12, color: '#337EFF'.toColor())),
                          ],
                        )
                      : _hitWidget(normalStyle, highStyle)),
            ),
          ],
        ),
      );
    }

    Widget _getTeamWidget() {
      NIMTeam team = (currentItem as TeamSearchInfo).team;
      return InkWell(
        onTap: () {
          goToTeamChat(context, team.id!);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Avatar(
              avatar: team.icon,
              name: team.name,
              width: 32,
              height: 32,
              bgCode: AvatarColor.avatarColor(content: team.id),
            ),
            Expanded(
              child: Container(
                  margin: const EdgeInsets.only(left: 12),
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(children: [
                      if (record.start > 0)
                        TextSpan(
                          text: team.name!.substring(0, record.start),
                          style: normalStyle,
                        ),
                      TextSpan(
                          text: team.name!.substring(record.start, record.end),
                          style: highStyle),
                      if (record.end <= team.name!.length - 1)
                        TextSpan(
                            text: team.name!.substring(record.end),
                            style: normalStyle)
                    ]),
                  )),
            )
          ],
        ),
      );
    }

    TextStyle titleStyle = TextStyle(fontSize: 14, color: '#B3B7BC'.toColor());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lastItem == null ||
              lastItem.getType() != currentItem.getType()) ...[
            Text(
              _getTitle(),
              style: titleStyle,
            ),
            Container(
              height: 1,
              color: '#DBE0E8'.toColor(),
              margin: const EdgeInsets.only(bottom: 8, top: 8),
            )
          ],
          if (currentItem.getType() == SearchType.contact) _getContactWidget(),
          if (currentItem.getType() == SearchType.normalTeam ||
              currentItem.getType() == SearchType.advancedTeam)
            _getTeamWidget(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SearchPage(
      key: widget.key,
      title: S.of(context).search_search,
      searchHint: S.of(context).search_search_hit,
      builder: (context, keyword) {
        if (keyword.isEmpty) {
          return Container();
        } else {
          return FutureBuilder<List<SearchInfo>>(
              future: _search(keyword),
              builder: (context, snapShot) {
                List<SearchInfo> searchList = snapShot.data ?? List.empty();
                if (searchList.isEmpty) {
                  return Column(
                    children: [
                      const SizedBox(
                        height: 68,
                      ),
                      SvgPicture.asset(
                        'images/ic_search_empty.svg',
                        package: 'searchkit_ui',
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      Text(
                        S.of(context).search_empty_tips,
                        style:
                            TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
                      )
                    ],
                  );
                } else {
                  return ListView.builder(
                      itemCount: searchList.length,
                      itemBuilder: (context, index) {
                        SearchInfo currentItem = searchList[index];
                        var lastItem = index > 0 ? searchList[index - 1] : null;
                        return _buildItem(context, currentItem, lastItem);
                      });
                }
              });
        }
      },
    );
  }
}
