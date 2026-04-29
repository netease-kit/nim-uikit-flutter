// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/repo/team_repo.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/contact/contact_provider.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../chat_kit_client.dart';
import '../../l10n/S.dart';
import 'chat_date_picker_widget.dart';
import 'chat_desktop_custom_date_dialog.dart';
import 'chat_desktop_date_picker_widget.dart';
import 'chat_desktop_member_picker_overlay.dart';
import 'chat_history_date_picker_dialog.dart';
import 'chat_history_file_message_page.dart';
import 'chat_history_image_message_page.dart';
import 'chat_history_member_message_page.dart';
import 'chat_history_search_result.dart';
import 'chat_history_search_types.dart';
import 'chat_history_video_message_page.dart';
import 'chat_search_type_chip.dart';

// re-export 保持外部 import 路径兼容
export 'chat_history_search_result.dart';
export 'history_message_item.dart';

/// 历史消息页面
class ChatHistoryMessagePage extends StatefulWidget {
  final String conversationId;
  final NIMConversationType conversationType;

  /// 是否嵌入到侧边面板（嵌入时隐藏系统 AppBar，改用自定义标题栏）
  final bool isEmbedded;

  /// 嵌入模式下关闭面板的回调
  final VoidCallback? onClose;

  /// 桌面/Web 端"定位到聊天"回调，接收目标 NIMMessage 后由外层触发 ChatPage 滚动定位
  final void Function(NIMMessage)? onLocateMessage;

  const ChatHistoryMessagePage({
    Key? key,
    required this.conversationId,
    required this.conversationType,
    this.isEmbedded = false,
    this.onClose,
    this.onLocateMessage,
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

  // Task 1.2: 桌面/Web 端 Tab 选中状态（null = 未选中，关键字搜索模式）
  SearchTabType? _selectedTab;

  // Task 1.3: 日期搜索相关状态
  int? _dateStartTime;
  int? _dateEndTime;

  // Task 1.4: 类型搜索结果分页状态（文件/图片/视频用 pageToken 分页）
  List<NIMMessage>? _typeSearchMessages;
  String _typePageToken = '';
  bool _typeHasMore = false;
  bool _typeIsLoading = false;

  // 日期搜索分页锚点（getMessageListEx 用 anchorMessage 分页）
  NIMMessage? _dateAnchorMessage;

  // Task 2.1~2.3: 群成员选择状态 & 浮层
  String? _selectedMemberId;
  String? _selectedMemberName;
  final LayerLink _memberTabLayerLink = LayerLink();
  OverlayEntry? _memberPickerOverlay;

  // 日期 Tab 浮层相关
  final LayerLink _dateTabLayerLink = LayerLink();
  OverlayEntry? _datePickerOverlay;
  OverlayEntry? _customDateDialogOverlay;
  int? _dateSelectedQuickIndex; // null = 未选中快捷项，-1 = 自定义范围选中

  initState() {
    super.initState();
    if (widget.conversationType == NIMConversationType.p2p) {
      getIt<ContactProvider>()
          .getContact(
        ChatKitUtils.getConversationTargetId(widget.conversationId),
      )
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
    _closeMemberPicker(); // Task 2.9: 防止内存泄漏
    _closeDatePickerOverlay();
    _closeCustomDateDialog();
    _searchController.dispose();
    super.dispose();
  }

  // Task 3.4 / 2.3 / 2.8: 反选 Tab，恢复关键字搜索模式
  void _onTabDeselect() {
    _closeMemberPicker(); // Task 2.8: 关闭浮层
    _closeDatePickerOverlay();
    _closeCustomDateDialog();
    setState(() {
      _dateSelectedQuickIndex = null;
      _selectedTab = null;
      _dateStartTime = null;
      _dateEndTime = null;
      _typeSearchMessages = null;
      _typePageToken = '';
      _typeHasMore = false;
      _typeIsLoading = false;
      _dateAnchorMessage = null;
      // Task 2.8: 清空群成员状态
      _selectedMemberId = null;
      _selectedMemberName = null;
    });
  }

  // Task 2.3: 选中非日期 Tab
  void _onTabSelected(SearchTabType type) {
    setState(() {
      _selectedTab = type;
      _searchController.clear();
      _typeSearchMessages = null;
    });
    _searchByType(type);
  }

  // Task 5.1~5.7: 根据 Tab 类型搜索消息
  Future<void> _searchByType(SearchTabType type,
      {bool loadMore = false}) async {
    if (_typeIsLoading) return;
    if (!loadMore) {
      _typePageToken = '';
      _typeHasMore = false;
    }
    setState(() {
      _typeIsLoading = true;
    });

    // 日期搜索使用专用接口，不走 searchMessageEx
    if (type == SearchTabType.date) {
      setState(() {
        _typeIsLoading = false;
      });
      await _searchByDate(loadMore: loadMore);
      return;
    }

    List<NIMMessageType>? typeList;

    switch (type) {
      case SearchTabType.file:
        // Task 5.2
        typeList = [NIMMessageType.file];
        break;
      case SearchTabType.image:
        // Task 5.3
        typeList = [NIMMessageType.image];
        break;
      case SearchTabType.video:
        // Task 5.4
        typeList = [NIMMessageType.video];
        break;
      case SearchTabType.teamMember:
        // Task 5.6: 群成员搜索由 _onTeamMemberTabTap 单独处理
        setState(() {
          _typeIsLoading = false;
        });
        return;
      default:
        setState(() {
          _typeIsLoading = false;
        });
        return;
    }

    final params = NIMMessageSearchExParams(
      conversationId: widget.conversationId,
      messageTypes: typeList,
      pageToken: loadMore ? _typePageToken : '',
      direction: NIMSearchDirection.V2NIM_SEARCH_DIRECTION_BACKWARD,
    );

    if ((await IMKitClient.enableCloudMessageSearch) && !checkNetwork()) {
      setState(() {
        _typeIsLoading = false;
      });
      return;
    }

    final result = await ChatMessageRepo.searchMessageEx(params);
    setState(() {
      _typeIsLoading = false;
      if (result.isSuccess && result.data != null) {
        final allMsgs = <NIMMessage>[];
        for (final item in result.data!.items ?? []) {
          allMsgs.addAll(item.messages ?? []);
        }
        if (loadMore) {
          _typeSearchMessages = [...(_typeSearchMessages ?? []), ...allMsgs];
        } else {
          _typeSearchMessages = allMsgs;
        }
        _typeHasMore = result.data!.hasMore;
        _typePageToken = result.data!.nextPageToken ?? '';
      } else {
        if (!loadMore) _typeSearchMessages = [];
        _typeHasMore = false;
      }
    });
  }

  /// 日期范围搜索：调用 getMessageListEx，用 anchorMessage 实现下拉加载更多
  /// 仅在桌面/Web 端日期 Tab 下使用，不影响移动端。
  Future<void> _searchByDate({bool loadMore = false}) async {
    if (_typeIsLoading) return;
    if (!loadMore) {
      _dateAnchorMessage = null;
      _typeHasMore = false;
    }
    setState(() {
      _typeIsLoading = true;
    });

    final start = _dateStartTime;
    final end = _dateEndTime;
    if (start == null) {
      setState(() {
        _typeIsLoading = false;
        if (!loadMore) _typeSearchMessages = [];
      });
      return;
    }

    // endTime 取结束日期当天末尾（23:59:59.999），确保当天消息全部包含
    final endTime = end != null ? end : 0;

    final option = NIMMessageListOption(
      conversationId: widget.conversationId,
      beginTime: loadMore ? _dateAnchorMessage?.createTime : start,
      endTime: endTime,
      direction: NIMQueryDirection.asc,
      anchorMessage: loadMore ? _dateAnchorMessage : null,
      limit: 100,
    );

    final result = await ChatMessageRepo.getMessageListEx(
      option,
      enablePin: false,
      addUserInfo: true,
    );

    setState(() {
      _typeIsLoading = false;
      if (result.isSuccess && result.data != null) {
        final msgs = result.data!.map((c) => c.nimMessage).toList();
        if (loadMore) {
          _typeSearchMessages = [...(_typeSearchMessages ?? []), ...msgs];
        } else {
          _typeSearchMessages = msgs;
        }
        // anchorMessage 更新为本次结果最后一条，供下次加载更多使用
        _dateAnchorMessage = msgs.isNotEmpty ? msgs.last : _dateAnchorMessage;
        // 若返回条数等于 limit，则可能还有更多
        _typeHasMore = msgs.length >= 50;
      } else {
        if (!loadMore) _typeSearchMessages = [];
        _typeHasMore = false;
      }
    });
  }

  // Task 5.7: 分页加载类型搜索结果
  void _loadMoreTypeMessages() {
    if (_selectedTab == SearchTabType.date) {
      _searchByDate(loadMore: true);
    } else if (_selectedTab != null) {
      _searchByType(_selectedTab!, loadMore: true);
    }
  }

  // Task 2.7: 群成员 Tab 点击
  // 桌面/Web 端：弹出浮层；移动端：保留原有导航逻辑
  void _onTeamMemberTabTap() async {
    if (ChatKitUtils.isDesktopOrWeb) {
      // Task 2.4: 桌面端弹出浮层
      _openMemberPicker();
    } else {
      // 移动端：保留原有 goToTeamMemberList 导航逻辑
      final teamId =
          ChatKitUtils.getConversationTargetId(widget.conversationId);
      final selectedUser = await goToTeamMemberList(
        context,
        teamId,
        maxSelectMemberCount: 1,
        isMultiSelectModel: true,
        showRole: false,
        showRemoveButton: false,
      );
      if (selectedUser is List<String> && selectedUser.isNotEmpty) {
        final memberId = selectedUser.first;
        final teamInfo =
            await TeamRepo.getTeamInfo(teamId, NIMTeamType.typeNormal);
        String memberName = memberId;
        final contact = await getIt<ContactProvider>().getContact(memberId);
        if (contact != null) {
          memberName = contact.getName();
        }
        setState(() {
          _selectedTab = SearchTabType.teamMember;
          _searchController.clear();
          _typeSearchMessages = null;
        });
        await _searchByMember(memberId, teamId, teamInfo);
      }
    }
  }

  // Task 2.4: 打开成员选择浮层（桌面/Web 端）
  void _openMemberPicker() {
    // 若已有浮层则先关闭
    _closeMemberPicker();
    final teamId = ChatKitUtils.getConversationTargetId(widget.conversationId);
    _memberPickerOverlay = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            // Task 5.1: 全屏透明遮罩，点击外部关闭浮层
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeMemberPicker,
                child: const SizedBox.expand(),
              ),
            ),
            // Task 3.1 / 2.4: 浮层锚定在群成员 Tab 按钮下方，右对齐向左展开
            CompositedTransformFollower(
              link: _memberTabLayerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 4),
              child: ChatDesktopMemberPickerOverlay(
                teamId: teamId,
                onMemberSelected: _onMemberSelected,
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_memberPickerOverlay!);
  }

  // Task 2.5: 关闭成员选择浮层
  void _closeMemberPicker() {
    _memberPickerOverlay?.remove();
    _memberPickerOverlay = null;
  }

  // ─── 日期 Tab Overlay 方法 ──────────────────────────────

  /// 打开快捷日期选择浮层
  void _showDatePickerOverlay() {
    _closeDatePickerOverlay();
    _closeCustomDateDialog();
    _datePickerOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // 全屏透明遮罩，点击外部关闭
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeDatePickerOverlay,
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: _dateTabLayerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: Padding(
              // 右边距 10px，防止弹框超出屏幕右侧
              padding: EdgeInsets.only(
                right: MediaQuery.of(ctx).size.width > 0 ? 10.0 : 0.0,
              ),
              child: ChatDesktopDatePickerWidget(
                selectedIndex: _dateSelectedQuickIndex,
                onDateRangeSelected: (start, end) {
                  _closeDatePickerOverlay();
                  setState(() {
                    _selectedTab = SearchTabType.date;
                    _dateStartTime = start.millisecondsSinceEpoch;
                    _dateEndTime = end?.millisecondsSinceEpoch;
                    _searchController.clear();
                    _typeSearchMessages = null;
                  });
                  _searchByType(SearchTabType.date);
                },
                onCustomSelected: () {
                  _closeDatePickerOverlay();
                  _showCustomDateDialog();
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_datePickerOverlay!);
  }

  void _closeDatePickerOverlay() {
    _datePickerOverlay?.remove();
    _datePickerOverlay = null;
  }

  /// 打开自定义日期范围弹框（二级 Overlay）
  void _showCustomDateDialog() {
    _closeCustomDateDialog();
    _customDateDialogOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeCustomDateDialog,
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: _dateTabLayerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(-10, 4),
            child: ChatDesktopCustomDateDialog(
              onConfirm: (start, end) {
                _closeCustomDateDialog();
                setState(() {
                  _dateSelectedQuickIndex = -1;
                  _selectedTab = SearchTabType.date;
                  _dateStartTime = start.millisecondsSinceEpoch;
                  _dateEndTime = end.millisecondsSinceEpoch;
                  _searchController.clear();
                  _typeSearchMessages = null;
                });
                _searchByType(SearchTabType.date);
              },
              onCancel: _closeCustomDateDialog,
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_customDateDialogOverlay!);
  }

  void _closeCustomDateDialog() {
    _customDateDialogOverlay?.remove();
    _customDateDialogOverlay = null;
  }

  // Task 2.6: 选中成员后的处理
  void _onMemberSelected(String memberId, String memberName) {
    _closeMemberPicker();
    setState(() {
      _selectedMemberId = memberId;
      _selectedMemberName = memberName;
      _selectedTab = SearchTabType.teamMember;
      _searchController.clear();
      _typeSearchMessages = null;
    });
  }

  Future<void> _searchByMember(
      String memberId, String teamId, NIMTeam? teamInfo,
      {bool loadMore = false}) async {
    if (_typeIsLoading) return;
    if (!loadMore) {
      _typePageToken = '';
      _typeHasMore = false;
    }
    setState(() {
      _typeIsLoading = true;
    });

    final params = NIMMessageSearchExParams(
      conversationId: widget.conversationId,
      senderAccountIds: [memberId],
      direction: NIMSearchDirection.V2NIM_SEARCH_DIRECTION_BACKWARD,
      pageToken: loadMore ? _typePageToken : '',
    );

    if ((await IMKitClient.enableCloudMessageSearch) && !checkNetwork()) {
      setState(() {
        _typeIsLoading = false;
      });
      return;
    }

    final result = await ChatMessageRepo.searchMessageEx(params);
    setState(() {
      _typeIsLoading = false;
      if (result.isSuccess && result.data != null) {
        final allMsgs = <NIMMessage>[];
        for (final item in result.data!.items ?? []) {
          allMsgs.addAll(item.messages ?? []);
        }
        if (loadMore) {
          _typeSearchMessages = [...(_typeSearchMessages ?? []), ...allMsgs];
        } else {
          _typeSearchMessages = allMsgs;
        }
        _typeHasMore = result.data!.hasMore;
        _typePageToken = result.data!.nextPageToken ?? '';
      } else {
        if (!loadMore) _typeSearchMessages = [];
        _typeHasMore = false;
      }
    });
  }

  // 显示日期选择弹框，返回选定的日期范围
  Future<DatePickerResult?> _showDesktopDatePickerDialog(
      BuildContext ctx) async {
    return await showDialog<DatePickerResult>(
      context: ctx,
      barrierColor: Colors.black26,
      builder: (dialogCtx) => ChatHistoryDatePickerDialog(dialogCtx: dialogCtx),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPadding = widget.isEmbedded ? 16.0 : 20.0;
    // Task 6.1/6.2/6.3: 根据平台构建不同内容区域
    final isDesktopOrWeb = ChatKitUtils.isDesktopOrWeb;

    Widget buildContent() {
      // 移动端保持不变
      if (!isDesktopOrWeb) {
        if (_searchController.text.isNotEmpty) {
          return Expanded(
            child: HistorySearchResult(
              keyword: _searchController.text,
              conversationId: widget.conversationId,
              conversationType: widget.conversationType,
              contactInfo: contactInfo,
              searchResult: _keywordSearchMessages,
              onLoadMore: _loadMoreKeywordMessages,
              isLoading: _isLoading,
              hasMore: _hasMore,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 45),
            Center(
              child: Text(
                S.of(context).chatMessageQuickSearch,
                style: const TextStyle(fontSize: 14, color: Color(0xFFB3B7BC)),
              ),
            ),
            const SizedBox(height: 20),
            _buildQuickSearchGrid(),
          ],
        );
      }

      // 桌面/Web 端 — Tab Bar + 内容区域
      // 必须用 Expanded 包住，使内部 Column 获得有界高度，Expanded 子组件才能正常展开
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildDesktopTabBar(),
            const SizedBox(height: 4),
            if (_selectedTab != null)
              // 文件/图片/视频：直接内嵌对应的移动端页面（isEmbedded=true 跳过 AppBar）
              // 日期/群成员：继续使用 HistorySearchResult
              Expanded(child: _buildDesktopTabContent())
            else if (_searchController.text.isNotEmpty)
              // 关键字搜索结果（桌面/Web 端）
              Expanded(
                child: HistorySearchResult(
                  keyword: _searchController.text,
                  conversationId: widget.conversationId,
                  conversationType: widget.conversationType,
                  contactInfo: contactInfo,
                  searchResult: _keywordSearchMessages,
                  onLoadMore: _loadMoreKeywordMessages,
                  isLoading: _isLoading,
                  hasMore: _hasMore,
                  onClose: widget.onClose,
                  onLocateMessage: (msg) {
                    if (widget.onLocateMessage != null) {
                      widget.onLocateMessage!(msg);
                    } else {
                      if (widget.isEmbedded) {
                        widget.onClose?.call();
                      }
                      goToChatAndKeepHome(
                        context,
                        widget.conversationId,
                        widget.conversationType,
                        message: msg,
                      );
                    }
                  },
                ),
              )
            else
              // 桌面/Web 端无搜索内容时显示空白（无 Grid）
              const SizedBox.shrink(),
          ],
        ),
      );
    }

    final body = Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildSearchBar(),
          buildContent(),
        ],
      ),
    );

    if (widget.isEmbedded) {
      // 嵌入模式：自定义标题栏 + 内容
      return Material(
        color: Colors.white,
        child: Column(
          children: [
            // 嵌入模式标题栏
            Container(
              height: 48,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE8E8E8), width: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      S.of(context).chatMessageSearchHistory,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: widget.onClose,
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return TransparentScaffold(
      title: S.of(context).chatMessageSearchHistory,
      backgroundColor: Colors.white,
      body: body,
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

  // Task 3.3: 搜索栏 — 选中 Tab 时显示 chip，否则显示正常输入框
  Widget _buildSearchBar() {
    final isDesktop = widget.isEmbedded || ChatKitUtils.isDesktopOrWeb;
    final barHeight = isDesktop ? 32.0 : 36.0;
    final iconColor =
        isDesktop ? const Color(0xFFC1C8D1) : const Color(0xFFA6ADB6);

    // 桌面/Web 端且有 Tab 选中时，显示 chip 替代输入框
    if (isDesktop && _selectedTab != null) {
      final chipLabel = _getChipLabel();
      // 群成员 Chip 点击（非 × 区域）重新弹出浮层
      final VoidCallback? chipOnTap =
          _selectedTab == SearchTabType.teamMember ? _openMemberPicker : null;
      return Container(
        height: barHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F5),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        child: SearchTypeChip(
          label: chipLabel,
          onRemove: _onTabDeselect,
          onTap: chipOnTap,
        ),
      );
    }

    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: iconColor, size: 16),
          prefixIconConstraints:
              BoxConstraints(minWidth: 36, minHeight: barHeight),
          hintText: S.of(context).messageSearchHint,
          hintStyle: TextStyle(
            fontSize: 14,
            color:
                isDesktop ? const Color(0xFFB3B7BC) : const Color(0xFFA6ADB6),
          ),
          contentPadding: EdgeInsets.zero,
          isDense: true,
          suffixIcon: IconButton(
            icon: SvgPicture.asset('images/ic_clear.svg', package: kPackage),
            onPressed: () {
              _searchController.clear();
            },
          ),
        ),
        style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
        textAlignVertical: TextAlignVertical.center,
        onSubmitted: (value) {
          searchMessageByKeyword(value);
        },
      ),
    );
  }

  // Task 3.5: 获取当前选中 Tab 对应的 chip 文字
  // 日期只显示"日期"，不显示具体时间范围（per Figma）
  // 群成员显示成员名称
  String _getChipLabel() {
    switch (_selectedTab) {
      case SearchTabType.file:
        return S.of(context).chatQuickSearchFile;
      case SearchTabType.image:
        return S.of(context).chatQuickSearchPicture;
      case SearchTabType.video:
        return S.of(context).chatQuickSearchVideo;
      case SearchTabType.date:
        return S.of(context).chatQuickSearchDate;
      case SearchTabType.teamMember:
        return _selectedMemberName ?? S.of(context).chatQuickSearchTeamMember;
      case null:
        return '';
    }
  }

  // 桌面/Web 端 Tab 内容区：
  // - file/image/video → 内嵌对应页面（isEmbedded=true，无 AppBar）
  // - date/teamMember  → ChatSearchResult（通用消息列表）
  Widget _buildDesktopTabContent() {
    switch (_selectedTab) {
      case SearchTabType.file:
        return ChatHistoryFileMessagePage(
          conversationId: widget.conversationId,
          conversationType: widget.conversationType,
          isEmbedded: true,
          onLocateMessage: widget.onLocateMessage,
          onClose: widget.onClose,
        );
      case SearchTabType.image:
        return ChatHistoryImageMessagePage(
          conversationId: widget.conversationId,
          conversationType: widget.conversationType,
          isEmbedded: true,
          onLocateMessage: widget.onLocateMessage,
          onClose: widget.onClose,
        );
      case SearchTabType.video:
        return ChatHistoryVideoMessagePage(
          conversationId: widget.conversationId,
          conversationType: widget.conversationType,
          isEmbedded: true,
          onLocateMessage: widget.onLocateMessage,
          onClose: widget.onClose,
        );
      case SearchTabType.teamMember:
        // Task 4.1: 选中成员后内嵌 ChatHistoryMemberMessagePage
        if (_selectedMemberId != null) {
          return ChatHistoryMemberMessagePage(
            conversationId: widget.conversationId,
            conversationType: widget.conversationType,
            sendId: _selectedMemberId!,
            isEmbedded: true,
            onBack: _onTabDeselect,
            onLocateMessage: widget.onLocateMessage,
            onClose: widget.onClose,
          );
        }
        return const SizedBox.shrink();
      case SearchTabType.date:
        return HistorySearchResult(
          keyword: '',
          conversationId: widget.conversationId,
          conversationType: widget.conversationType,
          contactInfo: contactInfo,
          searchResult: _typeSearchMessages,
          onLoadMore: _loadMoreTypeMessages,
          isLoading: _typeIsLoading,
          hasMore: _typeHasMore,
          onClose: widget.onClose,
          onLocateMessage: (msg) {
            if (widget.onLocateMessage != null) {
              widget.onLocateMessage!(msg);
            } else {
              if (widget.isEmbedded) widget.onClose?.call();
              goToChatAndKeepHome(
                context,
                widget.conversationId,
                widget.conversationType,
                message: msg,
              );
            }
          },
        );
      case null:
        return const SizedBox.shrink();
    }
  }

  // 桌面/Web 端横排 Tab 筛选栏
  Widget _buildDesktopTabBar() {
    // Tab 顺序（从左到右）：文件、图片、视频、日期、群成员（群聊时才显示）
    final tabs = <TabItem>[
      TabItem(
        label: S.of(context).chatQuickSearchFile,
        type: SearchTabType.file,
        onTap: () => _onTabSelected(SearchTabType.file),
      ),
      TabItem(
        label: S.of(context).chatQuickSearchPicture,
        type: SearchTabType.image,
        onTap: () => _onTabSelected(SearchTabType.image),
      ),
      TabItem(
        label: S.of(context).chatQuickSearchVideo,
        type: SearchTabType.video,
        onTap: () => _onTabSelected(SearchTabType.video),
      ),
      TabItem(
        label: S.of(context).chatQuickSearchDate,
        type: SearchTabType.date,
        onTap: _showDatePickerOverlay,
      ),
      // 群成员 Tab 仅在群聊中显示，固定在最右侧
      if (widget.conversationType == NIMConversationType.team)
        TabItem(
          label: S.of(context).chatQuickSearchTeamMember,
          type: SearchTabType.teamMember,
          onTap: _onTeamMemberTabTap,
        ),
    ];

    return SizedBox(
      height: 36,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            // Task 2.2: 选中/未选中样式
            final isSelected = _selectedTab == tab.type;
            // 为群成员/日期 Tab 按钮包裹 CompositedTransformTarget
            Widget tabWidget = GestureDetector(
              onTap: tab.onTap,
              child: Container(
                margin: const EdgeInsets.only(right: 20),
                padding: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: isSelected
                        ? const BorderSide(color: Color(0xFF337EFF), width: 2)
                        : BorderSide.none,
                  ),
                ),
                child: Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected
                        ? const Color(0xFF337EFF)
                        : const Color(0xFF333333),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
            if (tab.type == SearchTabType.teamMember) {
              tabWidget = CompositedTransformTarget(
                link: _memberTabLayerLink,
                child: tabWidget,
              );
            } else if (tab.type == SearchTabType.date) {
              tabWidget = CompositedTransformTarget(
                link: _dateTabLayerLink,
                child: tabWidget,
              );
            }
            return tabWidget;
          }).toList(),
        ),
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
            final teamId = ChatKitUtils.getConversationTargetId(
              widget.conversationId,
            );
            goToTeamMemberList(
              context,
              teamId,
              maxSelectMemberCount: 1,
              isMultiSelectModel: true,
              showRole: false,
              showRemoveButton: false,
            ).then((selectedUser) async {
              if (selectedUser is List<String>) {
                final teamInfo = await TeamRepo.getTeamInfo(
                  teamId,
                  NIMTeamType.typeNormal,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatHistoryMemberMessagePage(
                      conversationId: widget.conversationId,
                      sendId: selectedUser.first,
                      teamInfo: teamInfo,
                      conversationType: widget.conversationType,
                      isEmbedded: widget.isEmbedded,
                    ),
                  ),
                );
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
              ),
            ),
          );
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
              ),
            ),
          );
        },
      },
      {
        'label': S.of(context).chatQuickSearchDate,
        'icon': 'images/ic_search_date.svg',
        'onTap': () {
          if (ChatKitUtils.isDesktopOrWeb) {
            // 桌面/Web 端：在内嵌 Navigator 中推入桌面日期选择器页面
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatHistoryDesktopDatePickerPage(
                  conversationId: widget.conversationId,
                  conversationType: widget.conversationType,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DatePickerPage()),
            ).then((select) {
              if (select is int) {
                goToChatAndKeepHome(
                  context,
                  widget.conversationId,
                  widget.conversationType,
                  anchorDate: select,
                );
              }
            });
          }
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
              ),
            ),
          );
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
                  color: const Color(
                    0xFFF9F9F9,
                  ), // Light gray background for icon
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
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
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
