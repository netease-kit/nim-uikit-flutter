// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:im_common_ui/ui/avatar.dart';
import 'package:im_common_ui/ui/background.dart';
import 'package:im_common_ui/ui/dialog.dart';
import 'package:im_common_ui/ui/photo.dart';
import 'package:im_common_ui/utils/color_utils.dart';
import 'package:im_common_ui/widgets/transparent_scaffold.dart';
import 'package:corekit_im/service_locator.dart';
import 'package:corekit_im/services/login/login_service.dart';
import 'package:corekit_im/services/user_info/user_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_demo/generated/l10n.dart';
import 'package:nim_core/nim_core.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_svg/svg.dart';

enum EditType { none, avatar, nick, gender, birthday, phone, email, sign }

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  LoginService loginService = getIt<LoginService>();
  UserInfoProvider userInfoProvider = getIt<UserInfoProvider>();
  String title = '';
  EditType editType = EditType.none;
  late NIMUser userInfo;
  late final TextEditingController _controller;

  _updateInfo() {
    userInfoProvider.updateUserInfo(userInfo).then((value) {
      if (value.isSuccess) {
        loginService.getUserInfo();
        _backToPage();
      } else {
        Fluttertoast.showToast(msg: S.of(context).request_fail);
      }
    });
  }

  _onEditClick(EditType type) {
    if (type == EditType.avatar) {
      showPhotoSelector(context).then((url) {
        if (url != null) {
          userInfo.avatar = url;
          _updateInfo();
        }
      });
      return;
    }
    if (type == EditType.birthday) {
      showDateTimePicker(context, userInfo.birth, (time) {
        userInfo.birth = time;
        _updateInfo();
      });
      return;
    }
    switch (type) {
      case EditType.nick:
        title = S.of(context).user_info_nickname;
        _controller.text = userInfo.nick ?? '';
        break;
      case EditType.phone:
        title = S.of(context).user_info_phone;
        _controller.text = userInfo.mobile ?? '';
        break;
      case EditType.email:
        title = S.of(context).user_info_email;
        _controller.text = userInfo.email ?? '';
        break;
      case EditType.sign:
        title = S.of(context).user_info_sign;
        _controller.text = userInfo.sign ?? '';
        break;
      case EditType.gender:
        title = S.of(context).user_info_sexual;
        break;
      default:
        break;
    }
    setState(() {
      editType = type;
    });
  }

  _onEditSave() {
    switch (editType) {
      case EditType.nick:
        userInfo.nick = _controller.text;
        break;
      case EditType.phone:
        userInfo.mobile = _controller.text;
        break;
      case EditType.email:
        userInfo.email = _controller.text;
        break;
      case EditType.sign:
        userInfo.sign = _controller.text;
        break;
      default:
        break;
    }
    _updateInfo();
  }

  _backToPage() {
    setState(() {
      _controller.text = '';
      title = S.of(context).user_info_title;
      editType = EditType.none;
    });
  }

  int? _maxLength() {
    switch (editType) {
      case EditType.nick:
        return 30;
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
              package: 'teamkit_ui',
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
    _onGenderSelect(NIMUserGenderEnum genderEnum) {
      if (userInfo.gender == genderEnum) {
        return;
      }
      userInfo.gender = genderEnum;
      _updateInfo();
    }

    return CardBackground(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: ListTile.divideTiles(context: context, tiles: [
          ListTile(
            title: Text(
              S.of(context).sexual_unknown,
              style: textStyle,
            ),
            trailing: userInfo.gender == NIMUserGenderEnum.unknown
                ? const Icon(
                    Icons.check_rounded,
                    color: CommonColors.color_337eff,
                  )
                : null,
            onTap: () => _onGenderSelect(NIMUserGenderEnum.unknown),
          ),
          ListTile(
            title: Text(
              S.of(context).sexual_male,
              style: textStyle,
            ),
            trailing: userInfo.gender == NIMUserGenderEnum.male
                ? const Icon(
                    Icons.check_rounded,
                    color: CommonColors.color_337eff,
                  )
                : null,
            onTap: () => _onGenderSelect(NIMUserGenderEnum.male),
          ),
          ListTile(
            title: Text(
              S.of(context).sexual_female,
              style: textStyle,
            ),
            trailing: userInfo.gender == NIMUserGenderEnum.female
                ? const Icon(
                    Icons.check_rounded,
                    color: CommonColors.color_337eff,
                  )
                : null,
            onTap: () => _onGenderSelect(NIMUserGenderEnum.female),
          ),
        ]).toList(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (loginService.userInfo != null) {
      userInfo = NIMUser.fromMap(loginService.userInfo!.toMap());
    } else {
      userInfo = NIMUser();
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
      title: title.isEmpty ? S.of(context).user_info_title : title,
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
                      S.of(context).user_info_complete,
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

  final NIMUser userInfo;
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
    String sex = S.of(context).sexual_unknown;
    if (userInfo.gender == NIMUserGenderEnum.male) {
      sex = S.of(context).sexual_male;
    } else if (userInfo.gender == NIMUserGenderEnum.female) {
      sex = S.of(context).sexual_female;
    }
    List<Widget> userInfoTiles = [
      ListTile(
        title: Text(
          S.of(context).user_info_avatar,
          style: styleLeft,
        ),
        trailing: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Avatar(
              avatar: userInfo.avatar,
              name: userInfo.nick,
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
        title: Text(S.of(context).user_info_nickname),
        trailing: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                userInfo.nick ?? '',
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
        title: Text(S.of(context).user_info_account),
        trailing: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userInfo.userId ?? '',
              style: style,
            ),
            const SizedBox(
              width: 12,
            ),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: userInfo.userId));
                Fluttertoast.showToast(msg: S.of(context).action_copy_success);
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
        title: Text(S.of(context).user_info_sexual),
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
        title: Text(S.of(context).user_info_birthday),
        trailing: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userInfo.birth ?? '',
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
        title: Text(S.of(context).user_info_phone),
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
        title: Text(S.of(context).user_info_email),
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
              title: Text(S.of(context).user_info_sign),
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
