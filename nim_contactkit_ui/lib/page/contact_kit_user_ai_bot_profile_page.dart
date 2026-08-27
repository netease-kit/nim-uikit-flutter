// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';

import '../contact_kit_client.dart';
import '../l10n/S.dart';
import 'contact_kit_user_ai_bot_config_page.dart';
import 'contact_kit_user_ai_bot_form_page.dart';
import 'user_ai_bot_common.dart';
import 'viewmodel/user_ai_bot_profile_viewmodel.dart';

class ContactKitUserAIBotProfilePage extends StatefulWidget {
  final V2NIMUserAIBot bot;

  const ContactKitUserAIBotProfilePage({Key? key, required this.bot})
      : super(key: key);

  @override
  State<ContactKitUserAIBotProfilePage> createState() =>
      _ContactKitUserAIBotProfilePageState();
}

class _ContactKitUserAIBotProfilePageState
    extends BaseState<ContactKitUserAIBotProfilePage> {
  bool _changed = false;

  void _popProfile() {
    Navigator.pop(
      context,
      UserAIBotProfileResult(changed: _changed),
    );
  }

  Future<void> _openEdit(UserAIBotProfileViewModel viewModel) async {
    final result = await Navigator.push<V2NIMUserAIBot>(
      context,
      MaterialPageRoute(
        builder: (_) => ContactKitUserAIBotFormPage(bot: viewModel.bot),
      ),
    );
    if (!mounted || result == null) return;
    _changed = true;
    viewModel.setBot(result);
    await viewModel.fetchBot(result.accid ?? '');
  }

  Future<void> _openConfig(V2NIMUserAIBot bot) async {
    final accid = bot.accid;
    final token = bot.token;
    if (accid == null || accid.isEmpty || token == null || token.isEmpty) {
      ChatUIToast.show(S.of(context).contactRobotInvalidQrCode);
      return;
    }
    final config = buildUserAIBotConfigString(accid: accid, token: token);
    if (ChatKitUtils.isDesktopOrWeb) {
      await showDialog<void>(
        context: context,
        builder: (_) => ContactKitUserAIBotConfigDialog(config: config),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContactKitUserAIBotConfigPage(config: config),
        ),
      );
    }
  }

  Future<void> _refreshToken(UserAIBotProfileViewModel viewModel) async {
    final confirmed = await showCommonDialog(
      context: context,
      title: S.of(context).contactRobotRefreshConfirmTitle,
      content: S.of(context).contactRobotRefreshConfirmContent,
      positiveContent: S.of(context).contactRobotConfirm,
    );
    if (confirmed != true) return;
    if (!checkNetwork()) {
      return;
    }
    final result = await viewModel.refreshToken();
    if (!mounted) return;
    if (!result.isSuccess) {
      ChatUIToast.show(result.errorDetails ?? '');
    }
  }

  Future<void> _delete(UserAIBotProfileViewModel viewModel) async {
    final confirmed = await showCommonDialog(
      context: context,
      title: S.of(context).contactRobotDeleteConfirmTitle,
      content: S.of(context).contactRobotDeleteConfirmContent,
      positiveContent: S.of(context).contactRobotDeleteConfirmAction,
    );
    if (confirmed != true) return;
    if (!checkNetwork()) {
      return;
    }
    final result = await viewModel.deleteBot();
    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.pop(
        context,
        const UserAIBotProfileResult(deleted: true, changed: true),
      );
    } else {
      ChatUIToast.show(result.errorDetails ?? '');
    }
  }

  Widget _buildActionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, color: '#F5F8FC'.toColor()),
          ],
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required String title,
    required VoidCallback onTap,
    Color color = const Color(0xFF333333),
    bool showArrow = true,
    bool centerTitle = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title,
        textAlign: centerTitle ? TextAlign.center : TextAlign.left,
        style: TextStyle(fontSize: 16, color: color),
      ),
      trailing: showArrow
          ? SvgPicture.asset(
              'images/ic_right_arrow.svg',
              package: kPackage,
              width: 16,
              height: 16,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildBody(UserAIBotProfileViewModel viewModel) {
    final bot = viewModel.bot;
    if (viewModel.isLoading && bot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (bot == null) {
      return const SizedBox.shrink();
    }
    return ListView(
      padding: const EdgeInsets.only(top: 20, bottom: 24),
      children: [
        InkWell(
          onTap: () => _openEdit(viewModel),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Avatar(
                  width: 42,
                  height: 42,
                  avatar: bot.icon,
                  name: bot.name ?? bot.accid,
                  bgCode: AvatarColor.avatarColor(content: bot.accid),
                  radius: 21,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    bot.name ?? bot.accid ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF333333),
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
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: '',
          children: [
            _buildActionItem(
              title: S.of(context).contactRobotViewConfig,
              onTap: () => _openConfig(bot),
            ),
            _buildActionItem(
              title: S.of(context).contactRobotRefreshToken,
              onTap: () => _refreshToken(viewModel),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: '',
          children: [
            _buildActionItem(
              title: S.of(context).contactRobotSendMessage,
              onTap: () {
                final accid = bot.accid;
                if (accid != null && accid.isNotEmpty) {
                  goToP2pChat(context, accid);
                }
              },
              color: const Color(0xFF337EFF),
              showArrow: false,
              centerTitle: true,
            ),
            _buildActionItem(
              title: S.of(context).contactRobotDelete,
              onTap: () => _delete(viewModel),
              color: const Color(0xFFE6605C),
              showArrow: false,
              centerTitle: true,
            ),
          ],
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon:
            const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF333333)),
        onPressed: _popProfile,
      ),
      title: Text(
        S.of(context).contactRobotTitle,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF333333),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE9EFF5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserAIBotProfileViewModel()..setBot(widget.bot),
      builder: (context, child) {
        final viewModel = context.watch<UserAIBotProfileViewModel>();
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, result) async {
            if (!didPop) {
              _popProfile();
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFEFF1F4),
            appBar: _buildAppBar(),
            body: _buildBody(viewModel),
          ),
        );
      },
    );
  }
}
