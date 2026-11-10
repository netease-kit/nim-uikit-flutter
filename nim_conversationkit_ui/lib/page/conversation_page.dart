// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/duo/duo_shell_controller.dart';
import 'package:netease_common_ui/widgets/no_network_tip.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_conversationkit_ui/widgets/conversation_list.dart';
import 'package:nim_conversationkit_ui/widgets/conversation_pop_menu_button.dart';
import 'package:provider/provider.dart';

import '../l10n/S.dart';
import '../view_model/conversation_group_view_model.dart';
import '../view_model/conversation_view_model.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({
    Key? key,
    this.config,
    this.onUnreadCountChanged,
    this.topWidget,
    this.selectedConversationId,
  }) : super(key: key);

  final ValueChanged<int>? onUnreadCountChanged;
  final ConversationUIConfig? config;

  final Widget? topWidget;

  /// 桌面端：外部传入的当前选中会话 ID，用于同步高亮状态
  final String? selectedConversationId;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends BaseState<ConversationPage> {
  late ConversationTitleBarConfig _titleBarConfig;
  ConversationUIConfig get uiConfig =>
      widget.config ?? ConversationKitClient.instance.conversationUIConfig;

  @override
  void initState() {
    super.initState();
    _titleBarConfig = uiConfig.titleBarConfig;
  }

  @override
  Widget build(BuildContext context) {
    final enableCloudConversation =
        IMKitClient.isEnableCloudConversation() == true;
    final enableConversationGroup = IMKitConfigCenter.enableConversationGroup;
    final bool isDuo = DuoShellController.instance.enabled;
    final bool isDuoDual = isDuo && DuoShellController.instance.dual;
    final Widget conversationTitle = _buildConversationTitle(context);
    final Widget? searchAction = _titleBarConfig.showTitleBarRight2Icon
        ? _titleBarConfig.titleBarRight2Icon ??
            IconButton(
              onPressed: () {
                goGlobalSearchPage(context);
              },
              icon: SvgPicture.asset(
                'images/ic_search.svg',
                width: 26,
                height: 26,
                package: kPackage,
              ),
            )
        : null;
    final Widget? moreAction = _titleBarConfig.showTitleBarRightIcon
        ? _titleBarConfig.titleBarRightIcon ?? ConversationPopMenuButton()
        : null;
    final PreferredSizeWidget? appBar = _titleBarConfig.showTitleBar
        ? AppBar(
            centerTitle: _titleBarConfig.centerTitle,
            automaticallyImplyLeading: false,
            title: isDuoDual ? null : conversationTitle,
            titleSpacing: isDuoDual ? 0 : null,
            flexibleSpace: isDuoDual
                ? SafeArea(
                    bottom: false,
                    child: SizedBox.expand(
                      // 双屏左侧面板没有 leading，标题行默认从 x=0 开始，
                      // 云信 logo 会被屏幕圆角裁掉；补上与单屏一致的左边距。
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: conversationTitle,
                              ),
                            ),
                            if (searchAction != null) searchAction,
                            if (moreAction != null) moreAction,
                          ],
                        ),
                      ),
                    ),
                  )
                : null,
            elevation: 0.3,
            actions: isDuoDual
                ? const <Widget>[]
                : [
                    if (searchAction != null) searchAction,
                    if (moreAction != null) moreAction,
                  ],
          )
        : null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar == null ? null : _removeDuoRightSafeArea(context, appBar),
      body: ChangeNotifierProvider<ConversationViewModel>(
        create: (context) => ConversationViewModel(
          widget.onUnreadCountChanged,
          uiConfig.itemConfig.conversationComparator,
        ),
        builder: (context, child) {
          if (!enableCloudConversation || !enableConversationGroup) {
            return _buildConversationBody();
          }
          return ChangeNotifierProvider<ConversationGroupViewModel>(
            create: (context) => ConversationGroupViewModel(
              conversationViewModel: context.read<ConversationViewModel>(),
              context: context,
            ),
            builder: (context, child) {
              return _buildConversationBody(showGroupEntry: true);
            },
          );
        },
      ),
    );
  }

  /// Duo 折叠/双屏下页面内容区已经让出了右侧工具栏宽度，但系统上报的
  /// 右侧安全区（内屏摄像头/状态栏）比工具栏更宽。AppBar 在 primary 为
  /// true 时会自带一层 [SafeArea]，会把右侧安全区再内缩一次，导致右上角的
  /// 搜索、更多按钮无法贴齐内容区右边缘，右侧留下空隙。
  ///
  /// 这里仅在 Duo 路径去掉右侧安全区，普通 iPhone 与展开双屏的左侧列表
  /// 都以内容区右边缘为准；其他设备不受影响。
  PreferredSizeWidget _removeDuoRightSafeArea(
    BuildContext context,
    PreferredSizeWidget appBar,
  ) {
    if (!DuoShellController.instance.enabled) {
      return appBar;
    }
    return PreferredSize(
      preferredSize: appBar.preferredSize,
      child: MediaQuery.removePadding(
        context: context,
        removeRight: true,
        child: appBar,
      ),
    );
  }

  Widget _buildConversationTitle(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_titleBarConfig.showTitleBarLeftIcon)
          _titleBarConfig.titleBarLeftIcon ??
              SvgPicture.asset(
                'images/ic_yunxin.svg',
                width: 32,
                height: 32,
                package: kPackage,
              ),
        if (_titleBarConfig.showTitleBarLeftIcon) const SizedBox(width: 12),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _titleBarConfig.titleBarTitle ?? S.of(context).conversationTitle,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 20,
                color: _titleBarConfig.titleBarTitleColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversationBody({bool showGroupEntry = false}) {
    return Column(
      children: [
        if (widget.topWidget != null) widget.topWidget!,
        if (!hasNetWork) NoNetWorkTip(),
        Expanded(
          child: ConversationList(
            config: uiConfig.itemConfig,
            onUnreadCountChanged: widget.onUnreadCountChanged,
            selectedConversationId: widget.selectedConversationId,
          ),
        ),
      ],
    );
  }
}
