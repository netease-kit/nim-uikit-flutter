// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:im_common_ui/router/imkit_router.dart';
import 'package:im_common_ui/router/imkit_router_constants.dart';

import 'generated/l10n.dart';
import 'view/pages/team_kit_setting_page.dart';

class TeamKitClient {
  static get delegate {
    return S.delegate;
  }

  static init() {
    IMKitRouter.instance.registerRouter(
        RouterConstants.PATH_TEAM_SETTING_PAGE,
        (context) => TeamSettingPage(
            IMKitRouter.getArgumentFormMap<String>(context, 'teamId')!));
  }
}
