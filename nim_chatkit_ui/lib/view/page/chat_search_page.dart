// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/extension.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/text_search.dart';
import 'package:netease_common_ui/widgets/search_page.dart';
import 'package:netease_corekit_im/router/imkit_router_constants.dart';
import 'package:netease_corekit_im/services/message/chat_message.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit_ui/helper/chat_message_user_helper.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../chat_kit_client.dart';
import '../../l10n/S.dart';

class ChatSearchPage extends StatefulWidget {
  const ChatSearchPage(this.teamId, {Key? key}) : super(key: key);

  final String teamId;

  @override
  State<ChatSearchPage> createState() => _ChatSearchPageState();
}

class ChatSearchResult extends StatelessWidget {
  final List<ChatMessage>? searchResult;
  final String keyword;

  final String teamId;

  ChatSearchResult(
      {this.searchResult,
      required this.keyword,
      Key? key,
      required this.teamId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return searchResult == null || searchResult?.isEmpty == true
        ? Column(
            children: [
              const SizedBox(
                height: 68,
              ),
              SvgPicture.asset(
                'images/ic_list_empty.svg',
                package: kPackage,
              ),
              const SizedBox(
                height: 18,
              ),
              Text(
                S.of(context).messageSearchEmpty,
                style: TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
              )
            ],
          )
        : ListView.builder(
            itemCount: searchResult!.length,
            itemBuilder: (context, index) {
              ChatMessage item = searchResult![index];
              return InkWell(
                onTap: () async {
                  var conversationId = (await NimCore
                          .instance.conversationIdUtil
                          .teamConversationId(teamId))
                      .data!;
                  Navigator.pushNamedAndRemoveUntil(context,
                      RouterConstants.PATH_CHAT_PAGE, ModalRoute.withName('/'),
                      arguments: {
                        'conversationId': conversationId,
                        'conversationType': NIMConversationType.team,
                        'anchor': item.nimMessage
                      });
                },
                child: SearchItem(item, keyword),
              );
            });
  }
}

class _ChatSearchPageState extends State<ChatSearchPage> {
  TextEditingController inputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SearchPage(
      title: S.of(context).messageSearchTitle,
      searchHint: S.of(context).messageSearchHint,
      buildOnComplete: true,
      builder: (context, keyword) {
        if (keyword.isEmpty) {
          return Container();
        } else {
          return FutureBuilder<List<ChatMessage>?>(
              future: ChatMessageRepo.searchMessage(
                  keyword, widget.teamId, NIMConversationType.team),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return ChatSearchResult(
                    keyword: keyword,
                    teamId: widget.teamId,
                    searchResult: snapshot.data,
                  );
                }
                return Center(
                  child: CircularProgressIndicator(),
                );
              });
        }
      },
    );
  }
}

class SearchItem extends StatelessWidget {
  const SearchItem(this.message, this.keyword, {Key? key}) : super(key: key);

  final ChatMessage message;

  final String keyword;

  Future<String> _getUserName() async {
    if (message.nimMessage.conversationType == NIMConversationType.p2p) {
      return message.getNickName();
    } else {
      var teamId = (await NimCore.instance.conversationIdUtil
              .conversationTargetId(message.nimMessage.conversationId!))
          .data!;
      return getUserNickInTeam(teamId, message.nimMessage.senderId!);
    }
  }

  Widget _hitWidget(String content) {
    TextStyle normalStyle = TextStyle(fontSize: 16, color: '#333333'.toColor());
    TextStyle highStyle = TextStyle(fontSize: 16, color: '#337EFF'.toColor());
    return TextSearcher.hitWidget(content, keyword, normalStyle, highStyle);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Avatar(
              avatar: message.fromUser?.avatar,
              name: message.getNickName(),
              height: 42,
              width: 42,
            ),
          ),
          Positioned(
            left: 74,
            top: 10,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 90),
                  child: FutureBuilder<String>(
                      future: _getUserName(),
                      builder: (context, snap) {
                        return Text(
                          snap.data ?? '',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                              fontSize: 16, color: CommonColors.color_333333),
                        );
                      }),
                ),
                const SizedBox(
                  height: 6,
                ),
                _hitWidget(message.nimMessage.text ?? ''),
              ],
            ),
          ),
          Positioned(
              right: 0,
              top: 17,
              child: Text(
                message.nimMessage.createTime!.formatDateTime(),
                style: const TextStyle(
                    fontSize: 12, color: CommonColors.color_cccccc),
              )),
        ],
      ),
    );
  }
}
