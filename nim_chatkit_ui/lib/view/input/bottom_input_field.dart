// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:extended_text_field/extended_text_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common/netease_common.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/imagePicker/wechat_assets_picker.dart';
import 'package:netease_plugin_core_kit/netease_plugin_core_kit.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit/model/ait/ait_contacts_model.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit/services/message/nim_chat_cache.dart';
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:nim_chatkit_ui/helper/chat_message_helper.dart';
import 'package:nim_chatkit_ui/helper/chat_message_user_helper.dart';
import 'package:nim_chatkit_ui/view/ait/ait_manager.dart';
import 'package:nim_chatkit_ui/view/ait/ait_model.dart';
import 'package:nim_chatkit_ui/view/input/emoji/emoji.dart';
import 'package:nim_chatkit_ui/view/input/emoji/emoji_text.dart';
import 'package:nim_chatkit_ui/view/input/emoji_panel.dart';
import 'package:nim_chatkit_ui/view/input/ne_special_text_span_builder.dart';
import 'package:nim_chatkit_ui/view/input/translate_panel.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:video_player/video_player.dart';

import '../../chat_kit_client.dart';
import '../../l10n/S.dart';
import '../../view_model/chat_view_model.dart';
import 'actions.dart';
import 'more_panel.dart';
import 'record_panel.dart';
import 'video_metadata_web_stub.dart'
    if (dart.library.html) 'video_metadata_web_impl.dart' as _videoMetadata;

class BottomInputField extends StatefulWidget {
  const BottomInputField({
    Key? key,
    required this.scrollController,
    required this.conversationType,
    required this.conversationId,
    this.hint,
    this.chatUIConfig,
  }) : super(key: key);

  final String? hint;
  final NIMConversationType conversationType;
  final AutoScrollController scrollController;
  final ChatUIConfig? chatUIConfig;
  final String conversationId;

  @override
  State<StatefulWidget> createState() => _BottomInputFieldState();
}

class _BottomInputFieldState extends State<BottomInputField>
    with WidgetsBindingObserver {
  static const String blank = ' ';

  late TextEditingController inputController;
  late TextEditingController titleController;
  late ScrollController _scrollController;
  late FocusNode _focusNode;
  late FocusNode _titleFocusNode;
  late ChatViewModel _viewModel;

  String inputText = '';

  bool mute = false;
  bool _keyboardShow = false;
  bool _recording = false;

  /// none, input, record, emoji, more
  String _currentType = ActionConstants.none;

  AitManager? _aitManager;

  bool _isExpanded = false;

  // 展开输入框翻译面板
  bool _isTranslating = false;
  final GlobalKey<dynamic> _translatePanel = GlobalKey();

  ChatMessage? _replyMessageTemp;

  /// 桌面端表情弹框的 OverlayEntry
  OverlayEntry? _desktopEmojiOverlay;

  /// 表情按钮的 GlobalKey，用于定位弹框
  final GlobalKey _emojiButtonKey = GlobalKey();

  /// 桌面端图片/视频选择弹框的 OverlayEntry
  OverlayEntry? _desktopImageMenuOverlay;

  /// 图片按钮的 GlobalKey，用于定位弹框
  final GlobalKey _imageButtonKey = GlobalKey();

  /// 桌面端 @ 弹框的 OverlayEntry
  OverlayEntry? _desktopAitOverlay;

  /// 输入框容器的 GlobalKey，用于定位 @ 弹框宽度和位置
  final GlobalKey _inputContainerKey = GlobalKey();

  /// 图片/视频选择弹框的延迟关闭定时器
  Timer? _imageMenuCloseTimer;

  /// 标记是否正在执行 dispose，防止在 dispose 中调用 setState
  bool _isDisposing = false;

  hideAllPanel() {
    _focusNode.unfocus();
    _titleFocusNode.unfocus();
    setState(() {
      _currentType = ActionConstants.none;
      _isExpanded = false;
    });
  }

  addMention(String accId) {
    if (enableAit()) {
      _addAitMember(accId, reAdd: true);
    }
  }

  _onRecordActionTap(
    BuildContext context,
    String sessionId,
    NIMConversationType sessionType, {
    NIMMessageSender? messageSender,
  }) {
    if (_currentType == ActionConstants.record) {
      _currentType = ActionConstants.none;
    } else {
      _focusNode.unfocus();
      _currentType = ActionConstants.record;
    }
    setState(() {});
  }

  _onEmojiActionTap(
    BuildContext context,
    String sessionId,
    NIMConversationType sessionType, {
    NIMMessageSender? messageSender,
  }) {
    if (_titleFocusNode.hasFocus) {
      return;
    }
    // 桌面端：弹框方式显示表情
    if (ChatKitUtils.isDesktopOrWeb) {
      if (_desktopEmojiOverlay != null) {
        _dismissDesktopEmojiPopup();
      } else {
        _showDesktopEmojiPopup();
      }
      return;
    }
    // 移动端：底部面板
    if (_currentType == ActionConstants.emoji) {
      _currentType = ActionConstants.none;
    } else {
      _focusNode.unfocus();
      _currentType = ActionConstants.emoji;
    }
    setState(() {});
  }

  /// 桌面端：弹出表情选择弹框（显示在输入框右上方）
  void _showDesktopEmojiPopup() {
    final overlay = Overlay.of(context);
    // 获取表情按钮的位置
    final RenderBox? buttonBox =
        _emojiButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (buttonBox == null) return;

    final buttonPosition = buttonBox.localToGlobal(Offset.zero);

    // 弹框尺寸：每行9个表情，每个40px，加上 padding
    const double popupWidth = 9 * 44.0 + 32;
    const double popupHeight = 380.0;

    // 弹框位置：在按钮上方，水平居中对齐
    final double left =
        buttonPosition.dx + buttonBox.size.width / 2 - popupWidth / 2;
    final double top = buttonPosition.dy - popupHeight - 8;

    _desktopEmojiOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // 透明蒙层，点击关闭弹框
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismissDesktopEmojiPopup,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
            // 表情弹框
            Positioned(
              left: left.clamp(
                  8.0, MediaQuery.of(context).size.width - popupWidth - 8),
              top: top.clamp(8.0, double.infinity),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                shadowColor: Colors.black26,
                child: Container(
                  width: popupWidth,
                  height: popupHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _DesktopEmojiGrid(
                    onEmojiSelected: (emoji) {
                      _onDesktopEmojiSelected(emoji);
                    },
                    onEmojiDelete: _onDesktopEmojiDelete,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_desktopEmojiOverlay!);
    setState(() {
      _currentType = ActionConstants.emoji;
    });
  }

  /// 关闭桌面端表情弹框
  void _dismissDesktopEmojiPopup() {
    _desktopEmojiOverlay?.remove();
    _desktopEmojiOverlay = null;
    // 仅在 mounted 且非 dispose 阶段才调用 setState 更新 UI
    if (mounted && !_isDisposing) {
      setState(() {
        _currentType = ActionConstants.none;
      });
    }
  }

  /// 关闭桌面端 @ 弹框
  void _dismissDesktopAitPopup() {
    _desktopAitOverlay?.remove();
    _desktopAitOverlay = null;
  }

  /// 显示桌面端/Web 端 @ 成员选择弹框
  /// 弹框宽度与输入框容器对齐，从输入框上方弹出
  void _showDesktopAitPopup(void Function(dynamic aitUser) onSelected) {
    if (_aitManager == null) return;

    // P2P 且无数字人则不弹框
    final aiList = _aitManager!.aiUserList;
    if (_aitManager!.isP2P && aiList.isEmpty) return;

    // 弹框显示前，用当前 NIMChatCache 中最新的群成员刷新列表
    // 防止切换会话时读到旧缓存
    _aitManager!.refreshMemberList();

    final overlay = Overlay.of(context);

    // 获取输入框容器的位置和宽度
    final RenderBox? containerBox =
        _inputContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (containerBox == null) return;

    final containerPosition = containerBox.localToGlobal(Offset.zero);
    final containerWidth = containerBox.size.width;

    const double maxHeight = 320.0;
    const double itemHeight = 56.0;
    const double headerHeight = 48.0;

    // 在插入 OverlayEntry 前，把 screenHeight 从当前 context 取好，
    // 避免 _DesktopAitPopup 的 build 里调用 MediaQuery.of(context) 注册
    // 对旧 InheritedWidget 树的依赖，防止切换会话时触发断言
    final double screenHeight = MediaQuery.of(context).size.height;

    _desktopAitOverlay = OverlayEntry(
      builder: (overlayContext) {
        return _DesktopAitPopup(
          aitManager: _aitManager!,
          containerPosition: containerPosition,
          containerWidth: containerWidth,
          screenHeight: screenHeight,
          maxHeight: maxHeight,
          itemHeight: itemHeight,
          headerHeight: headerHeight,
          onSelected: (aitUser) {
            _dismissDesktopAitPopup();
            onSelected(aitUser);
          },
          onDismiss: _dismissDesktopAitPopup,
        );
      },
    );
    overlay.insert(_desktopAitOverlay!);
  }

  /// 显示桌面端图片/视频选择弹框
  void _showDesktopImageMenu() {
    if (_desktopImageMenuOverlay != null) return;
    final overlay = Overlay.of(context);
    final RenderBox? buttonBox =
        _imageButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (buttonBox == null) return;

    final buttonPosition = buttonBox.localToGlobal(Offset.zero);
    const double menuWidth = 120.0;
    const double menuHeight = 80.0;

    // 弹框位置：在按钮上方，水平居中对齐
    final double left =
        buttonPosition.dx + buttonBox.size.width / 2 - menuWidth / 2;
    final double top = buttonPosition.dy - menuHeight - 8;

    // 提前获取本地化字符串，避免 OverlayEntry 中 context 无法访问本地化
    final photoLabel = S.of(context).chatMessagePickPhoto;
    final videoLabel = S.of(context).chatMessagePickVideo;
    final screenWidth = MediaQuery.of(context).size.width;

    _desktopImageMenuOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: left.clamp(8.0, screenWidth - menuWidth - 8),
          top: top.clamp(8.0, double.infinity),
          child: MouseRegion(
            onEnter: (_) {
              _imageMenuCloseTimer?.cancel();
            },
            onExit: (_) {
              _imageMenuCloseTimer?.cancel();
              _imageMenuCloseTimer =
                  Timer(const Duration(milliseconds: 200), () {
                _dismissDesktopImageMenu();
              });
            },
            child: _DesktopImageVideoMenu(
              photoLabel: photoLabel,
              videoLabel: videoLabel,
              onPickImage: () {
                _dismissDesktopImageMenu();
                _onDesktopPickImage();
              },
              onPickVideo: () {
                _dismissDesktopImageMenu();
                _onDesktopPickVideo();
              },
            ),
          ),
        );
      },
    );
    overlay.insert(_desktopImageMenuOverlay!);
  }

  /// 关闭桌面端图片/视频选择弹框
  void _dismissDesktopImageMenu() {
    _imageMenuCloseTimer?.cancel();
    _imageMenuCloseTimer = null;
    _desktopImageMenuOverlay?.remove();
    _desktopImageMenuOverlay = null;
  }

  //获取桌面端插件的更多操作
  List<ActionItem> _getDesktopPluginActions() {
    final actions = <ActionItem>[];
    for (final action in NimPluginCoreKit().itemPool.getMoreActions()) {
      final enabled =
          action.enable?.call(widget.conversationId, widget.conversationType) !=
              false;
      if (enabled) {
        actions.add(ActionItem(
          type: action.type,
          icon: action.icon,
          title: action.title,
          permissions: action.permissions,
          deniedTip: action.deniedTip,
          onTap: action.onTap,
        ));
      }
    }
    return actions;
  }

  /// 桌面端选择图片并发送
  void _onDesktopPickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      // Web 端需要 withData 才能获取 file.bytes
      withData: kIsWeb,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      final fileName = file.name;
      String? imageType;
      if (fileName.lastIndexOf('.') + 1 < fileName.length) {
        imageType = fileName.substring(fileName.lastIndexOf('.') + 1);
      }

      Uint8List? bytes;
      if (kIsWeb) {
        // Web 端 file.path 为 null，dart:io 的 File 不可用，
        // 直接使用 FilePicker 返回的 bytes
        bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) return;
      } else {
        final path = file.path;
        if (path == null) return;
        bytes = await File(path).readAsBytes();
      }

      // 使用 decodeImageFromList 获取图片宽高
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final width = frame.image.width;
      final height = frame.image.height;
      frame.image.dispose();
      _viewModel.sendImageMessage(
        kIsWeb ? '' : file.path!,
        fileName,
        width,
        height,
        imageType: imageType,
        fileBytes: kIsWeb ? bytes : null,
      );
    }
  }

  /// 桌面端选择视频并发送
  void _onDesktopPickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      // Web 端需要 withData 才能获取 file.bytes
      withData: kIsWeb,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      final fileName = file.name;
      final size = file.size;
      final overSize = ChatKitClient.instance.chatUIConfig.maxVideoSize ?? 200;
      if (size > overSize * 1024 * 1024) {
        ChatUIToast.show(
          S.of(context).chatMessageFileSizeOverLimit("$overSize"),
          context: context,
        );
        return;
      }

      if (kIsWeb) {
        // Web 端 file.path 为 null，dart:io 的 File 不可用，
        // 直接使用 FilePicker 返回的 bytes
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) return;
        // 通过 HTMLVideoElement + Blob URL 读取视频元数据
        final meta = await _getWebVideoMetadata(bytes);
        _viewModel.sendVideoMessage(
          '',
          fileName,
          meta[2],
          meta[0],
          meta[1],
          fileBytes: bytes,
        );
      } else {
        final path = file.path;
        if (path == null) return;
        // 读取视频元数据（宽、高、时长），失败时回退到 [0, 0, 0]
        final meta = await _getDesktopVideoMetadata(path);
        _viewModel.sendVideoMessage(path, fileName, meta[2], meta[0], meta[1]);
      }
    }
  }

  /// 桌面端（macOS/Windows/Linux）通过 VideoPlayerController 读取视频元数据。
  /// 返回 [width, height, durationMs]；读取失败或超时时返回 [0, 0, 0]。
  Future<List<int>> _getDesktopVideoMetadata(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize().timeout(const Duration(seconds: 3));
      final size = controller.value.size;
      final durationMs = controller.value.duration.inMilliseconds;
      return [size.width.toInt(), size.height.toInt(), durationMs];
    } catch (_) {
      return [0, 0, 0];
    } finally {
      controller.dispose();
    }
  }

  /// Web 端通过 HTMLVideoElement + Blob ObjectURL 读取视频元数据。
  /// 返回 [width, height, durationMs]；读取失败或超时时返回 [0, 0, 0]。
  /// 注意：当前 _onDesktopPickVideo 在 Web 端会因 path == null 提前 return，
  /// 此方法预留供后续 Web 端视频发送支持使用。
  // ignore: unused_element
  Future<List<int>> _getWebVideoMetadata(List<int> bytes) =>
      _videoMetadata.fetchWebVideoMetadata(bytes);

  /// 桌面端表情选中回调
  void _onDesktopEmojiSelected(String emoji) {
    final text = inputController.text;
    final selection = inputController.selection;
    int cursorPos = selection.baseOffset;
    if (cursorPos < 0) {
      inputController.text = emoji;
    } else {
      inputController.text =
          (cursorPos > 0 ? text.substring(0, cursorPos) : '') +
              emoji +
              (cursorPos < text.length ? text.substring(cursorPos) : '');
    }
    inputText = inputController.text;
    inputController.selection = TextSelection.fromPosition(
      TextPosition(
        offset: (cursorPos < 0 ? 0 : cursorPos) + emoji.length,
      ),
    );

    Future.delayed(Duration(milliseconds: 20), () {
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    });
    setState(() {});
  }

  /// 桌面端表情删除回调
  void _onDesktopEmojiDelete() {
    final selection = inputController.selection;
    int cursorPos = selection.baseOffset;
    String originText = inputController.text;

    if (cursorPos < 0) {
      cursorPos = originText.length;
    }
    String text;
    int newCursorPos;

    final emojiStartIndex = _findMatchingBracket(originText, cursorPos);
    if (emojiStartIndex >= 0) {
      text = (emojiStartIndex > 0
              ? originText.substring(0, emojiStartIndex)
              : '') +
          (cursorPos >= originText.length
              ? ''
              : originText.substring(cursorPos));
      newCursorPos = emojiStartIndex;
    } else if (cursorPos > 0) {
      text = originText.substring(0, cursorPos - 1) +
          (cursorPos < originText.length
              ? originText.substring(cursorPos)
              : '');
      newCursorPos = cursorPos - 1;
    } else {
      text = originText;
      newCursorPos = cursorPos;
    }

    inputController.text = text;
    inputController.selection = TextSelection.collapsed(
      offset: newCursorPos,
    );
    inputText = text;
    setState(() {});
  }

  void showImagePicker(
    BuildContext context,
    RequestType requestType,
    int maxAssets,
  ) async {
    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        requestType: requestType,
        shouldRevertGrid: false,
        maxAssets: maxAssets,
        limitedPermissionOverlayPredicate: (state) => false,
        filterOptions: FilterOptionGroup(
          imageOption: const FilterOption(needTitle: true),
          videoOption: const FilterOption(needTitle: true),
        ),
      ),
    );
    if (result != null) {
      for (var entity in result) {
        final File? file = await entity.originFile;
        if (file != null) {
          if (requestType == RequestType.image) {
            String? imageType;
            if (file.path.lastIndexOf('.') + 1 < file.path.length) {
              imageType = file.path.substring(file.path.lastIndexOf('.') + 1);
            }
            _viewModel.sendImageMessage(
              file.path,
              entity.title,
              entity.width,
              entity.height,
              imageType: imageType,
            );
          } else if (requestType == RequestType.video) {
            var size = await file.length();
            int overSize =
                ChatKitClient.instance.chatUIConfig.maxVideoSize ?? 200;
            if (size > overSize * 1024 * 1024) {
              ChatUIToast.show(
                S.of(context).chatMessageFileSizeOverLimit("$overSize"),
                context: context,
              );
              return;
            }
            _viewModel.sendVideoMessage(
              file.path,
              entity.title,
              entity.duration * 1000,
              entity.width,
              entity.height,
            );
          }
        }
      }
    }
  }

  _onImageActionTap(
    BuildContext context,
    String sessionId,
    NIMConversationType sessionType, {
    NIMMessageSender? messageSender,
  }) {
    // 收起键盘
    _focusNode.unfocus();

    showAdaptiveChoose<int>(
      context: context,
      items: [
        AdaptiveChooseItem(
          label: S.of(context).chatMessagePickPhoto,
          value: 1,
        ),
        AdaptiveChooseItem(
          label: S.of(context).chatMessagePickVideo,
          value: 2,
        ),
      ],
      showCancel: true,
    ).then((value) async {
      if (value == 1 || value == 2) {
        final requestType = value == 1 ? RequestType.image : RequestType.video;

        // 显示顶部说明弹框
        showTopWarningDialog(
          context: context,
          title: S.of(context).permissionStorageTitle,
          content: S.of(context).permissionStorageContent,
        );

        // 权限检查
        final PermissionState ps = await AssetPicker.permissionCheck(
          requestOption: PermissionRequestOption(
            androidPermission: AndroidPermission(
              type: requestType,
              mediaLocation: false,
            ),
          ),
          returnResultDenied: true,
        );

        // 关闭说明弹框
        Navigator.of(context).pop();

        if (ps == PermissionState.authorized || ps == PermissionState.limited) {
          if (value == 1) {
            showImagePicker(context, RequestType.image, 9);
          } else if (value == 2) {
            showImagePicker(context, RequestType.video, 1);
          }
        } else {
          ChatUIToast.show(S.of(context).chatPermissionSystemCheck,
              context: context);
        }
      }
    });
  }

  _onMoreActionTap(
    BuildContext context,
    String sessionId,
    NIMConversationType sessionType, {
    NIMMessageSender? messageSender,
  }) {
    if (_currentType == ActionConstants.more) {
      _currentType = ActionConstants.none;
    } else {
      _focusNode.unfocus();
      _currentType = ActionConstants.more;
    }
    setState(() {});
  }

  Widget _actionIcon(String iconPath, String type) {
    bool selected = _currentType == type && !mute;
    return SvgPicture.asset(
      iconPath,
      package: kPackage,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        selected ? CommonColors.color_337eff : CommonColors.color_656a72,
        BlendMode.srcIn,
      ),
    );
  }

  /// 桌面端文件选择：直接调用 FilePicker，不走移动端权限流程
  void _onDesktopFileActionTap() async {
    final result = await FilePicker.platform.pickFiles(
      // Web 端需要 withData 才能获取 file.bytes
      withData: kIsWeb,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      final fileName = file.name;
      final size = file.size;
      final overSize = ChatKitClient.instance.chatUIConfig.maxFileSize ?? 200;
      if (size > overSize * 1024 * 1024) {
        ChatUIToast.show(
          S.of(context).chatMessageFileSizeOverLimit("$overSize"),
          context: context,
        );
        return;
      }
      if (kIsWeb) {
        // Web 端 file.path 为 null，dart:io 的 File 不可用，
        // 直接使用 FilePicker 返回的 bytes
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) return;
        _viewModel.sendFileMessage('', fileName, fileBytes: bytes);
      } else {
        final path = file.path;
        if (path == null) return;
        _viewModel.sendFileMessage(path, fileName);
      }
    }
  }

  List<ActionItem> _defaultInputActions() {
    // 桌面端不需要语音录制按钮，移除 more，平铺 file 和 translate
    if (ChatKitUtils.isDesktopOrWeb) {
      final List<ActionItem> desktopActions = [
        ActionItem(
          type: ActionConstants.emoji,
          icon: _actionIcon('images/ic_send_emoji.svg', ActionConstants.emoji),
          onTap: _onEmojiActionTap,
        ),
        ActionItem(
          type: ActionConstants.image,
          icon: _actionIcon('images/ic_send_image.svg', ActionConstants.image),
        ),
        ActionItem(
          type: ActionConstants.file,
          icon: SvgPicture.asset(
            'images/ic_chat_file_desktop.svg',
            package: kPackage,
            width: 24,
            height: 24,
          ),
          onTap: (context, sessionId, sessionType, {messageSender}) {
            _onDesktopFileActionTap();
          },
        ),
      ];
      // 翻译按钮：仅当配置了 AI 翻译用户时显示
      if (AIUserManager.instance.getAITranslateUser() != null) {
        desktopActions.add(
          ActionItem(
            type: ActionConstants.translate,
            icon: SvgPicture.asset(
              'images/ic_chat_translate_desktop.svg',
              package: kPackage,
              width: 24,
              height: 24,
            ),
            onTap: _onTranslateActionTap,
          ),
        );
      }
      //插件扩展按钮
      final pluginActions = _getDesktopPluginActions();
      if (pluginActions.isNotEmpty) {
        desktopActions.addAll(pluginActions);
      }
      return desktopActions;
    }
    return [
      ActionItem(
        type: ActionConstants.record,
        icon: _actionIcon('images/ic_send_voice.svg', ActionConstants.record),
        permissions: [Permission.microphone],
        onTap: _onRecordActionTap,
        deniedTip: S.of(context).microphoneDeniedTips,
        permissionTitle: S.of(context).permissionAudioTitle,
        permissionDesc: S.of(context).permissionAudioContent,
      ),

      ActionItem(
        type: ActionConstants.emoji,
        icon: _actionIcon('images/ic_send_emoji.svg', ActionConstants.emoji),
        onTap: _onEmojiActionTap,
      ),
      ActionItem(
        type: ActionConstants.image,
        icon: _actionIcon('images/ic_send_image.svg', ActionConstants.image),
        onTap: _onImageActionTap,
      ),
      // ActionItem(
      //     type: ActionConstants.file,
      //     icon: 'images/ic_send_file.svg',
      //     onTap: _onFileActionTap),
      ActionItem(
        type: ActionConstants.more,
        icon: _actionIcon('images/ic_more.svg', ActionConstants.more),
        onTap: _onMoreActionTap,
      ),
    ];
  }

  List<ActionItem> _getInputActions() {
    final List<ActionItem> inputActions = [];
    if (widget.chatUIConfig?.keepDefaultInputAction == true) {
      inputActions.addAll(_defaultInputActions());
    }
    if (widget.chatUIConfig?.inputActions?.isNotEmpty == true) {
      inputActions.addAll(widget.chatUIConfig!.inputActions!);
    }
    return inputActions;
  }

  double _getPanelHeight() {
    // 桌面端表情使用弹框，不在底部展开面板
    if (_currentType == ActionConstants.emoji && ChatKitUtils.isDesktopOrWeb) {
      return 0;
    }
    if (_currentType == ActionConstants.record ||
        _currentType == ActionConstants.more ||
        _currentType == ActionConstants.emoji) {
      return 197;
    }
    return 0;
  }

  Widget _getPanel() {
    if (_currentType == ActionConstants.record) {
      return RecordPanel(
        onPressedDown: () {
          setState(() {
            _recording = true;
          });
        },
        onEnd: () {
          setState(() {
            _recording = false;
          });
        },
        onCancel: () {
          setState(() {
            _recording = false;
          });
        },
      );
    }
    if (_currentType == ActionConstants.more) {
      return MorePanel(
        moreActions: widget.chatUIConfig?.moreActions,
        keepDefault: widget.chatUIConfig?.keepDefaultMoreAction ?? true,
        conversationId: widget.conversationId,
        conversationType: widget.conversationType,
        onTranslateClick: _onTranslateActionTap,
      );
    }
    if (_currentType == ActionConstants.emoji) {
      return EmojiPanel(
        onEmojiSelected: (emoji) {
          final text = inputController.text;
          final selection = inputController.selection;
          int cursorPos = selection.baseOffset;
          if (cursorPos < 0) {
            inputController.text = emoji;
          } else {
            inputController.text =
                (cursorPos > 0 ? text.substring(0, cursorPos) : '') +
                    emoji +
                    (cursorPos < text.length ? text.substring(cursorPos) : '');
          }
          inputText = inputController.text;
          inputController.selection = TextSelection.fromPosition(
            TextPosition(
              offset: (cursorPos < 0 ? 0 : cursorPos) + emoji.length,
            ),
          );

          Future.delayed(Duration(milliseconds: 20), () {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          });
        },
        onEmojiDelete: () {
          final selection = inputController.selection;
          int cursorPos = selection.baseOffset;
          String originText = inputController.text;

          if (cursorPos < 0) {
            cursorPos = originText.length;
          }
          String text;
          int newCursorPos;

          final emojiStartIndex = _findMatchingBracket(originText, cursorPos);
          if (emojiStartIndex >= 0) {
            // 删除表情
            text = (emojiStartIndex > 0
                    ? originText.substring(0, emojiStartIndex)
                    : '') +
                (cursorPos >= originText.length
                    ? ''
                    : originText.substring(cursorPos));
            newCursorPos = emojiStartIndex;
          } else if (cursorPos > 0) {
            // 删除普通字符
            text = originText.substring(0, cursorPos - 1) +
                (cursorPos < originText.length
                    ? originText.substring(cursorPos)
                    : '');
            newCursorPos = cursorPos - 1;
          } else {
            // 光标在最前面，无需删除
            text = originText;
            newCursorPos = cursorPos;
          }

          inputController.text = text;
          inputController.selection = TextSelection.collapsed(
            offset: newCursorPos,
          );
          inputText = text;
        },
        onEmojiSendClick: _sendTextMessage,
      );
    }
    return Container();
  }

  // 查找匹配的起始 [
  int _findMatchingBracket(String text, int endIndex) {
    if (endIndex > 0 && text[endIndex - 1] == ']') {
      for (int i = endIndex - 1; i >= 0; i--) {
        if (text[i] == '[') {
          String matchStr = text.substring(i, endIndex);
          final emoji = EmojiUtil.instance.emojiMap[matchStr];
          if (emoji != null) {
            return i;
          }
        }
      }
    }
    return -1;
  }

  //将指定用户添加到@列表中
  //[account]  用户id
  //[reAdd]  是否重新添加，如果为true，不管是否已经在列表中，都会添加
  void _addAitMember(String account, {bool reAdd = false}) async {
    if (_viewModel.teamInfo == null) {
      return;
    }
    String name = await getUserNickInTeam(
      _viewModel.teamInfo!.teamId,
      account,
      showAlias: false,
    );
    //已经在ait列表中，不再添加
    if (!reAdd && _aitManager?.haveBeAit(account) == true) {
      return;
    }
    _aitManager?.addAitWithText(account, '@$name$blank', inputText.length);
    String text = '$inputText@$name$blank';
    inputController.text = text;
    inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    inputText = text;
  }

  void _handleReplyAit(ChatMessage replyMsg) {
    if (_replyMessageTemp?.nimMessage.messageClientId ==
        replyMsg.nimMessage.messageClientId) {
      return;
    }
    _replyMessageTemp = replyMsg;
    if (enableAit()) {
      //如果是数字人消息，@数字人
      if (ChatMessageHelper.isReceivedMessageFromAi(replyMsg.nimMessage)) {
        String accountId = replyMsg.nimMessage.aiConfig!.accountId!;
        _addAitMember(accountId, reAdd: true);
      } else if (replyMsg.fromUser?.accountId != null &&
          replyMsg.fromUser?.accountId !=
              getIt<IMLoginService>().userInfo?.accountId) {
        String account = replyMsg.fromUser!.accountId!;
        _addAitMember(account, reAdd: true);
      }
    }
  }

  void _handleAitText() {
    String value = inputController.text;
    if (!enableAit()) {
      inputText = value;
      return;
    }
    int len = value.length;
    //光标位置
    final int endIndex = inputController.selection.baseOffset;
    if (inputText.length > len && _aitManager?.haveAitMember() == true) {
      // delete
      //删除的长度
      var deleteLen = inputText.length - len;
      var deletedAit = _aitManager?.deleteAitWithText(
        value,
        endIndex,
        deleteLen,
      );
      if (deletedAit != null) {
        //删除前判断长度，解决奔溃问题，
        //复现路径：发送消息@信息在最后，然后撤回，重新编辑，在删除
        if (deletedAit.segments[0].endIndex - deleteLen < value.length) {
          inputController.text = value.substring(
                  0, deletedAit.segments[0].start) +
              value.substring(deletedAit.segments[0].endIndex + 1 - deleteLen);
        } else {
          inputController.text = value.substring(
            0,
            deletedAit.segments[0].start,
          );
        }
        inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: deletedAit.segments[0].start),
        );
        inputText = inputController.text;
        return;
      }
    } else if (inputText.length < len) {
      // @ 弹出选择框

      if (endIndex > 0 && value[endIndex - 1] == '@') {
        // 用于处理选中 @ 成员后的回调逻辑（桌面端和移动端复用）
        void _onAitSelected(dynamic aitUser) {
          if (aitUser == AitContactsModel.accountAll) {
            final String allStr = S.of(context).chatTeamAitAll;
            _aitManager?.addAitWithText(
              AitContactsModel.accountAll,
              '@${S.of(context).chatTeamAitAll}$blank',
              endIndex - 1,
            );
            inputController.text =
                '${value.substring(0, endIndex)}$allStr$blank${value.substring(endIndex)}';
            inputController.selection = TextSelection.fromPosition(
              TextPosition(offset: endIndex + allStr.length + 1),
            );
            inputText = inputController.text;
          } else if (aitUser is AitBean) {
            String name = '';
            String accountId = '';
            if (aitUser.aiUser != null) {
              //选中数字人
              name = aitUser.getName();
              accountId = aitUser.getAccountId()!;
            } else {
              //选中正常用户
              final select = aitUser.teamMember!;
              // @列表需要展示用户备注，@结果不需要
              name = select.getName(needAlias: false);
              accountId = select.teamInfo.accountId;
            }
            //add to aitManager
            _aitManager?.addAitWithText(
              accountId,
              '@$name$blank',
              endIndex - 1,
            );
            inputController.text =
                '${value.substring(0, endIndex)}$name$blank${value.substring(endIndex)}';
            inputController.selection = TextSelection.fromPosition(
              TextPosition(offset: endIndex + name.length + 1),
            );
            inputText = inputController.text;
          }
        }

        if (ChatKitUtils.isDesktopOrWeb) {
          // 桌面端/Web端：使用 OverlayEntry 弹框，宽度限制在消息区域
          _showDesktopAitPopup((dynamic aitUser) {
            _onAitSelected(aitUser);
            // 选中成员后，将焦点重新 focus 到输入框
            _focusNode.requestFocus();
          });
        } else {
          // 移动端：使用底部弹框
          _aitManager?.selectMember(context).then(_onAitSelected);
        }
        inputText = value;
        return;
      } else if (_aitManager?.haveAitMember() == true) {
        //光标位置
        var endIndex = inputController.selection.baseOffset;
        //新增长度
        var addLen = len - inputText.length;
        _aitManager?.addTextWithoutAit(value, endIndex, addLen);
      }
    }
    inputText = value;
  }

  _sendTextMessage() {
    final title = titleController.text.trim();
    var text = inputController.text.trim();
    if (_aitManager?.aitEnd(text) == true) {
      text += blank;
    }
    if (title.isNotEmpty || text.isNotEmpty) {
      List<String>? pushList;
      if (enableAit()) {
        if (_aitManager?.aitContactsModel != null) {
          pushList = _aitManager!.getPushList();
        }
      }
      _viewModel.sendTextMessage(
        text,
        replyMsg: _viewModel.replyMessage?.nimMessage,
        pushList: pushList,
        aitContactsModel: _aitManager?.aitContactsModel,
        title: title,
      );
      _viewModel.replyMessage = null;
      _replyMessageTemp = null;
      // aitMemberMap.clear();
      inputController.clear();
      titleController.clear();
      inputText = '';
      _aitManager?.cleanAit();
      setState(() {
        _isExpanded = false;
      });
      //100ms 后重新Request focus，以此来弹出键盘
      Future.delayed(Duration(milliseconds: 100)).then((value) {
        _titleFocusNode.unfocus();
        _focusNode.requestFocus();
      });
    } else {
      ChatUIToast.show(
        S.of(context).chatMessageNotSupportEmptyMessage,
        context: context,
      );
    }
    _scrollToBottom();
  }

  _onTranslateActionTap(
    BuildContext context,
    String sessionId,
    NIMConversationType sessionType, {
    NIMMessageSender? messageSender,
  }) {
    setState(() {
      _isTranslating = !_isTranslating;
    });
  }

  _onTranslateCloseClick() {
    setState(() {
      _isTranslating = false;
    });
  }

  _onTranslateSureClick(String language, Function(bool textEmpty) completion) {
    if (inputController.text.isNotEmpty) {
      NIMAIUser? translateUser = AIUserManager.instance.getAITranslateUser();
      if (translateUser?.accountId != null) {
        _viewModel.translateInputText(inputController.text, language);
      }
      completion(false);
    } else {
      completion(true);
    }
  }

  _onTranslateUseClick(String result) {
    _aitManager?.cleanAit();
    inputText = result;
    inputController.text = result;
    _focusNode.requestFocus();
  }

  void _scrollToBottom() {
    context.read<ChatViewModel>().srollToNewMessage();
  }

  onViewModelChange() {
    if (_viewModel.reeditMessage != null) {
      _aitManager?.cleanAit();
      var reeditMessageContent = _viewModel.reeditMessage!.reeditMessage;
      var multiLineMap = _viewModel.reeditMessage!.multiLineMessage;
      String? titleText;
      if (multiLineMap?.isNotEmpty == true) {
        reeditMessageContent = multiLineMap![ChatMessage.keyMultiLineBody];
        titleText = multiLineMap[ChatMessage.keyMultiLineTitle];
      }

      //处理文本body
      if (reeditMessageContent?.isNotEmpty == true) {
        //由于发送消息的时候会把Text中的空格trim
        //判断如果是@信息在最后则补充空格
        var needBlank = false;
        if (_viewModel.reeditMessage?.aitContactsModel != null) {
          _aitManager?.forkAit(_viewModel.reeditMessage!.aitContactsModel!);
          if (_aitManager?.aitEnd(reeditMessageContent!) == true) {
            needBlank = true;
          }
        }
        inputController.text = reeditMessageContent! + (needBlank ? blank : '');
        inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: reeditMessageContent.length),
        );
        inputText = inputController.text;
      }
      //处理title
      if (titleText?.isNotEmpty == true) {
        titleController.text = titleText!;
        titleController.selection = TextSelection.fromPosition(
          TextPosition(offset: titleText.length),
        );
        setState(() {
          _isExpanded = true;
        });
        if (!_viewModel.isMultiSelected) _titleFocusNode.requestFocus();
      } else {
        if (!_viewModel.isMultiSelected) _focusNode.requestFocus();
      }

      _viewModel.reeditMessage = null;
    }
    if (_viewModel.replyMessage != null) {
      // 仅当回复消息真正发生变化时才请求输入框焦点。
      // 否则，ChatViewModel 任何 notifyListeners()（例如点击操作按钮时
      // 触发的 srollToNewMessage()）都会让 onViewModelChange 重新执行，
      // 进而调用 requestFocus 弹起键盘，从而把刚刚设置好的
      // _currentType = emoji 经 didChangeMetrics 改回 input，
      // 最终表现为「回复模式下点击表情按钮无法打开 EmojiPanel」。
      final bool isNewReply = _replyMessageTemp?.nimMessage.messageClientId !=
          _viewModel.replyMessage!.nimMessage.messageClientId;
      _handleReplyAit(_viewModel.replyMessage!);
      if (isNewReply && !_viewModel.isMultiSelected) {
        _focusNode.requestFocus();
      }
    } else {
      _replyMessageTemp = null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    inputController = TextEditingController();
    titleController = TextEditingController();
    _viewModel = context.read<ChatViewModel>();
    inputController.addListener(() {
      if (_viewModel.conversationType == NIMConversationType.p2p) {
        _viewModel.sendInputNotification(inputController.text.isNotEmpty);
      } else if (inputText == inputController.text &&
          _aitManager?.haveAitMember() == true) {
        //处理移动光标的问题
        var index = inputController.selection.baseOffset;
        var indexMoved = _aitManager?.resetAitCursor(index);
        if (indexMoved != null && indexMoved != index) {
          Alog.d(
            tag: 'ChatKit',
            moduleName: 'bottom input',
            content:
                'inputController.selection.baseOffset:$index, indexMoved:$indexMoved',
          );
          if (indexMoved > inputController.text.length) {
            indexMoved = inputController.text.length;
          }
          inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: indexMoved),
          );
        }
      }
      //处理剪切的case
      if (inputController.text.isEmpty &&
          _aitManager?.haveAitMember() == true) {
        _aitManager?.cleanAit();
      }
    });
    titleController.addListener(() {
      if (_viewModel.conversationType == NIMConversationType.p2p) {
        _viewModel.sendInputNotification(titleController.text.isNotEmpty);
      }
      if (titleController.text.isEmpty) {
        setState(() {});
      }
    });
    _scrollController = ScrollController();
    _focusNode = FocusNode();
    _titleFocusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _titleFocusNode.unfocus();
      }
    });
    _titleFocusNode.addListener(() {
      if (_titleFocusNode.hasFocus) {
        _focusNode.unfocus();
      }
    });
    _viewModel.addListener(onViewModelChange);
    if (enableAit()) {
      _aitManager = AitManager(
        _viewModel.sessionId,
        isP2P: widget.conversationType == NIMConversationType.p2p,
      );
    }
  }

  //是否支持@功能
  bool enableAit() {
    if (!IMKitClient.enableAit) {
      return false;
    }
    if (widget.conversationType == NIMConversationType.team) {
      return true;
    }
    final accountId = ChatKitUtils.getConversationTargetId(
      widget.conversationId,
    );
    if (AIUserManager.instance.isAIUser(accountId)) {
      return false;
    }
    if (AIUserManager.instance.getAIChatUserList().isNotEmpty) {
      return true;
    }
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_focusNode.hasFocus || _titleFocusNode.hasFocus) {
        showKeyboard();
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    _isDisposing = true;
    _dismissDesktopEmojiPopup();
    _dismissDesktopImageMenu();
    _dismissDesktopAitPopup();
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _titleFocusNode.dispose();
    _viewModel.removeListener(onViewModelChange);
    _aitManager?.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
    final newValue = bottomInset > 0.0;
    if (newValue != _keyboardShow) {
      setState(() {
        _keyboardShow = newValue;
        if (_keyboardShow) {
          _currentType = ActionConstants.input;
        }
      });
      _scrollToBottom();
    }
  }

  /// 是否有焦点
  bool haveFocus() {
    return _titleFocusNode.hasFocus || _focusNode.hasFocus;
  }

  bool _isShowTitle() {
    return IMKitClient.enableRichTextMessage &&
        !mute &&
        (_isExpanded || titleController.text.trim().isNotEmpty);
  }

  /// 桌面端输入框：支持 Enter 发送、Shift+Enter 换行，多行自适应
  /// 布局：左侧是输入区域，右侧是操作按钮（纵向排列）+ 发送按钮
  Widget _buildDesktopInputField(String? hint, bool showTitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // === 左侧：输入区域（可自动增长） ===
        Expanded(
          child: KeyboardListener(
            focusNode: FocusNode(skipTraversal: true),
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.enter) {
                // Shift+Enter: 换行（由 TextField 自行处理）
                if (HardwareKeyboard.instance.isShiftPressed) {
                  return;
                }
                // Enter: 发送消息
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final text = inputController.text;
                  if (text.endsWith('\n')) {
                    inputController.text = text.substring(0, text.length - 1);
                    inputController.selection = TextSelection.fromPosition(
                      TextPosition(offset: inputController.text.length),
                    );
                  }
                  _sendTextMessage();
                });
              }
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 40,
                maxHeight: 120,
              ),
              child: ExtendedTextField(
                controller: inputController,
                scrollController: _scrollController,
                specialTextSpanBuilder: NeSpecialTextSpanBuilder(),
                focusNode: _focusNode,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  fillColor: mute ? const Color(0xffe3e4e4) : Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: showTitle
                        ? const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          )
                        : BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  hintText:
                      '${hint ?? ""} ${S.of(context).chatMessageDesktopInputHint}',
                  hintStyle: const TextStyle(
                    color: Color(0xffb3b7bc),
                    fontSize: 14,
                  ),
                  hoverColor: Colors.transparent,
                  enabled: !mute,
                ),
                style: const TextStyle(
                  color: CommonColors.color_333333,
                  fontSize: 14,
                ),
                textInputAction: TextInputAction.newline,
                onChanged: (value) {
                  _handleAitText();
                  _translatePanel.currentState?.onInputTextChange();
                  // 触发 setState 以更新发送按钮颜色
                  setState(() {});
                },
                maxLines: null, // 自动增长
                minLines: 1,
                enabled: !mute,
              ),
            ),
          ),
        ),

        // === 右侧：操作按钮 + 发送按钮（底部对齐） ===
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 操作按钮组（横向排列，底部对齐）
              ..._getInputActions().map(
                (action) {
                  Key? buttonKey;
                  VoidCallback? onHoverEnter;
                  VoidCallback? onHoverExit;
                  if (action.type == ActionConstants.emoji) {
                    buttonKey = _emojiButtonKey;
                  } else if (action.type == ActionConstants.image) {
                    buttonKey = _imageButtonKey;
                    onHoverEnter = () {
                      _imageMenuCloseTimer?.cancel();
                      _showDesktopImageMenu();
                    };
                    onHoverExit = () {
                      _imageMenuCloseTimer?.cancel();
                      _imageMenuCloseTimer =
                          Timer(const Duration(milliseconds: 200), () {
                        _dismissDesktopImageMenu();
                      });
                    };
                  }
                  return _DesktopActionButton(
                    key: buttonKey,
                    action: action,
                    enable: !mute,
                    onHoverEnter: onHoverEnter,
                    onHoverExit: onHoverExit,
                    onTap: () {
                      _scrollToBottom();
                      if (action.enable && action.onTap != null) {
                        action.onTap!(
                          context,
                          widget.conversationId,
                          widget.conversationType,
                          messageSender: (message) {
                            _viewModel.sendMessage(message);
                          },
                        );
                      }
                    },
                  );
                },
              ),
              const SizedBox(width: 4),
              // 发送按钮
              _buildDesktopSendButton(),
            ],
          ),
        ),
      ],
    );
  }

  /// 桌面端发送按钮
  Widget _buildDesktopSendButton() {
    final hasContent = inputController.text.trim().isNotEmpty ||
        titleController.text.trim().isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: mute ? null : _sendTextMessage,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: SvgPicture.asset(
              'images/ic_chat_send_desktop.svg',
              package: kPackage,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                hasContent && !mute
                    ? const Color(0xFF537FF4)
                    : const Color(0xFFCCCCCC),
                BlendMode.srcIn,
              ),
            ),
          )),
    );
  }

  /// 移动端输入框：保持原有行为
  Widget _buildMobileInputField(String? hint, bool showTitle) {
    return Column(
      children: [
        SingleChildScrollView(
          child: SizedBox(
            height: showTitle ? null : 40,
            child: ExtendedTextField(
              controller: inputController,
              scrollController: _scrollController,
              specialTextSpanBuilder: NeSpecialTextSpanBuilder(),
              focusNode: _focusNode,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 9,
                  horizontal: 12,
                ),
                fillColor: mute ? const Color(0xffe3e4e4) : Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: _isExpanded
                      ? BorderRadius.zero
                      : (showTitle
                          ? const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            )
                          : BorderRadius.circular(8)),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xffb3b7bc),
                  fontSize: 16,
                ),
                enabled: !mute,
                suffixIcon: !IMKitClient.enableRichTextMessage || showTitle
                    ? null
                    : IconButton(
                        onPressed: () {
                          if (!mute) {
                            setState(() {
                              _isExpanded = !_isExpanded;
                              _titleFocusNode.unfocus();
                              _focusNode.unfocus();
                              hideKeyboard();
                            });
                          }
                        },
                        icon: SvgPicture.asset(
                          'images/ic_chat_input_expand.svg',
                          package: kPackage,
                          width: 24,
                          height: 24,
                        ),
                      ),
              ),
              style: const TextStyle(
                color: CommonColors.color_333333,
                fontSize: 16,
              ),
              textInputAction:
                  _isExpanded ? TextInputAction.newline : TextInputAction.send,
              onChanged: (value) {
                _handleAitText();
                _translatePanel.currentState?.onInputTextChange();
              },
              maxLines: _isExpanded ? 8 : (showTitle ? 2 : 1),
              onEditingComplete: _sendTextMessage,
              enabled: !mute,
            ),
          ),
        ),
        if (_isExpanded) ...[
          Container(height: 1, color: '#ECECEC'.toColor()),
          Container(
            color: Colors.white,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () {
                  if (!mute) {
                    _sendTextMessage();
                  }
                },
                icon: SvgPicture.asset(
                  'images/ic_chat_send.svg',
                  package: kPackage,
                  width: 32,
                  height: 32,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    mute = context.watch<ChatViewModel>().mute;
    if (mute) {
      _isExpanded = false;
      titleController.clear();
      inputController.clear();
    }
    bool showTitle = _isShowTitle();
    if (_isExpanded) {
      _currentType = ActionConstants.input;
    }
    String? hint = mute ? S.of(context).chatTeamAllMute : widget.hint;
    if (context.read<ChatViewModel>().isMultiSelected) {
      _focusNode.unfocus();
      _titleFocusNode.unfocus();
    }
    final bool isDesktop = ChatKitUtils.isDesktopOrWeb;
    return Container(
      key: _inputContainerKey,
      width: MediaQuery.of(context).size.width,
      color: !isDesktop ? const Color(0xffeff1f3) : null,
      margin: isDesktop
          ? const EdgeInsets.only(left: 10, right: 10, bottom: 8)
          : null,
      decoration: isDesktop
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xffd8eae4)),
            )
          : null,
      child: SafeArea(
        // 桌面端不需要底部安全区域
        bottom: !isDesktop,
        child: Column(
          children: [
            _isTranslating
                ? AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    // height: 77,
                    child: TranslatePanel(
                      key: _translatePanel,
                      onTranslateCloseClick: _onTranslateCloseClick,
                      onTranslateSureClick: _onTranslateSureClick,
                      onTranslateUseClick: _onTranslateUseClick,
                    ),
                  )
                : Container(),
            _viewModel.replyMessage != null && !_isExpanded
                ? Container(
                    height: 36,
                    padding: const EdgeInsets.only(left: 11, right: 7),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            context.read<ChatViewModel>().replyMessage = null;
                            _replyMessageTemp = null;
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            color: CommonColors.color_999999,
                            size: 14,
                          ),
                        ),
                        const VerticalDivider(
                          thickness: 1,
                          indent: 11,
                          endIndent: 11,
                          color: Color(0xffd8eae4),
                        ),
                        Expanded(
                          child: FutureBuilder<String>(
                            future: ChatMessageHelper.getReplayMessageTextById(
                              context,
                              _viewModel
                                  .replyMessage!.nimMessage.messageClientId!,
                              _viewModel.conversationId,
                            ),
                            builder: (context, snapshot) {
                              return Text(
                                S.of(context).chatMessageReplySomeone(
                                      snapshot.data ?? '',
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xff929299),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(),
            _recording
                ? const SizedBox(height: 54)
                : Padding(
                    padding: const EdgeInsets.all(7.0),
                    child: Column(
                      children: [
                        if (showTitle && !mute)
                          TextField(
                            controller: titleController,
                            focusNode: _titleFocusNode,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 9,
                                horizontal: 12,
                              ),
                              fillColor:
                                  mute ? Color(0xffe3e4e4) : Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                                borderSide: BorderSide.none,
                              ),
                              isDense: true,
                              hintText: S.of(context).chatMessageInputTitle,
                              hintStyle: const TextStyle(
                                color: Color(0xff333333),
                                fontSize: 18,
                              ),
                              enabled: !mute,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  if (!mute) {
                                    setState(() {
                                      _isExpanded = !_isExpanded;
                                      _titleFocusNode.unfocus();
                                      _focusNode.unfocus();
                                      hideKeyboard();
                                    });
                                  }
                                },
                                icon: SvgPicture.asset(
                                  _isExpanded
                                      ? 'images/ic_chat_lessen.svg'
                                      : 'images/ic_chat_input_expand.svg',
                                  package: kPackage,
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: CommonColors.color_333333,
                              fontSize: 18,
                            ),
                            textInputAction: TextInputAction.send,
                            onChanged: (value) {
                              _handleAitText();
                            },
                            maxLines: 1,
                            enabled: !mute,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(20),
                            ],
                            onEditingComplete: _sendTextMessage,
                            maxLengthEnforcement: MaxLengthEnforcement.none,
                          ),
                        ChatKitUtils.isDesktopOrWeb
                            ? _buildDesktopInputField(hint, showTitle)
                            : _buildMobileInputField(hint, showTitle),
                      ],
                    ),
                  ),
            if (_recording)
              SizedBox(
                height: 47,
                child: Text(
                  S.of(context).chatMessageVoiceIn,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CommonColors.color_999999,
                  ),
                ),
              ),
            // 移动端：底部独立操作栏行（桌面端操作栏已集成在输入框下方）
            if (!isDesktop && !_isExpanded && !_recording)
              Row(
                children: _getInputActions()
                    .map(
                      (action) => Expanded(
                        child: InputTextAction(
                          action: action,
                          enable: !mute,
                          onTap: () {
                            _scrollToBottom();
                            if (action.enable && action.onTap != null) {
                              action.onTap!(
                                context,
                                widget.conversationId,
                                widget.conversationType,
                                messageSender: (message) {
                                  _viewModel.sendMessage(message);
                                },
                              );
                            }
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            if (!mute)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _getPanelHeight(),
                child: _getPanel(),
              ),
          ],
        ),
      ),
    );
  }
}

/// 桌面端操作栏按钮：紧凑的图标按钮，带 hover 效果
class _DesktopActionButton extends StatefulWidget {
  final ActionItem action;
  final bool enable;
  final VoidCallback? onTap;
  final VoidCallback? onHoverEnter;
  final VoidCallback? onHoverExit;

  const _DesktopActionButton({
    Key? key,
    required this.action,
    required this.enable,
    this.onTap,
    this.onHoverEnter,
    this.onHoverExit,
  }) : super(key: key);

  @override
  State<_DesktopActionButton> createState() => _DesktopActionButtonState();
}

class _DesktopActionButtonState extends State<_DesktopActionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovering = true);
        widget.onHoverEnter?.call();
      },
      onExit: (_) {
        setState(() => _hovering = false);
        widget.onHoverExit?.call();
      },
      cursor:
          widget.enable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.enable ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: _hovering && widget.enable
                ? const Color(0x1A337EFF)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Opacity(
            opacity: widget.enable ? 1.0 : 0.4,
            child: widget.action.icon,
          ),
        ),
      ),
    );
  }
}

/// 桌面端表情弹框内容：网格布局，每行 9 个表情，带删除按钮
class _DesktopEmojiGrid extends StatelessWidget {
  final ValueChanged<String> onEmojiSelected;
  final VoidCallback onEmojiDelete;

  const _DesktopEmojiGrid({
    required this.onEmojiSelected,
    required this.onEmojiDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.0,
          ),
          itemCount: emojiData.length + 1, // +1 for delete button
          itemBuilder: (context, index) {
            // 最后一个是删除按钮
            if (index == emojiData.length) {
              return _DesktopEmojiItem(
                child: SvgPicture.asset(
                  'images/ic_emoji_del.svg',
                  package: kPackage,
                  height: 24,
                  width: 24,
                ),
                onTap: onEmojiDelete,
              );
            }
            final emoji = emojiData[index];
            final String source = emoji['name'] as String;
            final String tag = emoji['tag'] as String;
            return _DesktopEmojiItem(
              child: Image.asset(
                source,
                package: kPackage,
                height: 28,
                width: 28,
              ),
              onTap: () => onEmojiSelected(tag),
            );
          },
        ),
      ),
    );
  }
}

/// 桌面端单个表情项，带 hover 高亮效果
class _DesktopEmojiItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _DesktopEmojiItem({
    required this.child,
    required this.onTap,
  });

  @override
  State<_DesktopEmojiItem> createState() => _DesktopEmojiItemState();
}

class _DesktopEmojiItemState extends State<_DesktopEmojiItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: _hovering ? const Color(0x0F333333) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 桌面端图片/视频选择弹框
class _DesktopImageVideoMenu extends StatelessWidget {
  final String photoLabel;
  final String videoLabel;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;

  const _DesktopImageVideoMenu({
    required this.photoLabel,
    required this.videoLabel,
    required this.onPickImage,
    required this.onPickVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      shadowColor: Colors.black26,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DesktopMediaMenuItem(
              label: photoLabel,
              onTap: onPickImage,
            ),
            _DesktopMediaMenuItem(
              label: videoLabel,
              onTap: onPickVideo,
            ),
          ],
        ),
      ),
    );
  }
}

/// 桌面端弹框菜单项，带 hover 高亮效果
class _DesktopMediaMenuItem extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _DesktopMediaMenuItem({
    required this.label,
    required this.onTap,
  });

  @override
  State<_DesktopMediaMenuItem> createState() => _DesktopMediaMenuItemState();
}

class _DesktopMediaMenuItemState extends State<_DesktopMediaMenuItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hovering ? const Color(0x0F337EFF) : Colors.transparent,
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ),
    );
  }
}

/// 桌面端/Web 端 @ 成员选择弹框
/// 宽度与输入框容器对齐，定位在输入框上方
class _DesktopAitPopup extends StatefulWidget {
  final AitManager aitManager;
  final Offset containerPosition;
  final double containerWidth;

  /// 屏幕高度，在创建时由外部传入，避免在 build 中调用 MediaQuery.of(context)
  /// 防止注册对可能被 deactivate 的 InheritedWidget 的依赖
  final double screenHeight;
  final double maxHeight;
  final double itemHeight;
  final double headerHeight;
  final void Function(dynamic aitUser) onSelected;
  final VoidCallback onDismiss;

  const _DesktopAitPopup({
    required this.aitManager,
    required this.containerPosition,
    required this.containerWidth,
    required this.screenHeight,
    required this.maxHeight,
    required this.itemHeight,
    required this.headerHeight,
    required this.onSelected,
    required this.onDismiss,
  });

  @override
  State<_DesktopAitPopup> createState() => _DesktopAitPopupState();
}

class _DesktopAitPopupState extends State<_DesktopAitPopup> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 透明蒙层，点击关闭弹框
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        // @ 选择弹框主体
        Positioned(
          left: widget.containerPosition.dx,
          width: widget.containerWidth,
          bottom: widget.screenHeight - widget.containerPosition.dy + 4,
          child: Material(
            elevation: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            shadowColor: Colors.black26,
            color: Colors.white,
            child: ValueListenableBuilder<List<AitBean>?>(
              valueListenable: widget.aitManager.aitMemberList,
              builder: (context, value, _) {
                final members = (value ?? [])
                    .where(
                      (e) => e.getAccountId() != IMKitClient.account(),
                    )
                    .toList();

                // 计算实际高度：头部 + 成员列表（最多 maxHeight）
                final bool showAll = !widget.aitManager.isP2P &&
                    NIMChatCache.instance.haveAitAllPrivilege();
                final int itemCount = members.length + (showAll ? 1 : 0);
                final double listHeight = (itemCount * widget.itemHeight).clamp(
                  0.0,
                  widget.maxHeight - widget.headerHeight,
                );
                final double popupHeight = widget.headerHeight + listHeight;

                return SizedBox(
                  height: popupHeight,
                  child: Column(
                    children: [
                      // 顶部标题栏
                      SizedBox(
                        height: widget.headerHeight,
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            IconButton(
                              onPressed: widget.onDismiss,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF999999),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Text(
                                S.of(context).chatMessageAitContactTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1),
                      // 成员列表
                      Expanded(
                        child: ListView(
                          controller: _scrollController,
                          padding: EdgeInsets.zero,
                          children: [
                            // @所有人（仅群聊）
                            if (showAll)
                              _DesktopAitItem(
                                leading: SvgPicture.asset(
                                  'images/ic_team_all.svg',
                                  package: kPackage,
                                  height: 36,
                                  width: 36,
                                ),
                                title: S.of(context).chatTeamAitAll,
                                onTap: () => widget.onSelected(
                                  AitContactsModel.accountAll,
                                ),
                              ),
                            // 成员列表
                            ...members.map(
                              (user) => _DesktopAitItem(
                                leading: Avatar(
                                  avatar: user.getAvatar(),
                                  name: user.getAvatarName(),
                                  height: 36,
                                  width: 36,
                                ),
                                title: user.getName(),
                                onTap: () => widget.onSelected(user),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// 桌面端 @ 列表单项（支持 hover 高亮）
class _DesktopAitItem extends StatefulWidget {
  final Widget leading;
  final String title;
  final VoidCallback onTap;

  const _DesktopAitItem({
    required this.leading,
    required this.title,
    required this.onTap,
  });

  @override
  State<_DesktopAitItem> createState() => _DesktopAitItemState();
}

class _DesktopAitItemState extends State<_DesktopAitItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: _hovering ? const Color(0x0F337EFF) : Colors.transparent,
          child: Row(
            children: [
              widget.leading,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
