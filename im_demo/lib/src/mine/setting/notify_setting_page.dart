// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:im_common_ui/ui/background.dart';
import 'package:im_common_ui/widgets/common_list_tile.dart';
import 'package:im_common_ui/utils/color_utils.dart';
import 'package:im_common_ui/widgets/transparent_scaffold.dart';
import 'package:corekit_im/repo/config_repo.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../generated/l10n.dart';

class NotifySettingPage extends StatefulWidget {
  const NotifySettingPage({Key? key}) : super(key: key);

  @override
  State<NotifySettingPage> createState() => _NotifySettingPageState();
}

class _NotifySettingPageState extends State<NotifySettingPage> {
  bool notify = false;
  bool ring = false;
  bool shake = false;
  bool pushSync = false;
  bool showNoDetail = false;

  initSwitchValue() async {
    notify = await ConfigRepo.getMixNotification();
    if (Platform.isAndroid) {
      ring = await ConfigRepo.getRingToggle();
      shake = await ConfigRepo.getVibrateToggle();
    }
    pushSync = await ConfigRepo.isMultiPortPushOpen();
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
      title: S.of(context).setting_notify,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardBackground(
              child: CommonListTile(
                title: S.of(context).setting_notify_info,
                trailingType: TrailingType.onOff,
                switchValue: notify,
                onSwitchChanged: (value) {
                  if (Platform.isAndroid) {
                    ConfigRepo.updateMessageNotification(value);
                  }
                  ConfigRepo.updateMixNotification(value).then((success) {
                    Fluttertoast.showToast(
                        msg: success
                            ? S.of(context).setting_success
                            : S.of(context).setting_fail);
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
              _dividerTitle(S.of(context).setting_notify_mode),
              CardBackground(
                child: Column(
                  children: ListTile.divideTiles(context: context, tiles: [
                    CommonListTile(
                      title: S.of(context).setting_notify_mode_ring,
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
                      title: S.of(context).setting_notify_mode_shake,
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
            _dividerTitle(S.of(context).setting_notify_push),
            CardBackground(
              child: Column(
                children: ListTile.divideTiles(context: context, tiles: [
                  Visibility(
                    visible: false,
                    child: CommonListTile(
                      title: S.of(context).setting_notify_push_sync,
                      trailingType: TrailingType.onOff,
                      switchValue: pushSync,
                      onSwitchChanged: (value) {
                        ConfigRepo.updateMultiPortPushOpen(value);
                        setState(() {
                          pushSync = value;
                        });
                      },
                    ),
                  ),
                  CommonListTile(
                    title: S.of(context).setting_notify_push_detail,
                    trailingType: TrailingType.onOff,
                    switchValue: showNoDetail,
                    onSwitchChanged: (value) {
                      ConfigRepo.updatePushShowNoDetail(value).then((success) {
                        Fluttertoast.showToast(
                            msg: success
                                ? S.of(context).setting_success
                                : S.of(context).setting_fail);
                        if (success) {
                          setState(() {
                            showNoDetail = value;
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
