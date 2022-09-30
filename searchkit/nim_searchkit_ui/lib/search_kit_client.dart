// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_common_ui/router/imkit_router.dart';
import 'package:netease_common_ui/router/imkit_router_constants.dart';

import 'generated/l10n.dart';
import 'page/search_kit_search_page.dart';

class SearchKitClient {
  static get delegate {
    return S.delegate;
  }

  static init() {
    IMKitRouter.instance.registerRouter(RouterConstants.PATH_GLOBAL_SEARCH_PAGE,
        (context) => const SearchKitGlobalSearchPage());
  }
}
