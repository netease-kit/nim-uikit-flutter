// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/contact/contact_provider.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

/// 桌面端用户资料卡片弹出层
///
/// 使用 [OverlayEntry] 实现，浮于三栏布局之上。
/// 支持：
/// - 拖拽移动（Task 4.2）
/// - 最小化/展开切换（Task 4.3）
/// - 自身签名编辑（Task 4.4）
class UserProfilePopover {
  static const String _logTag = 'UserProfilePopover';

  static OverlayEntry? _currentEntry;

  /// 显示用户资料浮层
  ///
  /// [context] 用于获取 Overlay
  /// [accountId] 要展示的用户 ID
  /// [initialOffset] 弹出层的初始位置，可选（默认居中偏右）
  /// [onSendMessage] 点击"发消息"时的回调
  /// [onClose] 关闭时的回调
  static void show({
    required BuildContext context,
    required String accountId,
    Offset? initialOffset,
    VoidCallback? onSendMessage,
    VoidCallback? onClose,
  }) {
    // 先移除已有的弹层
    dismiss();

    final overlay = Overlay.of(context);

    _currentEntry = OverlayEntry(
      builder: (overlayContext) {
        return _UserProfilePopoverWidget(
          accountId: accountId,
          initialOffset: initialOffset ??
              Offset(
                MediaQuery.of(context).size.width * 0.5 - 160,
                MediaQuery.of(context).size.height * 0.2,
              ),
          onSendMessage: onSendMessage,
          onClose: () {
            dismiss();
            onClose?.call();
          },
        );
      },
    );

    overlay.insert(_currentEntry!);
  }

  /// 关闭当前弹层
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }

  /// 当前是否正在显示
  static bool get isShowing => _currentEntry != null;
}

class _UserProfilePopoverWidget extends StatefulWidget {
  final String accountId;
  final Offset initialOffset;
  final VoidCallback? onSendMessage;
  final VoidCallback? onClose;

  const _UserProfilePopoverWidget({
    required this.accountId,
    required this.initialOffset,
    this.onSendMessage,
    this.onClose,
  });

  @override
  State<_UserProfilePopoverWidget> createState() =>
      _UserProfilePopoverWidgetState();
}

class _UserProfilePopoverWidgetState extends State<_UserProfilePopoverWidget>
    with SingleTickerProviderStateMixin {
  static const String _logTag = 'UserProfilePopover';
  static const double _expandedWidth = 320.0;
  static const double _expandedHeight = 400.0;
  static const double _minimizedWidth = 200.0;
  static const double _minimizedHeight = 56.0;

  late Offset _offset;
  bool _isMinimized = false;
  bool _isEditingSignature = false;

  ContactInfo? _contactInfo;
  bool _isLoading = true;
  bool _isSelf = false;

  final TextEditingController _signatureController = TextEditingController();
  final FocusNode _signatureFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _offset = widget.initialOffset;
    _isSelf = widget.accountId == IMKitClient.account();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _sizeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.value = 1.0; // 初始为展开状态
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final contact =
          await getIt<ContactProvider>().getContact(widget.accountId);
      if (mounted) {
        setState(() {
          _contactInfo = contact;
          _isLoading = false;
          _signatureController.text = contact?.user.sign ?? '';
        });
      }
    } catch (e) {
      _logI('Failed to load user info: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleMinimized() {
    setState(() {
      _isMinimized = !_isMinimized;
      if (_isMinimized) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
  }

  Future<void> _saveSignature() async {
    if (!_isSelf) return;
    final newSign = _signatureController.text.trim();
    final params = NIMUserUpdateParam(sign: newSign);
    final result = await ContactRepo.updateSelfUserProfile(params);
    if (result.isSuccess) {
      _logI('Signature updated successfully');
      setState(() {
        _isEditingSignature = false;
      });
    } else {
      _logI('Failed to update signature: ${result.errorDetails}');
    }
  }

  void _logI(String content) {
    Alog.i(tag: 'ChatKit', moduleName: _logTag, content: content);
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _signatureFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _offset += details.delta;
            // 边界限制
            final screenSize = MediaQuery.of(context).size;
            final currentWidth =
                _isMinimized ? _minimizedWidth : _expandedWidth;
            final currentHeight =
                _isMinimized ? _minimizedHeight : _expandedHeight;
            _offset = Offset(
              _offset.dx.clamp(0, screenSize.width - currentWidth),
              _offset.dy.clamp(0, screenSize.height - currentHeight),
            );
          });
        },
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          shadowColor: Colors.black26,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isMinimized ? _minimizedWidth : _expandedWidth,
            height: _isMinimized ? _minimizedHeight : _expandedHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: '#E8E9EB'.toColor(), width: 0.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: _isMinimized
                ? _buildMinimizedContent()
                : _buildExpandedContent(),
          ),
        ),
      ),
    );
  }

  /// 最小化状态：只展示头像、昵称和操作按钮
  Widget _buildMinimizedContent() {
    final name = _contactInfo?.getName() ?? widget.accountId;
    final avatar = _contactInfo?.user.avatar;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Avatar(
            width: 36,
            height: 36,
            avatar: avatar,
            name: name,
            fontSize: 14,
            radius: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildIconButton(
            icon: Icons.open_in_full,
            tooltip: '展开',
            onPressed: _toggleMinimized,
          ),
          _buildIconButton(
            icon: Icons.close,
            tooltip: '关闭',
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  /// 展开状态：完整的资料卡
  Widget _buildExpandedContent() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final name = _contactInfo?.getName() ?? widget.accountId;
    final avatar = _contactInfo?.user.avatar;
    final accountId = _contactInfo?.user.accountId ?? widget.accountId;
    final sign = _contactInfo?.user.sign;

    return Column(
      children: [
        // 标题栏（可拖拽区域指示器 + 操作按钮）
        _buildTitleBar(),
        // 用户信息主体
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // 头像
                Avatar(
                  width: 72,
                  height: 72,
                  avatar: avatar,
                  name: name,
                  fontSize: 28,
                  radius: 36,
                ),
                const SizedBox(height: 12),
                // 昵称
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                // 账号 ID
                Text(
                  'ID: $accountId',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // 签名
                _buildSignatureSection(sign),
                const SizedBox(height: 24),
                // 操作按钮
                if (!_isSelf) _buildActionButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: '#F0F0F0'.toColor(), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 拖拽指示器
          Expanded(
            child: Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: '#D9D9D9'.toColor(),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          _buildIconButton(
            icon: Icons.close_fullscreen,
            tooltip: '最小化',
            onPressed: _toggleMinimized,
          ),
          _buildIconButton(
            icon: Icons.close,
            tooltip: '关闭',
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  /// 签名区域 — 自己的资料卡支持编辑
  Widget _buildSignatureSection(String? sign) {
    if (_isSelf && _isEditingSignature) {
      // 编辑模式
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: '#F7F7F7'.toColor(),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: '#337EFF'.toColor(), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _signatureController,
              focusNode: _signatureFocusNode,
              maxLines: 3,
              maxLength: 64,
              style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
              decoration: InputDecoration(
                hintText: '编辑签名...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: Color(0xFFCCCCCC)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditingSignature = false;
                      _signatureController.text = sign ?? '';
                    });
                  },
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '取消',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _saveSignature,
                  style: TextButton.styleFrom(
                    backgroundColor: '#337EFF'.toColor(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    '保存',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 展示模式
    final displaySign = (sign != null && sign.isNotEmpty) ? sign : '暂无签名';
    return InkWell(
      onTap: _isSelf
          ? () {
              setState(() {
                _isEditingSignature = true;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _signatureFocusNode.requestFocus();
              });
            }
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: '#F7F7F7'.toColor(),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.format_quote,
              size: 16,
              color: Color(0xFF999999),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displaySign,
                style: TextStyle(
                  fontSize: 13,
                  color: (sign != null && sign.isNotEmpty)
                      ? const Color(0xFF666666)
                      : const Color(0xFFCCCCCC),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_isSelf)
              const Icon(
                Icons.edit,
                size: 14,
                color: Color(0xFF999999),
              ),
          ],
        ),
      ),
    );
  }

  /// 操作按钮：发消息
  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onSendMessage,
        icon: const Icon(Icons.chat_bubble_outline, size: 16),
        label: const Text('发消息'),
        style: ElevatedButton.styleFrom(
          backgroundColor: '#337EFF'.toColor(),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: const Color(0xFF666666)),
        ),
      ),
    );
  }
}
