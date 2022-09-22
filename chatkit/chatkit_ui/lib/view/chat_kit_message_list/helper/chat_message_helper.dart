// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:chatkit_ui/generated/l10n.dart';
import 'package:chatkit_ui/view/chat_kit_message_list/helper/chat_message_user_helper.dart';
import 'package:corekit_im/service_locator.dart';
import 'package:corekit_im/services/login/login_service.dart';
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
          return buildUpdateTeamNotification(
              attachment as NIMUpdateTeamAttachment);
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
      return S().chat_message_unknown_notification;
    } else {
      return S().chat_message_unknown_notification;
    }
  }

  static String buildUpdateTeamNotification(
      NIMUpdateTeamAttachment attachment) {
    if (attachment.updatedFields.updatedName != null) {
      return S()
          .chat_team_notify_update_name(attachment.updatedFields.updatedName!);
    } else if (attachment.updatedFields.updatedIntroduce != null) {
      return S().chat_team_notify_update_introduction(
          attachment.updatedFields.updatedIntroduce!);
    } else if (attachment.updatedFields.updatedAnnouncement != null) {
      return S().chat_team_notice_update(
          attachment.updatedFields.updatedAnnouncement!);
    } else if (attachment.updatedFields.updatedVerifyType != null) {
      if (attachment.updatedFields.updatedVerifyType ==
          NIMVerifyTypeEnum.apply) {
        return S().chat_team_verify_update_as_need_verify;
      } else if (attachment.updatedFields.updatedVerifyType ==
          NIMVerifyTypeEnum.private) {
        return S().chat_team_verify_update_as_disallow_anyone_join;
      } else {
        return S().chat_team_verify_update_as_need_no_verify;
      }
    } else if (attachment.updatedFields.updatedExtension != null) {
      return S().chat_team_notify_update_extension(
          attachment.updatedFields.updatedExtension!);
    } else if (attachment.updatedFields.updatedServerExtension != null) {
      return S().chat_team_notify_update_extension_server(
          attachment.updatedFields.updatedServerExtension!);
    } else if (attachment.updatedFields.updatedIcon != null) {
      return S().chat_team_notify_update_team_avatar;
    } else if (attachment.updatedFields.updatedInviteMode != null) {
      return S().chat_team_invitation_permission_update(
          attachment.updatedFields.updatedInviteMode!.name);
    } else if (attachment.updatedFields.updatedUpdateMode != null) {
      return S().chat_team_modify_resource_permission_update(
          attachment.updatedFields.updatedUpdateMode!.name);
    } else if (attachment.updatedFields.updatedBeInviteMode != null) {
      return S().chat_team_invited_id_verify_permission_update(
          attachment.updatedFields.updatedBeInviteMode!.name);
    } else if (attachment.updatedFields.updatedExtensionUpdateMode != null) {
      return S().chat_team_modify_extension_permission_update(
          attachment.updatedFields.updatedExtensionUpdateMode!.name);
    } else if (attachment.updatedFields.updatedAllMuteMode != null) {
      if (attachment.updatedFields.updatedAllMuteMode ==
          NIMTeamAllMuteModeEnum.cancel) {
        return S().chat_team_cancel_all_mute;
      } else {
        return S().chat_team_full_mute;
      }
    }
    return S().chat_message_unknown_notification;
  }

  static Future<String> buildInviteMemberNotification(String tid,
      String fromAccId, NIMMemberChangeAttachment attachment) async {
    var fromName = await getTeamMemberDisplayName(tid, fromAccId);
    var memberNames = await buildMemberListString(tid, attachment.targets!,
        fromAccount: fromAccId);
    var team = (await NimCore.instance.teamService.queryTeam(tid)).data;
    if (team != null && team.type == NIMTeamTypeEnum.advanced) {
      return S().chat_advice_team_notify_invite(fromName, memberNames);
    } else {
      return S().chat_discuss_team_notify_invite(fromName, memberNames);
    }
  }

  static Future<String> buildKickMemberNotification(
      String tid, NIMMemberChangeAttachment attachment) async {
    var team = (await NimCore.instance.teamService.queryTeam(tid)).data;
    var members = await buildMemberListString(tid, attachment.targets!);
    if (team != null && team.type == NIMTeamTypeEnum.advanced) {
      return S().chat_advanced_team_notify_remove(members);
    } else {
      return S().chat_discuss_team_notify_remove(members);
    }
  }

  static Future<String> buildMemberLeaveNotification(
      String tid, String fromAccId) async {
    var team = (await NimCore.instance.teamService.queryTeam(tid)).data;
    var members = await getTeamMemberDisplayName(tid, fromAccId);
    if (team != null && team.type == NIMTeamTypeEnum.advanced) {
      return S().chat_advanced_team_notify_leave(members);
    } else {
      return S().chat_discuss_team_notify_leave(members);
    }
  }

  static Future<String> buildTeamDismissNotification(
      String tid, String fromAccId) async {
    return S().chat_team_notify_dismiss(
        await getTeamMemberDisplayName(tid, fromAccId));
  }

  static Future<String> buildManagerPassTeamApplyNotification(
      String tid, NIMMemberChangeAttachment attachment) async {
    return S().chat_team_notify_manager_pass(
        await buildMemberListString(tid, attachment.targets!));
  }

  static Future<String> buildTeamTransOwnerNotification(
      String tid, String from, NIMMemberChangeAttachment attachment) async {
    return S().chat_team_notify_trans_owner(
        (await getTeamMemberDisplayName(tid, from)),
        await buildMemberListString(tid, attachment.targets!));
  }

  static Future<String> buildTeamAddManagerNotification(
      String tid, NIMMemberChangeAttachment attachment) async {
    return S().chat_team_notify_add_manager(
        await buildMemberListString(tid, attachment.targets!));
  }

  static Future<String> buildTeamRemoveManagerNotification(
      String tid, NIMMemberChangeAttachment attachment) async {
    return S().chat_team_notify_remove_manager(
        await buildMemberListString(tid, attachment.targets!));
  }

  static Future<String> buildAcceptInviteNotification(
      String tid, String from, NIMMemberChangeAttachment attachment) async {
    return S().chat_team_notify_accept_invite(
        await buildMemberListString(tid, attachment.targets!),
        (await getTeamMemberDisplayName(tid, from)));
  }

  static Future<String> buildMuteTeamNotification(
      String tid, NIMMuteMemberAttachment attachment) async {
    if (attachment.mute) {
      return S().chat_team_notify_mute(
          await buildMemberListString(tid, attachment.targets!));
    } else {
      return S().chat_team_notify_un_mute(
          await buildMemberListString(tid, attachment.targets!));
    }
  }

  static Future<String> buildMemberListString(String tid, List<String> members,
      {String? fromAccount}) async {
    String memberList = '';
    for (var member in members) {
      if (fromAccount != member) {
        var name = await getTeamMemberDisplayName(tid, member);
        memberList = memberList + name + ',';
      }
    }
    return memberList.substring(0, memberList.length - 1);
  }

  static Future<String> getTeamMemberDisplayName(
      String tid, String accId) async {
    if (accId == getIt<LoginService>().userInfo!.userId) {
      return S().chat_message_you;
    }
    var teamNick = await getTeamMemberNick(tid, accId);
    if (teamNick != null && teamNick.isNotEmpty) {
      return teamNick;
    }
    return accId.getUserName();
  }

  static Future<String?> getTeamMemberNick(String tid, String accId) async {
    var memberResult =
        await NimCore.instance.teamService.queryTeamMember(tid, accId);
    if (memberResult.isSuccess && memberResult.data != null) {
      return memberResult.data!.teamNick;
    }
    return null;
  }
}

class ChatMessageHelper {
  static Future<String> getReplayMessageText(String replayMessageId,
      String sessionId, NIMSessionType sessionType) async {
    if (replayMessageId.isEmpty) {
      return '...';
    }
    var messageResult = await NimCore.instance.messageService
        .queryMessageListByUuid([replayMessageId], sessionId, sessionType);

    if (messageResult.isSuccess && messageResult.data?.isNotEmpty == true) {
      NIMMessage nimMessage = messageResult.data!.first;
      String nick = await nimMessage.fromAccount!.getUserName();
      String content = getReplayBrief(nimMessage);
      return '$nick : $content';
    } else {
      return '...';
    }
  }

  static String getReplayBrief(NIMMessage message) {
    String brief = 'unknown';
    switch (message.messageType) {
      case NIMMessageType.text:
        brief = message.content!;
        break;
      case NIMMessageType.image:
        brief = S().chat_message_brief_image;
        break;
      case NIMMessageType.audio:
        brief = S().chat_message_brief_audio;
        break;
      case NIMMessageType.video:
        brief = S().chat_message_brief_video;
        break;
      case NIMMessageType.location:
        brief = S().chat_message_brief_location;
        break;
      case NIMMessageType.file:
        brief = S().chat_message_brief_file;
        break;
      case NIMMessageType.avchat:
        //todo avChat
        brief = '';
        break;
      default:
        brief = S().chat_message_brief_custom;
        break;
    }
    return brief;
  }
}
