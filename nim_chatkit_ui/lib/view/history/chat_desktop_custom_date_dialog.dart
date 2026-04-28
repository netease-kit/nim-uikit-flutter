// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../chat_kit_client.dart';
import '../../l10n/S.dart';

/// 桌面/Web 端自定义日期范围弹框
/// 宽 200px，主视图高 ~126px（2 行日期 + 按钮行）
/// 点击日期行切换到内联日历选择视图，选完后切回主视图
class ChatDesktopCustomDateDialog extends StatefulWidget {
  /// 点击「确定」时回调，传入起止日期
  final void Function(DateTime start, DateTime end) onConfirm;

  /// 点击「取消」时回调
  final VoidCallback onCancel;

  const ChatDesktopCustomDateDialog({
    Key? key,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<ChatDesktopCustomDateDialog> createState() =>
      _ChatDesktopCustomDateDialogState();
}

class _ChatDesktopCustomDateDialogState
    extends State<ChatDesktopCustomDateDialog> {
  DateTime? _startDate;
  DateTime? _endDate;

  /// true = 日历视图展开中，false = 主视图（日期输入）
  bool _showingCalendar = false;

  /// true = 正在选起始日期，false = 正在选结束日期
  bool _editingStart = true;

  /// 日历当前展示的月份
  late DateTime _calendarMonth;

  /// 确定按钮是否可点
  bool get _isValid =>
      _startDate != null && _endDate != null && !_startDate!.isAfter(_endDate!);

  @override
  void initState() {
    super.initState();
    _calendarMonth = DateTime.now();
  }

  void _openCalendarForStart() {
    setState(() {
      _editingStart = true;
      _calendarMonth = _startDate != null ? _startDate! : DateTime.now();
      _showingCalendar = true;
    });
  }

  void _openCalendarForEnd() {
    setState(() {
      _editingStart = false;
      _calendarMonth = _endDate ?? _startDate ?? DateTime.now();
      _showingCalendar = true;
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      if (_editingStart) {
        // 起始日期保留日历传入的 00:00:00（当天开始），覆盖该天开头的消息
        _startDate = date;
        // 若结束日期早于新起始日期则清除
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      } else {
        // 结束日期归一到当天的 23:59:59.999，确保包含该天所有消息
        _endDate = DateTime(
          date.year,
          date.month,
          date.day,
          23,
          59,
          59,
          999,
        );
      }
      _showingCalendar = false;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return S.of(context).chatDatePlaceholder;
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6E6E6), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40858C8C),
            blurRadius: 7,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: _showingCalendar ? _buildCalendarView() : _buildMainView(),
        ),
      ),
    );
  }

  // ─── 主视图（日期输入） ───────────────────────────────

  Widget _buildMainView() {
    return KeyedSubtree(
      key: const ValueKey('main'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 起始日期输入框
          _buildDateInputBox(
            hint: S.of(context).chatDateStart,
            date: _startDate,
            onTap: _openCalendarForStart,
          ),
          // 分隔线
          const Divider(color: Color(0xFFE6E6E6), height: 1, thickness: 1),
          // 结束日期输入框
          _buildDateInputBox(
            hint: S.of(context).chatDateEnd,
            date: _endDate,
            onTap: _openCalendarForEnd,
          ),
          // 分隔线
          const Divider(color: Color(0xFFE6E6E6), height: 1, thickness: 1),
          // 操作按钮行
          _buildButtonRow(),
        ],
      ),
    );
  }

  /// 日期输入框行：左侧文字/日期值 + 右侧日历图标
  Widget _buildDateInputBox({
    required String hint,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final hasValue = date != null;
    final displayText = hasValue ? DateFormat('yyyy-MM-dd').format(date) : hint;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: 12,
                  color: hasValue
                      ? const Color(0xFF333333)
                      : const Color(0xFF999999),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(
              'images/ic_chat_desktop_date.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                Color(0xFF656A72),
                BlendMode.srcIn,
              ),
              package: kPackage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 取消按钮：有描边无背景
          _buildActionButton(
            label: S.of(context).chatDateCancel,
            onPressed: widget.onCancel,
            isConfirm: false,
          ),
          const SizedBox(width: 8),
          // 确定按钮：蓝色实底
          _buildActionButton(
            label: S.of(context).chatDateConfirm,
            onPressed: _isValid
                ? () => widget.onConfirm(_startDate!, _endDate!)
                : null,
            isConfirm: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isConfirm,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          color: isConfirm
              ? (onPressed != null
                  ? const Color(0xFF2A6BF2)
                  : const Color(0xFF2A6BF2).withOpacity(0.4))
              : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: isConfirm
              ? null
              : Border.all(color: const Color(0xFFD9D9D9), width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isConfirm ? Colors.white : const Color(0xFF333333),
          ),
        ),
      ),
    );
  }

  // ─── 日历视图 ───────────────────────────────────────────

  Widget _buildCalendarView() {
    return KeyedSubtree(
      key: const ValueKey('calendar'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部返回按钮 + 标题
          SizedBox(
            height: 40,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      size: 14, color: Color(0xFF666666)),
                  onPressed: () => setState(() => _showingCalendar = false),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  constraints: const BoxConstraints(),
                ),
                Text(
                  _editingStart
                      ? S.of(context).chatDateStart
                      : S.of(context).chatDateEnd,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFE8E8E8), height: 1, thickness: 1),
          // 日历组件
          _buildCalendarPicker(),
        ],
      ),
    );
  }

  Widget _buildCalendarPicker() {
    return _InlineCalendar(
      displayMonth: _calendarMonth,
      selectedStart: _startDate,
      selectedEnd: _endDate,
      editingStart: _editingStart,
      onMonthChanged: (month) => setState(() => _calendarMonth = month),
      onDateSelected: _onDateSelected,
    );
  }
}

// ─── 内联日历组件 ─────────────────────────────────────────

class _InlineCalendar extends StatelessWidget {
  final DateTime displayMonth;
  final DateTime? selectedStart;
  final DateTime? selectedEnd;
  final bool editingStart;
  final void Function(DateTime) onMonthChanged;
  final void Function(DateTime) onDateSelected;

  const _InlineCalendar({
    Key? key,
    required this.displayMonth,
    this.selectedStart,
    this.selectedEnd,
    required this.editingStart,
    required this.onMonthChanged,
    required this.onDateSelected,
  }) : super(key: key);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isSelected(DateTime date) {
    final start = selectedStart;
    final end = selectedEnd;
    if (start != null && _isSameDay(date, start)) return true;
    if (end != null && _isSameDay(date, end)) return true;
    return false;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isInRange(DateTime date) {
    final start = selectedStart;
    final end = selectedEnd;
    if (start == null || end == null) return false;
    return date.isAfter(start) && date.isBefore(end);
  }

  bool _isDisabled(DateTime date) {
    // 选结束日期时，不能早于起始日期
    if (!editingStart && selectedStart != null) {
      final startDay = DateTime(
          selectedStart!.year, selectedStart!.month, selectedStart!.day);
      final thisDay = DateTime(date.year, date.month, date.day);
      return thisDay.isBefore(startDay);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateUtils.getDaysInMonth(displayMonth.year, displayMonth.month);
    final firstWeekday =
        DateTime(displayMonth.year, displayMonth.month, 1).weekday;
    // Dart weekday: Mon=1, Sun=7; 转换为以周日为第一列
    final firstDayOffset = firstWeekday == 7 ? 0 : firstWeekday;
    final weekLabels = ['日', '一', '二', '三', '四', '五', '六'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 月份导航
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 18),
                onPressed: () => onMonthChanged(
                    DateTime(displayMonth.year, displayMonth.month - 1)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
              Text(
                DateFormat('yyyy年M月').format(displayMonth),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 18),
                onPressed: () => onMonthChanged(
                    DateTime(displayMonth.year, displayMonth.month + 1)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
          // 星期表头
          Row(
            children: weekLabels
                .map((w) => Expanded(
                      child: Center(
                        child: Text(
                          w,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 2),
          // 日期格子
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 0,
              childAspectRatio: 1.2,
            ),
            itemCount: firstDayOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstDayOffset) return const SizedBox();
              final day = index - firstDayOffset + 1;
              final date = DateTime(displayMonth.year, displayMonth.month, day);
              final selected = _isSelected(date);
              final inRange = _isInRange(date);
              final disabled = _isDisabled(date);
              final isToday = _isToday(date);
              return GestureDetector(
                onTap: disabled ? null : () => onDateSelected(date),
                child: Container(
                  decoration: selected
                      ? BoxDecoration(
                          color: const Color(0xFF2A6BF2),
                          borderRadius: BorderRadius.circular(4),
                        )
                      : inRange
                          ? BoxDecoration(
                              color: const Color(0xFF2A6BF2).withOpacity(0.1),
                            )
                          : null,
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        // 优先级：禁用 > 选中（白字蓝底）> 今日（蓝字）> 普通（深灰）
                        color: disabled
                            ? const Color(0xFFCCCCCC)
                            : selected
                                ? Colors.white
                                : isToday
                                    ? const Color(0xFF2A6BF2)
                                    : const Color(0xFF333333),
                        fontWeight: isToday && !selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
