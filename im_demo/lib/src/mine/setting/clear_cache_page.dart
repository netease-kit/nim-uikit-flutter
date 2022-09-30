// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:netease_common_ui/ui/background.dart';
import 'package:netease_common_ui/widgets/common_list_tile.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:netease_corekit_im/repo/misc_repo.dart';

import '../../../generated/l10n.dart';

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
    MiscRepo.getCacheSize().then((value) {
      double size = value / (1024 * 1024);
      cacheSize = size.toStringAsFixed(2);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
      title: S.of(context).setting_clear_cache,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: CardBackground(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ListTile.divideTiles(context: context, tiles: [
              CommonListTile(
                title: S.of(context).clear_message,
                trailingType: TrailingType.custom,
                onTap: () {
                  MiscRepo.clearMessageCache();
                  Fluttertoast.showToast(msg: S.of(context).clear_message_tips);
                },
              ),
              CommonListTile(
                title: S.of(context).clear_sdk_cache,
                trailingType: TrailingType.custom,
                customTrailing: Text(S.of(context).cache_size_text(cacheSize)),
                onTap: () {
                  MiscRepo.clearCacheSize();
                  setState(() {
                    cacheSize = '0.00';
                  });
                },
              )
            ]).toList(),
          ),
        ),
      ),
    );
  }
}
