// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:netease_common_ui/widgets/permission_request.dart';
import 'package:netease_common_ui/widgets/platform_utils.dart';
import 'package:nim_chatkit/extension.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

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
      ChatUIToast.show(content, context: context);
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
      content: 'copy from $path to $target',
    );
    return file.path;
  }

  _saveFinish(BuildContext context, dynamic result) {
    Alog.d(
      tag: 'ChatKit',
      moduleName: 'media save',
      content: 'save media result:$result',
    );
    _saveToast(context, result != null && result['isSuccess']);
  }

  /// 清理文件名：去除花括号，移除多余的点，确保带正确的扩展名。
  /// [rawName] 为原始文件名，[ext] 为扩展名（可能带或不带前导点），
  /// [fallbackName] 为当 rawName 不可用时的回退名。
  String _sanitizeFileName(String? rawName, String? ext, String fallbackName) {
    // 1. 清理扩展名：去除前导点号，得到纯扩展名（如 "png"）
    String? pureExt;
    if (ext != null && ext.isNotEmpty) {
      pureExt = ext.replaceAll(RegExp(r'^\.+'), '');
      if (pureExt.isEmpty) pureExt = null;
    }

    // 2. 确定基础文件名
    String baseName =
        (rawName != null && rawName.isNotEmpty) ? rawName : fallbackName;

    // 3. 去除花括号（Windows SDK 可能返回 {UUID} 形式的名称）
    baseName = baseName.replaceAll(RegExp(r'[{}]'), '');

    // 4. 移除文件名末尾可能存在的多余点号
    baseName = baseName.replaceAll(RegExp(r'\.+$'), '');

    // 5. 如果文件名本身已包含正确扩展名则不再追加
    if (pureExt != null) {
      final extWithDot = '.$pureExt';
      if (!baseName.toLowerCase().endsWith(extWithDot.toLowerCase())) {
        baseName = '$baseName$extWithDot';
      }
    }

    return baseName;
  }

  /// Web 端下载逻辑：通过 Dio 下载到内存，再用 FilePicker 弹出"另存为"对话框
  Future<void> _saveFileWeb(BuildContext context) async {
    final attachment = message.attachment;
    String? url;
    String? rawName;

    if (attachment is NIMMessageImageAttachment) {
      url = attachment.url;
      rawName = attachment.name;
    } else if (attachment is NIMMessageVideoAttachment) {
      url = attachment.url;
      rawName = attachment.name;
    }

    if (url == null || url.isEmpty) {
      if (context.mounted) _saveToast(context, false);
      return;
    }

    // 构造安全的文件名
    final String? ext =
        (attachment is NIMMessageFileAttachment) ? attachment.ext : null;
    final fallback =
        (message.messageType == NIMMessageType.video) ? 'video' : 'image';
    final fileName = _sanitizeFileName(rawName, ext, fallback);

    try {
      // 先通过 Dio 将文件下载到内存
      final response = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data ?? []);
      if (bytes.isEmpty) {
        if (context.mounted) _saveToast(context, false);
        return;
      }

      // 使用 FilePicker 弹出"另存为"对话框，将字节写入用户选择的位置
      final targetPath = await FilePicker.platform.saveFile(
        dialogTitle: S.of(context).chatSaveFileDialogTitle,
        fileName: fileName,
        bytes: bytes,
      );

      // Web 端 saveFile 传入 bytes 后会直接触发浏览器保存，targetPath 可能为 null
      if (context.mounted) {
        _saveToast(context, targetPath != null || bytes.isNotEmpty);
      }
    } catch (e) {
      Alog.e(
        tag: 'ChatKit',
        moduleName: 'media save web',
        content: 'Failed to download file on web: $e',
      );
      if (context.mounted) _saveToast(context, false);
    }
  }

  /// 桌面端（macOS/Windows/Linux）另存为逻辑
  /// 跳过权限请求，使用 file_picker 弹出系统"另存为"对话框
  Future<void> _saveFileDesktop(BuildContext context) async {
    final attachment = message.attachment;

    // 获取源文件路径（可能需要先下载）
    String? sourcePath;
    String? rawName;

    if (attachment is NIMMessageImageAttachment) {
      rawName = attachment.name;
      final localPath = attachment.path;
      final hasLocal =
          localPath?.isNotEmpty == true && File(localPath!).existsSync();
      if (hasLocal) {
        sourcePath = localPath;
      } else if (attachment.url?.isNotEmpty == true) {
        // 无本地文件，先通过 SDK 下载
        final params = NIMDownloadMessageAttachmentParams(
          attachment: attachment,
          type: NIMDownloadAttachmentType.nimDownloadAttachmentTypeSource,
          thumbSize: NIMSize(),
          messageClientId: message.messageClientId,
        );
        final result =
            await NimCore.instance.storageService.downloadAttachment(params);
        if (!result.isSuccess || result.data == null) {
          if (context.mounted) _saveToast(context, false);
          return;
        }
        sourcePath = result.data;
      }
    } else if (attachment is NIMMessageVideoAttachment) {
      rawName = attachment.name;
      final localPath = attachment.path;
      final hasLocal =
          localPath?.isNotEmpty == true && File(localPath!).existsSync();
      if (hasLocal) {
        sourcePath = localPath;
      } else {
        // 无本地文件，先通过 SDK 下载
        final params = NIMDownloadMessageAttachmentParams(
          attachment: attachment,
          type: NIMDownloadAttachmentType.nimDownloadAttachmentTypeSource,
          thumbSize: NIMSize(),
          messageClientId: message.messageClientId,
        );
        final result =
            await NimCore.instance.storageService.downloadAttachment(params);
        if (!result.isSuccess || result.data == null) {
          if (context.mounted) _saveToast(context, false);
          return;
        }
        sourcePath = result.data;
      }
    }

    if (sourcePath == null) {
      if (context.mounted) _saveToast(context, false);
      return;
    }

    // 优先从 sourcePath 中提取有意义的文件名作为回退
    // （当 SDK 返回的 attachment.name 是 UUID 时，本地文件路径可能包含真实文件名）
    final fallbackFromPath = p.basename(sourcePath);
    final fallbackDefault =
        (message.messageType == NIMMessageType.video) ? 'video' : 'image';

    // 判断 rawName 是否为 UUID 形式（如 {0440491b-...} 或 0440491b-...）
    final uuidPattern = RegExp(
      r'^\{?[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\}?$',
    );
    final bool isNameUuid =
        rawName != null && uuidPattern.hasMatch(rawName.trim());

    // 如果 SDK 返回的 name 是 UUID，则优先使用本地文件路径中提取的文件名
    final effectiveName = (isNameUuid || rawName == null || rawName.isEmpty)
        ? fallbackFromPath
        : rawName;

    // 构造安全的文件名
    final String? ext =
        (attachment is NIMMessageFileAttachment) ? attachment.ext : null;
    final fileName = _sanitizeFileName(effectiveName, ext, fallbackDefault);

    Alog.d(
      tag: 'ChatKit',
      moduleName: 'media save desktop',
      content:
          'sourcePath: $sourcePath, rawName: $rawName, effectiveName: $effectiveName, fileName: $fileName',
    );

    print(
        'GeorgeTest: sourcePath: $sourcePath, rawName: $rawName, effectiveName: $effectiveName, fileName: $fileName');

    // 弹出系统"另存为"对话框
    final targetPath = await FilePicker.platform.saveFile(
      dialogTitle: S.of(context).chatSaveFileDialogTitle,
      fileName: fileName,
    );

    if (targetPath == null) {
      // 用户取消，静默忽略
      return;
    }

    // 将文件复制到用户选择的路径
    try {
      await File(sourcePath).copy(targetPath);
      if (context.mounted) _saveToast(context, true);
    } catch (e) {
      Alog.e(
        tag: 'ChatKit',
        moduleName: 'media save desktop',
        content: 'Failed to copy file to $targetPath: $e',
      );
      if (context.mounted) _saveToast(context, false);
    }
  }

  void _saveFile(BuildContext context) async {
    if (!kIsWeb && Platform.isIOS) {
      var result;
      var attachment = message.attachment;
      if (attachment is NIMMessageImageAttachment) {
        var response = await Dio().get(
          attachment.url!,
          options: Options(responseType: ResponseType.bytes),
        );
        result = await ImageGallerySaverPlus.saveImage(
          response.data,
          name: attachment.name,
        );
      } else if (attachment is NIMMessageVideoAttachment) {
        result = await ImageGallerySaverPlus.saveFile(attachment.path!);
      }
      _saveFinish(context, result);
      return;
    }
    if (message.isFileDownload()) {
      NIMMessageFileAttachment attachment =
          message.attachment as NIMMessageFileAttachment;
      Alog.d(
        tag: 'ChatKit',
        moduleName: 'media save',
        content: 'media:${attachment.path}, ext:${attachment.ext}',
      );
      String path = attachment.path!;
      if (!attachment.path!.endsWith(attachment.ext!)) {
        path = await _copyFile(attachment.path!, attachment.ext!);
      }
      var result = await ImageGallerySaverPlus.saveFile(path);
      _saveFinish(context, result);
    } else {
      NIMDownloadMessageAttachmentParams params =
          NIMDownloadMessageAttachmentParams(
        attachment: message.attachment!,
        type: NIMDownloadAttachmentType.nimDownloadAttachmentTypeSource,
        thumbSize: NIMSize(),
        messageClientId: message.messageClientId,
      );

      NimCore.instance.storageService.downloadAttachment(params).then((
        value,
      ) async {
        if (value.data != null) {
          var attachment = message.attachment as NIMMessageFileAttachment;
          String? path = value.data;
          if (path != null &&
              attachment.ext != null &&
              !path.endsWith(attachment.ext!)) {
            path = await _copyFile(path, attachment.ext!);
          }
          var result = await ImageGallerySaverPlus.saveFile(path!);
          _saveFinish(context, result);
        }
      });
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
          ),
        ),
        Positioned(
          right: 12,
          bottom: 20,
          child: Row(
            children: [
              IconButton(
                onPressed: () async {
                  // Web 端：跳过权限请求，通过浏览器下载
                  if (kIsWeb) {
                    _saveFileWeb(context);
                    return;
                  }
                  // 桌面端：跳过权限请求，直接弹出另存为对话框
                  if (Platform.isMacOS ||
                      Platform.isWindows ||
                      Platform.isLinux) {
                    _saveFileDesktop(context);
                    return;
                  }
                  // 移动端（Android/iOS）：原有权限 + ImageGallerySaver 流程
                  final permissionList;
                  if (Platform.isAndroid &&
                      await PlatformUtils.isAboveAndroidT()) {
                    permissionList = [Permission.photos];
                  } else {
                    permissionList = [Permission.storage];
                  }
                  PermissionsHelper.requestPermission(permissionList).then((
                    value,
                  ) {
                    if (value) {
                      if (value) {
                        _saveFile(context);
                      } else {
                        ChatUIToast.show(
                          S.of(context).chatPermissionSystemCheck,
                          context: context,
                        );
                      }
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
        ),
      ],
    );
  }
}
