// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:nim_core_v2/nim_core.dart';

enum ConversationGroupKind {
  all,
  aitMe,
  unread,
  custom,
}

class ConversationGroupUiModel {
  static const String allId = 'ui_all';
  static const String aitMeId = 'ui_ait_me';
  static const String unreadId = 'ui_unread';

  final String id;
  final ConversationGroupKind kind;
  final String name;
  final bool visible;
  final int sortOrder;
  final V2NIMConversationGroup? sdkGroup;

  const ConversationGroupUiModel({
    required this.id,
    required this.kind,
    required this.name,
    required this.visible,
    required this.sortOrder,
    this.sdkGroup,
  });

  bool get isDefault => kind != ConversationGroupKind.custom;

  bool get isCustom => kind == ConversationGroupKind.custom;

  bool get canHide => kind != ConversationGroupKind.all;

  bool get canDelete => kind == ConversationGroupKind.custom;

  bool get canSetting => kind == ConversationGroupKind.custom;

  bool get fixedFirst => kind == ConversationGroupKind.all;

  ConversationGroupUiModel copyWith({
    String? name,
    bool? visible,
    int? sortOrder,
    V2NIMConversationGroup? sdkGroup,
  }) {
    return ConversationGroupUiModel(
      id: id,
      kind: kind,
      name: name ?? this.name,
      visible: visible ?? this.visible,
      sortOrder: sortOrder ?? this.sortOrder,
      sdkGroup: sdkGroup ?? this.sdkGroup,
    );
  }
}
