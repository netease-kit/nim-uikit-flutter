// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/repo/config_repo.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';

import '../../l10n/S.dart';

/// 桌面端设置弹窗
/// 包含消息已读未读、云端会话、AI Stream、安全提示、云端消息搜索 5 个配置项（下拉框样式）
class DesktopSettingsDialog extends StatefulWidget {
  const DesktopSettingsDialog({Key? key}) : super(key: key);

  @override
  State<DesktopSettingsDialog> createState() => _DesktopSettingsDialogState();
}

class _DesktopSettingsDialogState extends State<DesktopSettingsDialog> {
  bool _messageReadMode = false;
  bool _enableCloudConversation = false;
  bool _enableAIStream = true;
  bool _enableSafetyTips = true;
  bool _enableCloudMessageSearch = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final messageReadMode = await ConfigRepo.getShowReadStatus();
    final enableCloudConversation = await IMKitClient.enableCloudConversation;
    final enableAIStream = await IMKitClient.enableAIStream;
    final enableSafetyTips = await IMKitClient.enableSafetyTips;
    final enableCloudMessageSearch = await IMKitClient.enableCloudMessageSearch;
    if (mounted) {
      setState(() {
        _messageReadMode = messageReadMode;
        _enableCloudConversation = enableCloudConversation;
        _enableAIStream = enableAIStream;
        _enableSafetyTips = enableSafetyTips;
        _enableCloudMessageSearch = enableCloudMessageSearch;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
              child: Row(
                children: [
                  Text(
                    S.of(context).mineSetting,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    color: const Color(0xFF8B8FA3),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),
            const Divider(height: 16, thickness: 1, color: Color(0xFFF0F2F5)),

            // 设置项列表
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    _buildDropdownRow(
                      label: S.of(context).settingMessageReadMode,
                      value: _messageReadMode,
                      onChanged: (v) {
                        ConfigRepo.updateShowReadStatus(v);
                        setState(() => _messageReadMode = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownRow(
                      label: S.of(context).localConversation,
                      // localConversation 是"本地会话"=关闭云端，所以值取反显示
                      value: !_enableCloudConversation,
                      onChanged: (v) {
                        ConfigRepo.updateEnableCloudConversations(!v);
                        ChatUIToast.show(
                          S.of(context).settingAndResetTips,
                        );
                        setState(() => _enableCloudConversation = !v);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownRow(
                      label: S.of(context).aiStreamMode,
                      value: _enableAIStream,
                      onChanged: (v) {
                        IMKitClient.setEnableAIStream(v);
                        setState(() => _enableAIStream = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownRow(
                      label: S.of(context).textSafetyNotice,
                      value: _enableSafetyTips,
                      onChanged: (v) {
                        IMKitClient.setEnableSafetyTips(v);
                        setState(() => _enableSafetyTips = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (!kIsWeb)
                      _buildDropdownRow(
                        label: S.of(context).enableCloudMessageSearch,
                        value: _enableCloudMessageSearch,
                        onChanged: (v) {
                          IMKitClient.setEnableCloudMessageSearch(v);
                          setState(() => _enableCloudMessageSearch = v);
                        },
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 带下拉框的配置行：左侧文字标签，右侧 DropdownButton（是/否）
  Widget _buildDropdownRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    // 中英文冒号：中文用"："，英文用": "
    final colon =
        Localizations.localeOf(context).languageCode == 'zh' ? '：' : ': ';
    return Row(
      children: [
        // 左侧标签，右对齐
        Expanded(
          child: Text(
            '$label$colon',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
        ),
        const SizedBox(width: 16),
        // 右侧下拉框
        SizedBox(
          width: 200,
          height: 44,
          child: _DesktopDropdown(
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// 自定义下拉框组件，样式与截图一致：白色背景 + 圆角边框 + 右侧 ∨ 图标
/// 使用 DropdownButtonFormField + InputDecoration 实现边框，
/// 下拉菜单通过 Overlay 渲染，不会被外层边框遮挡。
class _DesktopDropdown extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DesktopDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return DropdownButtonFormField<bool>(
      value: value,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: Color(0xFF8B8FA3),
        size: 20,
      ),
      style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(8),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: [
        DropdownMenuItem<bool>(
          value: true,
          child: Text(
            s.labelYes,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
          ),
        ),
        DropdownMenuItem<bool>(
          value: false,
          child: Text(
            s.labelNo,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
          ),
        ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
