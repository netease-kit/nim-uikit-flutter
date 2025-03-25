// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_corekit/report/xkit_report.dart';
import 'package:netease_corekit_im/router/imkit_router.dart';
import 'package:netease_corekit_im/router/imkit_router_constants.dart';

import 'l10n/S.dart';
import 'page/search_kit_search_page.dart';

const String kPackage = 'nim_searchkit_ui';

class SearchKitClient {
  static get delegate {
    return S.delegate;
  }

  static init() {
    // SearchKitClientRepo.init();
    IMKitRouter.instance.registerRouter(RouterConstants.PATH_GLOBAL_SEARCH_PAGE,
        (context) => const SearchKitGlobalSearchPage());

    XKitReporter().register(moduleName: 'SearchUIKit', moduleVersion: '10.0.0');
  }
}
