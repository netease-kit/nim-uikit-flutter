// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_core_v2/nim_core.dart';

/// 选中的会话
class SelectedBeam {
  final NIMConversationType type;

  String? conversationId;

  String? sessionId;

  String? name;

  final String? avatar;

  int? count;

  SelectedBeam(
      {required this.type,
      this.conversationId,
      this.sessionId,
      this.name,
      this.count,
      this.avatar}) {
    if (conversationId == null && sessionId != null) {
      conversationId = ChatKitUtils.conversationId(sessionId!, type);
    } else if (sessionId == null && conversationId != null) {
      sessionId = ChatKitUtils.getConversationTargetId(conversationId!);
    }
    if (name == null) {
      name = sessionId;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is SelectedBeam) {
      return conversationId == other.conversationId &&
          sessionId == other.sessionId &&
          type == other.type;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(conversationId, sessionId, type);
}
