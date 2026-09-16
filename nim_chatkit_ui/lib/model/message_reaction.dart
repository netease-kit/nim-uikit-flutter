// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

///单个表情快捷回复的聚合状态
class MessageReactionSummary {
  MessageReactionSummary({
    required this.index,
    Iterable<String> operatorIds = const <String>[],
    Map<String, int> operatorCreateTimes = const <String, int>{},
    this.pending = false,
  })  : operatorIds = Set<String>.unmodifiable(operatorIds),
        operatorCreateTimes = Map<String, int>.unmodifiable({
          for (final id in operatorIds)
            if ((operatorCreateTimes[id] ?? 0) > 0)
              id: operatorCreateTimes[id]!,
        });

  final int index;
  final Set<String> operatorIds;

  /// 每位回复人的创建时间，保留明细以便取消回复后重新计算顺序。
  final Map<String, int> operatorCreateTimes;
  final bool pending;

  /// 当前表情仍有效回复中的最早创建时间；历史数据缺失时间时为 null。
  int? get createTime {
    int? earliest;
    for (final time in operatorCreateTimes.values) {
      if (earliest == null || time < earliest) earliest = time;
    }
    return earliest;
  }

  int get count => operatorIds.length;

  bool contains(String? accountId) {
    return accountId?.isNotEmpty == true && operatorIds.contains(accountId);
  }

  MessageReactionSummary copyWith({
    Iterable<String>? operatorIds,
    Map<String, int>? operatorCreateTimes,
    bool? pending,
  }) {
    return MessageReactionSummary(
      index: index,
      operatorIds: operatorIds ?? this.operatorIds,
      operatorCreateTimes: operatorCreateTimes ?? this.operatorCreateTimes,
      pending: pending ?? this.pending,
    );
  }
}

///一条消息的表情快捷回复状态
class MessageReactionState {
  MessageReactionState({
    Map<int, MessageReactionSummary> summaries =
        const <int, MessageReactionSummary>{},
    this.loaded = false,
    this.loading = false,
    this.version = 0,
  }) : summaries = Map<int, MessageReactionSummary>.unmodifiable(summaries);

  static final MessageReactionState empty = MessageReactionState();

  final Map<int, MessageReactionSummary> summaries;
  final bool loaded;
  final bool loading;
  final int version;

  MessageReactionState copyWith({
    Map<int, MessageReactionSummary>? summaries,
    bool? loaded,
    bool? loading,
    int? version,
  }) {
    return MessageReactionState(
      summaries: summaries ?? this.summaries,
      loaded: loaded ?? this.loaded,
      loading: loading ?? this.loading,
      version: version ?? this.version,
    );
  }
}

///快捷回复资源的固定索引配置
class MessageReactionConfig {
  MessageReactionConfig._();

  static const List<int> quickIndexes = <int>[3, 5, 1, 21, 65, 19, 20];
  static final List<int> allIndexes =
      List<int>.unmodifiable(List<int>.generate(112, (index) => index + 1));
  static final Set<int> supportedIndexes = allIndexes.toSet();

  static String assetPath(int index) {
    return 'reaction_emoji/${index.toString().padLeft(3, '0')}.png';
  }

  static int sortOrder(int index) {
    final quickIndex = quickIndexes.indexOf(index);
    return quickIndex >= 0 ? quickIndex : quickIndexes.length + index;
  }
}
