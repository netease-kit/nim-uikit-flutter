// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/photo.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_common_ui/widgets/update_text_info_page.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/utils/media_utils.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:provider/provider.dart';

import '../contact_kit_client.dart';
import '../l10n/S.dart';
import 'user_ai_bot_common.dart';
import 'viewmodel/user_ai_bot_form_viewmodel.dart';

class ContactKitUserAIBotFormPage extends StatefulWidget {
  final V2NIMUserAIBot? bot;

  const ContactKitUserAIBotFormPage({Key? key, this.bot}) : super(key: key);

  bool get isEdit => bot != null;

  @override
  State<ContactKitUserAIBotFormPage> createState() =>
      _ContactKitUserAIBotFormPageState();
}

class _ContactKitUserAIBotFormPageState
    extends State<ContactKitUserAIBotFormPage> {
  late final TextEditingController _nameController;
  late final String _accid;
  String? _avatar;

  @override
  void initState() {
    super.initState();
    _accid = widget.bot?.accid ?? generateDefaultUserAIBotAccid();
    _nameController = TextEditingController(
      text: widget.bot?.name ?? kDefaultUserAIBotName,
    );
    _avatar = widget.bot?.icon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<bool> _haveConnectivityForSubmit() async {
    if (ChatKitUtils.isDesktopOrWeb) {
      return true;
    }
    return haveConnectivity();
  }

  Future<void> _pickAvatar(UserAIBotFormViewModel viewModel) async {
    final path = await pickImageForPlatform(
      context,
      mobilePhotoSelector: (ctx) => showPhotoSelector(ctx),
    );
    if (path == null || !mounted || !await _haveConnectivityForSubmit()) {
      return;
    }
    final result = await viewModel.uploadAvatar(path);
    if (!mounted) return;
    if (result.isSuccess && result.data != null) {
      setState(() {
        _avatar = result.data;
      });
    } else {
      ChatUIToast.show(result.errorDetails ?? '', context: context);
    }
  }

  Future<void> _submit(UserAIBotFormViewModel viewModel) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ChatUIToast.show(S.of(context).contactRobotNameRequired,
          context: context);
      return;
    }
    if (!await _haveConnectivityForSubmit()) {
      return;
    }
    final result = widget.isEdit
        ? await viewModel.updateBot(accid: _accid, name: name, icon: _avatar)
        : await viewModel.createBot(accid: _accid, name: name, icon: _avatar);
    if (!mounted) return;
    if (result.isSuccess && result.data != null) {
      Navigator.pop(context, result.data);
    } else {
      ChatUIToast.show(result.errorDetails ?? '', context: context);
    }
  }

  Future<void> _editName() async {
    Future<bool> saveName(String value) async {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        ChatUIToast.show(S.of(context).contactRobotNameRequired,
            context: context);
        return false;
      }
      _nameController.text = trimmed;
      if (mounted) {
        setState(() {});
      }
      return true;
    }

    if (ChatKitUtils.isDesktopOrWeb) {
      await _showDesktopNameDialog(saveName);
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UpdateTextInfoPage(
            title: S.of(context).contactRobotName,
            content: _nameController.text,
            maxLength: 15,
            maxLines: 1,
            privilege: true,
            onSave: saveName,
            sureStr: S.of(context).contactSave,
          ),
        ),
      );
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showDesktopNameDialog(
    Future<bool> Function(String value) saveName,
  ) async {
    final controller = TextEditingController(text: _nameController.text);
    try {
      await showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: 400,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          S.of(context).contactRobotName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: const Color(0xFF999999),
                        onPressed: () => Navigator.pop(dialogContext),
                        tooltip: S.of(context).contactCancel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 15,
                    maxLines: 1,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: controller.clear,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(S.of(context).contactCancel),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () async {
                          final saved = await saveName(controller.text);
                          if (saved && dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                        child: Text(S.of(context).contactSave),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Widget _buildHeaderAvatar() {
    final displayName = _nameController.text.trim().isEmpty
        ? kDefaultUserAIBotName
        : _nameController.text.trim();
    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.only(right: 8),
      child: Avatar(
        width: 42,
        height: 42,
        avatar: _avatar,
        name: displayName,
        bgCode: AvatarColor.avatarColor(content: _accid),
        radius: 21,
      ),
    );
  }

  Widget _buildInfoCard(UserAIBotFormViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                S.of(context).contactRobotAvatar,
                style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
              ),
              const Spacer(),
              InkWell(
                child: Row(
                  children: [
                    _buildHeaderAvatar(),
                    SvgPicture.asset(
                      'images/ic_right_arrow.svg',
                      package: kPackage,
                      height: 16,
                      width: 16,
                    ),
                  ],
                ),
                onTap: () => _pickAvatar(viewModel),
              ),
            ],
          ),
          Container(
            height: 1,
            color: '#F5F8FC'.toColor(),
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          Row(
            children: [
              Text(
                S.of(context).contactRobotName,
                style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
              ),
              const Spacer(),
              InkWell(
                onTap: _editName,
                child: Row(
                  children: [
                    Text(
                      _nameController.text.trim().isEmpty
                          ? kDefaultUserAIBotName
                          : _nameController.text.trim(),
                      style:
                          TextStyle(fontSize: 16, color: '#999999'.toColor()),
                    ),
                    const SizedBox(width: 8),
                    SvgPicture.asset(
                      'images/ic_right_arrow.svg',
                      package: kPackage,
                      height: 16,
                      width: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget? _buildMobileAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon:
            const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF333333)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.isEdit
            ? S.of(context).contactRobotEditPageTitle
            : S.of(context).contactRobotCreate,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF333333),
        ),
      ),
      actions: [
        Consumer<UserAIBotFormViewModel>(
          builder: (context, viewModel, _) {
            return TextButton(
              onPressed:
                  viewModel.isSubmitting ? null : () => _submit(viewModel),
              child: Text(
                S.of(context).contactSave,
                style: const TextStyle(fontSize: 16, color: Color(0xFF337EFF)),
              ),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE9EFF5)),
      ),
    );
  }

  Widget _buildBody(UserAIBotFormViewModel viewModel) {
    return ListView(
      padding: const EdgeInsets.only(top: 20, bottom: 24),
      children: [
        _buildInfoCard(viewModel),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserAIBotFormViewModel(),
      builder: (context, child) {
        final viewModel = context.watch<UserAIBotFormViewModel>();
        if (ChatKitUtils.isDesktopOrWeb) {
          return Scaffold(
            backgroundColor: const Color(0xFFEFF1F4),
            appBar: _buildMobileAppBar(),
            body: _buildBody(viewModel),
          );
        }
        return Scaffold(
          backgroundColor: const Color(0xFFEFF1F4),
          appBar: _buildMobileAppBar(),
          body: _buildBody(viewModel),
        );
      },
    );
  }
}
