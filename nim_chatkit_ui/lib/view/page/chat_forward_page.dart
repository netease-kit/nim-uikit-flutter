// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/text_search.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/model/recent_forward.dart';
import 'package:nim_chatkit_ui/view_model/chat_forward_view_model.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:netease_common_ui/utils/color_utils.dart';

import '../../chat_kit_client.dart';
import '../../helper/contact_sort_helper.dart';
import '../../l10n/S.dart';
import '../../model/forward/forward_selected_beam.dart';

class ChatForwardPage extends StatefulWidget {
  final int maxSelectedCount;

  final List<String>? filterSession;

  const ChatForwardPage(
      {Key? key, this.filterSession, this.maxSelectedCount = 9})
      : super(key: key);

  @override
  State<ChatForwardPage> createState() => _ChatForwardPageState();
}

class _ChatForwardPageState extends State<ChatForwardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _tabListenerAttached = false; //避免重复绑定

  int currentTabIndex = 0;

  final PageStorageBucket _bucket = PageStorageBucket();

  late final TextEditingController _textController;

  late final ChatForwardViewModel _model =
      ChatForwardViewModel(widget.filterSession);

  // 添加状态变量
  String? searchKeyword;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _textController = TextEditingController();
    _textController.addListener(() {
      if (currentTabIndex == 0) {
        _model.searchConversationByKeyword(_textController.text);
      } else if (currentTabIndex == 1) {
        _model.searchContactByKeyword(_textController.text);
      } else if (currentTabIndex == 2) {
        _model.searchTeamByKeyword(_textController.text);
      }
      setState(() {
        searchKeyword = _textController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatForwardViewModel>.value(
      value: _model,
      builder: (context, child) {
        if (!_tabListenerAttached) {
          _tabController.addListener(() {
            currentTabIndex = _tabController.index;
            if (_tabController.index == 0) {
              context
                  .read<ChatForwardViewModel>()
                  .searchConversationByKeyword(_textController.text);
            } else if (_tabController.index == 1 &&
                !_tabController.indexIsChanging) {
              context
                  .read<ChatForwardViewModel>()
                  .getContactList(_textController.text);
            } else if (_tabController.index == 2) {
              context
                  .read<ChatForwardViewModel>()
                  .searchTeamByKeyword(_textController.text);
            }
          });
          _tabListenerAttached = true;
        }

        var isMultiSelect = context.watch<ChatForwardViewModel>().isMultiSelect;
        var selectedList = context.watch<ChatForwardViewModel>().selectedList;
        var selectedCount =
            selectedList.isEmpty ? '' : '(${selectedList.length})';

        return TransparentScaffold(
            title: S.of(context).forwardSelect,
            appbarLeadingIcon: Text(S.of(context).messageCancel,
                style: TextStyle(color: Colors.black, fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () {
                  if (isMultiSelect && _model.selectedList.isNotEmpty) {
                    Navigator.pop(context, _model.selectedList);
                  } else if (!isMultiSelect) {
                    context.read<ChatForwardViewModel>().setMultiSelect(true);
                  }
                },
                child: Text(
                    isMultiSelect
                        ? '${S.of(context).messageSure}$selectedCount'
                        : S.of(context).multiSelect,
                    style: TextStyle(
                        color: (isMultiSelect && _model.selectedList.isEmpty)
                            ? CommonColors.color_999999
                            : CommonColors.color_333333,
                        fontSize: 16)),
              ),
            ],
            backgroundColor: Colors.white,
            body: PageStorage(
              bucket: _bucket,
              child: Consumer<ChatForwardViewModel>(
                  builder: (context, model, child) {
                bool isMultiple = model.isMultiSelect;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 顶部搜索栏（固定）
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: S.of(context).forwardSearch,
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey.shade500),
                          suffixIcon: searchKeyword?.isNotEmpty == true
                              ? IconButton(
                                  icon: SvgPicture.asset(
                                    'images/ic_clear.svg',
                                    package: kPackage,
                                    height: 16,
                                    width: 16,
                                  ),
                                  onPressed: () {
                                    _textController.clear();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    // 已选列表（固定）
                    if (model.selectedList.isNotEmpty)
                      _buildSelectedList(model, model.selectedList),
                    // 最近转发（固定）
                    if (searchKeyword?.isNotEmpty != true &&
                        model.recentForwards.isNotEmpty)
                      _buildRecentForwards(
                          model, model.recentForwards, isMultiple),
                    // TabBar（固定）
                    Material(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.blue,
                        unselectedLabelColor: Colors.black87,
                        indicatorColor: Colors.blue,
                        indicatorSize: TabBarIndicatorSize.label,
                        tabs: [
                          Tab(text: S.of(context).forwardRecentConversation),
                          Tab(text: S.of(context).forwardMyFriends),
                          Tab(text: S.of(context).forwardTeam),
                        ],
                      ),
                    ),
                    // 仅此区域可滚动
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRecentChatsList(
                              model, model.conversationShowList, isMultiple),
                          _buildFriendList(
                              model, model.contactShowList, isMultiple),
                          _buildTeamList(model, model.teamShowList, isMultiple),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ));
      },
    );
  }

  /// 构建已经选中的列表
  Widget _buildSelectedList(
      ChatForwardViewModel outerModel, List<SelectedBeam> selectedList) {
    return InkWell(
      onTap: () {
        _showSelectedBottomSheet(outerModel);
      },
      child: Stack(children: [
        Container(
          height: 66,
          padding: EdgeInsets.only(right: 40),
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Color(0xFFf0f0f0), width: 6.0)),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            itemCount: selectedList.length,
            itemBuilder: (context, index) {
              final item = selectedList[index];
              final avatar = item.avatar;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Avatar(
                  avatar: avatar,
                  width: 44,
                  height: 44,
                  name: item.name,
                  fit: BoxFit.cover,
                  bgCode: AvatarColor.avatarColor(content: item.sessionId),
                ),
              );
            },
          ),
        ),
        Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Icon(Icons.keyboard_arrow_right_outlined))
      ]),
    );
  }

  // 展示底部已选弹框
  void _showSelectedBottomSheet(ChatForwardViewModel outerModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        // 保证在新 route 中也能取到同一个 model
        return ChangeNotifierProvider.value(
          value: outerModel,
          child: SafeArea(
            top: false,
            child: FractionallySizedBox(
              heightFactor: 0.9,
              child: Consumer<ChatForwardViewModel>(
                builder: (context, model, _) {
                  final items = model.selectedList;
                  return Column(
                    children: [
                      _buildSheetHeader(
                        title: '已选',
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) =>
                              _buildSelectedItemRow(items[index], model),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetHeader({
    required String title,
    required VoidCallback onBack,
  }) {
    const double h = 48;
    return Container(
      height: h,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: onBack,
              splashRadius: 20,
            ),
          ),
          Center(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: '#333333'.toColor(),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 右侧占位，确保标题视觉居中（与左侧 IconButton 宽度对齐）
          const Align(
            alignment: Alignment.centerRight,
            child: SizedBox(width: 48, height: h),
          ),
        ],
      ),
    );
  }

  /// 弹框中的 item 行
  Widget _buildSelectedItemRow(SelectedBeam item, ChatForwardViewModel model) {
    final isTeam = item.type == NIMConversationType.team;
    return Row(
      children: [
        const SizedBox(width: 12),
        Avatar(
          avatar: item.avatar,
          width: 44,
          height: 44,
          name: item.name,
          bgCode: AvatarColor.avatarColor(content: item.sessionId),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  item.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              if (isTeam && (item.count ?? 0) > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '(${item.count})',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () {
            model.removeSelected(item);
          },
        )
      ],
    );
  }

  /// 构建最近转发列表
  Widget _buildRecentForwards(ChatForwardViewModel model,
      List<RecentForward> recentForwards, bool isMultiSelect) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Color(0xFFf0f0f0), width: 8.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(S.of(context).forwardRecentForward,
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: isMultiSelect ? 105 : 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: recentForwards.length,
              itemBuilder: (context, index) {
                final item = recentForwards[index];
                final avatar = item.getAvatar();
                final isSelected = model.selectedList.indexWhere((e) =>
                        e.sessionId == item.sessionId &&
                        e.type == item.sessionType) >=
                    0;
                return GestureDetector(
                  onTap: () {
                    var selectedBeam = SelectedBeam(
                      type: item.sessionType,
                      sessionId: item.sessionId,
                      avatar: avatar,
                      name: item.getName(),
                    );
                    if (isMultiSelect) {
                      if (isSelected) {
                        model.removeSelected(selectedBeam);
                      } else {
                        addSelected(model.selectedList, selectedBeam);
                      }
                    } else {
                      Navigator.pop(context, [selectedBeam]);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        Avatar(
                          avatar: avatar,
                          width: 48,
                          height: 48,
                          name: item.getName(),
                          bgCode:
                              AvatarColor.avatarColor(content: item.sessionId),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 50,
                          child: Text(
                            item.getName(),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                        ),
                        if (isMultiSelect) ...[
                          const SizedBox(height: 6),
                          _SelectBox(selected: isSelected),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void addSelected(List<SelectedBeam> selectedList, SelectedBeam selected) {
    if (selectedList.length >= widget.maxSelectedCount) {
      Fluttertoast.showToast(
          msg: S
              .of(context)
              .maxSelectConversationLimit(widget.maxSelectedCount.toString()));
    } else {
      _model.addSelected(selected);
    }
  }

  /// 构建最近会话列表
  Widget _buildRecentChatsList(ChatForwardViewModel model,
      List<SearchResult<NIMConversation>> conversations, bool isMultiSelect) {
    if (conversations.isNotEmpty) {
      return ListView.builder(
        key: const PageStorageKey('recent_chats_list'),
        padding: EdgeInsets.zero,
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          if (conversations.isEmpty) {
            return Container();
          }
          final conversation = conversations[index];
          final name = conversation.data.name ??
              ChatKitUtils.getConversationTargetId(
                  conversation.data.conversationId);
          final selected = model.selectedList.indexWhere((e) =>
                  e.conversationId == conversation.data.conversationId &&
                  e.type == conversation.data.type) >=
              0;
          int? count =
              model.getConversationCount(conversation.data.conversationId);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              var selectedBeam = SelectedBeam(
                  type: conversation.data.type,
                  conversationId: conversation.data.conversationId,
                  avatar: conversation.data.avatar,
                  name: conversation.data.name);
              if (isMultiSelect) {
                if (selected) {
                  model.removeSelected(selectedBeam);
                } else {
                  addSelected(model.selectedList, selectedBeam);
                }
              } else {
                Navigator.pop(context, [selectedBeam]);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  if (isMultiSelect) ...[
                    _SelectBox(
                      selected: selected,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Avatar(
                    avatar: conversation.data.avatar,
                    width: 48,
                    height: 48,
                    name: conversation.data.name,
                    bgCode: AvatarColor.avatarColor(
                      content: ChatKitUtils.getConversationTargetId(
                          conversation.data.conversationId),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: _hitWidget(
                              name,
                              TextStyle(
                                  fontSize: 16, color: '#333333'.toColor()),
                              TextStyle(
                                  fontSize: 16,
                                  color: CommonColors.color_337eff),
                              hitInfo: conversation.searchInfo),
                        ),
                        if (count != null && count > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '($count)',
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                                fontSize: 16, color: '#333333'.toColor()),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            height: constraints.maxHeight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              SvgPicture.asset(
                searchKeyword?.isNotEmpty == true
                    ? 'images/ic_search_empty.svg'
                    : 'images/ic_list_empty.svg',
                package: kPackage,
              ),
              const SizedBox(height: 18),
              Text.rich(
                TextSpan(
                  style: TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
                  children: _buildTextSpans(
                    searchKeyword?.isNotEmpty == true
                        ? S.of(context).searchResultEmpty(searchKeyword!)
                        : S.of(context).forwardConversationEmpty,
                    searchKeyword,
                  ),
                ),
              )
            ]),
          );
        },
      );
    }
  }

  /// 构建好友列表
  Widget _buildFriendList(ChatForwardViewModel model,
      List<SearchResult<ContactInfo>> friends, bool isMultiSelect) {
    if (friends.isEmpty) {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SvgPicture.asset(
              searchKeyword?.isNotEmpty == true
                  ? 'images/ic_search_empty.svg'
                  : 'images/ic_list_empty.svg',
              package: kPackage,
            ),
            const SizedBox(
              height: 18,
            ),
            Text.rich(
              TextSpan(
                style: TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
                children: _buildTextSpans(
                  searchKeyword?.isNotEmpty == true
                      ? S.of(context).searchResultEmpty(searchKeyword!)
                      : S.of(context).forwardContactEmpty,
                  searchKeyword,
                ),
              ),
            )
          ]));
    } else {
      // 对好友列表按name进行排序
      final sortedFriends = sortFriends(friends);

      return ListView.builder(
        key: const PageStorageKey('friends_list'),
        padding: EdgeInsets.zero,
        itemCount: sortedFriends.length,
        itemBuilder: (context, index) {
          if (sortedFriends.isEmpty) {
            return Container();
          }
          final friend = sortedFriends[index]; // 使用排序后的列表
          final name = friend.data.getName();
          final accountId = friend.data.user.accountId;
          final selected = model.selectedList.indexWhere((e) =>
                  e.sessionId == accountId &&
                  e.type == NIMConversationType.p2p) >=
              0;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              var selectedBeam = SelectedBeam(
                  type: NIMConversationType.p2p,
                  sessionId: accountId,
                  avatar: friend.data.user.avatar,
                  name: friend.data.getName());
              if (isMultiSelect) {
                if (selected) {
                  model.removeSelected(selectedBeam);
                } else {
                  addSelected(model.selectedList, selectedBeam);
                }
              } else {
                Navigator.pop(context, [selectedBeam]);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  if (isMultiSelect) ...[
                    _SelectBox(
                      selected: selected,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Avatar(
                    avatar: friend.data.user.avatar,
                    width: 48,
                    height: 48,
                    name: friend.data.getName(needAlias: false),
                    bgCode: AvatarColor.avatarColor(
                      content: accountId,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: _hitWidget(
                              name,
                              TextStyle(
                                  fontSize: 16, color: '#333333'.toColor()),
                              TextStyle(
                                  fontSize: 16,
                                  color: CommonColors.color_337eff),
                              hitInfo: friend.searchInfo),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  /// 构建群组列表
  Widget _buildTeamList(ChatForwardViewModel model,
      List<SearchResult<NIMTeam>> teams, bool isMultiSelect) {
    if (teams.isEmpty) {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SvgPicture.asset(
              searchKeyword?.isNotEmpty == true
                  ? 'images/ic_search_empty.svg'
                  : 'images/ic_list_empty.svg',
              package: kPackage,
            ),
            const SizedBox(
              height: 18,
            ),
            Text.rich(
              TextSpan(
                style: TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
                children: _buildTextSpans(
                  searchKeyword?.isNotEmpty == true
                      ? S.of(context).searchResultEmpty(searchKeyword!)
                      : S.of(context).forwardTeamEmpty,
                  searchKeyword,
                ),
              ),
            )
          ]));
    } else {
      return ListView.builder(
        key: const PageStorageKey('team_list'),
        padding: EdgeInsets.zero,
        itemCount: teams.length,
        itemBuilder: (context, index) {
          if (teams.isEmpty) {
            return Container();
          }
          final team = teams[index];
          final name = team.data.name;
          final teamId = team.data.teamId;
          final count = team.data.memberCount;
          final selected = model.selectedList.indexWhere((e) =>
                  e.sessionId == teamId &&
                  e.type == NIMConversationType.team) >=
              0;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              var selectedBeam = SelectedBeam(
                  type: NIMConversationType.team,
                  sessionId: teamId,
                  avatar: team.data.avatar,
                  name: name);
              if (isMultiSelect) {
                if (selected) {
                  model.removeSelected(selectedBeam);
                } else {
                  addSelected(model.selectedList, selectedBeam);
                }
              } else {
                Navigator.pop(context, [selectedBeam]);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  if (isMultiSelect) ...[
                    _SelectBox(
                      selected: selected,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Avatar(
                    avatar: team.data.avatar,
                    width: 48,
                    height: 48,
                    name: team.data.name,
                    bgCode: AvatarColor.avatarColor(
                      content: teamId,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: _hitWidget(
                              name,
                              TextStyle(
                                  fontSize: 16, color: '#333333'.toColor()),
                              TextStyle(
                                  fontSize: 16,
                                  color: CommonColors.color_337eff),
                              hitInfo: team.searchInfo),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '($count)',
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                                fontSize: 16, color: '#333333'.toColor()),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  ///构建高亮文案
  List<TextSpan> _buildTextSpans(String text, String? keyword) {
    if (keyword?.isEmpty != false) {
      return [TextSpan(text: text)];
    }

    final index = text.toLowerCase().indexOf(keyword!.toLowerCase());
    if (index == -1) {
      return [TextSpan(text: text)];
    }

    return [
      if (index > 0) TextSpan(text: text.substring(0, index)),
      TextSpan(
        text: text.substring(index, index + keyword.length),
        style: TextStyle(color: CommonColors.color_337eff),
      ),
      if (index + keyword.length < text.length)
        TextSpan(text: text.substring(index + keyword.length)),
    ];
  }

  Widget _hitWidget(String content, TextStyle normalStyle, TextStyle highStyle,
      {RecordHitInfo? hitInfo}) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: hitInfo == null
          ? TextSpan(text: content, style: normalStyle)
          : TextSpan(children: [
              if (hitInfo.start > 0)
                TextSpan(
                  text: content.substring(0, hitInfo.start),
                  style: normalStyle,
                ),
              TextSpan(
                  text: content.substring(hitInfo.start, hitInfo.end),
                  style: highStyle),
              if (hitInfo.end <= content.length - 1)
                TextSpan(
                    text: content.substring(hitInfo.end), style: normalStyle)
            ]),
    );
  }
}

// 自定义圆形选择框
class _SelectBox extends StatelessWidget {
  final bool selected;

  const _SelectBox({Key? key, required this.selected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double size = 22;
    final borderColor = selected ? Colors.blue : Colors.grey.shade400;
    final bgColor = selected ? Colors.blue : Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      alignment: Alignment.center,
      child: selected
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : const SizedBox.shrink(),
    );
  }
}
