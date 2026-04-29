// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_callkit_ui/ne_callkit_ui.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_corekit/report/xkit_report.dart';
import 'package:netease_plugin_core_kit/netease_plugin_core_kit.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_config_center.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:nim_core_v2/nim_core.dart';

import 'chat_kit_message_avChat_item.dart';
import 'l10n/S.dart';

const String kPackage = 'nim_chatkit_callkit';

class ChatKitCall {
  static const String _kVersion = '10.6.1';

  static const String _kName = 'ChatKitCall';

  final String callMessageType = 'avCallMessage';

  ///呼叫组件是否已经注册
  bool _haveRegistered = false;

  static get delegate {
    return S.delegate;
  }

  ChatKitCall._();

  static final ChatKitCall instance = ChatKitCall._();

  /// 初始化
  /// 在IM登录后初始化调用
  /// [showIndex] 呼叫消息入口显示位置，默认1
  /// [appKey]      appKey
  /// [accountId]     当前用户的 accountId
  /// [extraConfig]  额外配置参数，包含 lckConfig 等
  void init({
    required String appKey,
    required String accountId,
    NEExtraConfig? extraConfig,
    int? showIndex,
  }) {
    ///web暂不支持呼叫
    if (kIsWeb) {
      return;
    }

    ///埋点上报
    XKitReporter().register(moduleName: _kName, moduleVersion: _kVersion);

    if (!_haveRegistered) {
      ///注册呼叫消息入口
      NimPluginCoreKit().itemPool.registerMoreAction(
            MessageInputAction(
              type: 'call',
              icon: SvgPicture.asset(
                  ChatKitUtils.isDesktopOrWeb
                      ? 'images/ic_call_desktop.svg'
                      : 'images/ic_call.svg',
                  width: 24,
                  height: 24,
                  package: kPackage),
              title: S.of().chatMessageCallTitle,
              onTap: (context, conversationId, conversationTye,
                  {messageSender}) {
                ///去位置消息页面
                _onCallActionTap(context, conversationId, conversationTye);
              },
              enable: (conversationId, conversationType) {
                if (conversationType == NIMConversationType.team) {
                  return false;
                }
                String targetId = ChatKitUtils.getConversationTargetId(
                  conversationId,
                );
                if (AIUserManager.instance.isAIUser(targetId)) {
                  return false;
                }
                return true;
              },
              index: showIndex ?? 1,
            ),
          );

      ///注册话单消息解析
      NimPluginCoreKit().messageBuilderPool.registerMessageTypeDecoder(
            NIMMessageType.call,
            (message) => callMessageType,
          );

      ///注册位置消息构建
      NimPluginCoreKit().messageBuilderPool.registerMessageContentBuilder(
            callMessageType,
            (context, message) => ChatKitMessageAvChatItem(message: message),
          );
      _haveRegistered = true;
    }

    _setupCallKit(
      appKey: appKey,
      accountId: accountId,
      extraConfig: extraConfig,
    );
    NECallKitUI.instance.enableFloatWindow(true);
  }

  Future<bool> checkNetwork() async {
    var connects = await Connectivity().checkConnectivity();
    return connects.contains(ConnectivityResult.mobile) ||
        connects.contains(ConnectivityResult.wifi) ||
        connects.contains(ConnectivityResult.ethernet) ||
        connects.contains(ConnectivityResult.bluetooth) ||
        connects.contains(ConnectivityResult.vpn);
  }

  //音视频呼叫方式选择弹框
  Future<int?> _showCallActionSelectDialog(
    BuildContext context,
  ) {
    final videoLabel = S.of(context).chatMessageVideoCallAction;
    final audioLabel = S.of(context).chatMessageAudioCallAction;

    if (ChatKitUtils.isDesktopOrWeb) {
      return showDialog<int>(
        context: context,
        builder: (context) {
          return SimpleDialog(
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(1),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'images/ic_video_call_desktop.svg',
                      package: kPackage,
                      width: 24,
                      height: 24,
                    ),
                    Text(videoLabel)
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(2),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'images/ic_voice_call_desktop.svg',
                      package: kPackage,
                      width: 24,
                      height: 24,
                    ),
                    Text(audioLabel)
                  ],
                ),
              ),
            ],
          );
        },
      );
    }

    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  videoLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: CommonColors.color_333333),
                ),
                onTap: () => Navigator.of(context).pop(1),
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(
                  audioLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: CommonColors.color_333333),
                ),
                onTap: () => Navigator.of(context).pop(2),
              ),
              const Divider(height: 8, thickness: 8),
              ListTile(
                title: Text(
                  S.of(context).messageCancel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: CommonColors.color_333333),
                ),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  //语音通话
  Future<void> _onCallActionTap(
    BuildContext context,
    String conversationId,
    NIMConversationType sessionType,
  ) async {
    //判断网络
    if (!(await checkNetwork())) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    String targetId = ChatKitUtils.getConversationTargetId(conversationId);
    final blockToast = S.of(context).chatBeenBlockByOthers;
    final value = await _showCallActionSelectDialog(context);
    if (value == null) {
      return;
    }

    final result = await NECallKitUI.instance.call(
      targetId,
      value == 1 ? NECallType.video : NECallType.audio,
    );
    if (result.code == ChatMessageRepo.errorInBlackList) {
      ChatUIToast.show(blockToast);
    }
  }

  ///初始化呼叫组件,
  /// 在IM登录后初始化调用
  /// [appKey]      appKey
  /// [accountId]     accountId
  /// [extraConfig]  额外配置参数，包含 lckConfig 等
  void _setupCallKit({
    required String appKey,
    required String accountId,
    NEExtraConfig? extraConfig,
  }) {
    NECallKitUI.instance.setupEngine(
      appKey,
      accountId,
      extraConfig: extraConfig,
    );
    IMKitConfigCenter.enableCallKit = true;
  }
}
