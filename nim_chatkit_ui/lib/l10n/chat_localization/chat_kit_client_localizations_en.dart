// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'chat_kit_client_localizations.dart';

/// The translations for English (`en`).
class ChatKitClientLocalizationsEn extends ChatKitClientLocalizations {
  ChatKitClientLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String chatMessageSendHint(String userName) {
    return 'Send to $userName';
  }

  @override
  String get chatPressedToSpeak => 'Pressed to speak';

  @override
  String get chatMessageVoiceIn =>
      'Release to send, hold and swipe to an empty area to cancel';

  @override
  String get chatMessagePickPhoto => 'Pick photo';

  @override
  String get chatMessagePickVideo => 'Pick video';

  @override
  String get chatMessageMoreShoot => 'Shooting';

  @override
  String get chatMessageTakePhoto => 'Take photo';

  @override
  String get chatMessageTakeVideo => 'Take video';

  @override
  String get chatMessageNonsupport => 'Nonsupport message Type';

  @override
  String get chatMessageMoreFile => 'File';

  @override
  String get chatMessageMoreLocation => 'Location';

  @override
  String get chatMessageAMapNotFound => 'ALi Map not found';

  @override
  String get chatMessageTencentMapNotFound => 'Tencent Map not found';

  @override
  String get chatMessageAMap => 'ALi Map';

  @override
  String get chatMessageTencentMap => 'Tencent Map';

  @override
  String get chatMessageUnknownType => 'Unknown Type';

  @override
  String get chatMessageImageSave => 'Image saved successfully';

  @override
  String get chatMessageImageSaveFail => 'Failed to save image';

  @override
  String get chatMessageVideoSave => 'Video saved successfully';

  @override
  String get chatMessageVideoSaveFail => 'Failed to save video';

  @override
  String get chatMessageActionCopy => 'copy';

  @override
  String get chatMessageActionReply => 'reply';

  @override
  String get chatMessageActionForward => 'forward';

  @override
  String get chatMessageActionPin => 'pin';

  @override
  String get chatMessageActionUnPin => 'unPin';

  @override
  String get chatMessageActionMultiSelect => 'multiSelect';

  @override
  String get chatMessageActionCollect => 'collect';

  @override
  String get chatMessageActionDelete => 'delete';

  @override
  String get chatMessageActionRevoke => 'revoke';

  @override
  String get chatMessageCopySuccess => 'Copy Success';

  @override
  String get chatMessageCollectSuccess => 'Collect Success';

  @override
  String get chatMessageDeleteConfirm => 'Delete this message?';

  @override
  String get chatMessageRevokeConfirm => 'Revoke this message?';

  @override
  String get chatMessageHaveBeenRevokedOrDelete =>
      'this message have been revoked or deleted';

  @override
  String chatMessagePinMessage(String userName) {
    return 'Pined by $userName，visible to both of you';
  }

  @override
  String chatMessagePinMessageForTeam(String userName) {
    return 'Pined by $userName，visible to everyone';
  }

  @override
  String get chatMessageHaveBeenRevoked => 'Message revoked';

  @override
  String get chatMessageReedit => ' Reedit >';

  @override
  String get chatMessageRevokeOverTime => 'Over Time,Revoke failed';

  @override
  String get chatMessageRevokeFailed => 'Revoke failed';

  @override
  String chatMessageReplySomeone(String content) {
    return 'Reply $content';
  }

  @override
  String get chatMessageBriefImage => '[Image]';

  @override
  String get chatMessageBriefAudio => '[Audio]';

  @override
  String get chatMessageBriefVideo => '[Video]';

  @override
  String get chatMessageBriefLocation => '[Location]';

  @override
  String get chatMessageBriefFile => '[File]';

  @override
  String get chatMessageBriefCustom => '[Custom Message]';

  @override
  String get chatMessageBriefChatHistory => '[Chat History]';

  @override
  String get chatSetting => 'Chat setting';

  @override
  String get chatMessageSignal => 'Message mark';

  @override
  String get chatMessageOpenMessageNotice => 'Open message notice';

  @override
  String get chatMessageSetTop => 'Set session top';

  @override
  String get chatMessageSend => 'Send';

  @override
  String chatAdviceTeamNotifyInvite(String user, String members) {
    return '$user had invited $members to join the team';
  }

  @override
  String chatDiscussTeamNotifyInvite(String user, String members) {
    return '$user invited $members join discuss team';
  }

  @override
  String chatDiscussTeamNotifyRemove(String users) {
    return '$users have been removed from discuss team';
  }

  @override
  String chatAdvancedTeamNotifyRemove(String users) {
    return '$users have been removed from team';
  }

  @override
  String chatDiscussTeamNotifyLeave(String users) {
    return '${users}have left discuss team';
  }

  @override
  String chatAdvancedTeamNotifyLeave(String user) {
    return '$user had exited team';
  }

  @override
  String chatTeamNotifyDismiss(String users) {
    return '${users}dismissed team';
  }

  @override
  String chatTeamNotifyManagerPass(String members) {
    return 'Manager accepted $members team apply';
  }

  @override
  String chatTeamNotifyTransOwner(String members, String user) {
    return '$user transfer owner to $members';
  }

  @override
  String chatTeamNotifyAddManager(String member) {
    return '$member set as manager';
  }

  @override
  String chatTeamNotifyRemoveManager(String member) {
    return '${member}remove from managers';
  }

  @override
  String chatTeamNotifyAcceptInvite(String members, String user) {
    return '$user accept $members\'s invite and join';
  }

  @override
  String chatTeamNotifyMute(String user) {
    return '$user mute by manager';
  }

  @override
  String chatTeamNotifyUnMute(String user) {
    return '$user un mute by manager';
  }

  @override
  String get chatMessageUnknownNotification => 'Unknown Notification';

  @override
  String chatTeamNotifyUpdateName(String user, String name) {
    return '$user had updated team name:\"$name\"';
  }

  @override
  String chatTeamNotifyUpdateIntroduction(String user) {
    return '$user had updated team introduction';
  }

  @override
  String chatTeamNoticeUpdate(String notice) {
    return 'team announcement update as $notice';
  }

  @override
  String get chatTeamVerifyUpdateAsNeedVerify => 'update as need verify';

  @override
  String get chatTeamVerifyUpdateAsNeedNoVerify => 'update as need no verify';

  @override
  String get chatTeamVerifyUpdateAsDisallowAnyoneJoin =>
      'update as disallow anyone join';

  @override
  String chatTeamNotifyUpdateExtension(String name) {
    return 'team extension update as $name';
  }

  @override
  String chatTeamNotifyUpdateExtensionServer(String name) {
    return 'team extension (server) update as$name';
  }

  @override
  String chatTeamNotifyUpdateTeamAvatar(String user) {
    return '$user had updated team avatar';
  }

  @override
  String chatTeamInvitationPermissionUpdate(String user, String permission) {
    return '$user had updated team invite permission:\"$permission\"';
  }

  @override
  String chatTeamModifyResourcePermissionUpdate(
      String user, String permission) {
    return '$user had updated team resource permission: \"$permission\"';
  }

  @override
  String chatTeamInvitedIdVerifyPermissionUpdate(String permission) {
    return 'team invited verify update as $permission';
  }

  @override
  String chatTeamModifyExtensionPermissionUpdate(String permission) {
    return 'team extension update permission as $permission';
  }

  @override
  String get chatTeamAllMute => 'Mute';

  @override
  String get chatTeamCancelAllMute => 'cancel all mute';

  @override
  String get chatTeamFullMute => 'mute all';

  @override
  String chatTeamUpdate(String key, String value) {
    return 'team $key updated as $value';
  }

  @override
  String get chatMessageYou => 'you';

  @override
  String get messageSearchTitle => 'Search History';

  @override
  String get messageSearchHint => 'Search chat content';

  @override
  String get messageSearchEmpty => 'No chat history';

  @override
  String get messageForwardToP2p => 'Forward to person';

  @override
  String get messageForwardToTeam => 'Forward to team';

  @override
  String get messageForwardTo => 'Send to';

  @override
  String get messageCancel => 'Cancel';

  @override
  String messageForwardMessageTips(String user) {
    return '[Forward]$user message';
  }

  @override
  String get messageReadStatus => 'Message read status';

  @override
  String messageReadWithNumber(String num) {
    return 'Read ($num)';
  }

  @override
  String messageUnreadWithNumber(String num) {
    return 'Unread ($num)';
  }

  @override
  String get messageAllRead => 'All member have read';

  @override
  String get messageAllUnread => 'All member unread';

  @override
  String get chatIsTyping => 'Is Typing';

  @override
  String get chatMessageAitContactTitle => 'Choose a reminder';

  @override
  String get chatTeamAitAll => 'All';

  @override
  String chatMessageFileSizeOverLimit(String size) {
    return 'Oops! File size limit ${size}M.';
  }

  @override
  String get chatTeamPermissionInviteAll => 'all';

  @override
  String get chatTeamPermissionInviteOnlyOwner => 'owner';

  @override
  String get chatTeamPermissionUpdateAll => 'all';

  @override
  String get chatTeamPermissionUpdateOnlyOwner => 'owner';

  @override
  String get microphoneDeniedTips => 'Please give your phone micro permission';

  @override
  String get locationDeniedTips => 'Please give your location permission';

  @override
  String get chatSpeakTooShort => 'Talk too short';

  @override
  String get chatTeamBeRemovedTitle => 'Tip';

  @override
  String get chatTeamBeRemovedContent => 'This group is disbanded';

  @override
  String get chatMessageSendFailedByBlackList =>
      'Send failed, you are in the blacklist';

  @override
  String get chatHaveNoPinMessage => 'No pinned message';

  @override
  String get chatMessageMergeForward => 'Merge Forward';

  @override
  String get chatMessageItemsForward => 'Items Forward';

  @override
  String chatMessageMergedTitle(String user) {
    return '${user}History Message';
  }

  @override
  String get chatMessageChatHistory => 'Chat History';

  @override
  String get chatMessagePostScript => 'Post Script';

  @override
  String get chatMessageMergeMessageError => 'System Error，Forward Error';

  @override
  String get chatMessageInputTitle => 'Input Title';

  @override
  String get chatMessageNotSupportEmptyMessage => 'Not support empty message';

  @override
  String chatMessageMergedForwardLimitOut(String number) {
    return 'Merge message limit$number';
  }

  @override
  String chatMessageForwardOneByOneLimitOut(String number) {
    return 'Forward message one by one limit$number';
  }

  @override
  String messageForwardMessageOneByOneTips(String user) {
    return '[Forward One by One]${user}Chat History';
  }

  @override
  String messageForwardMessageMergedTips(String user) {
    return '[Merged Forward]${user}Chat History';
  }

  @override
  String get chatMessageHaveMessageCantForward =>
      'There are messages that cannot be forwarded';

  @override
  String get chatMessageInfoError => 'Message info error';

  @override
  String get chatMessageMergeDepthOut =>
      'The message exceeds the merging limit and cannot be forwarded as is. Should it be sent without merging?';

  @override
  String get chatMessageExitMessageCannotForward =>
      'Exit message cannot be forwarded';

  @override
  String get chatTeamPermissionInviteOnlyOwnerAndManagers =>
      'Owner and managers';

  @override
  String get chatTeamPermissionUpdateOnlyOwnerAndManagers =>
      'Owner and managers';

  @override
  String get chatTeamHaveBeenKick => 'You have been kicked';

  @override
  String get chatMessageHaveCannotForwardMessages =>
      'There are messages that cannot be forwarded';
}
