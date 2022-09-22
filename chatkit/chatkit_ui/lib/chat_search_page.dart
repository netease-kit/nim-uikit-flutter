// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:chatkit/repo/chat_message_repo.dart';
import 'package:im_common_ui/extension.dart';
import 'package:im_common_ui/router/imkit_router_constants.dart';
import 'package:im_common_ui/ui/avatar.dart';
import 'package:im_common_ui/utils/color_utils.dart';
import 'package:im_common_ui/widgets/search_page.dart';
import 'package:corekit_im/services/message/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_core/nim_core.dart';

import 'generated/l10n.dart';

class ChatSearchPage extends StatefulWidget {
  const ChatSearchPage(this.teamId, {Key? key}) : super(key: key);

  final String teamId;

  @override
  State<ChatSearchPage> createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends State<ChatSearchPage> {
  TextEditingController inputController = TextEditingController();

  Widget _searchResultWidget(List<ChatMessage>? searchResult) {
    return searchResult == null || searchResult.isEmpty
        ? Column(
            children: [
              const SizedBox(
                height: 68,
              ),
              SvgPicture.asset(
                'images/ic_list_empty.svg',
                package: 'chatkit_ui',
              ),
              const SizedBox(
                height: 18,
              ),
              Text(
                S.of(context).message_search_empty,
                style: TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
              )
            ],
          )
        : ListView.builder(
            itemCount: searchResult.length,
            itemBuilder: (context, index) {
              ChatMessage item = searchResult[index];
              return InkWell(
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(context,
                      RouterConstants.PATH_CHAT_PAGE, ModalRoute.withName('/'),
                      arguments: {
                        'sessionId': widget.teamId,
                        'sessionType': NIMSessionType.team,
                        'anchor': item.nimMessage
                      });
                },
                child: SearchItem(item),
              );
            });
  }

  @override
  Widget build(BuildContext context) {
    return SearchPage(
      title: S.of(context).message_search_title,
      searchHint: S.of(context).message_search_hint,
      builder: (context, keyword) {
        if (keyword.isEmpty) {
          return Container();
        } else {
          return FutureBuilder<List<ChatMessage>?>(
              future: ChatMessageRepo.searchMessage(
                  keyword, widget.teamId, NIMSessionType.team),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return _searchResultWidget(snapshot.data);
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
  const SearchItem(this.message, {Key? key}) : super(key: key);

  final ChatMessage message;

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
                  child: Text(
                    message.getNickName(),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 16, color: CommonColors.color_333333),
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                Text(
                  message.nimMessage.content ?? '',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                      fontSize: 13, color: CommonColors.color_999999),
                ),
              ],
            ),
          ),
          Positioned(
              right: 0,
              top: 17,
              child: Text(
                message.nimMessage.timestamp.formatDateTime(),
                style: const TextStyle(
                    fontSize: 12, color: CommonColors.color_cccccc),
              )),
        ],
      ),
    );
  }
}
