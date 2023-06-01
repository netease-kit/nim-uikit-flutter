// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/permission_request.dart';
import 'package:netease_corekit_im/model/team_models.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:netease_corekit_im/services/message/chat_message.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/helper/chat_message_helper.dart';
import 'package:nim_chatkit_ui/view/input/emoji_panel.dart';
import 'package:nim_core/nim_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:video_player/video_player.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

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
  late TextEditingController inputController;
  late ScrollController _scrollController;
  late FocusNode _focusNode;
  late ChatViewModel _viewModel;

  final ImagePicker _picker = ImagePicker();

  String inputText = '';
  Map<String, UserInfoWithTeam?> aitMemberMap = {};

  bool mute = false;
  bool _keyboardShow = false;
  bool _recording = false;

  /// none, input, record, emoji, more
  String _currentType = ActionConstants.none;

  hideAllPanel() {
    _focusNode.unfocus();
    setState(() {
      _currentType = ActionConstants.none;
    });
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
        _viewModel.sendImageMessage(image.path, len);
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
        if (await PermissionsHelper.requestPermission(
            Platform.isIOS ? [Permission.photos] : [Permission.storage])) {
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
      color: selected ? CommonColors.color_337eff : CommonColors.color_656a72,
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

  void _handleReplyAit() {
    ChatMessage? replyMsg = _viewModel.replyMessage;
    if (widget.sessionType == NIMSessionType.team &&
        replyMsg != null &&
        replyMsg.fromUser?.userId != null &&
        replyMsg.fromUser?.userId != getIt<LoginService>().userInfo?.userId) {
      String account = replyMsg.fromUser!.userId!;
      NimCore.instance.teamService
          .queryTeamMember(_viewModel.teamInfo!.id!, account)
          .then((res) {
        if (res.isSuccess && res.data != null) {
          NIMTeamMember member = res.data!;
          String? name = member.teamNick;
          if (name == null || name.isEmpty) {
            name = replyMsg.fromUser?.nick ?? account;
          }
          if (aitMemberMap.containsKey('@$name')) {
            return;
          }
          aitMemberMap['@$name'] = UserInfoWithTeam(replyMsg.fromUser, member);
          String text = '$inputText@$name ';
          inputController.text = text;
          inputController.selection =
              TextSelection.fromPosition(TextPosition(offset: text.length));
          inputText = text;
        }
      });
    }
  }

  void _handleAitText(String value, List<UserInfoWithTeam>? member) {
    if (widget.sessionType != NIMSessionType.team) {
      inputText = value;
      return;
    }
    int len = value.length;
    if (inputText.length > len) {
      // delete
      Map<String, UserInfoWithTeam?> map = {};
      var matches = RegExp('@([^@\\s]*)').allMatches(value);
      matches.forEach((element) {
        String? name = element.group(0);
        if (name != null && aitMemberMap.containsKey(name)) {
          map[name] = aitMemberMap[name];
        }
      });
      aitMemberMap = map;
    } else if (value[len - 1] == '@' && inputText.length < len) {
      // @
      showModalBottomSheet(
          context: context,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8), topRight: Radius.circular(8))),
          builder: (context) {
            return Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: CommonColors.color_999999,
                          )),
                      Align(
                          alignment: Alignment.center,
                          child: Text(S.of(context).chatMessageAitContactTitle))
                    ],
                  ),
                ),
                ListTile(
                  leading: SvgPicture.asset(
                    'images/ic_team_all.svg',
                    package: kPackage,
                    height: 42,
                    width: 42,
                  ),
                  title: Text(S.of(context).chatTeamAitAll),
                  onTap: () {
                    Navigator.pop(context, 'all');
                  },
                ),
                if (member != null)
                  Expanded(
                      child: ListView.builder(
                          itemCount: member.length,
                          itemBuilder: (context, index) {
                            var user = member[index];
                            return ListTile(
                              leading: Avatar(
                                avatar: user.getAvatar(),
                                name: user.getName(
                                    needAlias: false, needTeamNick: false),
                                height: 42,
                                width: 42,
                              ),
                              title: Text(user.getName()),
                              onTap: () {
                                Navigator.pop(context, user);
                              },
                            );
                          }))
              ],
            );
          }).then((select) {
        if (select == 'all') {
          aitMemberMap['@${S.of(context).chatTeamAitAll}'] = null;
          inputController.text = "$value${S.of(context).chatTeamAitAll} ";
          inputText = inputController.text;
        } else if (select is UserInfoWithTeam) {
          // @列表需要展示用户备注，@结果不需要
          String name = select.getName(needAlias: false);
          aitMemberMap['@$name'] = select;
          inputController.text = "$value$name ";
          inputText = inputController.text;
        }
      });
    }
    inputText = value;
  }

  _sendTextMessage() {
    final text = inputController.text.trim();
    if (text.isNotEmpty) {
      List<String>? pushList;
      if (widget.sessionType == NIMSessionType.team) {
        pushList = [];
        if (aitMemberMap.containsKey('@${S.of(context).chatTeamAitAll}')) {
          // ait all
          pushList.add('ACCOUNT_ALL');
        } else {
          aitMemberMap.values.forEach((element) {
            if (element != null && element.userInfo != null) {
              pushList!.add(element.userInfo!.userId!);
            }
          });
        }
      }
      _viewModel.sendTextMessage(text,
          replyMsg: _viewModel.replyMessage?.nimMessage, pushList: pushList);
      _viewModel.replyMessage = null;
      aitMemberMap.clear();
      inputController.clear();
      inputText = '';
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
      inputController.text = _viewModel.reeditMessage!.reeditMessage!;
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
    inputController.addListener(() {
      if (_viewModel.sessionType == NIMSessionType.p2p) {
        _viewModel.sendInputNotification(inputController.text.isNotEmpty);
      }
    });
    _scrollController = ScrollController();
    _focusNode = FocusNode();
    _viewModel = context.read<ChatViewModel>();
    _viewModel.addListener(onViewModelChange);
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
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
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
                          _handleAitText(value,
                              context.read<ChatViewModel>().userInfoTeam);
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
                    children: _defaultInputActions()
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
