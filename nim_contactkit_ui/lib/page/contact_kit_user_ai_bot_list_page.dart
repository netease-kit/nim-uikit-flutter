// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';

import '../contact_kit_client.dart';
import '../l10n/S.dart';
import 'contact_kit_user_ai_bot_form_page.dart';
import 'contact_kit_user_ai_bot_profile_page.dart';
import 'user_ai_bot_common.dart';
import 'viewmodel/user_ai_bot_list_viewmodel.dart';

class ContactKitUserAIBotListPage extends StatefulWidget {
  final ContactListConfig? listConfig;

  const ContactKitUserAIBotListPage({Key? key, this.listConfig})
      : super(key: key);

  @override
  State<ContactKitUserAIBotListPage> createState() =>
      _ContactKitUserAIBotListPageState();
}

class _ContactKitUserAIBotListPageState
    extends State<ContactKitUserAIBotListPage> {
  Future<void> _openCreate(UserAIBotListViewModel viewModel) async {
    if (viewModel.bots.length >= kMaxUserAIBotCount) {
      ChatUIToast.show(S.of(context).contactRobotLimitToast);
      return;
    }
    final result = await Navigator.push<V2NIMUserAIBot>(
      context,
      MaterialPageRoute(
        builder: (_) => const ContactKitUserAIBotFormPage(),
      ),
    );
    if (!mounted || result == null) return;
    viewModel.upsertBot(result);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContactKitUserAIBotProfilePage(bot: result),
      ),
    );
    if (mounted) {
      await viewModel.refresh();
    }
  }

  Future<void> _openProfile(
    UserAIBotListViewModel viewModel,
    V2NIMUserAIBot bot,
  ) async {
    final result = await Navigator.push<UserAIBotProfileResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ContactKitUserAIBotProfilePage(bot: bot),
      ),
    );
    if (!mounted || result == null) return;
    if (result.deleted) {
      viewModel.removeBot(bot.accid ?? '');
      await viewModel.refresh();
    } else if (result.changed) {
      await viewModel.refresh();
    }
  }

  Widget _buildItem(UserAIBotListViewModel viewModel, V2NIMUserAIBot bot) {
    return InkWell(
      onTap: () => _openProfile(viewModel, bot),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          children: [
            Avatar(
              width: 36,
              height: 36,
              avatar: bot.icon,
              name: bot.name ?? bot.accid,
              bgCode: AvatarColor.avatarColor(content: bot.accid),
              radius: widget.listConfig?.avatarCornerRadius,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  bot.name ?? bot.accid ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.listConfig?.nameTextSize ?? 16,
                    color: widget.listConfig?.nameTextColor ??
                        CommonColors.color_333333,
                  ),
                ),
              ),
            ),
            SvgPicture.asset(
              'images/ic_right_arrow.svg',
              package: kPackage,
              width: 16,
              height: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(UserAIBotListViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'images/ic_search_empty.svg',
            package: kPackage,
          ),
          const SizedBox(height: 12),
          Text(
            S.of(context).contactRobotEmpty,
            style: TextStyle(fontSize: 14, color: '#B3B7BC'.toColor()),
          ),
          const SizedBox(height: 6),
          Text(
            S.of(context).contactRobotEmptyHint,
            style: TextStyle(fontSize: 14, color: '#B3B7BC'.toColor()),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(UserAIBotListViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.bots.isEmpty) {
      return _buildEmpty(viewModel);
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 80) {
          viewModel.loadMore();
        }
        return false;
      },
      child: ListView.separated(
        itemBuilder: (context, index) =>
            _buildItem(viewModel, viewModel.bots[index]),
        itemCount: viewModel.bots.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: '#F5F8FC'.toColor(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserAIBotListViewModel()..init(),
      builder: (context, child) {
        final viewModel = context.watch<UserAIBotListViewModel>();
        final actions = [
          IconButton(
            onPressed: () => _openCreate(viewModel),
            icon: const Icon(Icons.add),
          ),
        ];
        final body = _buildBody(viewModel);
        if (ChatKitUtils.isDesktopOrWeb) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(S.of(context).contactMyRobot),
              centerTitle: false,
              backgroundColor: Colors.white,
              elevation: 0.5,
              actions: actions,
            ),
            body: body,
          );
        }
        return TransparentScaffold(
          backgroundColor: Colors.white,
          title: S.of(context).contactMyRobot,
          centerTitle: true,
          actions: actions,
          elevation: 0,
          body: body,
        );
      },
    );
  }
}
