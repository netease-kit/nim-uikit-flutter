// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:ui';

import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:netease_common/netease_common.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/permission_request.dart';
import 'package:netease_common_ui/widgets/platform_utils.dart';
import 'package:nim_chatkit/im_kit_client.dart';
import 'package:nim_chatkit/model/ait/ait_contacts_model.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_chatkit/services/message/chat_message.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/manager/ai_user_manager.dart';
import 'package:nim_chatkit_ui/helper/chat_message_helper.dart';
import 'package:nim_chatkit_ui/helper/chat_message_user_helper.dart';
import 'package:nim_chatkit_ui/view/ait/ait_manager.dart';
import 'package:nim_chatkit_ui/view/ait/ait_model.dart';
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

class BottomInputField extends StatefulWidget {
  const BottomInputField(
      {Key? key,
      required this.scrollController,
      required this.conversationType,
      required this.conversationId,
      this.hint,
      this.chatUIConfig})
      : super(key: key);

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

  final ImagePicker _picker = ImagePicker();

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
      BuildContext context, String sessionId, NIMConversationType sessionType,
      {NIMMessageSender? messageSender}) {
    if (_currentType == ActionConstants.record) {
      _currentType = ActionConstants.none;
    } else {
      _focusNode.unfocus();
      _currentType = ActionConstants.record;
    }
    setState(() {});
  }

  _onEmojiActionTap(
      BuildContext context, String sessionId, NIMConversationType sessionType,
      {NIMMessageSender? messageSender}) {
    if (_titleFocusNode.hasFocus) {
      return;
    }
    if (_currentType == ActionConstants.emoji) {
      _currentType = ActionConstants.none;
    } else {
      _focusNode.unfocus();
      _currentType = ActionConstants.emoji;
    }
    setState(() {});
  }

  _pickImage() async {
    final List<XFile>? pickedFileList = await _picker.pickMultiImage();
    if (pickedFileList != null) {
      for (XFile image in pickedFileList) {
        Alog.d(
            tag: 'ChatKit',
            moduleName: 'bottom input',
            content: 'pick image path:${image.path}');

        String? imageType;
        if (image.path.lastIndexOf('.') + 1 < image.path.length) {
          imageType = image.path.substring(image.path.lastIndexOf('.') + 1);
        }
        final codec =
            await instantiateImageCodec(File(image.path).readAsBytesSync());
        final frame = await codec.getNextFrame();
        _viewModel.sendImageMessage(
            image.path, image.name, frame.image.width, frame.image.height,
            imageType: imageType);
      }
    }
  }

  _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    Alog.d(
        tag: 'ChatKit',
        moduleName: 'bottom input',
        content: 'pick video path:${video?.path}');
    if (video != null) {
      var length = await video.length();
      int overSize = ChatKitClient.instance.chatUIConfig.maxVideoSize ?? 200;
      if (length > overSize * 1024 * 1024) {
        Fluttertoast.showToast(
            msg: S.of(context).chatMessageFileSizeOverLimit("$overSize"));
        return;
      }
      VideoPlayerController controller =
          VideoPlayerController.file(File(video.path));
      controller.initialize().then((value) {
        _viewModel.sendVideoMessage(
            video.path,
            video.name,
            controller.value.duration.inMilliseconds,
            controller.value.size.width.toInt(),
            controller.value.size.height.toInt());
      });
    }
  }

  _onImageActionTap(
      BuildContext context, String sessionId, NIMConversationType sessionType,
      {NIMMessageSender? messageSender}) {
    // 收起键盘
    _focusNode.unfocus();

    var style = const TextStyle(fontSize: 16, color: CommonColors.color_333333);
    showBottomChoose<int>(
            context: context,
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Text(
                  S.of(context).chatMessagePickPhoto,
                  style: style,
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context, 2);
                },
                child: Text(
                  S.of(context).chatMessagePickVideo,
                  style: style,
                ),
              ),
            ],
            showCancel: true)
        .then((value) async {
      if (value == 1 || value == 2) {
        final permissionList;
        if (Platform.isIOS) {
          permissionList = [Permission.photos];
        } else if (Platform.isAndroid) {
          if (await PlatformUtils.isAboveAndroidT()) {
            permissionList = [Permission.photos, Permission.videos];
          } else {
            permissionList = [Permission.storage];
          }
        } else {
          permissionList = [];
        }
        if (await PermissionsHelper.requestPermission(permissionList)) {
          if (value == 1) {
            _pickImage();
          } else if (value == 2) {
            _pickVideo();
          }
        }
      }
    });
  }

  // _onFileActionTap() {
  // }

  _onMoreActionTap(
      BuildContext context, String sessionId, NIMConversationType sessionType,
      {NIMMessageSender? messageSender}) {
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
          BlendMode.srcIn),
    );
  }

  List<ActionItem> _defaultInputActions() {
    return [
      ActionItem(
          type: ActionConstants.record,
          icon: _actionIcon('images/ic_send_voice.svg', ActionConstants.record),
          permissions: [Permission.microphone],
          onTap: _onRecordActionTap,
          deniedTip: S.of(context).microphoneDeniedTips),
      ActionItem(
          type: ActionConstants.emoji,
          icon: _actionIcon('images/ic_send_emoji.svg', ActionConstants.emoji),
          onTap: _onEmojiActionTap),
      ActionItem(
          type: ActionConstants.image,
          icon: _actionIcon('images/ic_send_image.svg', ActionConstants.image),
          onTap: _onImageActionTap),
      // ActionItem(
      //     type: ActionConstants.file,
      //     icon: 'images/ic_send_file.svg',
      //     onTap: _onFileActionTap),
      ActionItem(
          type: ActionConstants.more,
          icon: _actionIcon('images/ic_more.svg', ActionConstants.more),
          onTap: _onMoreActionTap),
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
        sessionId: widget.conversationId,
        sessionType: widget.conversationType,
        onTranslateClick: _onTranslateActionTap,
      );
    }
    if (_currentType == ActionConstants.emoji) {
      return EmojiPanel(
        onEmojiSelected: (emoji) {
          final text = inputController.text;
          inputController.text = "$text$emoji";
          inputText = inputController.text;
          Future.delayed(Duration(milliseconds: 20), () {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          });
        },
        onEmojiDelete: () {
          final selection = inputController.selection;

          int cursorPos = selection.baseOffset;

          String originText = inputController.text;

          if (cursorPos < 0) {
            cursorPos = inputController.text.length;
          }

          String text;
          final emojiStartIndex = _findMatchingBracket(originText, cursorPos);
          if (emojiStartIndex >= 0) {
            text = (emojiStartIndex > 0
                    ? originText.substring(0, emojiStartIndex)
                    : '') +
                (cursorPos >= originText.length
                    ? ''
                    : originText.substring(cursorPos));
          } else {
            text = originText;
            text = originText.substring(0, cursorPos - 1) +
                (cursorPos < originText.length
                    ? originText.substring(cursorPos)
                    : '');
          }
          inputController.text = "$text";
          inputText = inputController.text;
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
    String name = await getUserNickInTeam(_viewModel.teamInfo!.teamId, account,
        showAlias: false);
    //已经在ait列表中，不再添加
    if (!reAdd && _aitManager?.haveBeAit(account) == true) {
      return;
    }
    _aitManager?.addAitWithText(account, '@$name$blank', inputText.length);
    String text = '$inputText@$name$blank';
    inputController.text = text;
    inputController.selection =
        TextSelection.fromPosition(TextPosition(offset: text.length));
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
      var deletedAit =
          _aitManager?.deleteAitWithText(value, endIndex, deleteLen);
      if (deletedAit != null) {
        //删除前判断长度，解决奔溃问题，
        //复现路径：发送消息@信息在最后，然后撤回，重新编辑，在删除
        if (deletedAit.segments[0].endIndex - deleteLen < value.length) {
          inputController.text = value.substring(
                  0, deletedAit.segments[0].start) +
              value.substring(deletedAit.segments[0].endIndex + 1 - deleteLen);
        } else {
          inputController.text =
              value.substring(0, deletedAit.segments[0].start);
        }
        inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: deletedAit.segments[0].start));
        inputText = inputController.text;
        return;
      }
    } else if (inputText.length < len) {
      // @ 弹出选择框

      if (endIndex > 0 && value[endIndex - 1] == '@') {
        _aitManager?.selectMember(context).then((aitUser) {
          if (aitUser == AitContactsModel.accountAll) {
            final String allStr = S.of(context).chatTeamAitAll;
            _aitManager?.addAitWithText(AitContactsModel.accountAll,
                '@${S.of(context).chatTeamAitAll}$blank', endIndex - 1);
            inputController.text =
                '${value.substring(0, endIndex)}$allStr$blank${value.substring(endIndex)}';
            inputController.selection = TextSelection.fromPosition(
                TextPosition(offset: endIndex + allStr.length + 1));
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
                accountId, '@$name$blank', endIndex - 1);
            inputController.text =
                '${value.substring(0, endIndex)}$name$blank${value.substring(endIndex)}';
            inputController.selection = TextSelection.fromPosition(
                TextPosition(offset: endIndex + name.length + 1));
            inputText = inputController.text;
          }
        });
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
      Fluttertoast.showToast(
          msg: S.of(context).chatMessageNotSupportEmptyMessage,
          gravity: ToastGravity.CENTER);
    }
    _scrollToBottom();
  }

  _onTranslateActionTap(
      BuildContext context, String sessionId, NIMConversationType sessionType,
      {NIMMessageSender? messageSender}) {
    setState(() {
      _isTranslating = true;
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
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 16), () {
      if (widget.scrollController.positions.isNotEmpty &&
          widget.scrollController.positions.length == 1) {
        widget.scrollController.animateTo(
          widget.scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.ease,
        );
      }
    });
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
            TextPosition(offset: reeditMessageContent.length));
        inputText = inputController.text;
      }
      //处理title
      if (titleText?.isNotEmpty == true) {
        titleController.text = titleText!;
        titleController.selection =
            TextSelection.fromPosition(TextPosition(offset: titleText.length));
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
      _handleReplyAit(_viewModel.replyMessage!);
      if (!_viewModel.isMultiSelected) {
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
                  'inputController.selection.baseOffset:$index, indexMoved:$indexMoved');
          if (indexMoved > inputController.text.length) {
            indexMoved = inputController.text.length;
          }
          inputController.selection =
              TextSelection.fromPosition(TextPosition(offset: indexMoved));
        }
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
      _viewModel.sessionId.then((sessionId) {
        _aitManager = AitManager(sessionId);
      });
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
    final accountId =
        ChatKitUtils.getConversationTargetId(widget.conversationId);
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
    return Container(
      width: MediaQuery.of(context).size.width,
      color: const Color(0xffeff1f3),
      child: SafeArea(
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
                                _viewModel.conversationId),
                            builder: (context, snapshot) {
                              return Text(
                                S.of(context).chatMessageReplySomeone(
                                    snapshot.data ?? ''),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xff929299)),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  )
                : Container(),
            _recording
                ? const SizedBox(
                    height: 54,
                  )
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
                                    vertical: 9, horizontal: 12),
                                fillColor:
                                    mute ? Color(0xffe3e4e4) : Colors.white,
                                filled: true,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8)),
                                    borderSide: BorderSide.none),
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
                                )),
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: CommonColors.color_333333,
                                fontSize: 18),
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
                        SingleChildScrollView(
                          child: SizedBox(
                            height: showTitle ? null : 40,
                            child: ExtendedTextField(
                              controller: inputController,
                              scrollController: _scrollController,
                              specialTextSpanBuilder:
                                  NeSpecialTextSpanBuilder(),
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 9, horizontal: 12),
                                  fillColor:
                                      mute ? Color(0xffe3e4e4) : Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(
                                      borderRadius: _isExpanded
                                          ? BorderRadius.zero
                                          : (showTitle
                                              ? BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(8),
                                                  bottomRight:
                                                      Radius.circular(8))
                                              : BorderRadius.circular(8)),
                                      borderSide: BorderSide.none),
                                  isDense: true,
                                  hintText: hint,
                                  hintStyle: const TextStyle(
                                      color: Color(0xffb3b7bc), fontSize: 16),
                                  enabled: !mute,
                                  suffixIcon:
                                      !IMKitClient.enableRichTextMessage ||
                                              showTitle
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
                                            )),
                              style: const TextStyle(
                                  color: CommonColors.color_333333,
                                  fontSize: 16),
                              textInputAction: _isExpanded
                                  ? TextInputAction.newline
                                  : TextInputAction.send,
                              onChanged: (value) {
                                _handleAitText();
                                _translatePanel.currentState
                                    ?.onInputTextChange();
                              },
                              maxLines: _isExpanded ? 8 : (showTitle ? 2 : 1),
                              onEditingComplete: _sendTextMessage,
                              enabled: !mute,
                            ),
                          ),
                        ),
                        if (_isExpanded) ...[
                          Container(
                            height: 1,
                            color: '#ECECEC'.toColor(),
                          ),
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
                                )),
                          ),
                        ]
                      ],
                    ),
                  ),
            if (_recording)
              SizedBox(
                height: 47,
                child: Text(
                  S.of(context).chatMessageVoiceIn,
                  style: const TextStyle(
                      fontSize: 12, color: CommonColors.color_999999),
                ),
              ),
            if (!_isExpanded && !_recording)
              Row(
                children: _getInputActions()
                    .map((action) => Expanded(
                            child: InputTextAction(
                          action: action,
                          enable: !mute,
                          onTap: () {
                            _scrollToBottom();
                            if (action.enable && action.onTap != null) {
                              action.onTap!(context, widget.conversationId,
                                  widget.conversationType,
                                  messageSender: (message) {
                                _viewModel.sendMessage(message);
                              });
                            }
                          },
                        )))
                    .toList(),
              ),
            if (!mute)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _getPanelHeight(),
                child: _getPanel(),
              )
          ],
        ),
      ),
    );
  }
}
