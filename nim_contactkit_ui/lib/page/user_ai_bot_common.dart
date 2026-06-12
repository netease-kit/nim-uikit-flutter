// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:uuid/uuid.dart';

const String kDefaultUserAIBotName = 'Bot_Claw';
const int kMaxUserAIBotCount = 10;
const int kUserAIBotPageLimit = 20;
const int kUserAIBotBindQrCodeNotFoundCode = 102309;
const int kUserAIBotBindQrCodeAlreadyBoundCode = 102311;

class UserAIBotProfileResult {
  final bool deleted;
  final bool changed;

  const UserAIBotProfileResult({
    this.deleted = false,
    this.changed = false,
  });
}

class UserAIBotLimitAction {
  final bool keepOnList;

  const UserAIBotLimitAction({this.keepOnList = true});
}

String generateDefaultUserAIBotAccid() {
  final uuid = const Uuid().v4().replaceAll('-', '');
  return 'Bot_${uuid.substring(0, 28)}';
}

String buildUserAIBotConfigString({
  required String accid,
  required String token,
}) {
  return '${IMKitClient.appKey ?? ''}|$accid|$token';
}

String maskUserAIBotConfigString(String config) {
  if (config.isEmpty) {
    return config;
  }
  final visibleLength = (config.length / 3).ceil().clamp(1, config.length);
  return '${config.substring(0, visibleLength)}...';
}

String? normalizeUserAIBotQrCode(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}

void sortUserAIBotsByCreateTimeDesc(List<V2NIMUserAIBot> bots) {
  bots.sort((a, b) {
    final createCompare = (b.createTime ?? 0).compareTo(a.createTime ?? 0);
    if (createCompare != 0) {
      return createCompare;
    }
    return (b.updateTime ?? 0).compareTo(a.updateTime ?? 0);
  });
}

Future<String?> ensureUserAIBotConversationVisible(String accid) async {
  final conversationIdResult =
      await NimCore.instance.conversationIdUtil.p2pConversationId(accid);
  final conversationId = conversationIdResult.data;
  if (conversationId == null || conversationId.isEmpty) {
    return null;
  }
  final enableCloudConversation = await IMKitClient.enableCloudConversation;
  final result = enableCloudConversation
      ? await NimCore.instance.conversationService.createConversation(
          conversationId,
        )
      : await NimCore.instance.localConversationService.createConversation(
          conversationId,
        );
  if (!result.isSuccess) {
    final existed = enableCloudConversation
        ? await NimCore.instance.conversationService.getConversation(
            conversationId,
          )
        : await NimCore.instance.localConversationService.getConversation(
            conversationId,
          );
    if (!existed.isSuccess) {
      return null;
    }
  }
  return conversationId;
}

Future<NIMResult<String>> uploadUserAIBotAvatar(String filePath) async {
  final task = await NimCore.instance.storageService.createUploadFileTask(
    NIMUploadFileParams(filePath: filePath),
  );
  if (!task.isSuccess || task.data == null) {
    return NIMResult.failure(message: task.errorDetails);
  }
  final uploadResult = await NimCore.instance.storageService.uploadFile(
    task.data!,
  );
  if (!uploadResult.isSuccess || uploadResult.data?.isEmpty != false) {
    return NIMResult.failure(message: uploadResult.errorDetails);
  }
  return NIMResult.success(data: uploadResult.data);
}
