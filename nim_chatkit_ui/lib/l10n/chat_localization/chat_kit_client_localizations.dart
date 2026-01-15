// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'chat_kit_client_localizations_en.dart';
import 'chat_kit_client_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ChatKitClientLocalizations
/// returned by `ChatKitClientLocalizations.of(context)`.
///
/// Applications need to include `ChatKitClientLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'chat_localization/chat_kit_client_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ChatKitClientLocalizations.localizationsDelegates,
///   supportedLocales: ChatKitClientLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the ChatKitClientLocalizations.supportedLocales
/// property.
abstract class ChatKitClientLocalizations {
  ChatKitClientLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ChatKitClientLocalizations? of(BuildContext context) {
    return Localizations.of<ChatKitClientLocalizations>(
        context, ChatKitClientLocalizations);
  }

  static const LocalizationsDelegate<ChatKitClientLocalizations> delegate =
      _ChatKitClientLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @chatMessageSendHint.
  ///
  /// In en, this message translates to:
  /// **'Send to {userName}'**
  String chatMessageSendHint(String userName);

  /// No description provided for @chatPressedToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Pressed to speak'**
  String get chatPressedToSpeak;

  /// No description provided for @chatMessageVoiceIn.
  ///
  /// In en, this message translates to:
  /// **'Release to send, hold and swipe to an empty area to cancel'**
  String get chatMessageVoiceIn;

  /// No description provided for @chatMessagePickPhoto.
  ///
  /// In en, this message translates to:
  /// **'Pick photo'**
  String get chatMessagePickPhoto;

  /// No description provided for @chatMessagePickVideo.
  ///
  /// In en, this message translates to:
  /// **'Pick video'**
  String get chatMessagePickVideo;

  /// No description provided for @chatMessageMoreShoot.
  ///
  /// In en, this message translates to:
  /// **'Shooting'**
  String get chatMessageMoreShoot;

  /// No description provided for @chatMessageTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get chatMessageTakePhoto;

  /// No description provided for @chatMessageTakeVideo.
  ///
  /// In en, this message translates to:
  /// **'Take video'**
  String get chatMessageTakeVideo;

  /// No description provided for @chatMessageNonsupport.
  ///
  /// In en, this message translates to:
  /// **'Nonsupport message Type'**
  String get chatMessageNonsupport;

  /// No description provided for @chatMessageMoreFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get chatMessageMoreFile;

  /// No description provided for @chatMessageMoreTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get chatMessageMoreTranslate;

  /// No description provided for @chatTranslateTo.
  ///
  /// In en, this message translates to:
  /// **'Translate to'**
  String get chatTranslateTo;

  /// No description provided for @chatTranslateSure.
  ///
  /// In en, this message translates to:
  /// **'AI Translate'**
  String get chatTranslateSure;

  /// No description provided for @chatTranslating.
  ///
  /// In en, this message translates to:
  /// **'AI Translating...'**
  String get chatTranslating;

  /// No description provided for @chatTranslateUse.
  ///
  /// In en, this message translates to:
  /// **'Translate to'**
  String get chatTranslateUse;

  /// No description provided for @chatTranslateLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Use↓'**
  String get chatTranslateLanguageTitle;

  /// No description provided for @chatMessageMoreLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get chatMessageMoreLocation;

  /// No description provided for @chatMessageAMapNotFound.
  ///
  /// In en, this message translates to:
  /// **'ALi Map not found'**
  String get chatMessageAMapNotFound;

  /// No description provided for @chatMessageTencentMapNotFound.
  ///
  /// In en, this message translates to:
  /// **'Tencent Map not found'**
  String get chatMessageTencentMapNotFound;

  /// No description provided for @chatMessageAMap.
  ///
  /// In en, this message translates to:
  /// **'ALi Map'**
  String get chatMessageAMap;

  /// No description provided for @chatMessageTencentMap.
  ///
  /// In en, this message translates to:
  /// **'Tencent Map'**
  String get chatMessageTencentMap;

  /// No description provided for @chatMessageUnknownType.
  ///
  /// In en, this message translates to:
  /// **'Unknown Type'**
  String get chatMessageUnknownType;

  /// No description provided for @chatMessageImageSave.
  ///
  /// In en, this message translates to:
  /// **'Image saved successfully'**
  String get chatMessageImageSave;

  /// No description provided for @chatMessageImageSaveFail.
  ///
  /// In en, this message translates to:
  /// **'Failed to save image'**
  String get chatMessageImageSaveFail;

  /// No description provided for @chatMessageVideoSave.
  ///
  /// In en, this message translates to:
  /// **'Video saved successfully'**
  String get chatMessageVideoSave;

  /// No description provided for @chatMessageVideoSaveFail.
  ///
  /// In en, this message translates to:
  /// **'Failed to save video'**
  String get chatMessageVideoSaveFail;

  /// No description provided for @chatMessageActionCopy.
  ///
  /// In en, this message translates to:
  /// **'copy'**
  String get chatMessageActionCopy;

  /// No description provided for @chatMessageActionReply.
  ///
  /// In en, this message translates to:
  /// **'reply'**
  String get chatMessageActionReply;

  /// No description provided for @chatMessageActionForward.
  ///
  /// In en, this message translates to:
  /// **'forward'**
  String get chatMessageActionForward;

  /// No description provided for @chatMessageActionPin.
  ///
  /// In en, this message translates to:
  /// **'pin'**
  String get chatMessageActionPin;

  /// No description provided for @chatMessageActionUnPin.
  ///
  /// In en, this message translates to:
  /// **'unPin'**
  String get chatMessageActionUnPin;

  /// No description provided for @chatMessageActionMultiSelect.
  ///
  /// In en, this message translates to:
  /// **'multiSelect'**
  String get chatMessageActionMultiSelect;

  /// No description provided for @chatMessageActionCollect.
  ///
  /// In en, this message translates to:
  /// **'collect'**
  String get chatMessageActionCollect;

  /// No description provided for @chatMessageActionDelete.
  ///
  /// In en, this message translates to:
  /// **'delete'**
  String get chatMessageActionDelete;

  /// No description provided for @chatMessageActionRevoke.
  ///
  /// In en, this message translates to:
  /// **'revoke'**
  String get chatMessageActionRevoke;

  /// No description provided for @chatMessageCopySuccess.
  ///
  /// In en, this message translates to:
  /// **'Copy Success'**
  String get chatMessageCopySuccess;

  /// No description provided for @chatMessageCollectSuccess.
  ///
  /// In en, this message translates to:
  /// **'Collect Success'**
  String get chatMessageCollectSuccess;

  /// No description provided for @chatMessageDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this message?'**
  String get chatMessageDeleteConfirm;

  /// No description provided for @chatMessageRevokeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Revoke this message?'**
  String get chatMessageRevokeConfirm;

  /// No description provided for @chatMessageHaveBeenRevokedOrDelete.
  ///
  /// In en, this message translates to:
  /// **'this message have been revoked or deleted'**
  String get chatMessageHaveBeenRevokedOrDelete;

  /// No description provided for @chatMessagePinMessage.
  ///
  /// In en, this message translates to:
  /// **'Pined by {userName}，visible to both of you'**
  String chatMessagePinMessage(String userName);

  /// No description provided for @chatMessagePinMessageForTeam.
  ///
  /// In en, this message translates to:
  /// **'Pined by {userName}，visible to everyone'**
  String chatMessagePinMessageForTeam(String userName);

  /// No description provided for @chatMessageHaveBeenRevoked.
  ///
  /// In en, this message translates to:
  /// **'Message revoked'**
  String get chatMessageHaveBeenRevoked;

  /// No description provided for @chatMessageReedit.
  ///
  /// In en, this message translates to:
  /// **' Reedit >'**
  String get chatMessageReedit;

  /// No description provided for @chatMessageRevokeOverTime.
  ///
  /// In en, this message translates to:
  /// **'Over Time,Revoke failed'**
  String get chatMessageRevokeOverTime;

  /// No description provided for @chatMessageRevokeFailed.
  ///
  /// In en, this message translates to:
  /// **'Revoke failed'**
  String get chatMessageRevokeFailed;

  /// No description provided for @chatMessageReplySomeone.
  ///
  /// In en, this message translates to:
  /// **'Reply {content}'**
  String chatMessageReplySomeone(String content);

  /// No description provided for @chatMessageBriefImage.
  ///
  /// In en, this message translates to:
  /// **'[Image]'**
  String get chatMessageBriefImage;

  /// No description provided for @chatMessageBriefAudio.
  ///
  /// In en, this message translates to:
  /// **'[Audio]'**
  String get chatMessageBriefAudio;

  /// No description provided for @chatMessageBriefVideo.
  ///
  /// In en, this message translates to:
  /// **'[Video]'**
  String get chatMessageBriefVideo;

  /// No description provided for @chatMessageBriefLocation.
  ///
  /// In en, this message translates to:
  /// **'[Location]'**
  String get chatMessageBriefLocation;

  /// No description provided for @chatMessageBriefFile.
  ///
  /// In en, this message translates to:
  /// **'[File]'**
  String get chatMessageBriefFile;

  /// No description provided for @chatMessageBriefCustom.
  ///
  /// In en, this message translates to:
  /// **'[Custom Message]'**
  String get chatMessageBriefCustom;

  /// No description provided for @chatMessageBriefChatHistory.
  ///
  /// In en, this message translates to:
  /// **'[Chat History]'**
  String get chatMessageBriefChatHistory;

  /// No description provided for @chatSetting.
  ///
  /// In en, this message translates to:
  /// **'Chat setting'**
  String get chatSetting;

  /// No description provided for @chatMessageSignal.
  ///
  /// In en, this message translates to:
  /// **'Message mark'**
  String get chatMessageSignal;

  /// No description provided for @chatMessageOpenMessageNotice.
  ///
  /// In en, this message translates to:
  /// **'Open message notice'**
  String get chatMessageOpenMessageNotice;

  /// No description provided for @chatMessageSetTop.
  ///
  /// In en, this message translates to:
  /// **'Set session top'**
  String get chatMessageSetTop;

  /// No description provided for @chatMessageSetPin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get chatMessageSetPin;

  /// No description provided for @chatMessageSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatMessageSend;

  /// No description provided for @chatAdviceTeamNotifyInvite.
  ///
  /// In en, this message translates to:
  /// **'{user} had invited {members} to join the team'**
  String chatAdviceTeamNotifyInvite(String user, String members);

  /// No description provided for @chatDiscussTeamNotifyInvite.
  ///
  /// In en, this message translates to:
  /// **'{user} invited {members} join discuss team'**
  String chatDiscussTeamNotifyInvite(String user, String members);

  /// No description provided for @chatDiscussTeamNotifyRemove.
  ///
  /// In en, this message translates to:
  /// **'{users} have been removed from discuss team'**
  String chatDiscussTeamNotifyRemove(String users);

  /// No description provided for @chatAdvancedTeamNotifyRemove.
  ///
  /// In en, this message translates to:
  /// **'{users} have been removed from team'**
  String chatAdvancedTeamNotifyRemove(String users);

  /// No description provided for @chatDiscussTeamNotifyLeave.
  ///
  /// In en, this message translates to:
  /// **'{users}have left discuss team'**
  String chatDiscussTeamNotifyLeave(String users);

  /// No description provided for @chatAdvancedTeamNotifyLeave.
  ///
  /// In en, this message translates to:
  /// **'{user} had exited team'**
  String chatAdvancedTeamNotifyLeave(String user);

  /// No description provided for @chatTeamNotifyDismiss.
  ///
  /// In en, this message translates to:
  /// **'{users}dismissed team'**
  String chatTeamNotifyDismiss(String users);

  /// No description provided for @chatTeamNotifyManagerPass.
  ///
  /// In en, this message translates to:
  /// **'Manager accepted {members} team apply'**
  String chatTeamNotifyManagerPass(String members);

  /// No description provided for @chatTeamNotifyTransOwner.
  ///
  /// In en, this message translates to:
  /// **'{user} transfer owner to {members}'**
  String chatTeamNotifyTransOwner(String members, String user);

  /// No description provided for @chatTeamNotifyAddManager.
  ///
  /// In en, this message translates to:
  /// **'{member} set as manager'**
  String chatTeamNotifyAddManager(String member);

  /// No description provided for @chatTeamNotifyRemoveManager.
  ///
  /// In en, this message translates to:
  /// **'{member}remove from managers'**
  String chatTeamNotifyRemoveManager(String member);

  /// No description provided for @chatTeamNotifyAcceptInvite.
  ///
  /// In en, this message translates to:
  /// **'{user} accept {members}\'s invite and join'**
  String chatTeamNotifyAcceptInvite(String members, String user);

  /// No description provided for @chatTeamNotifyMute.
  ///
  /// In en, this message translates to:
  /// **'{user} mute by manager'**
  String chatTeamNotifyMute(String user);

  /// No description provided for @chatTeamNotifyUnMute.
  ///
  /// In en, this message translates to:
  /// **'{user} un mute by manager'**
  String chatTeamNotifyUnMute(String user);

  /// No description provided for @chatMessageUnknownNotification.
  ///
  /// In en, this message translates to:
  /// **'Unknown Notification'**
  String get chatMessageUnknownNotification;

  /// No description provided for @chatTeamNotifyUpdateName.
  ///
  /// In en, this message translates to:
  /// **'{user} had updated team name:\"{name}\"'**
  String chatTeamNotifyUpdateName(String user, String name);

  /// No description provided for @chatTeamNotifyUpdateIntroduction.
  ///
  /// In en, this message translates to:
  /// **'{user} had updated team introduction'**
  String chatTeamNotifyUpdateIntroduction(String user);

  /// No description provided for @chatTeamNoticeUpdate.
  ///
  /// In en, this message translates to:
  /// **'team announcement update as {notice}'**
  String chatTeamNoticeUpdate(String notice);

  /// No description provided for @chatTeamVerifyUpdateAsNeedVerify.
  ///
  /// In en, this message translates to:
  /// **'{name} enabled group join approval'**
  String chatTeamVerifyUpdateAsNeedVerify(String name);

  /// No description provided for @chatTeamVerifyUpdateAsNeedNoVerify.
  ///
  /// In en, this message translates to:
  /// **'{name} disabled group join approval'**
  String chatTeamVerifyUpdateAsNeedNoVerify(String name);

  /// No description provided for @chatTeamInviteUpdateAsNeedVerify.
  ///
  /// In en, this message translates to:
  /// **'{name} enabled invitation approval for joining the group'**
  String chatTeamInviteUpdateAsNeedVerify(String name);

  /// No description provided for @chatTeamInviteUpdateAsNeedNoVerify.
  ///
  /// In en, this message translates to:
  /// **'{name} disabled invitation approval for joining the group'**
  String chatTeamInviteUpdateAsNeedNoVerify(String name);

  /// No description provided for @chatTeamVerifyUpdateAsDisallowAnyoneJoin.
  ///
  /// In en, this message translates to:
  /// **'update as disallow anyone join'**
  String get chatTeamVerifyUpdateAsDisallowAnyoneJoin;

  /// No description provided for @chatTeamNotifyUpdateExtension.
  ///
  /// In en, this message translates to:
  /// **'team extension update as {name}'**
  String chatTeamNotifyUpdateExtension(String name);

  /// No description provided for @chatTeamNotifyUpdateExtensionServer.
  ///
  /// In en, this message translates to:
  /// **'team extension (server) update as{name}'**
  String chatTeamNotifyUpdateExtensionServer(String name);

  /// No description provided for @chatTeamNotifyUpdateTeamAvatar.
  ///
  /// In en, this message translates to:
  /// **'{user} had updated team avatar'**
  String chatTeamNotifyUpdateTeamAvatar(String user);

  /// No description provided for @chatTeamInvitationPermissionUpdate.
  ///
  /// In en, this message translates to:
  /// **'{user} had updated team invite permission:\"{permission}\"'**
  String chatTeamInvitationPermissionUpdate(String user, String permission);

  /// No description provided for @chatTeamModifyResourcePermissionUpdate.
  ///
  /// In en, this message translates to:
  /// **'{user} had updated team resource permission: \"{permission}\"'**
  String chatTeamModifyResourcePermissionUpdate(String user, String permission);

  /// No description provided for @chatTeamInvitedIdVerifyPermissionUpdate.
  ///
  /// In en, this message translates to:
  /// **'team invited verify update as {permission}'**
  String chatTeamInvitedIdVerifyPermissionUpdate(String permission);

  /// No description provided for @chatTeamModifyExtensionPermissionUpdate.
  ///
  /// In en, this message translates to:
  /// **'team extension update permission as {permission}'**
  String chatTeamModifyExtensionPermissionUpdate(String permission);

  /// No description provided for @chatTeamAllMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get chatTeamAllMute;

  /// No description provided for @chatTeamCancelAllMute.
  ///
  /// In en, this message translates to:
  /// **'cancel all mute'**
  String get chatTeamCancelAllMute;

  /// No description provided for @chatTeamFullMute.
  ///
  /// In en, this message translates to:
  /// **'mute all'**
  String get chatTeamFullMute;

  /// No description provided for @chatTeamUpdate.
  ///
  /// In en, this message translates to:
  /// **'team {key} updated as {value}'**
  String chatTeamUpdate(String key, String value);

  /// No description provided for @chatMessageYou.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get chatMessageYou;

  /// No description provided for @messageSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Message'**
  String get messageSearchTitle;

  /// No description provided for @messageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search chat content'**
  String get messageSearchHint;

  /// No description provided for @messageSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No chat history'**
  String get messageSearchEmpty;

  /// No description provided for @messageForwardToP2p.
  ///
  /// In en, this message translates to:
  /// **'Forward to person'**
  String get messageForwardToP2p;

  /// No description provided for @messageForwardToTeam.
  ///
  /// In en, this message translates to:
  /// **'Forward to team'**
  String get messageForwardToTeam;

  /// No description provided for @messageForwardTo.
  ///
  /// In en, this message translates to:
  /// **'Send to'**
  String get messageForwardTo;

  /// No description provided for @messageCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get messageCancel;

  /// No description provided for @messageForwardMessageTips.
  ///
  /// In en, this message translates to:
  /// **'[Forward]{user} message'**
  String messageForwardMessageTips(String user);

  /// No description provided for @messageReadStatus.
  ///
  /// In en, this message translates to:
  /// **'Message read status'**
  String get messageReadStatus;

  /// No description provided for @messageReadWithNumber.
  ///
  /// In en, this message translates to:
  /// **'Read ({num})'**
  String messageReadWithNumber(String num);

  /// No description provided for @messageUnreadWithNumber.
  ///
  /// In en, this message translates to:
  /// **'Unread ({num})'**
  String messageUnreadWithNumber(String num);

  /// No description provided for @messageAllRead.
  ///
  /// In en, this message translates to:
  /// **'All member have read'**
  String get messageAllRead;

  /// No description provided for @messageAllUnread.
  ///
  /// In en, this message translates to:
  /// **'All member unread'**
  String get messageAllUnread;

  /// No description provided for @chatIsTyping.
  ///
  /// In en, this message translates to:
  /// **'Is Typing'**
  String get chatIsTyping;

  /// No description provided for @chatMessageAitContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a reminder'**
  String get chatMessageAitContactTitle;

  /// No description provided for @chatTeamAitAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get chatTeamAitAll;

  /// No description provided for @chatMessageFileSizeOverLimit.
  ///
  /// In en, this message translates to:
  /// **'Oops! File size limit {size}M.'**
  String chatMessageFileSizeOverLimit(String size);

  /// No description provided for @chatTeamPermissionInviteAll.
  ///
  /// In en, this message translates to:
  /// **'all'**
  String get chatTeamPermissionInviteAll;

  /// No description provided for @chatTeamPermissionInviteOnlyOwner.
  ///
  /// In en, this message translates to:
  /// **'owner'**
  String get chatTeamPermissionInviteOnlyOwner;

  /// No description provided for @chatTeamPermissionUpdateAll.
  ///
  /// In en, this message translates to:
  /// **'all'**
  String get chatTeamPermissionUpdateAll;

  /// No description provided for @chatTeamPermissionUpdateOnlyOwner.
  ///
  /// In en, this message translates to:
  /// **'owner'**
  String get chatTeamPermissionUpdateOnlyOwner;

  /// No description provided for @microphoneDeniedTips.
  ///
  /// In en, this message translates to:
  /// **'Please give your phone micro permission'**
  String get microphoneDeniedTips;

  /// No description provided for @locationDeniedTips.
  ///
  /// In en, this message translates to:
  /// **'Please give your location permission'**
  String get locationDeniedTips;

  /// No description provided for @chatSpeakTooShort.
  ///
  /// In en, this message translates to:
  /// **'Talk too short'**
  String get chatSpeakTooShort;

  /// No description provided for @chatTeamBeRemovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get chatTeamBeRemovedTitle;

  /// No description provided for @chatTeamBeRemovedContent.
  ///
  /// In en, this message translates to:
  /// **'This group is disbanded'**
  String get chatTeamBeRemovedContent;

  /// No description provided for @chatMessageSendFailedByBlackList.
  ///
  /// In en, this message translates to:
  /// **'Send failed, you are in the blacklist'**
  String get chatMessageSendFailedByBlackList;

  /// No description provided for @chatHaveNoPinMessage.
  ///
  /// In en, this message translates to:
  /// **'No pinned message'**
  String get chatHaveNoPinMessage;

  /// No description provided for @chatMessageMergeForward.
  ///
  /// In en, this message translates to:
  /// **'Merge Forward'**
  String get chatMessageMergeForward;

  /// No description provided for @chatMessageItemsForward.
  ///
  /// In en, this message translates to:
  /// **'Items Forward'**
  String get chatMessageItemsForward;

  /// No description provided for @chatMessageMergedTitle.
  ///
  /// In en, this message translates to:
  /// **'{user}History Message'**
  String chatMessageMergedTitle(String user);

  /// No description provided for @chatMessageChatHistory.
  ///
  /// In en, this message translates to:
  /// **'Chat History'**
  String get chatMessageChatHistory;

  /// No description provided for @chatMessagePostScript.
  ///
  /// In en, this message translates to:
  /// **'Post Script'**
  String get chatMessagePostScript;

  /// No description provided for @chatMessageMergeMessageError.
  ///
  /// In en, this message translates to:
  /// **'System Error，Forward Error'**
  String get chatMessageMergeMessageError;

  /// No description provided for @chatMessageInputTitle.
  ///
  /// In en, this message translates to:
  /// **'Input Title'**
  String get chatMessageInputTitle;

  /// No description provided for @chatMessageNotSupportEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Not support empty message'**
  String get chatMessageNotSupportEmptyMessage;

  /// No description provided for @chatMessageMergedForwardLimitOut.
  ///
  /// In en, this message translates to:
  /// **'Merge message limit{number}'**
  String chatMessageMergedForwardLimitOut(String number);

  /// No description provided for @chatMessageForwardOneByOneLimitOut.
  ///
  /// In en, this message translates to:
  /// **'Forward message one by one limit{number}'**
  String chatMessageForwardOneByOneLimitOut(String number);

  /// No description provided for @messageForwardMessageOneByOneTips.
  ///
  /// In en, this message translates to:
  /// **'[Forward One by One]{user}Chat History'**
  String messageForwardMessageOneByOneTips(String user);

  /// No description provided for @messageForwardMessageMergedTips.
  ///
  /// In en, this message translates to:
  /// **'[Merged Forward]{user}Chat History'**
  String messageForwardMessageMergedTips(String user);

  /// No description provided for @chatMessageHaveMessageCantForward.
  ///
  /// In en, this message translates to:
  /// **'There are messages that cannot be forwarded'**
  String get chatMessageHaveMessageCantForward;

  /// No description provided for @chatMessageInfoError.
  ///
  /// In en, this message translates to:
  /// **'Message info error'**
  String get chatMessageInfoError;

  /// No description provided for @chatMessageMergeDepthOut.
  ///
  /// In en, this message translates to:
  /// **'The message exceeds the merging limit and cannot be forwarded as is. Should it be sent without merging?'**
  String get chatMessageMergeDepthOut;

  /// No description provided for @chatMessageExitMessageCannotForward.
  ///
  /// In en, this message translates to:
  /// **'Exit message cannot be forwarded'**
  String get chatMessageExitMessageCannotForward;

  /// No description provided for @chatTeamPermissionInviteOnlyOwnerAndManagers.
  ///
  /// In en, this message translates to:
  /// **'Owner and managers'**
  String get chatTeamPermissionInviteOnlyOwnerAndManagers;

  /// No description provided for @chatTeamPermissionUpdateOnlyOwnerAndManagers.
  ///
  /// In en, this message translates to:
  /// **'Owner and managers'**
  String get chatTeamPermissionUpdateOnlyOwnerAndManagers;

  /// No description provided for @chatTeamHaveBeenKick.
  ///
  /// In en, this message translates to:
  /// **'You have been kicked'**
  String get chatTeamHaveBeenKick;

  /// No description provided for @chatMessageHaveCannotForwardMessages.
  ///
  /// In en, this message translates to:
  /// **'There are messages that cannot be forwarded'**
  String get chatMessageHaveCannotForwardMessages;

  /// No description provided for @teamMsgAitAllPrivilegeIsAll.
  ///
  /// In en, this message translates to:
  /// **'@All privilege update to all'**
  String get teamMsgAitAllPrivilegeIsAll;

  /// No description provided for @teamMsgAitAllPrivilegeIsOwner.
  ///
  /// In en, this message translates to:
  /// **'@All privilege update to owner and manager'**
  String get teamMsgAitAllPrivilegeIsOwner;

  /// No description provided for @chatMessagePinLimitTips.
  ///
  /// In en, this message translates to:
  /// **'Number of pin reaches the limit.'**
  String get chatMessagePinLimitTips;

  /// No description provided for @chatMessageRemovedTip.
  ///
  /// In en, this message translates to:
  /// **'The message was removed.'**
  String get chatMessageRemovedTip;

  /// No description provided for @chatAiSearchError.
  ///
  /// In en, this message translates to:
  /// **'AI error'**
  String get chatAiSearchError;

  /// No description provided for @chatAiMessageTypeUnsupport.
  ///
  /// In en, this message translates to:
  /// **'Unsupported format'**
  String get chatAiMessageTypeUnsupport;

  /// No description provided for @chatAiErrorUserNotExist.
  ///
  /// In en, this message translates to:
  /// **'User does not exist'**
  String get chatAiErrorUserNotExist;

  /// No description provided for @chatAiErrorFailedRequestToTheLlm.
  ///
  /// In en, this message translates to:
  /// **'Failed request to the language model'**
  String get chatAiErrorFailedRequestToTheLlm;

  /// No description provided for @chatAiErrorAiMessagesFunctionDisabled.
  ///
  /// In en, this message translates to:
  /// **'AI messaging function not enabled'**
  String get chatAiErrorAiMessagesFunctionDisabled;

  /// No description provided for @chatAiErrorUserBanned.
  ///
  /// In en, this message translates to:
  /// **'User banned'**
  String get chatAiErrorUserBanned;

  /// No description provided for @chatAiErrorUserChatBanned.
  ///
  /// In en, this message translates to:
  /// **'User chat banned'**
  String get chatAiErrorUserChatBanned;

  /// No description provided for @chatAiErrorMessageHitAntispam.
  ///
  /// In en, this message translates to:
  /// **'Message hit anti-spam'**
  String get chatAiErrorMessageHitAntispam;

  /// No description provided for @chatAiErrorNotAnAiAccount.
  ///
  /// In en, this message translates to:
  /// **'Not an AI account'**
  String get chatAiErrorNotAnAiAccount;

  /// No description provided for @chatAiErrorTeamMemberNotExist.
  ///
  /// In en, this message translates to:
  /// **'Team member does not exist'**
  String get chatAiErrorTeamMemberNotExist;

  /// No description provided for @chatAiErrorTeamNormalMemberChatBanned.
  ///
  /// In en, this message translates to:
  /// **'Team normal member chat banned'**
  String get chatAiErrorTeamNormalMemberChatBanned;

  /// No description provided for @chatAiErrorTeamMemberChatBanned.
  ///
  /// In en, this message translates to:
  /// **'Team member chat banned'**
  String get chatAiErrorTeamMemberChatBanned;

  /// No description provided for @chatAiErrorCannotBlocklistAnAiAccount.
  ///
  /// In en, this message translates to:
  /// **'Cannot blocklist an AI account'**
  String get chatAiErrorCannotBlocklistAnAiAccount;

  /// No description provided for @chatAiErrorRateLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'Rate limit exceeded'**
  String get chatAiErrorRateLimitExceeded;

  /// No description provided for @chatAiErrorParameter.
  ///
  /// In en, this message translates to:
  /// **'Parameter error'**
  String get chatAiErrorParameter;

  /// No description provided for @chatUserOnline.
  ///
  /// In en, this message translates to:
  /// **'[Online]'**
  String get chatUserOnline;

  /// No description provided for @chatUserOffline.
  ///
  /// In en, this message translates to:
  /// **'[Offline]'**
  String get chatUserOffline;

  /// No description provided for @forwardSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get forwardSelect;

  /// No description provided for @multiSelect.
  ///
  /// In en, this message translates to:
  /// **'Multi-Select'**
  String get multiSelect;

  /// No description provided for @forwardSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get forwardSearch;

  /// No description provided for @forwardRecentForward.
  ///
  /// In en, this message translates to:
  /// **'Recent Forward'**
  String get forwardRecentForward;

  /// No description provided for @forwardRecentConversation.
  ///
  /// In en, this message translates to:
  /// **'Recent Chat'**
  String get forwardRecentConversation;

  /// No description provided for @forwardMyFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get forwardMyFriends;

  /// No description provided for @forwardTeam.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get forwardTeam;

  /// No description provided for @forwardConversationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Conversation'**
  String get forwardConversationEmpty;

  /// No description provided for @forwardContactEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Friend'**
  String get forwardContactEmpty;

  /// No description provided for @forwardTeamEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Team'**
  String get forwardTeamEmpty;

  /// No description provided for @messageSure.
  ///
  /// In en, this message translates to:
  /// **'Sure'**
  String get messageSure;

  /// No description provided for @chatMessageCallError.
  ///
  /// In en, this message translates to:
  /// **'Call Error'**
  String get chatMessageCallError;

  /// No description provided for @chatMessageCopyNumber.
  ///
  /// In en, this message translates to:
  /// **'Copy Number'**
  String get chatMessageCopyNumber;

  /// No description provided for @chatMessageCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get chatMessageCall;

  /// No description provided for @messagePhoneCallTips.
  ///
  /// In en, this message translates to:
  /// **'{number} Maybe a phone number,you can'**
  String messagePhoneCallTips(String number);

  /// No description provided for @searchResultEmpty.
  ///
  /// In en, this message translates to:
  /// **'Have no result for {keyword}'**
  String searchResultEmpty(String keyword);

  /// No description provided for @maxSelectConversationLimit.
  ///
  /// In en, this message translates to:
  /// **'Can not select more than {number} chats'**
  String maxSelectConversationLimit(String number);

  /// No description provided for @webConnectError.
  ///
  /// In en, this message translates to:
  /// **'Web view loading error'**
  String get webConnectError;

  /// No description provided for @chatMessageCallFile.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get chatMessageCallFile;

  /// No description provided for @chatMessageVideoCallAction.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get chatMessageVideoCallAction;

  /// No description provided for @chatMessageAudioCallAction.
  ///
  /// In en, this message translates to:
  /// **'Voice Call'**
  String get chatMessageAudioCallAction;

  /// No description provided for @chatMessageBriefVideoCall.
  ///
  /// In en, this message translates to:
  /// **'[Video Call]'**
  String get chatMessageBriefVideoCall;

  /// No description provided for @chatMessageBriefAudioCall.
  ///
  /// In en, this message translates to:
  /// **'[Voice Call]'**
  String get chatMessageBriefAudioCall;

  /// No description provided for @chatMessageAudioCallText.
  ///
  /// In en, this message translates to:
  /// **'[Voice Call]'**
  String get chatMessageAudioCallText;

  /// No description provided for @chatMessageVideoCallText.
  ///
  /// In en, this message translates to:
  /// **'[Video Call]'**
  String get chatMessageVideoCallText;

  /// No description provided for @chatMessageCallCancel.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get chatMessageCallCancel;

  /// No description provided for @chatMessageCallRefused.
  ///
  /// In en, this message translates to:
  /// **'Refused'**
  String get chatMessageCallRefused;

  /// No description provided for @chatMessageCallTimeout.
  ///
  /// In en, this message translates to:
  /// **'Time Out'**
  String get chatMessageCallTimeout;

  /// No description provided for @chatMessageCallBusy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get chatMessageCallBusy;

  /// No description provided for @chatMessageCallCompleted.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get chatMessageCallCompleted;

  /// No description provided for @chatVoiceFromSpeaker.
  ///
  /// In en, this message translates to:
  /// **'turn on speaker'**
  String get chatVoiceFromSpeaker;

  /// No description provided for @chatVoiceFromEarSpeaker.
  ///
  /// In en, this message translates to:
  /// **'turn off speaker'**
  String get chatVoiceFromEarSpeaker;

  /// No description provided for @chatVoiceFromSpeakerTips.
  ///
  /// In en, this message translates to:
  /// **'turn on speaker'**
  String get chatVoiceFromSpeakerTips;

  /// No description provided for @chatVoiceFromEarSpeakerTips.
  ///
  /// In en, this message translates to:
  /// **'Switched to ear speaker，Move phone to ear to hear audio'**
  String get chatVoiceFromEarSpeakerTips;

  /// No description provided for @chatBeenBlockByOthers.
  ///
  /// In en, this message translates to:
  /// **'You have been blocked.'**
  String get chatBeenBlockByOthers;

  /// No description provided for @chatPermissionSystemCheck.
  ///
  /// In en, this message translates to:
  /// **'Failed to get permission. Please go to system settings to grant it.'**
  String get chatPermissionSystemCheck;

  /// No description provided for @permissionCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'The camera is used for'**
  String get permissionCameraTitle;

  /// No description provided for @permissionCameraContent.
  ///
  /// In en, this message translates to:
  /// **'Photo-taking, video records, video calls, ...'**
  String get permissionCameraContent;

  /// No description provided for @permissionStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'The storage is used for'**
  String get permissionStorageTitle;

  /// No description provided for @permissionStorageContent.
  ///
  /// In en, this message translates to:
  /// **'Files, photos, videos, ...'**
  String get permissionStorageContent;

  /// No description provided for @permissionAudioTitle.
  ///
  /// In en, this message translates to:
  /// **'The micro is used for'**
  String get permissionAudioTitle;

  /// No description provided for @permissionAudioContent.
  ///
  /// In en, this message translates to:
  /// **'Voice records, voice calls, ...'**
  String get permissionAudioContent;

  /// No description provided for @chatMessageAntispamPornography.
  ///
  /// In en, this message translates to:
  /// **'Pornography'**
  String get chatMessageAntispamPornography;

  /// No description provided for @chatMessageAntispamAdvertising.
  ///
  /// In en, this message translates to:
  /// **'Advertising'**
  String get chatMessageAntispamAdvertising;

  /// No description provided for @chatMessageAntispamIllegalAdvertising.
  ///
  /// In en, this message translates to:
  /// **'Illegal Advertising'**
  String get chatMessageAntispamIllegalAdvertising;

  /// No description provided for @chatMessageAntispamViolenceTerrorism.
  ///
  /// In en, this message translates to:
  /// **'Violence & Terrorism'**
  String get chatMessageAntispamViolenceTerrorism;

  /// No description provided for @chatMessageAntispamContraband.
  ///
  /// In en, this message translates to:
  /// **'Contraband'**
  String get chatMessageAntispamContraband;

  /// No description provided for @chatMessageAntispamPoliticalSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Political Sensitivity'**
  String get chatMessageAntispamPoliticalSensitivity;

  /// No description provided for @chatMessageAntispamAbuse.
  ///
  /// In en, this message translates to:
  /// **'Abuse'**
  String get chatMessageAntispamAbuse;

  /// No description provided for @chatMessageAntispamSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get chatMessageAntispamSpam;

  /// No description provided for @chatMessageAntispamOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get chatMessageAntispamOther;

  /// No description provided for @chatMessageAntispamInappropriateValues.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate Values'**
  String get chatMessageAntispamInappropriateValues;

  /// No description provided for @chatMessageAntispamTips.
  ///
  /// In en, this message translates to:
  /// **'The content may involve {reason}. Please adjust it before sending.'**
  String chatMessageAntispamTips(String reason);

  /// No description provided for @chatMessageWarningTips.
  ///
  /// In en, this message translates to:
  /// **'For Yunxin IM product demo use only. Do not trust messages involving money transfers or winning prizes. Do not call unknown numbers. Beware of scams.'**
  String get chatMessageWarningTips;

  /// No description provided for @chatMessageTapToReport.
  ///
  /// In en, this message translates to:
  /// **'Tap to report'**
  String get chatMessageTapToReport;

  /// No description provided for @chatMessageQuickSearch.
  ///
  /// In en, this message translates to:
  /// **'Quick Search Message'**
  String get chatMessageQuickSearch;

  /// No description provided for @chatMessageSearchHistory.
  ///
  /// In en, this message translates to:
  /// **'Search History Message'**
  String get chatMessageSearchHistory;

  /// No description provided for @chatQuickSearchTeamMember.
  ///
  /// In en, this message translates to:
  /// **'Team Member'**
  String get chatQuickSearchTeamMember;

  /// No description provided for @chatQuickSearchPicture.
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get chatQuickSearchPicture;

  /// No description provided for @chatQuickSearchVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get chatQuickSearchVideo;

  /// No description provided for @chatQuickSearchDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get chatQuickSearchDate;

  /// No description provided for @chatQuickSearchFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get chatQuickSearchFile;

  /// No description provided for @chatQuickSearchByDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by date'**
  String get chatQuickSearchByDate;

  /// No description provided for @chatDateYearMonth.
  ///
  /// In en, this message translates to:
  /// **'{month}/{year}'**
  String chatDateYearMonth(String year, String month);

  /// No description provided for @chatDateMonth.
  ///
  /// In en, this message translates to:
  /// **'{month}'**
  String chatDateMonth(String month);

  /// No description provided for @chatDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatDateToday;

  /// No description provided for @chatDateRecent7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get chatDateRecent7Days;

  /// No description provided for @chatDateRecent30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get chatDateRecent30Days;

  /// No description provided for @chatHistoryLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more messages'**
  String get chatHistoryLoadMore;

  /// No description provided for @chatHistoryDateFormatMonthDay.
  ///
  /// In en, this message translates to:
  /// **'MM/dd'**
  String get chatHistoryDateFormatMonthDay;

  /// No description provided for @chatHistoryDateFormaYearMonthDay.
  ///
  /// In en, this message translates to:
  /// **'yy/MM/dd'**
  String get chatHistoryDateFormaYearMonthDay;

  /// No description provided for @chatHistoryFinish.
  ///
  /// In en, this message translates to:
  /// **'Sure'**
  String get chatHistoryFinish;

  /// No description provided for @chatHistorySelectChatDate.
  ///
  /// In en, this message translates to:
  /// **'Select Chat Date'**
  String get chatHistorySelectChatDate;

  /// No description provided for @chatHistorySearchByMember.
  ///
  /// In en, this message translates to:
  /// **'Search By Member'**
  String get chatHistorySearchByMember;

  /// No description provided for @chatHistoryDateFormatYearMonthDayHourMine.
  ///
  /// In en, this message translates to:
  /// **'yy/MM/dd/ HH:mm'**
  String get chatHistoryDateFormatYearMonthDayHourMine;

  /// No description provided for @chatHistoryDateFormatMonthDayHourMine.
  ///
  /// In en, this message translates to:
  /// **'MM/dd/ HH:mm'**
  String get chatHistoryDateFormatMonthDayHourMine;

  /// No description provided for @chatHistoryDateFormatHourMine.
  ///
  /// In en, this message translates to:
  /// **'HH:mm'**
  String get chatHistoryDateFormatHourMine;

  /// No description provided for @chatHistoryMessageNotAnyMore.
  ///
  /// In en, this message translates to:
  /// **'Not Any More'**
  String get chatHistoryMessageNotAnyMore;

  /// No description provided for @chatHistoryOrientation.
  ///
  /// In en, this message translates to:
  /// **'Find in chat'**
  String get chatHistoryOrientation;

  /// No description provided for @chatCollectionFrom.
  ///
  /// In en, this message translates to:
  /// **'From{name}'**
  String chatCollectionFrom(String name);

  /// No description provided for @chatNewMessage.
  ///
  /// In en, this message translates to:
  /// **'{number}new message'**
  String chatNewMessage(String number);

  /// No description provided for @chatMessageCollectedLimit.
  ///
  /// In en, this message translates to:
  /// **'Message Collected Limited'**
  String get chatMessageCollectedLimit;

  /// No description provided for @chatHaveNoCollectionMessage.
  ///
  /// In en, this message translates to:
  /// **'NO Collection'**
  String get chatHaveNoCollectionMessage;

  /// No description provided for @chatCollectionDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this collection？'**
  String get chatCollectionDeleteConfirm;

  /// No description provided for @chatSearchImageMessageEmpty.
  ///
  /// In en, this message translates to:
  /// **'NO Picture Message'**
  String get chatSearchImageMessageEmpty;

  /// No description provided for @chatSearchVideoMessageEmpty.
  ///
  /// In en, this message translates to:
  /// **'NO Video Message'**
  String get chatSearchVideoMessageEmpty;

  /// No description provided for @chatSearchFileMessageEmpty.
  ///
  /// In en, this message translates to:
  /// **'NO File Message'**
  String get chatSearchFileMessageEmpty;
}

class _ChatKitClientLocalizationsDelegate
    extends LocalizationsDelegate<ChatKitClientLocalizations> {
  const _ChatKitClientLocalizationsDelegate();

  @override
  Future<ChatKitClientLocalizations> load(Locale locale) {
    return SynchronousFuture<ChatKitClientLocalizations>(
        lookupChatKitClientLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_ChatKitClientLocalizationsDelegate old) => false;
}

ChatKitClientLocalizations lookupChatKitClientLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ChatKitClientLocalizationsEn();
    case 'zh':
      return ChatKitClientLocalizationsZh();
  }

  throw FlutterError(
      'ChatKitClientLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
