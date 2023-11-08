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
  /// **'update as need verify'**
  String get chatTeamVerifyUpdateAsNeedVerify;

  /// No description provided for @chatTeamVerifyUpdateAsNeedNoVerify.
  ///
  /// In en, this message translates to:
  /// **'update as need no verify'**
  String get chatTeamVerifyUpdateAsNeedNoVerify;

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
  /// **'Search History'**
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
