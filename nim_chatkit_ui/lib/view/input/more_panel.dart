// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/permission_request.dart';
import 'package:netease_common_ui/widgets/platform_utils.dart';
import 'package:netease_plugin_core_kit/netease_plugin_core_kit.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../../chat_kit_client.dart';
import '../../l10n/S.dart';
import '../../view_model/chat_view_model.dart';
import 'actions.dart';

class MorePanel extends StatefulWidget {
  const MorePanel(
      {Key? key,
      required this.sessionId,
      required this.sessionType,
      required this.onTranslateClick,
      this.moreActions,
      this.keepDefault = true})
      : super(key: key);

  final bool keepDefault;
  final List<ActionItem>? moreActions;

  final String sessionId;

  final NIMConversationType sessionType;

  final Function(BuildContext context, String conversationId,
          NIMConversationType sessionType, {NIMMessageSender? messageSender})?
      onTranslateClick;

  @override
  State<StatefulWidget> createState() => _MorePanelState();
}

class _MorePanelState extends State<MorePanel> {
  static const int pageSize = 8;
  final ImagePicker _picker = ImagePicker();

  List<ActionItem> getActions() {
    if (widget.moreActions != null) {
      return [
        if (widget.keepDefault) ..._defaultMoreActions(),
        ...widget.moreActions!,
      ];
    }
    return _defaultMoreActions();
  }

  List<ActionItem> _defaultMoreActions() {
    final List<ActionItem> defaultActions = [
      ActionItem(
          type: ActionConstants.shoot,
          icon: SvgPicture.asset(
            'images/ic_shoot.svg',
            package: kPackage,
          ),
          title: S.of(context).chatMessageMoreShoot,
          permissions: [Permission.camera],
          onTap: _onShootActionTap),
      ActionItem(
          type: ActionConstants.file,
          icon: SvgPicture.asset(
            'images/ic_file.svg',
            package: kPackage,
          ),
          title: S.of(context).chatMessageMoreFile,
          onTap: _onFileActionTap),
    ];

    // 未配置翻译数字人则不展示【翻译】入口
    if (AIUserManager.instance.getAITranslateUser() != null) {
      defaultActions.add(ActionItem(
          type: ActionConstants.translate,
          icon: SvgPicture.asset(
            'images/ic_translate.svg',
            package: kPackage,
          ),
          title: S.of(context).chatMessageMoreTranslate,
          onTap: widget.onTranslateClick));
    }

    var pluginActions = NimPluginCoreKit()
        .itemPool
        .getMoreActions()
        .where((action) => action.enable?.call(widget.sessionType) != false)
        .map((e) => ActionItem(
            type: e.type,
            icon: e.icon,
            title: e.title,
            permissions: e.permissions,
            deniedTip: e.deniedTip,
            onTap: e.onTap));
    defaultActions.addAll(pluginActions);
    return defaultActions;
  }

  _onFileActionTap(
      BuildContext context, String sessionId, NIMConversationType sessionType,
      {NIMMessageSender? messageSender}) async {
    final permissionList;
    if (Platform.isAndroid && await PlatformUtils.isAboveAndroidT()) {
      permissionList = [Permission.photos];
    } else {
      permissionList = [Permission.storage];
    }
    if (!(await PermissionsHelper.requestPermission(permissionList))) {
      return;
    }
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    final platformFile = result?.files.single;
    if (platformFile?.path != null) {
      final overSize = ChatKitClient.instance.chatUIConfig.maxFileSize ?? 200;
      if (platformFile!.size > overSize * 1024 * 1024) {
        Fluttertoast.showToast(
            msg: S.of(context).chatMessageFileSizeOverLimit("$overSize"));
        return;
      }
      context
          .read<ChatViewModel>()
          .sendFileMessage(platformFile.path!, platformFile.name);
    } else {
      Alog.w(tag: 'MorePanel', content: 'file path is null.');
    }
  }

  _onShootActionTap(
      BuildContext context, String sessionId, NIMConversationType sessionType,
      {NIMMessageSender? messageSender}) {
    var style = const TextStyle(fontSize: 16, color: CommonColors.color_333333);
    showBottomChoose<int>(
            context: context,
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Text(
                  S.of(context).chatMessageTakePhoto,
                  style: style,
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context, 2);
                },
                child: Text(
                  S.of(context).chatMessageTakeVideo,
                  style: style,
                ),
              ),
            ],
            showCancel: true)
        .then((value) {
      if (value == 1) {
        _onTakePhoto();
      } else if (value == 2) {
        _onTakeVideo();
      }
    });
  }

  _onTakePhoto() async {
    final XFile? photo =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    Alog.i(
        tag: 'ChatKit',
        moduleName: 'more action',
        content: 'take photo path:${photo?.path}');
    if (photo != null) {
      final codec =
          await instantiateImageCodec(File(photo.path).readAsBytesSync());
      final frame = await codec.getNextFrame();
      context.read<ChatViewModel>().sendImageMessage(
          photo.path, photo.name, frame.image.width, frame.image.height);
    }
  }

  _onTakeVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    Alog.i(
        tag: 'ChatKit',
        moduleName: 'more action',
        content: 'take video path:${video?.path}');
    if (video != null) {
      VideoPlayerController controller =
          VideoPlayerController.file(File(video.path));
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
    List<ActionItem> moreActions = getActions();
    List<Widget> pages = [];
    int size = (moreActions.length / pageSize).ceil();
    for (int i = 0; i < size; ++i) {
      int start = i * pageSize;
      int end = start + pageSize > moreActions.length
          ? moreActions.length
          : start + pageSize;
      pages.add(MoreActionPage(
        actions: moreActions.sublist(start, end),
        sessionId: widget.sessionId,
        sessionType: widget.sessionType,
        messageSender: (message) {
          context.read<ChatViewModel>().sendMessage(message);
        },
      ));
    }
    return PageView(
      children: pages,
      allowImplicitScrolling: true,
    );
  }
}

class MoreActionPage extends StatelessWidget {
  const MoreActionPage({
    Key? key,
    required this.actions,
    required this.sessionId,
    required this.sessionType,
    this.messageSender,
  }) : super(key: key);

  final List<ActionItem> actions;

  final String sessionId;

  final NIMConversationType sessionType;

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
                sessionId: sessionId,
                sessionType: sessionType,
                messageSender: messageSender);
          }).toList(),
        ),
      ),
    );
  }
}

class MoreItemAction extends StatelessWidget {
  const MoreItemAction(
      {Key? key,
      required this.action,
      required this.sessionId,
      required this.sessionType,
      this.messageSender})
      : super(key: key);

  final ActionItem action;

  final String sessionId;

  final NIMConversationType sessionType;

  final NIMMessageSender? messageSender;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: action.permissions != null
              ? () {
                  PermissionsHelper.requestPermission(action.permissions!,
                          deniedTip: action.deniedTip)
                      .then((value) {
                    if (value && action.onTap != null) {
                      action.onTap!(context, sessionId, sessionType,
                          messageSender: messageSender);
                    }
                  });
                }
              : () {
                  if (action.onTap != null) {
                    action.onTap!(context, sessionId, sessionType,
                        messageSender: messageSender);
                  }
                },
          child: Container(
            height: 56,
            width: 56,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10), color: Colors.white),
            child: action.icon,
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          action.title ?? "",
          style:
              const TextStyle(fontSize: 10, color: CommonColors.color_666666),
        )
      ],
    );
  }
}
