// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:netease_common_ui/ui/background.dart';
import 'package:netease_common_ui/widgets/common_list_tile.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:netease_corekit_im/repo/config_repo.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../l10n/S.dart';

class NotifySettingPage extends StatefulWidget {
  const NotifySettingPage({Key? key}) : super(key: key);

  @override
  State<NotifySettingPage> createState() => _NotifySettingPageState();
}

class _NotifySettingPageState extends State<NotifySettingPage> {
  bool notify = false;
  bool ring = false;
  bool shake = false;
  bool showNoDetail = false;

  initSwitchValue() async {
    notify = await ConfigRepo.getMixNotification();
    if (Platform.isAndroid) {
      ring = await ConfigRepo.getRingToggle();
      shake = await ConfigRepo.getVibrateToggle();
    }
    showNoDetail = await ConfigRepo.isPushShowNoDetail();

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initSwitchValue();
  }

  Widget _dividerTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 16, 13, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, color: CommonColors.color_666666),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
      title: S.of(context).settingNotify,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardBackground(
              child: CommonListTile(
                title: S.of(context).settingNotifyInfo,
                trailingType: TrailingType.onOff,
                switchValue: notify,
                onSwitchChanged: (value) {
                  if (Platform.isAndroid) {
                    ConfigRepo.updateMessageNotification(value);
                  }
                  ConfigRepo.updateMixNotification(value).then((success) {
                    Fluttertoast.showToast(
                        msg: success
                            ? S.of(context).settingSuccess
                            : S.of(context).settingFail);
                    if (success) {
                      setState(() {
                        notify = value;
                      });
                    }
                  });
                },
              ),
            ),
            if (Platform.isAndroid) ...[
              _dividerTitle(S.of(context).settingNotifyMode),
              CardBackground(
                child: Column(
                  children: ListTile.divideTiles(context: context, tiles: [
                    CommonListTile(
                      title: S.of(context).settingNotifyModeRing,
                      trailingType: TrailingType.onOff,
                      switchValue: ring,
                      onSwitchChanged: (value) {
                        ConfigRepo.updateRingToggle(value);
                        setState(() {
                          ring = value;
                        });
                      },
                    ),
                    CommonListTile(
                      title: S.of(context).settingNotifyModeShake,
                      trailingType: TrailingType.onOff,
                      switchValue: shake,
                      onSwitchChanged: (value) {
                        ConfigRepo.updateVibrateToggle(value);
                        setState(() {
                          shake = value;
                        });
                      },
                    ),
                  ]).toList(),
                ),
              ),
            ],
            _dividerTitle(S.of(context).settingNotifyPush),
            CardBackground(
              child: Column(
                children: ListTile.divideTiles(context: context, tiles: [
                  CommonListTile(
                    title: S.of(context).settingNotifyPushDetail,
                    trailingType: TrailingType.onOff,
                    switchValue: showNoDetail,
                    onSwitchChanged: (value) {
                      ConfigRepo.updatePushShowNoDetail(!showNoDetail)
                          .then((success) {
                        Fluttertoast.showToast(
                            msg: success
                                ? S.of(context).settingSuccess
                                : S.of(context).settingFail);
                        if (success) {
                          setState(() {
                            showNoDetail = !showNoDetail;
                          });
                        }
                      });
                    },
                  ),
                ]).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
