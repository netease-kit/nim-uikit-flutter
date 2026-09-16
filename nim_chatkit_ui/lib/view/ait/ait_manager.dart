// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/model/ait/ait_contacts_model.dart';
import 'package:nim_chatkit/model/ait/ait_msg.dart';
import 'package:nim_chatkit/model/team_models.dart';
import 'package:nim_chatkit/repo/team_member_search_repository.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/message/nim_chat_cache.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../chat_kit_client.dart';
import '../../helper/ait_member_search_helper.dart';
import '../../l10n/S.dart';
import '../../widget/ait_member_highlight_text.dart';
import 'ait_model.dart';

///@消息管理类
class AitManager {
  final AitContactsModel _aitContactsModel = AitContactsModel();

  get aitContactsModel => _aitContactsModel;

  /// 暴露 AI 用户列表，供桌面端弹框使用
  List<AitBean> get aiUserList => _aiUserList ?? [];

  /// 暴露成员列表通知器，供桌面端弹框监听
  ValueNotifier<List<AitBean>?> get aitMemberList => _aitMemberList;

  final String teamId;

  /// 是否为 P2P 单聊场景，P2P 场景下只展示 AI 数字人
  final bool isP2P;

  StreamSubscription? _teamSub;
  bool _disposed = false;

  ValueNotifier<List<AitBean>?> _aitMemberList = ValueNotifier(null);

  List<AitBean>? _aiUserList;

  AitManager(this.teamId, {this.isP2P = false}) {
    // _aiUserList 只保存 AI 数字人，不混入群成员，防止切换群聊时旧群成员污染新群
    _aiUserList = AIUserManager.instance
        .getAIChatUserList()
        .map((e) => AitBean(aiUser: e))
        .toList();

    if (!isP2P) {
      // 初始加载：AI用户 + 当前群成员
      _aitMemberList.value = _buildAitList(NIMChatCache.instance.teamMembers);
      // 监听群成员变化，动态刷新列表
      _teamSub = NIMChatCache.instance.teamMembersNotifier.listen((event) {
        _aitMemberList.value = _buildAitList(event);
      });
    } else {
      // P2P 场景：只展示 AI 数字人，不监听群成员变化
      _aitMemberList.value = _aiUserList!;
    }
  }

  /// 构建 @ 成员列表：AI用户（始终最新）+ 本次群成员快照（去除已是AI的成员）
  List<AitBean> _buildAitList(List<UserInfoWithTeam> teamMembers) {
    final List<AitBean> aitList = [];
    final memberAccountIds = teamMembers
        .where((member) => member.teamInfo.inTeam)
        .map((member) => member.teamInfo.accountId)
        .toSet();
    // 先加 AI 用户（重新从 AIUserManager 获取，确保最新）
    aitList.addAll(
      AIUserManager.instance.getAIChatUserList().map(
            (aiUser) => AitBean(
              aiUser: aiUser,
              isAIUserTeamMember: memberAccountIds.contains(aiUser.accountId),
            ),
          ),
    );
    // 再加群成员（去除 AI 用户，防止重复）
    aitList.addAll(
      teamMembers
          .where(
            (member) => !AIUserManager.instance.isAIChatUserByAccount(
              member.teamInfo.accountId,
            ),
          )
          .map((e) => AitBean(teamMember: e)),
    );
    return aitList;
  }

  /// 刷新成员列表（从当前 NIMChatCache 实时获取），供桌面端弹框显示前调用
  /// 防止切换会话时初始化读到旧缓存
  void refreshMemberList() {
    if (!isP2P) {
      _aitMemberList.value = _buildAitList(NIMChatCache.instance.teamMembers);
    }
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
        //如果有@所有人，则不需要填写pushList
        pushList.clear();
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
    _disposed = true;
    _teamSub?.cancel();
  }

  void loadMoreMembers() {
    NIMChatCache.instance.fetchTeamMember(teamId, loadMore: true);
  }

  /// Loads all members for an active search query, independently of the
  /// current chat cache pagination.
  Future<void> loadAllMembers() async {
    if (isP2P) return;
    final cachedMembers = NIMChatCache.instance.teamMembers;
    final teamType = NIMChatCache.instance.teamInfo?.teamType ??
        (cachedMembers.isNotEmpty
            ? cachedMembers.first.teamInfo.teamType
            : null) ??
        NIMTeamType.typeNormal;
    final members = await getIt<TeamMemberSearchRepository>().loadAll(
      teamId,
      teamType,
    );
    if (_disposed) return;
    _aitMemberList.value = _buildAitList(members);
  }

  ///选择@的成员
  Future<dynamic> selectMember(BuildContext context) async {
    // P2P 场景：无数字人则不弹框，直接返回 null
    if (isP2P && (_aiUserList == null || _aiUserList!.isEmpty)) {
      return null;
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      builder: (context) {
        return _AitMemberPickerSheet(
          memberListenable: _aitMemberList,
          isP2P: isP2P,
          onLoadMore: loadMoreMembers,
          onLoadAll: loadAllMembers,
        );
      },
    );
  }
}

class _AitMemberPickerSheet extends StatefulWidget {
  final ValueNotifier<List<AitBean>?> memberListenable;
  final bool isP2P;
  final VoidCallback onLoadMore;
  final Future<void> Function() onLoadAll;

  const _AitMemberPickerSheet({
    required this.memberListenable,
    required this.isP2P,
    required this.onLoadMore,
    required this.onLoadAll,
  });

  @override
  State<_AitMemberPickerSheet> createState() => _AitMemberPickerSheetState();
}

class _AitMemberPickerSheetState extends State<_AitMemberPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String _query = '';
  bool _loadingAllMembers = false;
  bool _searchError = false;
  int _searchGeneration = 0;

  bool get _isSearching => _query.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChange);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode
      ..removeListener(_handleSearchFocusChange)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearchFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleScroll() {
    if (_isSearching || !_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent) {
      widget.onLoadMore();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchGeneration++;
    setState(() {
      _query = '';
      _loadingAllMembers = false;
      _searchError = false;
    });
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    if (_query.trim().isEmpty || _loadingAllMembers) {
      return;
    }
    final generation = ++_searchGeneration;
    setState(() {
      _loadingAllMembers = true;
      _searchError = false;
    });
    unawaited(() async {
      try {
        await widget.onLoadAll();
      } catch (_) {
        if (mounted && generation == _searchGeneration) {
          setState(() {
            _loadingAllMembers = false;
            _searchError = true;
          });
        }
        return;
      }
      if (!mounted || generation != _searchGeneration) {
        return;
      }
      setState(() => _loadingAllMembers = false);
    }());
  }

  void _retrySearch() {
    if (_query.trim().isNotEmpty) {
      _onSearchChanged(_query);
    }
  }

  OutlineInputBorder _searchBorder() => const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        borderSide: BorderSide(color: Colors.transparent),
      );

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = _searchFocusNode.hasFocus
        ? MediaQuery.viewInsetsOf(context).bottom
        : 0.0;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: ValueListenableBuilder<List<AitBean>?>(
          valueListenable: widget.memberListenable,
          builder: (context, value, child) {
            final allMembers = (value ?? const <AitBean>[])
                .where(
                  (element) => element.getAccountId() != IMKitClient.account(),
                )
                .toList();
            final members = _isSearching
                ? allMembers
                    .where(
                      (element) => matchesAitMemberFields(
                        element.searchableFields,
                        _query,
                      ),
                    )
                    .toList()
                : allMembers;
            final showAll = !widget.isP2P &&
                !_isSearching &&
                NIMChatCache.instance.haveAitAllPrivilege();

            return Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: CommonColors.color_999999,
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Text(S.of(context).chatMessageAitContactTitle),
                      ),
                    ],
                  ),
                ),
                if (!widget.isP2P)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _onSearchChanged,
                        onTapOutside: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        textInputAction: TextInputAction.search,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF2F4F5),
                          hintText: S.of(context).chatMemberPickerSearchHint,
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFA6ADB6),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 18,
                            color: Color(0xFFA6ADB6),
                          ),
                          suffixIcon: _isSearching
                              ? IconButton(
                                  onPressed: _clearSearch,
                                  icon: const Icon(
                                    Icons.clear,
                                    size: 18,
                                    color: Color(0xFFA6ADB6),
                                  ),
                                )
                              : null,
                          contentPadding: EdgeInsets.zero,
                          border: _searchBorder(),
                          enabledBorder: _searchBorder(),
                          focusedBorder: _searchBorder(),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: members.isEmpty && !showAll
                      ? (_isSearching && _loadingAllMembers)
                          ? const _AitMemberLoadingState()
                          : (_isSearching && _searchError)
                              ? _AitMemberErrorState(onRetry: _retrySearch)
                              : AitMemberEmptyState(searching: _isSearching)
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: members.length + (showAll ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (showAll && index == 0) {
                              return ListTile(
                                leading: SvgPicture.asset(
                                  'images/ic_team_all.svg',
                                  package: kPackage,
                                  height: 42,
                                  width: 42,
                                ),
                                title: Text(S.of(context).chatTeamAitAll),
                                onTap: () {
                                  Navigator.pop(
                                    context,
                                    AitContactsModel.accountAll,
                                  );
                                },
                              );
                            }
                            final memberIndex = showAll ? index - 1 : index;
                            final user = members[memberIndex];
                            return ListTile(
                              leading: Avatar(
                                avatar: user.getAvatar(),
                                name: user.getAvatarName(),
                                height: 42,
                                width: 42,
                              ),
                              title: _AitMemberTitle(user: user, query: _query),
                              onTap: () => Navigator.pop(context, user),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Empty state shared by mobile and desktop mention member pickers.
class AitMemberEmptyState extends StatelessWidget {
  final bool searching;

  const AitMemberEmptyState({Key? key, this.searching = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            searching
                ? 'images/ic_search_empty.svg'
                : 'images/ic_list_empty.svg',
            key: const ValueKey<String>('ait-member-empty-image'),
            package: kPackage,
            height: searching ? 73 : 85,
          ),
          const SizedBox(height: 18),
          Text(
            searching
                ? S.of(context).chatMemberPickerSearchEmpty
                : S.of(context).chatMemberPickerEmpty,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFB3B7BC),
            ),
          ),
        ],
      ),
    );
  }
}

class _AitMemberLoadingState extends StatelessWidget {
  const _AitMemberLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(height: 8),
          Text(S.of(context).chatMemberPickerSearching),
        ],
      ),
    );
  }
}

class _AitMemberErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _AitMemberErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        tooltip: S.of(context).botSubsessionRetry,
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
      ),
    );
  }
}

class _AitMemberTitle extends StatelessWidget {
  final AitBean user;
  final String query;

  const _AitMemberTitle({required this.user, required this.query});

  @override
  Widget build(BuildContext context) {
    final fields = user.searchableFields;
    final displayName = user.displayName;
    final subtitles = findAitMemberSubtitles(fields, displayName, query);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AitMemberHighlightText(
          displayName: displayName,
          query: query,
          style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
        ),
        ...subtitles.map(
          (value) => AitMemberHighlightText(
            displayName: value,
            query: query,
            style: const TextStyle(fontSize: 12, color: Color(0xFF858A92)),
          ),
        ),
      ],
    );
  }
}
