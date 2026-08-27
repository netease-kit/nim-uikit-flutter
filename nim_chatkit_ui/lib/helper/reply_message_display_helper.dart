// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// Whether a reply reference should be displayed in the message list.
bool shouldDisplayReplyMessage({
  required String? replyMessageClientId,
  String? threadRootMessageClientId,
  bool hideThreadRootReply = false,
}) {
  if (replyMessageClientId?.isNotEmpty != true) {
    return false;
  }
  return !hideThreadRootReply ||
      threadRootMessageClientId?.isNotEmpty != true ||
      replyMessageClientId != threadRootMessageClientId;
}
