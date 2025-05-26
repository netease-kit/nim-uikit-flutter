// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/ui/background.dart';
import 'package:netease_common_ui/ui/dialog.dart';
import 'package:netease_common_ui/ui/photo.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/utils/connectivity_checker.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_chatkit/services/user_info/user_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_demo/l10n/S.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_svg/svg.dart';

enum EditType { none, avatar, nick, gender, birthday, phone, email, sign }

const int male = 1;

const int female = 2;

const int genderUnknown = 0;

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  IMLoginService loginService = getIt<IMLoginService>();
  UserInfoProvider userInfoProvider = getIt<UserInfoProvider>();
  String title = '';
  EditType editType = EditType.none;
  late NIMUserInfo userInfo;
  late final TextEditingController _controller;

  _updateInfo(NIMUserUpdateParam params) async {
    if (!await haveConnectivity()) {
      return;
    }
    userInfoProvider.updateUserInfo(params).then((value) {
      if (value.isSuccess) {
        loginService.getUserInfo().then((result) {
          if (result != null) {
            userInfo = result;
          }
          _backToPage();
        });
      } else {
        Fluttertoast.showToast(msg: S.of(context).requestFail);
      }
    });
  }

  _onEditClick(EditType type) async {
    if (!await haveConnectivity()) {
      return;
    }
    if (type == EditType.avatar) {
      showPhotoSelector(context).then((path) async {
        if (path != null) {
          final fileParams = NIMUploadFileParams(filePath: path);
          final task = await NimCore.instance.storageService
              .createUploadFileTask(fileParams);
          if (task.isSuccess && task.data != null) {
            final uploadUrl =
                await NimCore.instance.storageService.uploadFile(task.data!);
            if (uploadUrl.isSuccess && uploadUrl.data?.isNotEmpty == true) {
              final updateParams = NIMUserUpdateParam(avatar: uploadUrl.data);
              _updateInfo(updateParams);
            }
          }
        }
      });
      return;
    }
    if (type == EditType.birthday) {
      showDateTimePicker(context, userInfo.birthday, (time) {
        final updateParams = NIMUserUpdateParam(birthday: time);
        _updateInfo(updateParams);
      });
      return;
    }
    switch (type) {
      case EditType.nick:
        title = S.of(context).userInfoNickname;
        _controller.text = userInfo.name ?? '';
        break;
      case EditType.phone:
        title = S.of(context).userInfoPhone;
        _controller.text = userInfo.mobile ?? '';
        break;
      case EditType.email:
        title = S.of(context).userInfoEmail;
        _controller.text = userInfo.email ?? '';
        break;
      case EditType.sign:
        title = S.of(context).userInfoSign;
        _controller.text = userInfo.sign ?? '';
        break;
      case EditType.gender:
        title = S.of(context).userInfoSexual;
        break;
      default:
        break;
    }
    setState(() {
      editType = type;
    });
  }

  _onEditSave() {
    final updateParams = NIMUserUpdateParam();
    switch (editType) {
      case EditType.nick:
        updateParams.name = _controller.text.trim();
        break;
      case EditType.phone:
        updateParams.mobile = _controller.text;
        break;
      case EditType.email:
        updateParams.email = _controller.text;
        break;
      case EditType.sign:
        updateParams.sign = _controller.text;
        break;
      default:
        break;
    }
    _updateInfo(updateParams);
  }

  _backToPage() {
    setState(() {
      _controller.text = '';
      title = S.of(context).userInfoTitle;
      editType = EditType.none;
    });
  }

  int? _maxLength() {
    switch (editType) {
      case EditType.nick:
        return 15;
      case EditType.sign:
        return 50;
      case EditType.email:
        return 30;
      case EditType.phone:
        return 11;
      default:
        return null;
    }
  }

  TextInputType? _inputType() {
    if (editType == EditType.phone) {
      return TextInputType.phone;
    } else if (editType == EditType.email) {
      return TextInputType.emailAddress;
    }
    return null;
  }

  Widget _editTextInfo() {
    return CardBackground(
      child: TextField(
        style: const TextStyle(fontSize: 16, color: CommonColors.color_333333),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          suffixIcon: IconButton(
            iconSize: 16,
            onPressed: () {
              _controller.clear();
            },
            icon: SvgPicture.asset(
              'images/ic_clear.svg',
              package: 'nim_teamkit_ui',
            ),
          ),
        ),
        controller: _controller,
        keyboardType: _inputType(),
        inputFormatters: [LengthLimitingTextInputFormatter(_maxLength())],
      ),
    );
  }

  Widget _editGender() {
    TextStyle textStyle =
        const TextStyle(fontSize: 16, color: CommonColors.color_333333);
    _onGenderSelect(int genderEnum) {
      if (userInfo.gender == genderEnum) {
        return;
      }
      final updateParams = NIMUserUpdateParam(gender: genderEnum);
      _updateInfo(updateParams);
    }

    return CardBackground(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: ListTile.divideTiles(context: context, tiles: [
          ListTile(
            title: Text(
              S.of(context).sexualMale,
              style: textStyle,
            ),
            trailing: userInfo.gender == male
                ? const Icon(
                    Icons.check_rounded,
                    color: CommonColors.color_337eff,
                  )
                : null,
            onTap: () => _onGenderSelect(male),
          ),
          ListTile(
            title: Text(
              S.of(context).sexualFemale,
              style: textStyle,
            ),
            trailing: userInfo.gender == female
                ? const Icon(
                    Icons.check_rounded,
                    color: CommonColors.color_337eff,
                  )
                : null,
            onTap: () => _onGenderSelect(female),
          ),
        ]).toList(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (loginService.userInfo != null) {
      userInfo = loginService.userInfo!;
    } else {
      userInfo = NIMUserInfo();
    }
    _controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    bool isEditText = editType == EditType.nick ||
        editType == EditType.phone ||
        editType == EditType.email ||
        editType == EditType.sign;
    if (isEditText) {
      body = _editTextInfo();
    } else if (editType == EditType.gender) {
      body = _editGender();
    } else {
      body = _PersonalInfoPage(
        userInfo,
        _onEditClick,
      );
    }
    return TransparentScaffold(
      title: title.isEmpty ? S.of(context).userInfoTitle : title,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_rounded,
          size: 26,
        ),
        onPressed: () {
          if (editType != EditType.none) {
            _backToPage();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      actions: isEditText
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: TextButton(
                    onPressed: _onEditSave,
                    child: Text(
                      S.of(context).userInfoComplete,
                      style: const TextStyle(
                          fontSize: 16, color: CommonColors.color_666666),
                    )),
              )
            ]
          : null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: body,
      ),
    );
  }
}

class _PersonalInfoPage extends StatelessWidget {
  const _PersonalInfoPage(this.userInfo, this.onEditClick);

  final NIMUserInfo userInfo;
  final Function(EditType type) onEditClick;

  @override
  Widget build(BuildContext context) {
    Widget arrow = SvgPicture.asset(
      'assets/ic_right_arrow.svg',
      height: 16,
      width: 16,
    );
    TextStyle styleLeft = const TextStyle(color: CommonColors.color_333333);
    TextStyle style = const TextStyle(fontSize: 12, color: Color(0xffa6adb6));
    String sex = S.of(context).sexualUnknown;
    if (userInfo.gender == male) {
      sex = S.of(context).sexualMale;
    } else if (userInfo.gender == female) {
      sex = S.of(context).sexualFemale;
    }
    List<Widget> userInfoTiles = [
      ListTile(
        title: Text(
          S.of(context).userInfoAvatar,
          style: styleLeft,
        ),
        trailing: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Avatar(
              avatar: userInfo.avatar,
              name: userInfo.name,
              bgCode: AvatarColor.avatarColor(content: userInfo.accountId),
              height: 36,
              width: 36,
            ),
            const SizedBox(
              width: 12,
            ),
            arrow
          ],
        ),
        onTap: () => onEditClick(EditType.avatar),
      ),
      ListTile(
        title: Text(S.of(context).userInfoNickname),
        trailing: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                userInfo.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            arrow
          ],
        ),
        onTap: () => onEditClick(EditType.nick),
      ),
      ListTile(
        title: Text(S.of(context).userInfoAccount),
        trailing: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userInfo.accountId ?? '',
              style: style,
            ),
            const SizedBox(
              width: 12,
            ),
            InkWell(
              onTap: () {
                Clipboard.setData(
                    ClipboardData(text: userInfo.accountId ?? ''));
                Fluttertoast.showToast(msg: S.of(context).actionCopySuccess);
              },
              child: Image.asset(
                'assets/ic_copy.png',
                height: 16,
                width: 16,
              ),
            )
          ],
        ),
      ),
      ListTile(
        title: Text(S.of(context).userInfoSexual),
        trailing: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sex,
              style: style,
            ),
            const SizedBox(
              width: 12,
            ),
            arrow
          ],
        ),
        onTap: () => onEditClick(EditType.gender),
      ),
      ListTile(
        title: Text(S.of(context).userInfoBirthday),
        trailing: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userInfo.birthday ?? '',
              style: style,
            ),
            const SizedBox(
              width: 12,
            ),
            arrow
          ],
        ),
        onTap: () => onEditClick(EditType.birthday),
      ),
      ListTile(
        title: Text(S.of(context).userInfoPhone),
        trailing: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userInfo.mobile ?? '',
              style: style,
            ),
            const SizedBox(
              width: 12,
            ),
            arrow
          ],
        ),
        onTap: () => onEditClick(EditType.phone),
      ),
      ListTile(
        title: Text(S.of(context).userInfoEmail),
        trailing: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                userInfo.email ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            arrow
          ],
        ),
        onTap: () => onEditClick(EditType.email),
      ),
    ];
    return SingleChildScrollView(
      child: Column(
        children: [
          CardBackground(
            child: Column(
              children:
                  ListTile.divideTiles(context: context, tiles: userInfoTiles)
                      .toList(),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          CardBackground(
            child: ListTile(
              title: Text(S.of(context).userInfoSign),
              trailing: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth - 96 - 36;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w),
                        child: Text(
                          userInfo.sign ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: style,
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      arrow
                    ],
                  );
                },
              ),
              onTap: () => onEditClick(EditType.sign),
            ),
          ),
        ],
      ),
    );
  }
}
