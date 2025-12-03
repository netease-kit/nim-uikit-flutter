// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'chat_kit_client_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class ChatKitClientLocalizationsZh extends ChatKitClientLocalizations {
  ChatKitClientLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String chatMessageSendHint(String userName) {
    return '发送给 $userName';
  }

  @override
  String get chatPressedToSpeak => '按住说话';

  @override
  String get chatMessageVoiceIn => '松开发送，按住滑到空白区域取消';

  @override
  String get chatMessagePickPhoto => '照片';

  @override
  String get chatMessagePickVideo => '视频';

  @override
  String get chatMessageMoreShoot => '拍摄';

  @override
  String get chatMessageTakePhoto => '拍照';

  @override
  String get chatMessageTakeVideo => '摄像';

  @override
  String get chatMessageNonsupport => '当前版本暂不支持该消息体';

  @override
  String get chatMessageMoreFile => '文件';

  @override
  String get chatMessageMoreTranslate => '翻译';

  @override
  String get chatTranslateTo => '翻译为...';

  @override
  String get chatTranslateSure => 'AI处理';

  @override
  String get chatTranslating => 'AI处理中...';

  @override
  String get chatTranslateUse => '使用↓';

  @override
  String get chatTranslateLanguageTitle => '将输入内容翻译为';

  @override
  String get chatMessageMoreLocation => '位置';

  @override
  String get chatMessageAMapNotFound => '未检测到高德地图';

  @override
  String get chatMessageTencentMapNotFound => '未检测到腾讯地图';

  @override
  String get chatMessageAMap => '高德地图';

  @override
  String get chatMessageTencentMap => '腾讯地图';

  @override
  String get chatMessageUnknownType => '未知类型';

  @override
  String get chatMessageImageSave => '图片已保存到手机';

  @override
  String get chatMessageImageSaveFail => '图片保存失败';

  @override
  String get chatMessageVideoSave => '视频已保存到手机';

  @override
  String get chatMessageVideoSaveFail => '视频保存失败';

  @override
  String get chatMessageActionCopy => '复制';

  @override
  String get chatMessageActionReply => '回复';

  @override
  String get chatMessageActionForward => '转发';

  @override
  String get chatMessageActionPin => '标记';

  @override
  String get chatMessageActionUnPin => '取消标记';

  @override
  String get chatMessageActionMultiSelect => '多选';

  @override
  String get chatMessageActionCollect => '收藏';

  @override
  String get chatMessageActionDelete => '删除';

  @override
  String get chatMessageActionRevoke => '撤回';

  @override
  String get chatMessageCopySuccess => '复制成功';

  @override
  String get chatMessageCollectSuccess => '收藏成功';

  @override
  String get chatMessageDeleteConfirm => '删除此消息？';

  @override
  String get chatMessageRevokeConfirm => '撤回此消息？';

  @override
  String get chatMessageHaveBeenRevokedOrDelete => '该消息已被撤回或者删除';

  @override
  String chatMessagePinMessage(String userName) {
    return '$userName标记了这条信息，对话内容双方均可见';
  }

  @override
  String chatMessagePinMessageForTeam(String userName) {
    return '$userName标记了这条信息，所有群成员均可见';
  }

  @override
  String get chatMessageHaveBeenRevoked => '此消息已撤回';

  @override
  String get chatMessageReedit => ' 重新编辑 >';

  @override
  String get chatMessageRevokeOverTime => '已超过时间无法撤回';

  @override
  String get chatMessageRevokeFailed => '撤回失败';

  @override
  String chatMessageReplySomeone(String content) {
    return '回复 $content';
  }

  @override
  String get chatMessageBriefImage => '[图片]';

  @override
  String get chatMessageBriefAudio => '[语音]';

  @override
  String get chatMessageBriefVideo => '[视频]';

  @override
  String get chatMessageBriefLocation => '[地理位置]';

  @override
  String get chatMessageBriefFile => '[文件]';

  @override
  String get chatMessageBriefCustom => '[自定义消息]';

  @override
  String get chatMessageBriefChatHistory => '[聊天记录]';

  @override
  String get chatSetting => '聊天设置';

  @override
  String get chatMessageSignal => '标记';

  @override
  String get chatMessageOpenMessageNotice => '开启消息提醒';

  @override
  String get chatMessageSetTop => '聊天置顶';

  @override
  String get chatMessageSetPin => 'PIN置顶';

  @override
  String get chatMessageSend => '发送';

  @override
  String chatAdviceTeamNotifyInvite(String user, String members) {
    return '$user 邀请$members加入群组';
  }

  @override
  String chatDiscussTeamNotifyInvite(String user, String members) {
    return '$user邀请$members加入讨论组';
  }

  @override
  String chatDiscussTeamNotifyRemove(String users) {
    return '$users已被移出讨论组';
  }

  @override
  String chatAdvancedTeamNotifyRemove(String users) {
    return '$users已被移出群';
  }

  @override
  String chatDiscussTeamNotifyLeave(String users) {
    return '$users离开了讨论组';
  }

  @override
  String chatAdvancedTeamNotifyLeave(String user) {
    return '$user 退出了群聊';
  }

  @override
  String chatTeamNotifyDismiss(String users) {
    return '$users解散了群';
  }

  @override
  String chatTeamNotifyManagerPass(String members) {
    return '管理员通过用户$members的入群申请';
  }

  @override
  String chatTeamNotifyTransOwner(String members, String user) {
    return '$user将群转移给$members';
  }

  @override
  String chatTeamNotifyAddManager(String member) {
    return '$member被任命为管理员';
  }

  @override
  String chatTeamNotifyRemoveManager(String member) {
    return '$member被撤销管理员身份';
  }

  @override
  String chatTeamNotifyAcceptInvite(String members, String user) {
    return '$user接受了$members的入群邀请';
  }

  @override
  String chatTeamNotifyMute(String user) {
    return '$user被管理员禁言';
  }

  @override
  String chatTeamNotifyUnMute(String user) {
    return '$user被管理员解除禁言';
  }

  @override
  String get chatMessageUnknownNotification => '未知通知';

  @override
  String chatTeamNotifyUpdateName(String user, String name) {
    return '$user 更新群名称为\"$name\"';
  }

  @override
  String chatTeamNotifyUpdateIntroduction(String user) {
    return '$user 更新了群介绍';
  }

  @override
  String chatTeamNoticeUpdate(String notice) {
    return '群公告变更为$notice';
  }

  @override
  String chatTeamVerifyUpdateAsNeedVerify(String name) {
    return '$name开启了入群审核';
  }

  @override
  String chatTeamVerifyUpdateAsNeedNoVerify(String name) {
    return '$name关闭了入群审核';
  }

  @override
  String chatTeamInviteUpdateAsNeedVerify(String name) {
    return '$name开启了入群邀请需要同意';
  }

  @override
  String chatTeamInviteUpdateAsNeedNoVerify(String name) {
    return '$name关闭了入群邀请需要同意';
  }

  @override
  String get chatTeamVerifyUpdateAsDisallowAnyoneJoin => '群身份验证权限更新为不容许任何人申请加入';

  @override
  String chatTeamNotifyUpdateExtension(String name) {
    return '扩展字段被更新为$name';
  }

  @override
  String chatTeamNotifyUpdateExtensionServer(String name) {
    return '扩展字段（服务器）被更新为$name';
  }

  @override
  String chatTeamNotifyUpdateTeamAvatar(String user) {
    return '$user 更新了群头像';
  }

  @override
  String chatTeamInvitationPermissionUpdate(String user, String permission) {
    return '$user 更新了群权限\"邀请他人权限\"为\"$permission\"';
  }

  @override
  String chatTeamModifyResourcePermissionUpdate(
      String user, String permission) {
    return '$user 更新了群权限\"群资料修改权限\"为\"$permission\"';
  }

  @override
  String chatTeamInvitedIdVerifyPermissionUpdate(String permission) {
    return '群被邀请人身份验证权限被更新为$permission';
  }

  @override
  String chatTeamModifyExtensionPermissionUpdate(String permission) {
    return '群扩展字段修改权限被更新为$permission';
  }

  @override
  String get chatTeamAllMute => '当前群主设置为禁言';

  @override
  String get chatTeamCancelAllMute => '群禁言已关闭';

  @override
  String get chatTeamFullMute => '群禁言已开启';

  @override
  String chatTeamUpdate(String key, String value) {
    return '群$key被更新为$value';
  }

  @override
  String get chatMessageYou => '你';

  @override
  String get messageSearchTitle => '历史记录';

  @override
  String get messageSearchHint => '搜索聊天内容';

  @override
  String get messageSearchEmpty => '暂无聊天记录';

  @override
  String get messageForwardToP2p => '转发到个人';

  @override
  String get messageForwardToTeam => '转发到群组';

  @override
  String get messageForwardTo => '发送给';

  @override
  String get messageCancel => '取消';

  @override
  String messageForwardMessageTips(String user) {
    return '[转发]$user的会话记录';
  }

  @override
  String get messageReadStatus => '消息阅读状态';

  @override
  String messageReadWithNumber(String num) {
    return '已读($num)';
  }

  @override
  String messageUnreadWithNumber(String num) {
    return '未读($num)';
  }

  @override
  String get messageAllRead => '全部成员已读';

  @override
  String get messageAllUnread => '全部成员未读';

  @override
  String get chatIsTyping => '正在输入中...';

  @override
  String get chatMessageAitContactTitle => '选择提醒';

  @override
  String get chatTeamAitAll => '所有人';

  @override
  String chatMessageFileSizeOverLimit(String size) {
    return '当前文件大小超出${size}M发送限制，请重新选择';
  }

  @override
  String get chatTeamPermissionInviteAll => '所有人';

  @override
  String get chatTeamPermissionInviteOnlyOwner => '仅群主';

  @override
  String get chatTeamPermissionUpdateAll => '所有人';

  @override
  String get chatTeamPermissionUpdateOnlyOwner => '仅群主';

  @override
  String get microphoneDeniedTips => '请在设置页面添加麦克风权限';

  @override
  String get locationDeniedTips => '请在设置页面添加定位权限';

  @override
  String get chatSpeakTooShort => '说话时间太短';

  @override
  String get chatTeamBeRemovedTitle => '提醒';

  @override
  String get chatTeamBeRemovedContent => '该群聊已被解散';

  @override
  String get chatMessageSendFailedByBlackList => '对方已将您拉黑，消息发送失败';

  @override
  String get chatHaveNoPinMessage => '暂无标记消息';

  @override
  String get chatMessageMergeForward => '合并转发';

  @override
  String get chatMessageItemsForward => '逐条转发';

  @override
  String chatMessageMergedTitle(String user) {
    return '$user的消息';
  }

  @override
  String get chatMessageChatHistory => '聊天记录';

  @override
  String get chatMessagePostScript => '留言';

  @override
  String get chatMessageMergeMessageError => '系统异常，转发失败';

  @override
  String get chatMessageInputTitle => '请输入标题';

  @override
  String get chatMessageNotSupportEmptyMessage => '不支持发送空消息';

  @override
  String chatMessageMergedForwardLimitOut(String number) {
    return '合并转发限制$number条消息';
  }

  @override
  String chatMessageForwardOneByOneLimitOut(String number) {
    return '逐条转发限制$number条消息';
  }

  @override
  String messageForwardMessageOneByOneTips(String user) {
    return '[逐条转发]$user的会话记录';
  }

  @override
  String messageForwardMessageMergedTips(String user) {
    return '[合并转发]$user的会话记录';
  }

  @override
  String get chatMessageHaveMessageCantForward => '存在不可转发的消息体';

  @override
  String get chatMessageInfoError => '信息获取失败';

  @override
  String get chatMessageMergeDepthOut => '存在超出合并限制的消息，无法合并转发，是否去除后发送?';

  @override
  String get chatMessageExitMessageCannotForward => '存在不可转发的消息体';

  @override
  String get chatTeamPermissionInviteOnlyOwnerAndManagers => '群主和管理员';

  @override
  String get chatTeamPermissionUpdateOnlyOwnerAndManagers => '群主和管理员';

  @override
  String get chatTeamHaveBeenKick => '您已被移除群聊';

  @override
  String get chatMessageHaveCannotForwardMessages => '存在不可转发的消息体，是否去除后发送？';

  @override
  String get teamMsgAitAllPrivilegeIsAll => '@所有人权限更新为所有人';

  @override
  String get teamMsgAitAllPrivilegeIsOwner => '@所有人权限更新为群主和管理员';

  @override
  String get chatMessagePinLimitTips => '已超出pin数量上限';

  @override
  String get chatMessageRemovedTip => '该消息已撤回或删除';

  @override
  String get chatAiSearchError => '模型请求异常';

  @override
  String get chatAiMessageTypeUnsupport => '暂不支持该格式';

  @override
  String get chatAiErrorUserNotExist => '用户不存在';

  @override
  String get chatAiErrorFailedRequestToTheLlm => '请求大语言模型失败';

  @override
  String get chatAiErrorAiMessagesFunctionDisabled => 'AI消息功能未开通';

  @override
  String get chatAiErrorUserBanned => '用户被禁用';

  @override
  String get chatAiErrorUserChatBanned => '用户被禁言';

  @override
  String get chatAiErrorMessageHitAntispam => '消息命中反垃圾';

  @override
  String get chatAiErrorNotAnAiAccount => '不是数字人账号';

  @override
  String get chatAiErrorTeamMemberNotExist => '群成员不存在';

  @override
  String get chatAiErrorTeamNormalMemberChatBanned => '群普通成员禁言';

  @override
  String get chatAiErrorTeamMemberChatBanned => '群成员被禁言';

  @override
  String get chatAiErrorCannotBlocklistAnAiAccount => '不允许对数字人进行黑名单操作';

  @override
  String get chatAiErrorRateLimitExceeded => '频率超限';

  @override
  String get chatAiErrorParameter => '参数错误';

  @override
  String get chatUserOnline => '[在线]';

  @override
  String get chatUserOffline => '[离线]';

  @override
  String get forwardSelect => '选择';

  @override
  String get multiSelect => '多选';

  @override
  String get forwardSearch => '搜索';

  @override
  String get forwardRecentForward => '最近转发';

  @override
  String get forwardRecentConversation => '最近会话';

  @override
  String get forwardMyFriends => '我的好友';

  @override
  String get forwardTeam => '我的群聊';

  @override
  String get forwardConversationEmpty => '暂无会话';

  @override
  String get forwardContactEmpty => '暂无好友';

  @override
  String get forwardTeamEmpty => '暂无群组';

  @override
  String get messageSure => '确定';

  @override
  String get chatMessageCallError => '呼叫出错';

  @override
  String get chatMessageCopyNumber => '复制号码';

  @override
  String get chatMessageCall => '呼叫';

  @override
  String messagePhoneCallTips(String number) {
    return '$number可能是一个电话号码，你可以';
  }

  @override
  String searchResultEmpty(String keyword) {
    return '未搜索到$keyword相关结果';
  }

  @override
  String maxSelectConversationLimit(String number) {
    return '最多只能选择$number个会话';
  }

  @override
  String get webConnectError => '页面加载失败';

  @override
  String get chatMessageCallFile => '音视频通话';

  @override
  String get chatMessageVideoCallAction => '视频通话';

  @override
  String get chatMessageAudioCallAction => '语音通话';

  @override
  String get chatMessageBriefVideoCall => '[视频通话]';

  @override
  String get chatMessageBriefAudioCall => '[语音通话]';

  @override
  String get chatMessageAudioCallText => '[语音通话]';

  @override
  String get chatMessageVideoCallText => '[视频通话]';

  @override
  String get chatMessageCallCancel => '已取消';

  @override
  String get chatMessageCallRefused => '已拒绝';

  @override
  String get chatMessageCallTimeout => '未接听';

  @override
  String get chatMessageCallBusy => '忙线未接听';

  @override
  String get chatMessageCallCompleted => '通话时长';

  @override
  String get chatVoiceFromSpeaker => '扬声器';

  @override
  String get chatVoiceFromEarSpeaker => '听筒播放';

  @override
  String get chatVoiceFromSpeakerTips => '扬声器播放';

  @override
  String get chatVoiceFromEarSpeakerTips => '切换听筒播放模式，请贴近手机聆听';

  @override
  String get chatBeenBlockByOthers => '您已被对方拉黑';

  @override
  String get chatPermissionSystemCheck => '权限获取失败，请前往系统设置页面设置';

  @override
  String get permissionCameraTitle => '相机权限使用说明';

  @override
  String get permissionCameraContent => '用户拍照，视频录制， 视频通话等场景';

  @override
  String get permissionStorageTitle => '存储权限使用说明';

  @override
  String get permissionStorageContent => '用户发送文件、图片、视频等场景';

  @override
  String get permissionAudioTitle => '麦克风权限使用说明';

  @override
  String get permissionAudioContent => '用户录制， 音频通话等场景';

  @override
  String get chatMessageAntispamPornography => '色情';

  @override
  String get chatMessageAntispamAdvertising => '广告';

  @override
  String get chatMessageAntispamIllegalAdvertising => '广告法';

  @override
  String get chatMessageAntispamViolenceTerrorism => '暴恐';

  @override
  String get chatMessageAntispamContraband => '违禁';

  @override
  String get chatMessageAntispamPoliticalSensitivity => '涉政';

  @override
  String get chatMessageAntispamAbuse => '谩骂';

  @override
  String get chatMessageAntispamSpam => '灌水';

  @override
  String get chatMessageAntispamOther => '其他';

  @override
  String get chatMessageAntispamInappropriateValues => '涉价值观';

  @override
  String chatMessageAntispamTips(String reason) {
    return '内容可能涉及$reason, 请调整后发送';
  }

  @override
  String get chatMessageWarningTips =>
      '仅用于体验云信IM产品功能，请勿轻信汇款，中奖等涉及钱款的信息，勿轻易拨打陌生电话，谨防上当受骗，';

  @override
  String get chatMessageTapToReport => '点击举报';
}
