// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../l10n/S.dart';

/// 桌面/Web 端快捷日期选择器
/// 提供 4 个快捷选项：今天 / 最近一周 / 最近一个月 / 自定义范围
/// 固定尺寸：宽 128px，高 144px（4 行 × 32px + 上下各 8px padding）
class ChatDesktopDatePickerWidget extends StatefulWidget {
  /// 选中快捷日期范围后的回调
  final void Function(DateTime start, DateTime? end)? onDateRangeSelected;

  /// 点击「自定义范围」时的回调（由父页面负责弹出自定义弹框）
  final VoidCallback? onCustomSelected;

  /// 当前选中的快捷选项索引（-1 表示自定义，null 表示无选中）
  final int? selectedIndex;

  const ChatDesktopDatePickerWidget({
    Key? key,
    this.onDateRangeSelected,
    this.onCustomSelected,
    this.selectedIndex,
  }) : super(key: key);

  @override
  State<ChatDesktopDatePickerWidget> createState() =>
      _ChatDesktopDatePickerWidgetState();
}

class _ChatDesktopDatePickerWidgetState
    extends State<ChatDesktopDatePickerWidget> {
  /// 内部选中状态（快捷选项索引 0-2，-1 代表自定义）
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex ?? -2; // -2 = 无选中
  }

  @override
  void didUpdateWidget(ChatDesktopDatePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _selectedIndex = widget.selectedIndex ?? -2;
    }
  }

  // 快捷日期选项（仅 3 个快捷 + 1 个自定义入口）
  List<_QuickOption> get _quickOptions => [
        _QuickOption(
          label: S.of(context).chatDateToday,
          getRange: () {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            return _DateRange(today, null);
          },
        ),
        _QuickOption(
          label: S.of(context).chatDateRecent7Days,
          getRange: () {
            final now = DateTime.now();
            final start = DateTime(now.year, now.month, now.day)
                .subtract(const Duration(days: 7));
            return _DateRange(start, null);
          },
        ),
        _QuickOption(
          label: S.of(context).chatDateRecent30Days,
          getRange: () {
            final now = DateTime.now();
            final start = DateTime(now.year, now.month, now.day)
                .subtract(const Duration(days: 30));
            return _DateRange(start, null);
          },
        ),
      ];

  void _selectQuickOption(int index) {
    final option = _quickOptions[index];
    final range = option.getRange();
    setState(() => _selectedIndex = index);
    widget.onDateRangeSelected?.call(range.start, range.end);
  }

  void _selectCustom() {
    setState(() => _selectedIndex = -1);
    widget.onCustomSelected?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: SizedBox(
        width: 128,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3 个快捷选项
              ..._quickOptions.asMap().entries.map((entry) {
                final i = entry.key;
                final opt = entry.value;
                return _buildOptionRow(
                  label: opt.label,
                  isSelected: _selectedIndex == i,
                  onTap: () => _selectQuickOption(i),
                );
              }),
              // 自定义范围入口
              _buildOptionRow(
                label: S.of(context).chatDateCustom,
                isSelected: _selectedIndex == -1,
                onTap: _selectCustom,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionRow({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 32,
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: isSelected
              ? Container(
                  width: 120,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEEEF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── 数据类 ───────────────────────────────────────────────

class _QuickOption {
  final String label;
  final _DateRange Function() getRange;

  _QuickOption({required this.label, required this.getRange});
}

class _DateRange {
  final DateTime start;
  final DateTime? end;

  _DateRange(this.start, this.end);
}
