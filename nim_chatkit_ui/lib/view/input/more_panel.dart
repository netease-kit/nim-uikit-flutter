// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:netease_common_ui/base/base_state.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/permission_request.dart';
import 'package:netease_common_ui/widgets/platform_utils.dart';
import 'package:netease_plugin_core_kit/netease_plugin_core_kit.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../chat_kit_client.dart';
import '../../l10n/S.dart';
import '../../view_model/chat_view_model.dart';
import 'actions.dart';

class MorePanel extends StatefulWidget {
  const MorePanel({
    Key? key,
    required this.conversationId,
    required this.conversationType,
    required this.onTranslateClick,
    this.moreActions,
    this.keepDefault = true,
  }) : super(key: key);

  final bool keepDefault;
  final List<ActionItem>? moreActions;

  final String conversationId;

  final NIMConversationType conversationType;

  final Function(
    BuildContext context,
    String conversationId,
    NIMConversationType conversationType, {
    NIMMessageSender? messageSender,
  })? onTranslateClick;

  @override
  State<StatefulWidget> createState() => _MorePanelState();
}

class _MorePanelState extends BaseState<MorePanel> {
  static const int pageSize = 8;
  final ImagePicker _picker = ImagePicker();

  List<ActionItem> getActions(NIMConversationType conversationType) {
    if (widget.moreActions != null) {
      return [
        if (widget.keepDefault) ..._defaultMoreActions(conversationType),
        ...widget.moreActions!,
      ];
    }
    return _defaultMoreActions(conversationType);
  }

  List<ActionItem> _defaultMoreActions(NIMConversationType conversationType) {
    final List<ActionItem> defaultActions = [
      ActionItem(
        type: ActionConstants.shoot,
        icon: SvgPicture.asset('images/ic_shoot.svg', package: kPackage),
        title: S.of(context).chatMessageMoreShoot,
        permissions: [Permission.camera],
        permissionTitle: S.of(context).permissionCameraTitle,
        permissionDesc: S.of(context).permissionCameraContent,
        deniedTip: S.of(context).chatPermissionSystemCheck,
        onTap: _onShootActionTap,
      ),
      ActionItem(
        type: ActionConstants.file,
        icon: SvgPicture.asset('images/ic_file.svg', package: kPackage),
        title: S.of(context).chatMessageMoreFile,
        onTap: _onFileActionTap,
      ),
    ];

    // 未配置翻译数字人则不展示【翻译】入口
    if (AIUserManager.instance.getAITranslateUser() != null) {
      defaultActions.add(
        ActionItem(
          type: ActionConstants.translate,
          icon: SvgPicture.asset('images/ic_translate.svg', package: kPackage),
          title: S.of(context).chatMessageMoreTranslate,
          onTap: widget.onTranslateClick,
        ),
      );
    }

    var pluginActions = NimPluginCoreKit()
        .itemPool
        .getMoreActions()
        .where(
          (action) =>
              action.enable?.call(
                widget.conversationId,
                widget.conversationType,
              ) !=
              false,
        )
        .map(
          (e) => ActionItem(
            type: e.type,
            icon: e.icon,
            title: e.title,
            permissions: e.permissions,
            deniedTip: e.deniedTip,
            index: e.index,
            onTap: e.onTap,
          ),
        );
    defaultActions.addAll(
      pluginActions.where((action) => action.index == null),
    );
    var indexActions = pluginActions.where((action) => action.index != null);
    for (var action in indexActions) {
      defaultActions.insert(action.index!, action);
    }
    return defaultActions;
  }

  _onFileActionTap(
    BuildContext context,
    String sessionId,
    NIMConversationType sessionType, {
    NIMMessageSender? messageSender,
  }) async {
    final permissionList;
    if (!kIsWeb &&
        Platform.isAndroid &&
        await PlatformUtils.isAboveAndroidT()) {
      permissionList = [Permission.photos, Permission.videos, Permission.audio];
    } else {
      permissionList = [Permission.storage];
    }
    showTopWarningDialog(
      context: context,
      title: S.of(context).permissionStorageTitle,
      content: S.of(context).permissionStorageContent,
    );
    if (!(await PermissionsHelper.requestPermission(permissionList))) {
      Navigator.of(context).pop();
      ChatUIToast.show(S.of(context).chatPermissionSystemCheck,
          context: context);
      return;
    }
    Navigator.of(context).pop();
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    final platformFile = result?.files.single;
    if (platformFile?.path != null) {
      final overSize = ChatKitClient.instance.chatUIConfig.maxFileSize ?? 200;
      if (platformFile!.size > overSize * 1024 * 1024) {
        ChatUIToast.show(
          S.of(context).chatMessageFileSizeOverLimit("$overSize"),
          context: context,
        );
        return;
      }
      context.read<ChatViewModel>().sendFileMessage(
            platformFile.path!,
            platformFile.name,
          );
    } else {
      Alog.w(tag: 'MorePanel', content: 'file path is null.');
    }
  }

  _onShootActionTap(
    BuildContext context,
    String sessionId,
    NIMConversationType sessionType, {
    NIMMessageSender? messageSender,
  }) {
    showAdaptiveChoose<int>(
      context: context,
      items: [
        AdaptiveChooseItem(
          label: S.of(context).chatMessageTakePhoto,
          value: 1,
        ),
        AdaptiveChooseItem(
          label: S.of(context).chatMessageTakeVideo,
          value: 2,
        ),
      ],
      showCancel: true,
    ).then((value) {
      if (value == 1) {
        _onTakePhoto();
      } else if (value == 2) {
        _onTakeVideo();
      }
    });
  }

  _onTakePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    Alog.i(
      tag: 'ChatKit',
      moduleName: 'more action',
      content: 'take photo path:${photo?.path}',
    );
    if (photo != null) {
      // iOS 相机产出的可能是 HEIC / Display P3 宽色域图片，
      // 直接发送会导致接收方或本地消息列表展示时出现严重偏绿色调。
      // 这里在 iOS 端统一通过 flutter_image_compress 转码为标准 sRGB JPEG，
      // 同时根据 EXIF 自动校正方向。
      String sendPath = photo.path;
      String sendName = photo.name;
      if (!kIsWeb && Platform.isIOS) {
        final normalized = await _normalizeIOSPhoto(photo);
        if (normalized != null) {
          sendPath = normalized.path;
          sendName = normalized.name;
        }
      }
      final codec = await instantiateImageCodec(
        File(sendPath).readAsBytesSync(),
      );
      final frame = await codec.getNextFrame();
      context.read<ChatViewModel>().sendImageMessage(
            sendPath,
            sendName,
            frame.image.width,
            frame.image.height,
          );
    }
  }

  /// 将 iOS 相机产出的 HEIC / 宽色域图片转换为标准 sRGB JPEG。
  /// 转换失败时返回 null，由调用方回退使用原始文件。
  Future<XFile?> _normalizeIOSPhoto(XFile origin) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final baseName = p.basenameWithoutExtension(origin.name);
      final fileName =
          '${baseName}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetPath = p.join(tempDir.path, fileName);
      final result = await FlutterImageCompress.compressAndGetFile(
        origin.path,
        targetPath,
        format: CompressFormat.jpeg,
        quality: 80,
        // 修正部分相机拍摄的图片方向丢失问题
        autoCorrectionAngle: true,
        keepExif: false,
      );
      if (result != null) {
        Alog.i(
          tag: 'ChatKit',
          moduleName: 'more action',
          content: 'normalize ios photo to sRGB jpeg: ${result.path}',
        );
        return XFile(result.path, name: fileName);
      }
    } catch (e, s) {
      Alog.e(
        tag: 'ChatKit',
        moduleName: 'more action',
        content: 'normalize ios photo failed: $e\n$s',
      );
    }
    return null;
  }

  _onTakeVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    Alog.i(
      tag: 'ChatKit',
      moduleName: 'more action',
      content: 'take video path:${video?.path}',
    );
    if (video != null) {
      VideoPlayerController controller;
      if (!kIsWeb && Platform.isAndroid) {
        controller = VideoPlayerController.file(
          File(video.path),
          viewType: VideoViewType.platformView,
        );
      } else {
        controller = VideoPlayerController.file(File(video.path));
      }

      controller.initialize().then((value) {
        context.read<ChatViewModel>().sendVideoMessage(
              video.path,
              video.name,
              controller.value.duration.inMilliseconds,
              controller.value.size.width.toInt(),
              controller.value.size.height.toInt(),
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<ActionItem> moreActions = getActions(widget.conversationType);
    List<Widget> pages = [];
    int size = (moreActions.length / pageSize).ceil();
    for (int i = 0; i < size; ++i) {
      int start = i * pageSize;
      int end = start + pageSize > moreActions.length
          ? moreActions.length
          : start + pageSize;
      pages.add(
        MoreActionPage(
          actions: moreActions.sublist(start, end),
          conversationId: widget.conversationId,
          conversationType: widget.conversationType,
          messageSender: (message) {
            context.read<ChatViewModel>().sendMessage(message);
          },
        ),
      );
    }
    return PageView(children: pages, allowImplicitScrolling: true);
  }
}

class MoreActionPage extends StatelessWidget {
  const MoreActionPage({
    Key? key,
    required this.actions,
    required this.conversationId,
    required this.conversationType,
    this.messageSender,
  }) : super(key: key);

  final List<ActionItem> actions;

  final String conversationId;

  final NIMConversationType conversationType;

  final NIMMessageSender? messageSender;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: Wrap(
          spacing: (sw - 56 * 4 - 16 * 2) / 3,
          runSpacing: 16,
          children: actions.map((action) {
            return MoreItemAction(
              action: action,
              conversationId: conversationId,
              conversationType: conversationType,
              messageSender: messageSender,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class MoreItemAction extends StatelessWidget {
  const MoreItemAction({
    Key? key,
    required this.action,
    required this.conversationId,
    required this.conversationType,
    this.messageSender,
  }) : super(key: key);

  final ActionItem action;

  final String conversationId;

  final NIMConversationType conversationType;

  final NIMMessageSender? messageSender;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: action.permissions != null
              ? () {
                  if (action.permissionDesc?.isNotEmpty == true) {
                    showTopWarningDialog(
                      context: context,
                      title: action.permissionTitle,
                      content: action.permissionDesc ?? '',
                    );
                  }
                  PermissionsHelper.requestPermission(
                    action.permissions!,
                    deniedTip: action.deniedTip,
                  ).then((value) {
                    if (action.permissionDesc?.isNotEmpty == true) {
                      Navigator.of(context).pop();
                    }
                    if (value && action.onTap != null) {
                      action.onTap!(
                        context,
                        conversationId,
                        conversationType,
                        messageSender: messageSender,
                      );
                    }
                  });
                }
              : () {
                  if (action.onTap != null) {
                    action.onTap!(
                      context,
                      conversationId,
                      conversationType,
                      messageSender: messageSender,
                    );
                  }
                },
          child: Container(
            height: 56,
            width: 56,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: action.icon,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          action.title ?? "",
          style: const TextStyle(
            fontSize: 10,
            color: CommonColors.color_666666,
          ),
        ),
      ],
    );
  }
}
