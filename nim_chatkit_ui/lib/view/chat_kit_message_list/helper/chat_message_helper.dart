// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:netease_corekit_im/services/team/team_provider.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/helper/chat_message_user_helper.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:nim_core/nim_core.dart';

class NotifyHelper {
  static Future<String> getNotificationText(NIMMessage message) async {
    if (message.messageAttachment is NIMTeamNotificationAttachment) {
      NIMTeamNotificationAttachment attachment =
          message.messageAttachment as NIMTeamNotificationAttachment;
      switch (attachment.type) {
        case NIMTeamNotificationTypes.inviteMember:
          return buildInviteMemberNotification(message.sessionId!,
              message.fromAccount!, attachment as NIMMemberChangeAttachment);
        case NIMTeamNotificationTypes.kickMember:
          return buildKickMemberNotification(
              message.sessionId!, attachment as NIMMemberChangeAttachment);
        case NIMTeamNotificationTypes.leaveTeam:
          return buildMemberLeaveNotification(
              message.sessionId!, message.fromAccount!);
        case NIMTeamNotificationTypes.dismissTeam:
          return buildTeamDismissNotification(
              message.sessionId!, message.fromAccount!);
        case NIMTeamNotificationTypes.updateTeam:
          return buildUpdateTeamNotification(message.sessionId!,
              message.fromAccount!, attachment as NIMUpdateTeamAttachment);
        case NIMTeamNotificationTypes.passTeamApply:
          return buildManagerPassTeamApplyNotification(
              message.sessionId!, attachment as NIMMemberChangeAttachment);
        case NIMTeamNotificationTypes.transferOwner:
          return buildTeamTransOwnerNotification(message.sessionId!,
              message.fromAccount!, attachment as NIMMemberChangeAttachment);
        case NIMTeamNotificationTypes.addTeamManager:
          return buildTeamAddManagerNotification(
              message.sessionId!, attachment as NIMMemberChangeAttachment);
        case NIMTeamNotificationTypes.removeTeamManager:
          return buildTeamRemoveManagerNotification(
              message.sessionId!, attachment as NIMMemberChangeAttachment);
        case NIMTeamNotificationTypes.acceptInvite:
          return buildAcceptInviteNotification(message.sessionId!,
              message.fromAccount!, attachment as NIMMemberChangeAttachment);
        case NIMTeamNotificationTypes.muteTeamMember:
          return buildMuteTeamNotification(
              message.sessionId!, attachment as NIMMuteMemberAttachment);
      }
      return S.of().chatMessageUnknownNotification;
    } else {
      return S.of().chatMessageUnknownNotification;
    }
  }

  static Future<String> buildUpdateTeamNotification(
      String tid, String fromAccId, NIMUpdateTeamAttachment attachment) async {
    if (attachment.updatedFields.updatedName != null) {
      var fromName = await getTeamMemberDisplayName(tid, fromAccId);
      return S.of().chatTeamNotifyUpdateName(
          fromName, attachment.updatedFields.updatedName!);
    } else if (attachment.updatedFields.updatedIntroduce != null) {
      var fromName = await getTeamMemberDisplayName(tid, fromAccId);
      return S.of().chatTeamNotifyUpdateIntroduction(fromName);
    } else if (attachment.updatedFields.updatedAnnouncement != null) {
      return S
          .of()
          .chatTeamNoticeUpdate(attachment.updatedFields.updatedAnnouncement!);
    } else if (attachment.updatedFields.updatedVerifyType != null) {
      if (attachment.updatedFields.updatedVerifyType ==
          NIMVerifyTypeEnum.apply) {
        return S.of().chatTeamVerifyUpdateAsNeedVerify;
      } else if (attachment.updatedFields.updatedVerifyType ==
          NIMVerifyTypeEnum.private) {
        return S.of().chatTeamVerifyUpdateAsDisallowAnyoneJoin;
      } else {
        return S.of().chatTeamVerifyUpdateAsNeedNoVerify;
      }
    } else if (attachment.updatedFields.updatedExtension != null) {
      return S.of().chatTeamNotifyUpdateExtension(
          attachment.updatedFields.updatedExtension!);
    } else if (attachment.updatedFields.updatedServerExtension != null) {
      return S.of().chatTeamNotifyUpdateExtensionServer(
          attachment.updatedFields.updatedServerExtension!);
    } else if (attachment.updatedFields.updatedIcon != null) {
      var fromName = await getTeamMemberDisplayName(tid, fromAccId);
      return S.of().chatTeamNotifyUpdateTeamAvatar(fromName);
    } else if (attachment.updatedFields.updatedInviteMode != null) {
      var fromName = await getTeamMemberDisplayName(tid, fromAccId);
      return S.of().chatTeamInvitationPermissionUpdate(
          fromName,
          getTeamInvitePermissionName(
              attachment.updatedFields.updatedInviteMode!));
    } else if (attachment.updatedFields.updatedUpdateMode != null) {
      var fromName = await getTeamMemberDisplayName(tid, fromAccId);
      return S.of().chatTeamModifyResourcePermissionUpdate(
          fromName,
          getTeamUpdatePermissionName(
              attachment.updatedFields.updatedUpdateMode!));
    } else if (attachment.updatedFields.updatedBeInviteMode != null) {
      return S.of().chatTeamInvitedIdVerifyPermissionUpdate(
          attachment.updatedFields.updatedBeInviteMode!.name);
    } else if (attachment.updatedFields.updatedExtensionUpdateMode != null) {
      return S.of().chatTeamModifyExtensionPermissionUpdate(
          attachment.updatedFields.updatedExtensionUpdateMode!.name);
    } else if (attachment.updatedFields.updatedAllMuteMode != null) {
      if (attachment.updatedFields.updatedAllMuteMode ==
          NIMTeamAllMuteModeEnum.cancel) {
        return S.of().chatTeamCancelAllMute;
      } else {
        return S.of().chatTeamFullMute;
      }
    }
    return S.of().chatMessageUnknownNotification;
  }

  static Future<String> buildInviteMemberNotification(String tid,
      String fromAccId, NIMMemberChangeAttachment attachment) async {
    var fromName = await getTeamMemberDisplayName(tid, fromAccId);
    var memberNames = await buildMemberListString(tid, attachment.targets!,
        fromAccount: fromAccId);
    var team = (await NimCore.instance.teamService.queryTeam(tid)).data;
    if (team != null && !getIt<TeamProvider>().isGroupTeam(team)) {
      return S.of().chatAdviceTeamNotifyInvite(fromName, memberNames);
    } else {
      return S.of().chatDiscussTeamNotifyInvite(fromName, memberNames);
    }
  }

  static Future<String> buildKickMemberNotification(
      String tid, NIMMemberChangeAttachment attachment) async {
    var team = (await NimCore.instance.teamService.queryTeam(tid)).data;
    var members = await buildMemberListString(tid, attachment.targets!);
    if (team != null && !getIt<TeamProvider>().isGroupTeam(team)) {
      return S.of().chatAdvancedTeamNotifyRemove(members);
    } else {
      return S.of().chatDiscussTeamNotifyRemove(members);
    }
  }

  static Future<String> buildMemberLeaveNotification(
      String tid, String fromAccId) async {
    var team = (await NimCore.instance.teamService.queryTeam(tid)).data;
    var members = await getTeamMemberDisplayName(tid, fromAccId);
    if (team != null && !getIt<TeamProvider>().isGroupTeam(team)) {
      return S.of().chatAdvancedTeamNotifyLeave(members);
    } else {
      return S.of().chatDiscussTeamNotifyLeave(members);
    }
  }

  static Future<String> buildTeamDismissNotification(
      String tid, String fromAccId) async {
    return S
        .of()
        .chatTeamNotifyDismiss(await getTeamMemberDisplayName(tid, fromAccId));
  }

  static Future<String> buildManagerPassTeamApplyNotification(
      String tid, NIMMemberChangeAttachment attachment) async {
    return S.of().chatTeamNotifyManagerPass(
        await buildMemberListString(tid, attachment.targets!));
  }

  static Future<String> buildTeamTransOwnerNotification(
      String tid, String from, NIMMemberChangeAttachment attachment) async {
    return S.of().chatTeamNotifyTransOwner(
        (await getTeamMemberDisplayName(tid, from)),
        await buildMemberListString(tid, attachment.targets!));
  }

  static Future<String> buildTeamAddManagerNotification(
      String tid, NIMMemberChangeAttachment attachment) async {
    return S.of().chatTeamNotifyAddManager(
        await buildMemberListString(tid, attachment.targets!));
  }

  static Future<String> buildTeamRemoveManagerNotification(
      String tid, NIMMemberChangeAttachment attachment) async {
    return S.of().chatTeamNotifyRemoveManager(
        await buildMemberListString(tid, attachment.targets!));
  }

  static Future<String> buildAcceptInviteNotification(
      String tid, String from, NIMMemberChangeAttachment attachment) async {
    return S.of().chatTeamNotifyAcceptInvite(
        await buildMemberListString(tid, attachment.targets!),
        (await getTeamMemberDisplayName(tid, from)));
  }

  static Future<String> buildMuteTeamNotification(
      String tid, NIMMuteMemberAttachment attachment) async {
    if (attachment.mute) {
      return S.of().chatTeamNotifyMute(
          await buildMemberListString(tid, attachment.targets!));
    } else {
      return S.of().chatTeamNotifyUnMute(
          await buildMemberListString(tid, attachment.targets!));
    }
  }

  static Future<String> buildMemberListString(String tid, List<String> members,
      {String? fromAccount}) async {
    String memberList = '';
    for (var member in members) {
      if (fromAccount != member) {
        var name = await getTeamMemberDisplayName(tid, member);
        memberList = memberList + name + '、';
      }
    }
    return memberList.substring(0, memberList.length - 1);
  }

  static Future<String> getTeamMemberDisplayName(
      String tid, String accId) async {
    if (accId == getIt<LoginService>().userInfo!.userId) {
      return S.of().chatMessageYou;
    }
    return getUserNickInTeam(tid, accId);
  }

  static Future<String?> getTeamMemberNick(String tid, String accId) async {
    var memberResult =
        await NimCore.instance.teamService.queryTeamMember(tid, accId);
    if (memberResult.isSuccess && memberResult.data != null) {
      return memberResult.data!.teamNick;
    }
    return null;
  }

  static String getTeamInvitePermissionName(NIMTeamInviteModeEnum mode) {
    return mode == NIMTeamInviteModeEnum.all
        ? S.of().chatTeamPermissionInviteAll
        : S.of().chatTeamPermissionInviteOnlyOwner;
  }

  static String getTeamUpdatePermissionName(NIMTeamUpdateModeEnum mode) {
    return mode == NIMTeamUpdateModeEnum.all
        ? S.of().chatTeamPermissionUpdateAll
        : S.of().chatTeamPermissionUpdateOnlyOwner;
  }
}

class ChatMessageHelper {
  static Future<String> getReplayMessageText(
      BuildContext context,
      String replayMessageId,
      String sessionId,
      NIMSessionType sessionType) async {
    if (replayMessageId.isEmpty) {
      return '';
    }
    var messageResult = await NimCore.instance.messageService
        .queryMessageListByUuid([replayMessageId], sessionId, sessionType);

    if (messageResult.isSuccess) {
      if (messageResult.data?.isNotEmpty == true) {
        NIMMessage nimMessage = messageResult.data!.first;
        String nick = nimMessage.sessionType == NIMSessionType.p2p
            ? await nimMessage.fromAccount!.getUserName()
            : await getUserNickInTeam(
                nimMessage.sessionId!, nimMessage.fromAccount!,
                showAlias: false);
        String content = getReplayBrief(nimMessage);
        return '$nick : $content';
      } else {
        return S.of(context).chatMessageHaveBeenRevokedOrDelete;
      }
    } else {
      return '';
    }
  }

  static String getReplayBrief(NIMMessage message) {
    String brief = 'unknown';
    switch (message.messageType) {
      case NIMMessageType.text:
        brief = message.content!;
        break;
      case NIMMessageType.image:
        brief = S.of().chatMessageBriefImage;
        break;
      case NIMMessageType.audio:
        brief = S.of().chatMessageBriefAudio;
        break;
      case NIMMessageType.video:
        brief = S.of().chatMessageBriefVideo;
        break;
      case NIMMessageType.location:
        brief = S.of().chatMessageBriefLocation;
        break;
      case NIMMessageType.file:
        brief = S.of().chatMessageBriefFile;
        break;
      case NIMMessageType.avchat:
        //todo avChat
        brief = '';
        break;
      default:
        brief = S.of().chatMessageBriefCustom;
        break;
    }
    return brief;
  }
}
