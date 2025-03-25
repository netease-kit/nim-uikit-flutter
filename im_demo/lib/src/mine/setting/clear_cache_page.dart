// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_common_ui/ui/background.dart';
import 'package:netease_common_ui/widgets/common_list_tile.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../l10n/S.dart';

class ClearCachePage extends StatefulWidget {
  const ClearCachePage({Key? key}) : super(key: key);

  @override
  State<ClearCachePage> createState() => _ClearCachePageState();
}

class _ClearCachePageState extends State<ClearCachePage> {
  String cacheSize = '';

  @override
  void initState() {
    super.initState();
    // MiscRepo.getCacheSize().then((value) {
    //   double size = value / (1024 * 1024);
    //   cacheSize = size.toStringAsFixed(2);
    //   setState(() {});
    // });
  }

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
      title: S.of(context).settingClearCache,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: CardBackground(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ListTile.divideTiles(context: context, tiles: [
                CommonListTile(
                  title: S.of(context).clearMessage,
                  trailingType: TrailingType.custom,
                  onTap: () {
                    // MiscRepo.clearMessageCache();
                    Fluttertoast.showToast(msg: S.of(context).clearMessageTips);
                  },
                ),
                CommonListTile(
                  title: S.of(context).clearSdkCache,
                  trailingType: TrailingType.custom,
                  customTrailing: Text(S.of(context).cacheSizeText(cacheSize)),
                  onTap: () {
                    // MiscRepo.clearCacheSize();
                    setState(() {
                      cacheSize = '0.00';
                    });
                  },
                )
              ]).toList()),
        ),
      ),
    );
  }
}
