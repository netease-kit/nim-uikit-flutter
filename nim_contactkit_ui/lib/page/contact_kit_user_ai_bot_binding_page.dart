// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
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
import 'viewmodel/user_ai_bot_binding_viewmodel.dart';

class ContactKitUserAIBotBindingPage extends StatefulWidget {
  final String qrCode;

  const ContactKitUserAIBotBindingPage({Key? key, required this.qrCode})
      : super(key: key);

  @override
  State<ContactKitUserAIBotBindingPage> createState() =>
      _ContactKitUserAIBotBindingPageState();
}

class _ContactKitUserAIBotBindingPageState
    extends State<ContactKitUserAIBotBindingPage> {
  String _bindErrorMessage(NIMResult<V2NIMUserAIBot> result) {
    if (result.code == kUserAIBotBindQrCodeAlreadyBoundCode) {
      return S.of(context).contactRobotQrCodeBound;
    }
    if (result.code == kUserAIBotBindQrCodeNotFoundCode) {
      return S.of(context).contactRobotQrCodeExpired;
    }
    return result.errorDetails ?? '';
  }

  Future<void> _bind(
    UserAIBotBindingViewModel viewModel,
    V2NIMUserAIBot bot, {
    bool showConfirmation = true,
  }) async {
    if (!await haveConnectivity()) {
      return;
    }
    if (showConfirmation) {
      final confirmed = await showCommonDialog(
        context: context,
        title: S.of(context).contactRobotBindConfirmTitle,
        content: S.of(context).contactRobotBindConfirmContent,
        positiveContent: S.of(context).contactRobotConfirm,
      );
      if (confirmed != true) return;
    }
    final result = await viewModel.bind(widget.qrCode, bot);
    if (!mounted) return;
    if (result.isSuccess && result.data != null) {
      ChatUIToast.show(S.of(context).contactRobotBindingSuccess);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ContactKitUserAIBotProfilePage(bot: result.data!),
        ),
      );
    } else {
      ChatUIToast.show(_bindErrorMessage(result));
    }
  }

  Future<void> _createAndBind(UserAIBotBindingViewModel viewModel) async {
    if (!await haveConnectivity()) {
      return;
    }
    if (viewModel.hasReachedLimit) {
      ChatUIToast.show(S.of(context).contactRobotLimitToast);
      return;
    }
    final bot = await Navigator.push<V2NIMUserAIBot>(
      context,
      MaterialPageRoute(
        builder: (_) => const ContactKitUserAIBotFormPage(),
      ),
    );
    if (!mounted || bot == null) return;
    viewModel.addBot(bot);
    await _bind(viewModel, bot, showConfirmation: false);
  }

  Widget _buildBotItem(
    UserAIBotBindingViewModel viewModel,
    V2NIMUserAIBot bot,
  ) {
    return InkWell(
      onTap: () => _bind(viewModel, bot),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Avatar(
              width: 36,
              height: 36,
              avatar: bot.icon,
              name: bot.name ?? bot.accid,
              bgCode: AvatarColor.avatarColor(content: bot.accid),
              radius: 18,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(bot.name ?? bot.accid ?? '')),
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

  Widget _buildBody(UserAIBotBindingViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        InkWell(
          onTap: () => _createAndBind(viewModel),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.add, color: Color(0xFF337EFF)),
                const SizedBox(width: 8),
                Expanded(child: Text(S.of(context).contactRobotBindNew)),
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
        const SizedBox(height: 16),
        Text(
          S.of(context).contactRobotBindExistingHint,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        ...viewModel.bots.map(
          (bot) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildBotItem(viewModel, bot),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserAIBotBindingViewModel()..loadBots(),
      builder: (context, child) {
        final viewModel = context.watch<UserAIBotBindingViewModel>();
        final body = _buildBody(viewModel);
        if (ChatKitUtils.isDesktopOrWeb) {
          return Scaffold(
            backgroundColor: const Color(0xFFEFF1F4),
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(S.of(context).contactRobotBind),
              centerTitle: false,
              backgroundColor: Colors.white,
              elevation: 0.5,
            ),
            body: body,
          );
        }
        return TransparentScaffold(
          backgroundColor: const Color(0xFFEFF1F4),
          title: S.of(context).contactRobotBind,
          body: body,
        );
      },
    );
  }
}
