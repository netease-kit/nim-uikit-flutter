// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:lpinyin/lpinyin.dart';
import 'package:nim_chatkit/model/contact_info.dart';

import '../view_model/chat_forward_view_model.dart';

/// 对好友列表进行自定义排序
List<SearchResult<ContactInfo>> sortFriends(
    List<SearchResult<ContactInfo>> friends) {
  final sortedFriends = List<SearchResult<ContactInfo>>.from(friends);

  sortedFriends.sort((a, b) {
    final nameA = a.data.getName();
    final nameB = b.data.getName();

    // 空名称处理
    if (nameA.isEmpty && nameB.isEmpty) return 0;
    if (nameA.isEmpty) return 1;
    if (nameB.isEmpty) return -1;

    // 获取排序键
    final sortKeyA = _getSortKey(nameA);
    final sortKeyB = _getSortKey(nameB);

    // 按类型优先级排序：字母/拼音 > 其他字符
    final typeA = _getCharType(nameA);
    final typeB = _getCharType(nameB);

    if (typeA != typeB) {
      return typeA.compareTo(typeB);
    }

    // 同类型按字典序排序
    return sortKeyA.compareTo(sortKeyB);
  });

  return sortedFriends;
}

/// 获取排序键
String _getSortKey(String name) {
  if (name.isEmpty) return '';

  final firstChar = name[0];

  // 判断首字符是否为中文
  if (_isChinese(firstChar)) {
    // 中文转拼音
    final pinyin = PinyinHelper.getPinyinE(name,
        separator: '', format: PinyinFormat.WITHOUT_TONE);
    return pinyin.toLowerCase();
  } else if (_isLetter(firstChar)) {
    // 英文字母
    return name.toLowerCase();
  } else {
    // 其他字符
    return name.toLowerCase();
  }
}

/// 获取字符类型（用于排序优先级）
int _getCharType(String name) {
  if (name.isEmpty) return 2;

  final firstChar = name[0];

  if (_isChinese(firstChar) || _isLetter(firstChar)) {
    return 0; // 中文/字母优先
  } else {
    return 1; // 其他字符靠后
  }
}

/// 判断是否为中文字符
bool _isChinese(String char) {
  final code = char.codeUnitAt(0);
  return (code >= 0x4e00 && code <= 0x9fff) || // 基本汉字
      (code >= 0x3400 && code <= 0x4dbf) || // 扩展A
      (code >= 0x20000 && code <= 0x2a6df); // 扩展B
}

/// 判断是否为英文字母
bool _isLetter(String char) {
  return RegExp(r'^[a-zA-Z]$').hasMatch(char);
}
