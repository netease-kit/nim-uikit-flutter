// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/repo/team_repo.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/contact/contact_provider.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../chat_kit_client.dart';
import '../../helper/chat_message_helper.dart';
import '../../helper/chat_message_user_helper.dart';
import '../../l10n/S.dart';
import 'chat_date_picker_widget.dart';
import 'chat_history_file_message_page.dart';
import 'chat_history_image_message_page.dart';
import 'chat_history_member_message_page.dart';
import 'chat_history_video_message_page.dart';

/// 历史消息页面
class ChatHistoryMessagePage extends StatefulWidget {
  final String conversationId;
  final NIMConversationType conversationType;

  const ChatHistoryMessagePage({
    Key? key,
    required this.conversationId,
    required this.conversationType,
  }) : super(key: key);

  @override
  State<ChatHistoryMessagePage> createState() => _ChatHistoryMessagePageState();
}

class _ChatHistoryMessagePageState extends BaseState<ChatHistoryMessagePage> {
  final TextEditingController _searchController = TextEditingController();

  ContactInfo? contactInfo;

  List<NIMMessage>? _keywordSearchMessages;

  var _pageToken = '';
  var _hasMore = false;
  var _isLoading = true;

  initState() {
    super.initState();
    if (widget.conversationType == NIMConversationType.p2p) {
      getIt<ContactProvider>()
          .getContact(
              ChatKitUtils.getConversationTargetId(widget.conversationId))
          .then((value) {
        contactInfo = value;
        setState(() {});
      });
    }
    _searchController.addListener(() {
      if (_searchController.text.isEmpty) {
        setState(() {
          _keywordSearchMessages = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
      title: S.of(context).chatMessageSearchHistory,
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildSearchBar(),
            if (_searchController.text.isNotEmpty)
              Expanded(
                child: ChatSearchResult(
                  keyword: _searchController.text,
                  conversationId: widget.conversationId,
                  conversationType: widget.conversationType,
                  contactInfo: contactInfo,
                  searchResult: _keywordSearchMessages,
                  onLoadMore: _loadMoreKeywordMessages,
                  isLoading: _isLoading,
                  hasMore: _hasMore,
                ),
              )
            else ...[
              const SizedBox(height: 45),
              Text(
                S.of(context).chatMessageQuickSearch,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFB3B7BC),
                ),
              ),
              const SizedBox(height: 20),
              _buildQuickSearchGrid(),
            ]
          ],
        ),
      ),
    );
  }

  void searchMessageByKeyword(String keyword) async {
    _pageToken = '';
    _hasMore = false;
    _isLoading = true;
    setState(() {});

    NIMMessageSearchExParams params = NIMMessageSearchExParams(
      conversationId: widget.conversationId,
      keywordList: [keyword],
      pageToken: _pageToken,
    );
    if ((await IMKitClient.enableCloudMessageSearch) && !checkNetwork()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final result = await ChatMessageRepo.searchMessageEx(params);
    _isLoading = false;
    if (result.isSuccess && result.data != null) {
      if (result.data!.items?.isNotEmpty == true) {
        _keywordSearchMessages = result.data!.items!.first.messages;
      } else {
        _keywordSearchMessages = [];
      }
      _hasMore = result.data!.hasMore;
      _pageToken = result.data!.nextPageToken ?? '';
    } else {
      _keywordSearchMessages = [];
      _hasMore = false;
    }
    setState(() {});
  }

  void _loadMoreKeywordMessages() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    setState(() {});

    NIMMessageSearchExParams params = NIMMessageSearchExParams(
      conversationId: widget.conversationId,
      keywordList: [_searchController.text],
      pageToken: _pageToken,
    );
    if ((await IMKitClient.enableCloudMessageSearch) && !checkNetwork()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final result = await ChatMessageRepo.searchMessageEx(params);
    _isLoading = false;
    if (result.isSuccess && result.data != null) {
      if (result.data!.items?.isNotEmpty == true) {
        var newMessages = result.data!.items!.first.messages;
        if (newMessages != null) {
          _keywordSearchMessages?.addAll(newMessages);
        }
      }
      _hasMore = result.data!.hasMore;
      _pageToken = result.data!.nextPageToken ?? '';
    } else {
      _hasMore = false;
    }
    setState(() {});
  }

  Widget _buildSearchBar() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: Color(0xFFA6ADB6),
            size: 16,
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 36),
          hintText: S.of(context).messageSearchHint,
          hintStyle: TextStyle(
            fontSize: 14,
            color: Color(0xFFA6ADB6),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 0),
          isDense: true,
          suffixIcon: IconButton(
            icon: SvgPicture.asset(
              'images/ic_clear.svg',
              package: kPackage,
            ),
            onPressed: () {
              _searchController.clear();
            },
          ),
        ),
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF333333),
        ),
        textAlignVertical: TextAlignVertical.center,
        onSubmitted: (value) {
          searchMessageByKeyword(value);
        },
      ),
    );
  }

  Widget _buildQuickSearchGrid() {
    final List<Map<String, dynamic>> items = [
      if (widget.conversationType == NIMConversationType.team)
        {
          'label': S.of(context).chatQuickSearchTeamMember,
          'icon': 'images/ic_search_team_member.svg',
          'onTap': () {
            final teamId =
                ChatKitUtils.getConversationTargetId(widget.conversationId);
            goToTeamMemberList(context, teamId,
                    maxSelectMemberCount: 1,
                    isMultiSelectModel: true,
                    showRole: false,
                    showRemoveButton: false)
                .then((selectedUser) async {
              if (selectedUser is List<String>) {
                final teamInfo =
                    await TeamRepo.getTeamInfo(teamId, NIMTeamType.typeNormal);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ChatHistoryMemberMessagePage(
                              conversationId: widget.conversationId,
                              sendId: selectedUser.first,
                              teamInfo: teamInfo,
                              conversationType: widget.conversationType,
                            )));
              }
            });
          },
        },
      {
        'label': S.of(context).chatQuickSearchPicture,
        'icon': 'images/ic_search_image.svg',
        'onTap': () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ChatHistoryImageMessagePage(
                        conversationId: widget.conversationId,
                        conversationType: widget.conversationType,
                      )));
        },
      },
      {
        'label': S.of(context).chatQuickSearchVideo,
        'icon': 'images/ic_search_video.svg',
        'onTap': () {
          // jump to video search page
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ChatHistoryVideoMessagePage(
                        conversationId: widget.conversationId,
                        conversationType: widget.conversationType,
                      )));
        },
      },
      {
        'label': S.of(context).chatQuickSearchDate,
        'icon': 'images/ic_search_date.svg',
        'onTap': () {
          Navigator.push(context,
                  MaterialPageRoute(builder: (context) => DatePickerPage()))
              .then((select) {
            if (select is int) {
              goToChatAndKeepHome(
                  context, widget.conversationId, widget.conversationType,
                  anchorDate: select);
            }
          });
        },
      },
      {
        'label': S.of(context).chatQuickSearchFile,
        'icon': 'images/ic_search_file.svg',
        'onTap': () {
          // jump to file search page
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ChatHistoryFileMessagePage(
                        conversationId: widget.conversationId,
                        conversationType: widget.conversationType,
                      )));
        },
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: item['onTap'],
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF9F9F9), // Light gray background for icon
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  item["icon"]!,
                  package: kPackage,
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['label'],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChatSearchResult extends StatefulWidget {
  final List<NIMMessage>? searchResult;
  final String keyword;

  final String? teamId;

  final String conversationId;

  final NIMConversationType conversationType;

  final ContactInfo? contactInfo;

  final VoidCallback? onLoadMore;
  final bool isLoading;
  final bool hasMore;

  ChatSearchResult(
      {this.searchResult,
      required this.keyword,
      required this.conversationId,
      Key? key,
      this.teamId,
      this.contactInfo,
      required this.conversationType,
      this.onLoadMore,
      this.isLoading = false,
      this.hasMore = true})
      : super(key: key);

  @override
  State<ChatSearchResult> createState() => _ChatSearchResultState();
}

class _ChatSearchResultState extends State<ChatSearchResult> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      widget.onLoadMore?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.searchResult == null || widget.searchResult?.isEmpty == true
        ? (widget.isLoading
            ? Container()
            : Column(
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
              ))
        : ListView.builder(
            controller: _scrollController,
            itemCount: widget.searchResult!.length + 1,
            itemBuilder: (context, index) {
              if (index == widget.searchResult!.length) {
                return _buildFooter();
              }
              NIMMessage item = widget.searchResult![index];
              return InkWell(
                onTap: () async {
                  goToChatAndKeepHome(
                      context, widget.conversationId, widget.conversationType,
                      message: item);
                },
                child: HistoryMessageItem(item, widget.keyword,
                    contactInfo: widget.contactInfo),
              );
            },
          );
  }

  Widget _buildFooter() {
    if (widget.isLoading) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (!widget.hasMore && widget.searchResult?.isNotEmpty == true) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: Text(
          S.of(context).chatHistoryMessageNotAnyMore,
          style: TextStyle(fontSize: 12, color: CommonColors.color_999999),
        ),
      );
    }
    return Container();
  }
}

class HistoryMessageItem extends StatelessWidget {
  const HistoryMessageItem(this.message, this.keyword,
      {Key? key, this.contactInfo})
      : super(key: key);

  final NIMMessage message;

  final String keyword;

  final ContactInfo? contactInfo;

  Future<UserAvatarInfo> _getUserAvatarInfo() async {
    if (message.aiConfig?.aiStatus == NIMMessageAIStatus.response &&
        AIUserManager.instance.isAIUser(message.aiConfig?.accountId)) {
      final aiUser =
          AIUserManager.instance.getAIUserById(message.aiConfig!.accountId!);
      return UserAvatarInfo(aiUser!.name ?? aiUser.accountId!,
          avatarName: aiUser.name, avatar: aiUser.avatar);
    }
    if (message.conversationType == NIMConversationType.p2p) {
      if (message.isSelf != true && contactInfo != null) {
        return UserAvatarInfo(contactInfo!.getName(),
            avatarName: contactInfo!.getName(needAlias: false),
            avatar: contactInfo?.user.avatar);
      }
      final selfInfo = IMKitClient.getUserInfo();
      if (message.isSelf == true && selfInfo != null) {
        return UserAvatarInfo(selfInfo.name ?? message.senderId!,
            avatar: selfInfo.avatar,
            avatarName: selfInfo.name ?? message.senderId!);
      }
      return UserAvatarInfo(message.senderId!, avatarName: message.senderId!);
    } else {
      var teamId =
          ChatKitUtils.getConversationTargetId(message.conversationId!);
      return await getUserAvatarInfoInTeam(teamId, message.senderId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.centerLeft,
      child: FutureBuilder<UserAvatarInfo>(
          future: _getUserAvatarInfo(),
          builder: (context, snapshot) {
            final userInfo = snapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    getFormatTime(message.createTime!.toInt(), context),
                    style: TextStyle(
                      fontSize: 12,
                      color: '#B3B7BC'.toColor(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Avatar(
                      avatar: userInfo?.avatar,
                      name: userInfo?.avatarName,
                      height: 32,
                      width: 32,
                      radius: 16,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userInfo?.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: CommonColors.color_333333,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          buildHistoryMessage(context, message,
                              keyword: keyword)
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
    );
  }
}
