// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_core_v2/nim_core.dart';

import '../../l10n/S.dart';
import 'chat_desktop_date_picker_widget.dart';
import 'chat_history_search_types.dart';

/// 历史消息日期选择弹框 Dialog Widget
/// 提供今天、最近一周、最近一个月及自定义日期范围四种快捷选项
class ChatHistoryDatePickerDialog extends StatefulWidget {
  final BuildContext dialogCtx;

  const ChatHistoryDatePickerDialog({Key? key, required this.dialogCtx})
      : super(key: key);

  @override
  State<ChatHistoryDatePickerDialog> createState() =>
      _ChatHistoryDatePickerDialogState();
}

class _ChatHistoryDatePickerDialogState
    extends State<ChatHistoryDatePickerDialog> {
  bool _showCustom = false;
  DateTime? _customStart;
  DateTime? _customEnd;

  // 时间戳工具：某天 0:00:00 的毫秒
  static int _startOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;

  // 时间戳工具：某天 23:59:59 的毫秒
  static int _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59).millisecondsSinceEpoch;

  @override
  Widget build(BuildContext buildCtx) {
    final s = S.of(buildCtx);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 用 widget.dialogCtx 来 pop，因为 build 的 context 已经是 Dialog 内部的
    final popCtx = widget.dialogCtx;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: Colors.white,
      child: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题栏
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE8E8E8), width: 0.5),
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  s.chatQuickSearchByDate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ),
            // 今天
            _buildOption(
              label: s.chatSearchToday,
              onTap: () {
                Navigator.of(popCtx).pop(DatePickerResult(
                  startTime: _startOfDay(today),
                  endTime: null,
                  label: s.chatSearchToday,
                ));
              },
            ),
            // 最近一周
            _buildOption(
              label: s.chatSearchThisWeek,
              onTap: () {
                final start = today.subtract(const Duration(days: 6));
                Navigator.of(popCtx).pop(DatePickerResult(
                  startTime: _startOfDay(start),
                  endTime: null,
                  label: s.chatSearchThisWeek,
                ));
              },
            ),
            // 最近一个月
            _buildOption(
              label: s.chatSearchThisMonth,
              onTap: () {
                final start = today.subtract(const Duration(days: 29));
                Navigator.of(popCtx).pop(DatePickerResult(
                  startTime: _startOfDay(start),
                  endTime: null,
                  label: s.chatSearchThisMonth,
                ));
              },
            ),
            // 自定义
            _buildOption(
              label: s.chatSearchCustomDateRange,
              trailing: Icon(
                _showCustom
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 16,
                color: const Color(0xFF999999),
              ),
              onTap: () {
                setState(() {
                  _showCustom = !_showCustom;
                });
              },
            ),
            if (_showCustom) _buildCustomDatePicker(popCtx),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
            if (trailing != null) ...[const Spacer(), trailing],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDatePicker(BuildContext dialogContext) {
    final fmt = DateFormat('yyyy/MM/dd');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: _customStart ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _customStart = picked;
                        if (_customEnd != null &&
                            _customEnd!.isBefore(_customStart!)) {
                          _customEnd = null;
                        }
                      });
                      _tryConfirmCustom(dialogContext);
                    }
                  },
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _customStart != null
                          ? fmt.format(_customStart!)
                          : S.of(context).chatDateStartHint,
                      style: TextStyle(
                        fontSize: 13,
                        color: _customStart != null
                            ? const Color(0xFF333333)
                            : const Color(0xFFA6ADB6),
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('—', style: TextStyle(color: Color(0xFF999999))),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: _customEnd ?? _customStart ?? DateTime.now(),
                      firstDate: _customStart ?? DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _customEnd = picked;
                      });
                      _tryConfirmCustom(dialogContext);
                    }
                  },
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _customEnd != null
                          ? fmt.format(_customEnd!)
                          : S.of(context).chatDateEndHint,
                      style: TextStyle(
                        fontSize: 13,
                        color: _customEnd != null
                            ? const Color(0xFF333333)
                            : const Color(0xFFA6ADB6),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 开始和结束都选了才确认
  void _tryConfirmCustom(BuildContext dialogContext) {
    if (_customStart != null && _customEnd != null) {
      final fmt = DateFormat('yyyy/MM/dd');
      final label = '${fmt.format(_customStart!)} - ${fmt.format(_customEnd!)}';
      Navigator.of(dialogContext).pop(DatePickerResult(
        startTime: _startOfDay(_customStart!),
        endTime: _endOfDay(_customEnd!),
        label: label,
      ));
    }
  }
}

/// 桌面/Web 端内嵌日期选择器页面（在面板内 Navigator 中使用）
class ChatHistoryDesktopDatePickerPage extends StatelessWidget {
  final String conversationId;
  final NIMConversationType conversationType;

  const ChatHistoryDesktopDatePickerPage({
    Key? key,
    required this.conversationId,
    required this.conversationType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 自定义标题栏
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
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  S.of(context).chatQuickSearchDate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
          // 日期选择器
          Expanded(
            child: SingleChildScrollView(
              child: ChatDesktopDatePickerWidget(
                onDateRangeSelected: (start, end) {
                  // 日期选定后跳转到聊天并定位到该日期
                  goToChatAndKeepHome(
                    context,
                    conversationId,
                    conversationType,
                    anchorDate: start.millisecondsSinceEpoch,
                  );
                  // 返回日期选择页面
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
