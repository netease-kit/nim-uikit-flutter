// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_corekit/report/xkit_report.dart';
import 'package:nim_chatkit/router/imkit_router.dart';
import 'package:nim_chatkit/router/imkit_router_constants.dart';
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
            IMKitRouter.getArgumentFormMap<String>(context, 'teamId')!));

    IMKitRouter.instance.registerRouter(
      RouterConstants.PATH_TEAM_DETAIL_PAGE,
      (context) => TeamKitDetailPage(
        teamId: IMKitRouter.getArgumentFormMap<String>(context, 'teamId')!,
      ),
    );

    IMKitRouter.instance.registerRouter(
        RouterConstants.PATH_TEAM_MEMBER_PAGE,
        (context) => TeamKitMemberListPage(
            tId: IMKitRouter.getArgumentFormMap<String>(context, 'teamId')!,
            showOwnerAndManager: IMKitRouter.getArgumentFormMap<bool>(
                    context, 'showOwnerAndManager') ??
                true,
            isGroupTeam:
                IMKitRouter.getArgumentFormMap<bool>(context, 'isGroupTeam') ??
                    false,
            isMultiSelectModel: IMKitRouter.getArgumentFormMap<bool>(
                    context, 'isMultiSelectModel') ??
                false,
            singleSelect:
                IMKitRouter.getArgumentFormMap<bool>(context, 'singleSelect') ??
                    false,
            showAIMember:
                IMKitRouter.getArgumentFormMap<bool>(context, 'showAIMember') ??
                    true,
            maxSelectMemberCount: IMKitRouter.getArgumentFormMap<int>(
                context, 'maxSelectMemberCount'),
            showRole: IMKitRouter.getArgumentFormMap<bool>(context, 'showRole') ?? true,
            showRemoveButton: IMKitRouter.getArgumentFormMap<bool>(context, 'showRemoveButton') ?? true));

    XKitReporter().register(moduleName: 'TeamUIKit', moduleVersion: '10.3.0');
  }

  TeamKitClient._();

  static TeamKitClient? _instance;

  static TeamKitClient get instance {
    _instance ??= TeamKitClient._();
    return _instance!;
  }
}
