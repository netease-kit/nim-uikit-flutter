// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';

import '../../chat_kit_client.dart';
import '../../l10n/S.dart';

class DatePickerPage extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? minDate;
  final DateTime? maxDate;

  const DatePickerPage({
    Key? key,
    this.initialDate,
    this.minDate,
    this.maxDate,
  }) : super(key: key);

  @override
  State<DatePickerPage> createState() => _DatePickerPageState();
}

class _DatePickerPageState extends State<DatePickerPage> {
  late DateTime _selectedDate;
  late DateTime _minDate;
  late DateTime _maxDate; // 真实的最大日期
  late DateTime _displayMaxDate; // 当前列表显示的上限日期
  final ScrollController _scrollController = ScrollController();

  // 0: 自定义日期, 1: 今天, 2: 最近7天, 3: 最近30天
  int _quickOption = 0;

  // Cache month heights for sticky header calculation
  List<double> _monthHeights = [];
  double _screenWidth = 0;
  DateTime? _stickyDate;
  final double _monthHeaderHeight = 44.0; // Fixed header height
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    _selectedDate =
        widget.initialDate ?? DateTime(now.year, now.month, now.day);
    _maxDate = widget.maxDate ?? DateTime.now();
    _displayMaxDate = _maxDate;
    _minDate = widget.minDate ?? DateTime(1970, 1, 1);

    // 初始化判断是否是今天
    if (_isSameDay(_selectedDate, DateTime.now())) {
      _quickOption = 1;
    }

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_monthHeights.isEmpty || !_scrollController.hasClients) return;

    // 检查是否需要加载更多新日期（向下滚动到底部）
    if (_scrollController.offset < 500 &&
        !_isLoadingMore &&
        _displayMaxDate.isBefore(_maxDate)) {
      _loadMoreNewerDates();
    }

    // In a reverse list:
    // offset 0 is at the bottom (displaying latest items).
    // As we scroll UP (to see older items), offset INCREASES.
    // We want to find which item is at the TOP of the viewport.
    // The visual top of the list content corresponds to: scrollOffset + viewportHeight.
    final double topOffset =
        _scrollController.offset + _scrollController.position.viewportDimension;

    // Find the month item that contains 'topOffset' in the cumulative height list.
    // But wait, the list items are stacked from bottom to top?
    // No, ListView(reverse: true) lays out children starting from bottom.
    // Index 0 is at offset 0 (Bottom).
    // Index 1 is above Index 0.
    // Heights accumulate from 0 (Bottom) upwards.
    // So cumulative height from index 0 to i corresponds to offset from bottom.

    double currentHeight = 0;
    int targetIndex = -1;

    for (int i = 0; i < _monthHeights.length; i++) {
      if (topOffset >= currentHeight &&
          topOffset < currentHeight + _monthHeights[i]) {
        targetIndex = i;
        break;
      }
      currentHeight += _monthHeights[i];
    }

    if (targetIndex != -1) {
      final date =
          DateTime(_displayMaxDate.year, _displayMaxDate.month - targetIndex);
      if (_stickyDate?.year != date.year || _stickyDate?.month != date.month) {
        setState(() {
          _stickyDate = date;
        });
      }
    }
  }

  Future<void> _loadMoreNewerDates() async {
    _isLoadingMore = true;
    // 每次加载3年，或者直到最大日期
    DateTime nextDate = DateTime(_displayMaxDate.year + 3, 12, 31);
    if (nextDate.isAfter(_maxDate)) {
      nextDate = _maxDate;
    }

    // 计算新增部分的高度，用于调整滚动位置
    double addedHeight = _calculateHeightForRange(_displayMaxDate, nextDate);

    setState(() {
      _displayMaxDate = nextDate;
      _calculateMonthHeights();
    });

    // 保持视觉位置不变
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.offset + addedHeight);
      }
      _isLoadingMore = false;
    });
  }

  int _getDisplayDaysInMonth(int year, int month) {
    int days = DateUtils.getDaysInMonth(year, month);
    final now = DateTime.now();
    if (year > now.year || (year == now.year && month > now.month)) {
      return 0;
    }
    if (year == now.year && month == now.month) {
      return now.day < days ? now.day : days;
    }
    return days;
  }

  double _calculateHeightForRange(DateTime start, DateTime end) {
    if (_screenWidth == 0) return 0;

    // 计算从 start(不含) 到 end(含) 的月份高度总和
    // 注意：start 是旧的 displayMaxDate，end 是新的 displayMaxDate
    // 我们需要计算新增的月份（即比 start 更新的月份）

    int monthCount = (end.year - start.year) * 12 + end.month - start.month;
    double totalHeight = 0;
    final double cellHeight = _screenWidth / 7;

    for (int i = 0; i < monthCount; i++) {
      // 从 end 开始倒推
      DateTime monthDate = DateTime(end.year, end.month - i);
      final daysInMonth =
          _getDisplayDaysInMonth(monthDate.year, monthDate.month);
      final firstWeekday = DateTime(monthDate.year, monthDate.month, 1).weekday;
      final firstDayIndex = firstWeekday == 7 ? 0 : firstWeekday;

      int rows = ((daysInMonth + firstDayIndex) / 7).ceil();
      double gridHeight = rows * cellHeight;
      totalHeight += _monthHeaderHeight + gridHeight;
    }
    return totalHeight;
  }

  void _calculateMonthHeights() {
    if (_screenWidth == 0) return;

    int monthCount = (_displayMaxDate.year - _minDate.year) * 12 +
        _displayMaxDate.month -
        _minDate.month +
        1;
    _monthHeights = List<double>.filled(monthCount, 0);

    final double cellHeight = _screenWidth / 7;

    for (int i = 0; i < monthCount; i++) {
      DateTime monthDate =
          DateTime(_displayMaxDate.year, _displayMaxDate.month - i);
      final daysInMonth =
          _getDisplayDaysInMonth(monthDate.year, monthDate.month);
      final firstWeekday = DateTime(monthDate.year, monthDate.month, 1).weekday;
      final firstDayIndex = firstWeekday == 7 ? 0 : firstWeekday;

      int rows = ((daysInMonth + firstDayIndex) / 7).ceil();
      double gridHeight = rows * cellHeight;
      // Padding top 16 + bottom 8 + Text height (approx 20) = 44
      _monthHeights[i] = _monthHeaderHeight + gridHeight;
    }
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _onQuickOptionSelected(int option) {
    setState(() {
      _quickOption = option;
      if (option == 1) {
        //选中并定位到当前日期
        _selectedDate = DateTime.now();
        // 恢复显示范围到最新
        if (_displayMaxDate != _maxDate) {
          _displayMaxDate = _maxDate;
          _calculateMonthHeights();
        }
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      } else if (option == 2) {
        // 选中并定位到七天之前的日期
        _selectedDate = DateTime.now().subtract(const Duration(days: 7));
        // 确保选中的日期不早于最小日期
        if (_selectedDate.isBefore(_minDate)) {
          _selectedDate = _minDate;
        }
        // 恢复显示范围到最新
        if (_displayMaxDate != _maxDate) {
          _displayMaxDate = _maxDate;
          _calculateMonthHeights();
        }
        // 等待布局更新后滚动
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToMonth(_selectedDate);
        });
      } else if (option == 3) {
        // 选中并定位到30天之前的日期
        _selectedDate = DateTime.now().subtract(const Duration(days: 30));
        // 确保选中的日期不早于最小日期
        if (_selectedDate.isBefore(_minDate)) {
          _selectedDate = _minDate;
        }
        // 恢复显示范围到最新
        if (_displayMaxDate != _maxDate) {
          _displayMaxDate = _maxDate;
          _calculateMonthHeights();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToMonth(_selectedDate);
        });
      }
    });
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _MonthPickerBottomSheet(
          minDate: _minDate,
          maxDate: _maxDate,
          currentDate: _stickyDate ?? _selectedDate,
          onDateSelected: (DateTime selectedDate) {
            // 优化：如果选择的日期比较久远，重置 displayMaxDate 为该年年底
            // 这样列表长度会大大缩短，避免卡顿
            DateTime newDisplayMax = DateTime(selectedDate.year, 12, 31);
            if (newDisplayMax.isAfter(_maxDate)) {
              newDisplayMax = _maxDate;
            }

            setState(() {
              _displayMaxDate = newDisplayMax;
              _calculateMonthHeights();
            });

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToMonth(selectedDate);
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _scrollToMonth(DateTime targetDate) {
    if (!_scrollController.hasClients) return;

    // Calculate the index of the target month in the reversed list
    int monthDiff = (_displayMaxDate.year - targetDate.year) * 12 +
        (_displayMaxDate.month - targetDate.month);

    // Calculate the cumulative height up to the target month
    double targetOffset = 0;
    for (int i = 0; i < monthDiff && i < _monthHeights.length; i++) {
      targetOffset += _monthHeights[i];
    }

    // 使用 jumpTo 代替 animateTo 避免长距离滚动的性能问题
    _scrollController.jumpTo(targetOffset);
  }

  void _scrollToSpecificDate(DateTime targetDate) {
    if (!_scrollController.hasClients) return;

    // Calculate the index of the target month in the reversed list
    int monthDiff = (_displayMaxDate.year - targetDate.year) * 12 +
        (_displayMaxDate.month - targetDate.month);

    if (monthDiff < 0 || monthDiff >= _monthHeights.length) return;

    // Calculate the cumulative height up to the target month
    double targetOffset = 0;
    for (int i = 0; i < monthDiff; i++) {
      targetOffset += _monthHeights[i];
    }

    // Calculate additional offset to show the specific date within the month
    // First, add the month header height
    targetOffset += _monthHeaderHeight;

    // Calculate which week the target date is in
    final firstWeekday = DateTime(targetDate.year, targetDate.month, 1).weekday;
    final firstDayIndex = firstWeekday == 7 ? 0 : firstWeekday;
    final dayPositionInMonth = targetDate.day - 1 + firstDayIndex;
    final weekIndex = (dayPositionInMonth / 7).floor();

    // Add offset for the weeks above the target week
    final cellHeight = _screenWidth / 7;
    targetOffset += weekIndex * cellHeight;

    // Add some padding to ensure the date is visible (not at the very top)
    targetOffset += cellHeight; // One week of padding

    _scrollController.jumpTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final newWidth = MediaQuery.of(context).size.width;
    if (_screenWidth != newWidth) {
      _screenWidth = newWidth;
      _calculateMonthHeights();
      WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
    }

    return TransparentScaffold(
      title: S.of(context).chatQuickSearchByDate,
      backgroundColor: Colors.white,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, _selectedDate.millisecondsSinceEpoch);
          },
          child: Text(
            S.of(context).chatHistoryFinish,
            style:
                const TextStyle(color: CommonColors.color_337eff, fontSize: 16),
          ),
        )
      ],
      body: Column(
        children: [
          _buildQuickFilterBar(),
          if (_stickyDate != null) ...[
            GestureDetector(
                onTap: () {
                  _showMonthPicker();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        S.of(context).chatDateYearMonth(
                            _stickyDate!.year.toString(),
                            _stickyDate!.month.toString()),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF999999), // Darker for sticky header
                        ),
                      ),
                      const SizedBox(width: 4),
                      SvgPicture.asset(
                        'images/ic_arrow_down.svg',
                        package: kPackage,
                        height: 12,
                        width: 12,
                      )
                    ],
                  ),
                ))
          ],
          _buildWeekHeader(),
          Expanded(
            child: _buildCalendarList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildQuickButton(S.of(context).chatDateToday, 1),
          const SizedBox(width: 12),
          _buildQuickButton(S.of(context).chatDateRecent7Days, 2),
          const SizedBox(width: 12),
          _buildQuickButton(S.of(context).chatDateRecent30Days, 3),
        ],
      ),
    );
  }

  Widget _buildQuickButton(String text, int option) {
    final bool isSelected = _quickOption == option;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onQuickOptionSelected(option),
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? CommonColors.color_337eff : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected
                  ? CommonColors.color_337eff
                  : const Color(0xFFE5E5E5),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : CommonColors.color_333333,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekHeader() {
    final weeks = ['日', '一', '二', '三', '四', '五', '六'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weeks
            .map((w) => Text(
                  w,
                  style:
                      const TextStyle(color: Color(0xFF999999), fontSize: 12),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarList() {
    int monthCount = (_displayMaxDate.year - _minDate.year) * 12 +
        _displayMaxDate.month -
        _minDate.month +
        1;

    return ListView.builder(
      controller: _scrollController,
      itemCount: monthCount,
      reverse: true, // List starts from bottom (latest date)
      itemBuilder: (context, index) {
        // Calculate date backwards from maxDate
        // index 0 -> maxDate's month
        // index 1 -> maxDate's month - 1
        DateTime currentMonthDate =
            DateTime(_displayMaxDate.year, _displayMaxDate.month - index);
        return _buildMonthItem(currentMonthDate);
      },
    );
  }

  Widget _buildMonthItem(DateTime monthDate) {
    final daysInMonth = _getDisplayDaysInMonth(monthDate.year, monthDate.month);
    final firstWeekday = DateTime(monthDate.year, monthDate.month, 1).weekday;
    final firstDayIndex = firstWeekday == 7 ? 0 : firstWeekday;

    // Rule: show year only if month is January
    String monthText;
    if (monthDate.month == 1) {
      monthText = S.of(context).chatDateYearMonth(
          monthDate.year.toString(), monthDate.month.toString());
    } else {
      monthText = S.of(context).chatDateMonth(monthDate.month.toString());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: _monthHeaderHeight,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            monthText,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
          ),
          itemCount: daysInMonth + firstDayIndex,
          itemBuilder: (context, index) {
            if (index < firstDayIndex) {
              return Container();
            }
            final day = index - firstDayIndex + 1;
            final date = DateTime(monthDate.year, monthDate.month, day);
            return _buildDayItem(date);
          },
        ),
      ],
    );
  }

  Widget _buildDayItem(DateTime date) {
    bool isSelected = false;

    // 根据不同的快捷选项判断是否选中
    if (_quickOption == 0) {
      // 自定义日期模式，只有选中的日期高亮
      isSelected = _isSameDay(date, _selectedDate);
    } else if (_quickOption == 1) {
      // 今天模式，只有今天高亮
      isSelected = _isSameDay(date, DateTime.now());
    } else if (_quickOption == 2) {
      // 7天前模式，只有7天前的那一天高亮
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      isSelected = _isSameDay(date, sevenDaysAgo);
    } else if (_quickOption == 3) {
      // 30天前模式，只有30天前的那一天高亮
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      isSelected = _isSameDay(date, thirtyDaysAgo);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = _isSameDay(date, now);
    final isFuture = date.isAfter(today);

    if (isFuture) {
      return Container();
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
          _quickOption = 0;
          if (isToday) {
            _quickOption = 1;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? CommonColors.color_337eff : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? Colors.white : CommonColors.color_333333,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isToday)
              Text(
                S.of(context).chatDateToday,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white : CommonColors.color_337eff,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthPickerBottomSheet extends StatefulWidget {
  final DateTime minDate;
  final DateTime maxDate;
  final DateTime currentDate;
  final Function(DateTime) onDateSelected;

  const _MonthPickerBottomSheet({
    Key? key,
    required this.minDate,
    required this.maxDate,
    required this.currentDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  State<_MonthPickerBottomSheet> createState() =>
      _MonthPickerBottomSheetState();
}

class _MonthPickerBottomSheetState extends State<_MonthPickerBottomSheet> {
  late ScrollController _yearScrollController;
  late ScrollController _monthScrollController;
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.currentDate.year;
    _selectedMonth = widget.currentDate.month;
    _yearScrollController = ScrollController();
    _monthScrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedYear();
      _scrollToSelectedMonth();
    });
  }

  @override
  void dispose() {
    _yearScrollController.dispose();
    _monthScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedYear() {
    if (!_yearScrollController.hasClients) return;
    final yearIndex = _selectedYear - widget.minDate.year;
    const itemHeight = 56.0;
    final offset = yearIndex * itemHeight - 112; // Center the selection
    _yearScrollController.animateTo(
      offset.clamp(0.0, _yearScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToSelectedMonth() {
    if (!_monthScrollController.hasClients) return;
    const itemHeight = 56.0;
    final offset =
        (_selectedMonth - 1) * itemHeight - 112; // Center the selection
    _monthScrollController.animateTo(
      offset.clamp(0.0, _monthScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  List<int> _getAvailableYears() {
    List<int> years = [];
    for (int year = widget.minDate.year; year <= widget.maxDate.year; year++) {
      years.add(year);
    }
    return years;
  }

  List<int> _getAvailableMonths() {
    List<int> months = [];
    for (int month = 1; month <= 12; month++) {
      DateTime testDate = DateTime(_selectedYear, month);
      if (testDate.isAfter(widget.minDate.subtract(const Duration(days: 1))) &&
          testDate.isBefore(widget.maxDate.add(const Duration(days: 32)))) {
        months.add(month);
      }
    }
    return months;
  }

  String _getMonthName(int month) {
    const monthNames = [
      '01',
      '02',
      '03',
      '04',
      '05',
      '06',
      '07',
      '08',
      '09',
      '10',
      '11',
      '12'
    ];
    return monthNames[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildYearList()),
                Expanded(child: _buildMonthList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.close,
              size: 24,
              color: Color(0xFF999999),
            ),
          ),
          Text(
            S.of(context).chatHistorySelectChatDate,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          GestureDetector(
            onTap: () {
              widget.onDateSelected(DateTime(_selectedYear, _selectedMonth));
            },
            child: Text(
              S.of(context).chatHistoryFinish,
              style: TextStyle(
                fontSize: 16,
                color: CommonColors.color_337eff,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearList() {
    final years = _getAvailableYears();
    return ListView.builder(
      controller: _yearScrollController,
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final isSelected = year == _selectedYear;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedYear = year;
              // Check if current selected month is available for this year
              final availableMonths = _getAvailableMonths();
              if (!availableMonths.contains(_selectedMonth)) {
                _selectedMonth =
                    availableMonths.isNotEmpty ? availableMonths.first : 1;
                _scrollToSelectedMonth();
              }
            });
          },
          child: Container(
            height: 56,
            alignment: Alignment.center,
            color: isSelected ? const Color(0xFFF8F9FA) : Colors.transparent,
            child: Text(
              '$year',
              style: TextStyle(
                fontSize: 16,
                color: isSelected
                    ? CommonColors.color_337eff
                    : const Color(0xFF333333),
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthList() {
    final months = _getAvailableMonths();
    return ListView.builder(
      controller: _monthScrollController,
      itemCount: months.length,
      itemBuilder: (context, index) {
        final month = months[index];
        final isSelected = month == _selectedMonth;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedMonth = month;
            });
          },
          child: Container(
            height: 56,
            alignment: Alignment.center,
            color: isSelected ? const Color(0xFFF8F9FA) : Colors.transparent,
            child: Text(
              _getMonthName(month),
              style: TextStyle(
                fontSize: 16,
                color: isSelected
                    ? CommonColors.color_337eff
                    : const Color(0xFF333333),
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }
}
