// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:netease_common_ui/widgets/platform_utils.dart';
import 'package:nim_chatkit/extension.dart';
import 'package:netease_common_ui/widgets/permission_request.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:nim_core/nim_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../chat_kit_client.dart';
import '../l10n/S.dart';

class MediaBottomActionOverlay extends StatelessWidget {
  final NIMMessage message;

  const MediaBottomActionOverlay(this.message, {Key? key}) : super(key: key);

  void _saveToast(BuildContext context, bool success) {
    String? content;
    if (message.messageType == NIMMessageType.video) {
      content = success
          ? S.of(context).chatMessageVideoSave
          : S.of(context).chatMessageVideoSaveFail;
    } else if (message.messageType == NIMMessageType.image) {
      content = success
          ? S.of(context).chatMessageImageSave
          : S.of(context).chatMessageImageSaveFail;
    }
    if (content != null) {
      Fluttertoast.showToast(msg: content);
    }
  }

  Future<String> _copyFile(String path, String ext) async {
    String target = path + '.' + ext;
    if (File(target).existsSync()) {
      return target;
    }
    var file = await File(path).copy(target);
    Alog.d(
        tag: 'ChatKit',
        moduleName: 'media save',
        content: 'copy from $path to $target');
    return file.path;
  }

  _saveFinish(BuildContext context, dynamic result) {
    Alog.d(
        tag: 'ChatKit',
        moduleName: 'media save',
        content: 'save media result:$result');
    _saveToast(context, result != null && result['isSuccess']);
  }

  void _saveFile(BuildContext context) async {
    if (Platform.isIOS) {
      var result;
      var attachment = message.messageAttachment;
      if (attachment is NIMImageAttachment) {
        var response = await Dio().get(attachment.url!,
            options: Options(responseType: ResponseType.bytes));
        result = await ImageGallerySaver.saveImage(response.data,
            name: attachment.displayName);
      } else if (attachment is NIMVideoAttachment) {
        result = await ImageGallerySaver.saveFile(attachment.path!);
      }
      _saveFinish(context, result);
      return;
    }
    if (message.isFileDownload()) {
      NIMFileAttachment attachment =
          message.messageAttachment as NIMFileAttachment;
      Alog.d(
          tag: 'ChatKit',
          moduleName: 'media save',
          content: 'media:${attachment.path}, ext:${attachment.extension}');
      String path = attachment.path!;
      if (!attachment.path!.endsWith(attachment.extension!)) {
        path = await _copyFile(attachment.path!, attachment.extension!);
      }
      var result = await ImageGallerySaver.saveFile(path);
      _saveFinish(context, result);
    } else {
      NimCore.instance.messageService
          .downloadAttachment(message: message, thumb: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
            left: 12,
            bottom: 20,
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              iconSize: 28,
              icon: SvgPicture.asset(
                'images/ic_close_round.svg',
                package: kPackage,
              ),
            )),
        Positioned(
          right: 12,
          bottom: 20,
          child: Row(
            children: [
              IconButton(
                onPressed: () async {
                  final permissionList;
                  if (Platform.isAndroid &&
                      await PlatformUtils.isAboveAndroidT()) {
                    permissionList = [Permission.manageExternalStorage];
                  } else {
                    permissionList = [Permission.storage];
                  }
                  PermissionsHelper.requestPermission(permissionList)
                      .then((value) {
                    if (value) {
                      _saveFile(context);
                    }
                  });
                },
                iconSize: 28,
                icon: SvgPicture.asset(
                  'images/ic_download.svg',
                  package: kPackage,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
