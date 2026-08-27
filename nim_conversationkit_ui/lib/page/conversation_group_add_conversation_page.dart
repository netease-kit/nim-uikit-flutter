// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/text_search.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/repo/conversation_repo.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:provider/provider.dart';

import '../conversation_kit_client.dart';
import '../l10n/S.dart';
import '../model/conversation_group_ui_model.dart';
import '../model/conversation_info.dart';
import '../view_model/conversation_group_view_model.dart';

class ConversationGroupAddConversationPage extends StatefulWidget {
  const ConversationGroupAddConversationPage({
    Key? key,
    required this.model,
    required this.group,
  }) : super(key: key);

  final ConversationGroupViewModel model;
  final ConversationGroupUiModel group;

  @override
  State<ConversationGroupAddConversationPage> createState() =>
      _ConversationGroupAddConversationPageState();
}

class _ConversationGroupAddConversationPageState
    extends BaseState<ConversationGroupAddConversationPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _initialConversationIds = {};
  final Set<String> _selectedConversationIds = {};
  final List<ConversationInfo> _allConversations = [];
  final List<ConversationInfo> _showConversations = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _finished = false;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_filterConversations);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  void _onScroll() {
    if (_isSearching || _loading || _loadingMore || _finished) {
      return;
    }
    if (!_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 48) {
      _loadConversations();
    }
  }

  Future<void> _initData() async {
    setState(() {
      _loading = true;
    });
    await widget.model.loadAllConversationsForGroup(widget.group);
    if (!mounted) {
      return;
    }
    _initialConversationIds
      ..clear()
      ..addAll(
        widget.model.displayConversations.map(
          (conversation) => conversation.getConversationId(),
        ),
      );
    _selectedConversationIds..clear();
    _loading = false;
    await _loadConversations(refresh: true);
  }

  bool _isInTargetGroup(ConversationInfo conversation) {
    final conversationId = conversation.getConversationId();
    return _initialConversationIds.contains(conversationId) ||
        conversation.conversation.groupIds?.contains(widget.group.id) == true;
  }

  Future<void> _loadConversations({bool refresh = false}) async {
    if (_isSearching && !refresh) {
      return;
    }
    if (refresh) {
      _offset = 0;
      _finished = false;
      _allConversations.clear();
    }
    if (_loading || _loadingMore || _finished) {
      return;
    }
    if (mounted) {
      setState(() {
        if (refresh) {
          _loading = true;
        } else {
          _loadingMore = true;
        }
      });
    }
    final result = await ConversationRepo.getConversationList(
      _offset,
      widget.model.conversationViewModel.pageLimit,
    );
    if (!mounted) {
      return;
    }
    final conversations =
        widget.model.conversationViewModel.convertConversationInfo(
              result?.conversationList,
            ) ??
            [];
    if (result != null) {
      _offset = result.offset;
      _finished = result.finished;
    } else {
      _finished = true;
    }
    final existingIds = _allConversations
        .map((conversation) => conversation.getConversationId())
        .toSet();
    _allConversations.addAll(
      conversations.where(
        (conversation) =>
            !existingIds.contains(conversation.getConversationId()),
      ),
    );
    _filterConversations();
    if (!_isSearching &&
        _showConversations.length <
            widget.model.conversationViewModel.pageLimit &&
        !_finished) {
      _loading = false;
      _loadingMore = false;
      await _loadConversations();
      return;
    }
    setState(() {
      _loading = false;
      _loadingMore = false;
    });
  }

  void _filterConversations() {
    final keyword = _searchController.text.trim();
    _showConversations
      ..clear()
      ..addAll(
        keyword.isEmpty
            ? _allConversations.where(
                (conversation) => !_isInTargetGroup(conversation),
              )
            : _allConversations.where((conversation) {
                return !_isInTargetGroup(conversation) &&
                    conversation.getName().contains(keyword);
              }),
      );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ConversationGroupViewModel>.value(
      value: widget.model,
      child: TransparentScaffold(
        title: S.of(context).conversationGroupAddTitle(
              _selectedConversationIds.length,
              ConversationGroupViewModel.maxGroupConversationCount,
            ),
        leadingWidth: 72,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            S.of(context).cancelTitle,
            style: const TextStyle(color: CommonColors.color_333333),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submit,
            child: Text(
              S.of(context).sureTitle,
              style: const TextStyle(color: CommonColors.color_337eff),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        appBarBackgroundColor: Colors.white,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _searchController,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(
                    color: CommonColors.color_333333,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: S.of(context).conversationGroupSearchHint,
                    hintStyle: const TextStyle(
                      color: Color(0xFFA6ADB6),
                      fontSize: 16,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: SvgPicture.asset(
                        'images/ic_conversation_search.svg',
                        package: kPackage,
                        width: 16,
                        height: 16,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 32,
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                              color: Color(0xFFA6ADB6),
                            ),
                            onPressed: _searchController.clear,
                          ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF2F3F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _showConversations.isEmpty
                      ? _EmptyView()
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _showConversations.length +
                              (!_isSearching && _loadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _showConversations.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            }
                            final conversation = _showConversations[index];
                            return _ConversationSelectRow(
                              conversation: conversation,
                              keyword: _searchController.text.trim(),
                              selected: _selectedConversationIds.contains(
                                conversation.getConversationId(),
                              ),
                              onChanged: (selected) =>
                                  _toggleConversation(conversation, selected),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleConversation(ConversationInfo conversation, bool selected) {
    final conversationId = conversation.getConversationId();
    if (selected) {
      final remainingCount =
          ConversationGroupViewModel.maxGroupConversationCount -
              _initialConversationIds.length;
      if (_selectedConversationIds.length >= remainingCount) {
        ChatUIToast.show(
          S.of(context).conversationGroupConversationLimit,
          context: context,
        );
        return;
      }
      _selectedConversationIds.add(conversationId);
    } else {
      _selectedConversationIds.remove(conversationId);
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (!checkNetwork()) {
      return;
    }
    final addIds = _selectedConversationIds.toList();
    if (addIds.isNotEmpty) {
      final result = await widget.model.addConversationsToGroup(
        widget.group,
        addIds,
      );
      if (!result.isSuccess) {
        final joinGroupLimit =
            ConversationGroupViewModel.isConversationJoinGroupLimit(
          result.code,
        );
        await _refreshConversationsAfterAddFailure(
          clearSelection: !joinGroupLimit,
        );
        if (!mounted) {
          return;
        }
        if (joinGroupLimit) {
          ChatUIToast.show(
            S.of(context).conversationGroupJoinedLimit,
            context: context,
          );
        } else if (result.code ==
            ConversationGroupViewModel
                .conversationGroupConversationCountLimit) {
          ChatUIToast.show(
            S.of(context).conversationGroupConversationCountLimit,
            context: context,
          );
        } else if (result.code ==
            ConversationGroupViewModel.conversationNotExist) {
          ChatUIToast.show(
            S.of(context).conversationGroupConversationNotExist,
            context: context,
          );
        } else {
          ChatUIToast.show(
            result.errorDetails ??
                S.of(context).conversationGroupOperationFailed,
            context: context,
          );
        }
        return;
      }
      if (result.data?.isNotEmpty == true) {
        final hasJoinGroupLimit = result.data!.any(
          (operation) =>
              ConversationGroupViewModel.isConversationJoinGroupLimit(
            operation.error?.code,
          ),
        );
        final allConversationsFailed = addIds.every(
          (conversationId) => result.data!.any(
            (operation) => operation.conversationId == conversationId,
          ),
        );
        await _refreshConversationsAfterAddFailure(
          clearSelection: !(allConversationsFailed && hasJoinGroupLimit),
        );
        if (!mounted) {
          return;
        }
        if (!allConversationsFailed) {
          ChatUIToast.show(
            S.of(context).conversationGroupPartialAddFailed,
            context: context,
          );
          Navigator.pop(context);
          return;
        }
        ChatUIToast.show(
          hasJoinGroupLimit
              ? S.of(context).conversationGroupJoinedLimit
              : result.data!.any(
                  (operation) =>
                      operation.error?.code ==
                      ConversationGroupViewModel.conversationNotExist,
                )
                  ? S.of(context).conversationGroupConversationNotExist
                  : S.of(context).conversationGroupPartialAddFailed,
          context: context,
        );
        return;
      }
    }
    Navigator.pop(context);
  }

  Future<void> _refreshConversationsAfterAddFailure({
    bool clearSelection = true,
  }) async {
    await widget.model.conversationViewModel.queryConversationList();
    if (!mounted) {
      return;
    }
    _initialConversationIds
      ..clear()
      ..addAll(
        widget.model.displayConversations.map(
          (conversation) => conversation.getConversationId(),
        ),
      );
    if (clearSelection) {
      _selectedConversationIds.clear();
    }
    await _loadConversations(refresh: true);
  }
}

class _ConversationSelectRow extends StatelessWidget {
  const _ConversationSelectRow({
    required this.conversation,
    required this.keyword,
    required this.selected,
    required this.onChanged,
  });

  final ConversationInfo conversation;
  final String keyword;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!selected),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            _SelectIndicator(selected: selected),
            const SizedBox(width: 10),
            Avatar(
              avatar: conversation.getAvatar() ?? '',
              name: conversation.getName(),
              width: 40,
              height: 40,
              radius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: keyword.isEmpty
                  ? Text(
                      conversation.getName(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CommonColors.color_333333,
                        fontSize: 16,
                      ),
                    )
                  : TextSearcher.hitWidget(
                      conversation.getName(),
                      keyword,
                      const TextStyle(
                        color: CommonColors.color_333333,
                        fontSize: 16,
                      ),
                      const TextStyle(
                        color: CommonColors.color_337eff,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectIndicator extends StatelessWidget {
  const _SelectIndicator({
    required this.selected,
  });

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: selected ? CommonColors.color_337eff : Colors.transparent,
        shape: BoxShape.circle,
        border: selected
            ? null
            : Border.all(
                color: const Color(0xFFA6ADB6),
                width: 1.5,
              ),
      ),
      child: selected
          ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            )
          : null,
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'images/ic_search_empty.svg',
            package: kPackage,
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).conversationEmpty,
            style: const TextStyle(
              color: CommonColors.color_b3b7bc,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
