// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/permission_request.dart';
import 'package:netease_common_ui/widgets/platform_utils.dart';
import 'package:netease_corekit_im/model/ait/ait_contacts_model.dart';
import 'package:netease_corekit_im/model/team_models.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:netease_corekit_im/services/message/chat_message.dart';
import 'package:nim_chatkit_ui/view/ait/ait_manager.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/helper/chat_message_helper.dart';
import 'package:nim_chatkit_ui/view/input/emoji_panel.dart';
import 'package:nim_core/nim_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:video_player/video_player.dart';
import 'package:yunxin_alog/yunxin_alog.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/helper/chat_message_user_helper.dart';

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
      required this.sessionType,
      this.hint,
      this.chatUIConfig})
      : super(key: key);

  final String? hint;
  final NIMSessionType sessionType;
  final AutoScrollController scrollController;
  final ChatUIConfig? chatUIConfig;

  @override
  State<StatefulWidget> createState() => _BottomInputFieldState();
}

class _BottomInputFieldState extends State<BottomInputField>
    with WidgetsBindingObserver {
  static const String blank = ' ';

  late TextEditingController inputController;
  late ScrollController _scrollController;
  late FocusNode _focusNode;
  late ChatViewModel _viewModel;

  final ImagePicker _picker = ImagePicker();

  String inputText = '';

  bool mute = false;
  bool _keyboardShow = false;
  bool _recording = false;

  /// none, input, record, emoji, more
  String _currentType = ActionConstants.none;

  AitManager? _aitManager;

  hideAllPanel() {
    _focusNode.unfocus();
    setState(() {
      _currentType = ActionConstants.none;
    });
  }

  addMention(String accId) {
    if (_viewModel.sessionType == NIMSessionType.team) {
      _addAitMember(accId, reAdd: true);
    }
  }

  _onRecordActionTap(BuildContext context) {
    if (_currentType == ActionConstants.record) {
      _currentType = ActionConstants.none;
    } else {
      _focusNode.unfocus();
      _currentType = ActionConstants.record;
    }
    setState(() {});
  }

  _onEmojiActionTap(BuildContext context) {
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
        int len = await image.length();
        Alog.d(
            tag: 'ChatKit',
            moduleName: 'bottom input',
            content: 'pick image path:${image.path}');

        String? imageType;
        if (image.path.lastIndexOf('.') + 1 < image.path.length) {
          imageType = image.path.substring(image.path.lastIndexOf('.') + 1);
        }
        _viewModel.sendImageMessage(image.path, len, imageType: imageType);
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
            controller.value.duration.inMilliseconds,
            controller.value.size.width.toInt(),
            controller.value.size.height.toInt(),
            video.name);
      });
    }
  }

  _onImageActionTap(BuildContext context) {
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

  _onMoreActionTap(BuildContext context) {
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
          String originText = inputController.text;
          var text = originText.characters.skipLast(1);
          inputController.text = "$text";
          inputText = inputController.text;
        },
        onEmojiSendClick: _sendTextMessage,
      );
    }
    return Container();
  }

  //将指定用户添加到@列表中
  //[account]  用户id
  //[reAdd]  是否重新添加，如果为true，不管是否已经在列表中，都会添加
  void _addAitMember(String account, {bool reAdd = false}) async {
    if (_viewModel.teamInfo == null) {
      return;
    }
    String name = await getUserNickInTeam(_viewModel.teamInfo!.id!, account,
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

  void _handleReplyAit() {
    ChatMessage? replyMsg = _viewModel.replyMessage;
    if (widget.sessionType == NIMSessionType.team &&
        replyMsg != null &&
        replyMsg.fromUser?.userId != null &&
        replyMsg.fromUser?.userId != getIt<LoginService>().userInfo?.userId) {
      String account = replyMsg.fromUser!.userId!;
      _addAitMember(account);
    }
  }

  void _handleAitText() {
    String value = inputController.text;
    if (widget.sessionType != NIMSessionType.team) {
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
        if (deletedAit.segments[0].end - deleteLen < value.length) {
          inputController.text =
              value.substring(0, deletedAit.segments[0].start) +
                  value.substring(deletedAit.segments[0].end - deleteLen);
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
        _aitManager?.selectMember(context).then((select) {
          if (select == AitContactsModel.accountAll) {
            final String allStr = S.of(context).chatTeamAitAll;
            _aitManager?.addAitWithText(AitContactsModel.accountAll,
                '@${S.of(context).chatTeamAitAll}$blank', endIndex - 1);
            inputController.text =
                '${value.substring(0, endIndex)}$allStr$blank${value.substring(endIndex)}';
            inputController.selection = TextSelection.fromPosition(
                TextPosition(offset: endIndex + allStr.length + 1));
            inputText = inputController.text;
          } else if (select is UserInfoWithTeam) {
            // @列表需要展示用户备注，@结果不需要
            String name = select.getName(needAlias: false);
            //add to aitManager
            _aitManager?.addAitWithText(
                select.teamInfo.account!, '@$name$blank', endIndex - 1);
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
    final text = inputController.text.trim();
    if (text.isNotEmpty) {
      List<String>? pushList;
      if (widget.sessionType == NIMSessionType.team) {
        if (_aitManager?.aitContactsModel != null) {
          pushList = _aitManager!.getPushList();
        }
      }
      _viewModel.sendTextMessage(
        text,
        replyMsg: _viewModel.replyMessage?.nimMessage,
        pushList: pushList,
        aitContactsModel: _aitManager?.aitContactsModel,
      );
      _viewModel.replyMessage = null;
      // aitMemberMap.clear();
      inputController.clear();
      inputText = '';
      _aitManager?.cleanAit();
    }
    _scrollToBottom();
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
    if (_viewModel.reeditMessage != null &&
        _viewModel.reeditMessage!.reeditMessage?.isNotEmpty == true) {
      _focusNode.requestFocus();
      //由于发送消息的时候回吧Text中的空格trim
      //判断如果是@信息在最后则补充空格
      var needBlank = false;
      if (_viewModel.reeditMessage?.aitContactsModel != null) {
        _aitManager?.forkAit(_viewModel.reeditMessage!.aitContactsModel!);
        if (_aitManager?.aitEnd(_viewModel.reeditMessage!.reeditMessage!) ==
            true) {
          needBlank = true;
        }
      }
      inputController.text =
          _viewModel.reeditMessage!.reeditMessage! + (needBlank ? blank : '');
      inputController.selection = TextSelection.fromPosition(TextPosition(
          offset: _viewModel.reeditMessage!.reeditMessage!.length));
      inputText = inputController.text;
      _viewModel.reeditMessage = null;
    }
    if (_viewModel.replyMessage != null) {
      _focusNode.requestFocus();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    inputController = TextEditingController();
    _viewModel = context.read<ChatViewModel>();
    inputController.addListener(() {
      if (_viewModel.sessionType == NIMSessionType.p2p) {
        _viewModel.sendInputNotification(inputController.text.isNotEmpty);
      } else if (inputText == inputController.text &&
          _aitManager?.haveAitMember() == true) {
        //处理移动光标的问题
        var index = inputController.selection.baseOffset;
        var indexMoved = _aitManager?.resetAitCursor(index);
        if (indexMoved != null && indexMoved != index) {
          if (indexMoved > inputController.text.length) {
            indexMoved = inputController.text.length;
          }
          inputController.selection =
              TextSelection.fromPosition(TextPosition(offset: indexMoved));
        }
      }
    });
    _scrollController = ScrollController();
    _focusNode = FocusNode();
    _viewModel.addListener(onViewModelChange);
    if (widget.sessionType == NIMSessionType.team) {
      _aitManager = AitManager(_viewModel.sessionId);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_focusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
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

  @override
  Widget build(BuildContext context) {
    var team = context.watch<ChatViewModel>().teamInfo;
    if (team != null &&
        team.creator != getIt<LoginService>().userInfo?.userId) {
      mute = team.isAllMute ?? false;
    }
    String? hint = mute ? S.of(context).chatTeamAllMute : widget.hint;
    return Container(
      width: MediaQuery.of(context).size.width,
      color: const Color(0xffeff1f3),
      child: SafeArea(
        child: Column(
          children: [
            _viewModel.replyMessage != null
                ? Container(
                    height: 36,
                    padding: const EdgeInsets.only(left: 11, right: 7),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            context.read<ChatViewModel>().replyMessage = null;
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
                            future: ChatMessageHelper.getReplayMessageText(
                                context,
                                _viewModel.replyMessage!.nimMessage.uuid!,
                                _viewModel.sessionId,
                                _viewModel.sessionType),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.done) {
                                _handleReplyAit();
                              }
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
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: inputController,
                        scrollController: _scrollController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 9, horizontal: 12),
                            fillColor: mute ? Color(0xffe3e4e4) : Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none),
                            isDense: true,
                            hintText: hint,
                            hintStyle: const TextStyle(
                                color: Color(0xffb3b7bc), fontSize: 16),
                            enabled: !mute),
                        maxLines: 1,
                        style: const TextStyle(
                            color: CommonColors.color_333333, fontSize: 16),
                        textInputAction: TextInputAction.send,
                        onChanged: (value) {
                          _handleAitText();
                        },
                        onEditingComplete: _sendTextMessage,
                        enabled: !mute,
                      ),
                    ),
                  ),
            _recording
                ? SizedBox(
                    height: 47,
                    child: Text(
                      S.of(context).chatMessageVoiceIn,
                      style: const TextStyle(
                          fontSize: 12, color: CommonColors.color_999999),
                    ),
                  )
                : Row(
                    children: _getInputActions()
                        .map((action) => Expanded(
                                child: InputTextAction(
                              action: action,
                              enable: !mute,
                              onTap: () {
                                _scrollToBottom();
                                if (action.onTap != null) {
                                  action.onTap!(context);
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
