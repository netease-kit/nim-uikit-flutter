// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/model/bot_subsession_models.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit_ui/helper/bot_subsession_action_helper.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/view/page/chat_setting_page.dart';
import 'package:nim_chatkit_ui/view_model/bot_subsession_list_view_model.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';

import '../../chat_kit_client.dart';

class BotSubsessionListPage extends StatefulWidget {
  final String conversationId;
  final NIMConversationType conversationType;
  final BotSubsessionTopicContext? selectedTopicContext;
  final ValueChanged<BotSubsessionTopicContext>? onTopicSelected;
  final bool showDesktopBorder;

  const BotSubsessionListPage({
    Key? key,
    required this.conversationId,
    required this.conversationType,
    this.selectedTopicContext,
    this.onTopicSelected,
    this.showDesktopBorder = false,
  }) : super(key: key);

  @override
  State<BotSubsessionListPage> createState() => _BotSubsessionListPageState();
}

class _BotSubsessionListPageState extends BaseState<BotSubsessionListPage> {
  final TextEditingController _searchController = TextEditingController();
  late BotSubsessionListViewModel _viewModel;
  // bool _handledFallback = false;

  @override
  void initState() {
    super.initState();
    _viewModel = BotSubsessionListViewModel(widget.conversationId);
  }

  @override
  void didUpdateWidget(covariant BotSubsessionListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      _viewModel.dispose();
      _viewModel = BotSubsessionListViewModel(widget.conversationId);
      return;
    }
    if (!ChatKitUtils.isDesktopOrWeb) {
      return;
    }
    final oldSelectedContext = oldWidget.selectedTopicContext;
    final selectedContext = widget.selectedTopicContext;
    if (oldSelectedContext?.isPlaceholder == true &&
        selectedContext?.topic != null &&
        selectedContext?.localKey == oldSelectedContext?.localKey) {
      _viewModel.replacePlaceholderWithTopic(
        oldSelectedContext!,
        selectedContext!.topic!,
        notify: false,
      );
      return;
    }
    _discardHiddenDraft(widget.selectedTopicContext);
  }

  @override
  void dispose() {
    if (ChatKitUtils.isDesktopOrWeb) {
      _discardHiddenDraft(widget.selectedTopicContext, notify: false);
    }
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _discardHiddenDraft(
    BotSubsessionTopicContext? visibleContext, {
    bool notify = true,
  }) {
    final draftContext = _viewModel.draftContext;
    if (draftContext == null || !draftContext.isPlaceholder) {
      return;
    }
    if (visibleContext?.topicKey == draftContext.topicKey) {
      return;
    }
    _viewModel.discardPlaceholder(
      expectedContext: draftContext,
      notify: notify,
    );
  }

  Future<void> _createSubsession(
    BuildContext context,
    BotSubsessionListViewModel viewModel,
  ) async {
    if (!await haveConnectivity()) {
      return;
    }
    if (!mounted) return;
    viewModel.createPlaceholder(S.of(context).botSubsessionNewSession);
    final contextValue = viewModel.draftContext;
    if (contextValue == null) return;
    await viewModel.markConversationRead();
    if (ChatKitUtils.isDesktopOrWeb) {
      widget.onTopicSelected?.call(contextValue);
    } else {
      await goToTopicChatPage(
        context,
        widget.conversationId,
        contextValue,
      );
    }
    if (!ChatKitUtils.isDesktopOrWeb && viewModel.draftContext != null) {
      viewModel.discardPlaceholder();
    }
  }

  Widget _buildPageBody(BotSubsessionListViewModel model) {
    if (ChatKitUtils.isDesktopOrWeb) {
      return _buildDesktopPageBody(model);
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              onChanged: model.updateKeyword,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: S.of(context).botSubsessionSearchHint,
                hintStyle: const TextStyle(
                  color: Color(0xFFB3B7BC),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          model.updateKeyword('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.close, size: 18),
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: const Color(0xFFF5F6F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildBody(context, model),
        ),
      ],
    );
  }

  Widget _buildDesktopPageBody(BotSubsessionListViewModel model) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: widget.showDesktopBorder
            ? const Border(
                right: BorderSide(color: Color(0xFFEBEDF0), width: 1),
              )
            : null,
      ),
      child: Column(
        children: [
          Container(
            height: 72,
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFEBEDF0), width: 1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${model.pageTitle} · ${S.of(context).botSubsessionNewSession}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF262626),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _DesktopIconButton(
                      icon: Icons.add,
                      onTap: () => _createSubsession(context, model),
                    ),
                    const SizedBox(width: 6),
                    _DesktopIconButton(
                      icon: Icons.more_vert,
                      onTap: () => _openChatSetting(model),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 26,
                  child: TextField(
                    controller: _searchController,
                    onChanged: model.updateKeyword,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF262626),
                    ),
                    decoration: InputDecoration(
                      hintText: S.of(context).botSubsessionSearchHint,
                      hintStyle: const TextStyle(
                        color: Color(0xFF8C8C8C),
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 14,
                        color: Color(0xFF8C8C8C),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 26,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                _searchController.clear();
                                model.updateKeyword('');
                                setState(() {});
                              },
                              icon: const Icon(Icons.close, size: 14),
                            )
                          : null,
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 26,
                      ),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: const Color(0xFFF7F8FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(context, model),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'images/ic_list_empty.svg',
            package: kPackage,
          ),
          const SizedBox(height: 18),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFB3B7BC),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _openChatSetting(BotSubsessionListViewModel model) {
    final robot = model.robot;
    final accid = robot?.accid ?? model.targetId;
    final page = ChatSettingPage(
      ContactInfo(
        NIMUserInfo(
          accountId: accid,
          name: robot?.name,
          avatar: robot?.icon,
          sign: robot?.sign,
        ),
      ),
      widget.conversationId,
    );
    if (ChatKitUtils.isDesktopOrWeb) {
      showDesktopDialog(
        context,
        page,
        width: 480,
        height: 620,
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<BotSubsessionListViewModel>(
        builder: (context, model, _) {
          // if (model.fallbackToLinearChat && !_handledFallback) {
          //   _handledFallback = true;
          //   WidgetsBinding.instance.addPostFrameCallback((_) {
          //     model.consumeFallbackNavigation();
          //     goToChatPage(
          //       context,
          //       widget.conversationId,
          //       widget.conversationType,
          //       forceLinearChat: true,
          //     );
          //   });
          // }
          final body = _buildPageBody(model);
          final actions = [
            IconButton(
              onPressed: () => _createSubsession(context, model),
              icon: const Icon(Icons.add),
            ),
            IconButton(
              onPressed: () => _openChatSetting(model),
              icon: const Icon(Icons.more_horiz),
            ),
          ];
          if (ChatKitUtils.isDesktopOrWeb) {
            return Scaffold(body: body);
          }
          return TransparentScaffold(
            backgroundColor: Colors.white,
            centerTitle: true,
            title: model.pageTitle,
            elevation: 0,
            actions: actions,
            body: body,
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, BotSubsessionListViewModel model) {
    if (model.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (model.loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('加载失败'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: model.reload,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (model.items.isEmpty) {
      return _buildEmpty(
        model.keyword.isEmpty ? '暂无子会话' : '未找到相关子会话',
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 80) {
          model.loadMore();
        }
        return false;
      },
      child: ListView.separated(
        itemCount: model.items.length + (model.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= model.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = model.items[index];
          return _TopicListTile(
            item: item,
            checkNetwork: checkNetwork,
            selected: _isSelectedTopic(item.context),
            onTopicSelected: widget.onTopicSelected,
          );
        },
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          indent: 56,
        ),
      ),
    );
  }

  bool _isSelectedTopic(BotSubsessionTopicContext context) {
    final selected = widget.selectedTopicContext;
    if (selected == null) {
      return false;
    }
    if (context.topic?.topicId != null && selected.topic?.topicId != null) {
      return context.topic!.topicId == selected.topic!.topicId;
    }
    return context.topicKey == selected.topicKey;
  }
}

class _DesktopIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _DesktopIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_DesktopIconButton> createState() => _DesktopIconButtonState();
}

class _DesktopIconButtonState extends State<_DesktopIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF0F2F5) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: _hovered ? const Color(0xFF262626) : const Color(0xFF8C8C8C),
          ),
        ),
      ),
    );
  }
}

class _TopicListTile extends StatelessWidget {
  final BotSubsessionListItem item;
  final bool Function() checkNetwork;
  final bool selected;
  final ValueChanged<BotSubsessionTopicContext>? onTopicSelected;

  const _TopicListTile({
    required this.item,
    required this.checkNetwork,
    this.selected = false,
    this.onTopicSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (ChatKitUtils.isDesktopOrWeb) {
      return _buildDesktopTile(context);
    }
    final topic = item.context.topic;
    return InkWell(
      onTap: () {
        final viewModel = context.read<BotSubsessionListViewModel>();
        viewModel.markConversationRead();
        goToTopicChatPage(
          context,
          item.context.conversationId,
          item.context,
        );
      },
      onLongPress: item.isPlaceholder
          ? null
          : () {
              _showTopicActions(context, item);
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(
              'images/ic_chat_bot_sub_item.svg',
              package: kPackage,
              width: 42,
              height: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: _buildHighlightedTitle(item),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF262626),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(item.latestTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFBFBFBF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.summary.isEmpty
                              ? (topic?.topicName ?? '')
                              : item.summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8C8C8C),
                          ),
                        ),
                      ),
                      if (item.showUnreadDot) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF4D4F),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTile(BuildContext context) {
    final topic = item.context.topic;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final viewModel = context.read<BotSubsessionListViewModel>();
        viewModel.markConversationRead();
        if (onTopicSelected != null) {
          onTopicSelected!(item.context);
          return;
        }
        goToTopicChatPage(
          context,
          item.context.conversationId,
          item.context,
        );
      },
      onSecondaryTapUp: item.isPlaceholder
          ? null
          : (details) {
              _showDesktopTopicActions(context, item, details.globalPosition);
            },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          color: selected ? const Color(0xFFE8F0FF) : Colors.transparent,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'images/ic_chat_bot_sub_item.svg',
                package: kPackage,
                width: 42,
                height: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: _buildHighlightedTitle(item),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF262626),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(item.latestTime),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8C8C8C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.summary.isEmpty
                                ? (topic?.topicName ?? '')
                                : item.summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8C8C8C),
                            ),
                          ),
                        ),
                        if (item.showUnreadDot) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5222D),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildHighlightedTitle(BotSubsessionListItem item) {
    final start = item.highlightStart;
    final end = item.highlightEnd;
    if (start == null || end == null || start < 0 || end > item.title.length) {
      return [TextSpan(text: item.title)];
    }
    return [
      if (start > 0) TextSpan(text: item.title.substring(0, start)),
      const TextSpan(
        style: TextStyle(color: Color(0xFF337EFF)),
      ),
      TextSpan(
        text: item.title.substring(start, end),
        style: const TextStyle(color: Color(0xFF337EFF)),
      ),
      if (end < item.title.length) TextSpan(text: item.title.substring(end)),
    ];
  }

  Future<void> _showTopicActions(
    BuildContext context,
    BotSubsessionListItem item,
  ) async {
    final viewModel = context.read<BotSubsessionListViewModel>();
    await BotSubsessionActionHelper.showTopicActions(
      context: context,
      currentTitle: item.title,
      onRename: (title) => viewModel.renameTopic(item, title),
      onDelete: () => viewModel.deleteTopic(item),
      checkNetwork: checkNetwork,
    );
  }

  Future<void> _showDesktopTopicActions(
    BuildContext context,
    BotSubsessionListItem item,
    Offset position,
  ) async {
    final viewModel = context.read<BotSubsessionListViewModel>();
    await BotSubsessionActionHelper.showDesktopTopicActions(
      context: context,
      globalPosition: position,
      currentTitle: item.title,
      onRename: (title) => viewModel.renameTopic(item, title),
      onDelete: () => viewModel.deleteTopic(item),
      checkNetwork: checkNetwork,
    );
  }

  String _formatTime(int millis) {
    if (millis <= 0) {
      return '';
    }
    final time = DateTime.fromMillisecondsSinceEpoch(millis);
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfYesterday = startOfToday.subtract(const Duration(days: 1));
    if (time.isAfter(startOfToday)) {
      final hh = time.hour.toString().padLeft(2, '0');
      final mm = time.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    if (time.isAfter(startOfYesterday)) {
      return '昨天';
    }
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    return '$month-$day';
  }
}
