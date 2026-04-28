// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_corekit/report/xkit_report.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/router/imkit_router.dart';
import 'package:nim_chatkit/router/imkit_router_constants.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/view/history/chat_history_message_page.dart';
import 'package:nim_chatkit_ui/view/page/chat_pin_page.dart';
import 'package:nim_teamkit_ui/view/pages/team_kit_detail_page.dart';
import 'package:nim_teamkit_ui/view/pages/team_kit_member_list_page.dart';

import 'l10n/S.dart';
import 'view/pages/team_kit_setting_page.dart';

const String kPackage = 'nim_teamkit_ui';

class TeamKitClient {
  /// 群管理员数量限制
  int? teamManagerLimit;

  static get delegate {
    return S.delegate;
  }

  static init() {
    // TeamKitClientRepo.init();
    IMKitRouter.instance.registerRouter(
      RouterConstants.PATH_TEAM_SETTING_PAGE,
      (context) => TeamSettingPage(
        IMKitRouter.getArgumentFormMap<String>(context, 'teamId')!,
      ),
    );

    IMKitRouter.instance.registerRouter(
      RouterConstants.PATH_TEAM_DETAIL_PAGE,
      (context) => TeamKitDetailPage(
        teamId: IMKitRouter.getArgumentFormMap<String>(context, 'teamId')!,
      ),
    );

    // 注册桌面端群组详情弹框 Builder，桌面/Web 端以 Dialog 方式展示群组详情
    setDesktopTeamDetailBuilder(
      (teamId) => TeamKitDetailPage(teamId: teamId),
    );

    if (ChatKitUtils.isDesktopOrWeb &&
        ChatKitClient.instance.chatUIConfig.teamSettingPanelBuilder == null) {
      ChatKitClient.instance.chatUIConfig.teamSettingPanelBuilder =
          (teamId, onClose, onQuitTeam) {
        return TeamSettingPage(
          teamId,
          isPanel: true,
          onClose: onClose,
          onQuitTeam: onQuitTeam,
          pinPageBuilder: (conversationId, conversationType, chatTitle) {
            return ChatPinPage(
              conversationId: conversationId,
              conversationType: conversationType,
              chatTitle: chatTitle,
            );
          },
          historyPageBuilder: (conversationId, conversationType) {
            return ChatHistoryMessagePage(
              conversationId: conversationId,
              conversationType: conversationType,
            );
          },
        );
      };
    }

    IMKitRouter.instance.registerRouter(
      RouterConstants.PATH_TEAM_MEMBER_PAGE,
      (context) => TeamKitMemberListPage(
        tId: IMKitRouter.getArgumentFormMap<String>(context, 'teamId')!,
        showOwnerAndManager: IMKitRouter.getArgumentFormMap<bool>(
              context,
              'showOwnerAndManager',
            ) ??
            true,
        isGroupTeam:
            IMKitRouter.getArgumentFormMap<bool>(context, 'isGroupTeam') ??
                false,
        isMultiSelectModel: IMKitRouter.getArgumentFormMap<bool>(
              context,
              'isMultiSelectModel',
            ) ??
            false,
        singleSelect:
            IMKitRouter.getArgumentFormMap<bool>(context, 'singleSelect') ??
                false,
        showAIMember:
            IMKitRouter.getArgumentFormMap<bool>(context, 'showAIMember') ??
                true,
        maxSelectMemberCount: IMKitRouter.getArgumentFormMap<int>(
          context,
          'maxSelectMemberCount',
        ),
        showRole:
            IMKitRouter.getArgumentFormMap<bool>(context, 'showRole') ?? true,
        showRemoveButton:
            IMKitRouter.getArgumentFormMap<bool>(context, 'showRemoveButton') ??
                true,
      ),
    );

    XKitReporter().register(moduleName: 'TeamUIKit', moduleVersion: '10.3.0');
  }

  TeamKitClient._();

  static TeamKitClient? _instance;

  static TeamKitClient get instance {
    _instance ??= TeamKitClient._();
    return _instance!;
  }
}
