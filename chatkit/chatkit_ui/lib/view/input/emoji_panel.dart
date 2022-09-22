// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:chatkit_ui/generated/l10n.dart';
import 'package:chatkit_ui/view/input/emoji.dart';
import 'package:im_common_ui/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class EmojiPanel extends StatefulWidget {
  const EmojiPanel(
      {Key? key,
      required this.onEmojiSelected,
      required this.onEmojiSendClick,
      required this.onEmojiDelete})
      : super(key: key);

  final ValueChanged<String> onEmojiSelected;
  final Function() onEmojiDelete;
  final Function() onEmojiSendClick;

  @override
  State<StatefulWidget> createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<EmojiPanel> {
  static const int _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [];
    int size = (emojiData.length / _pageSize).ceil();
    for (int i = 0; i < size; ++i) {
      int start = i * _pageSize;
      int end = start + _pageSize > emojiData.length
          ? emojiData.length
          : start + _pageSize;
      pages.add(EmojiPage(
        start: start,
        end: end,
        emojiTap: widget.onEmojiSelected,
        deleteTap: widget.onEmojiDelete,
      ));
    }

    return Column(
      children: [
        const Divider(
          height: 1,
          color: Color(0xffE9EAEB),
        ),
        Expanded(
          child: PageView(
            children: pages,
            allowImplicitScrolling: true,
          ),
        ),
        Container(
          alignment: Alignment.topRight,
          height: 32,
          color: Colors.white,
          child: InkWell(
            onTap: widget.onEmojiSendClick,
            child: Container(
              height: 32,
              width: 60,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: CommonColors.color_337eff),
              child: Text(
                S.of(context).chat_message_send,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class EmojiPage extends StatelessWidget {
  const EmojiPage(
      {Key? key,
      required this.start,
      required this.end,
      required this.emojiTap,
      required this.deleteTap})
      : super(key: key);

  final int start;
  final int end;
  final ValueChanged<String> emojiTap;
  final Function() deleteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          var w = constraints.maxWidth / 7;
          var h = constraints.maxHeight / 3;
          return GridView.count(
            crossAxisCount: 7,
            childAspectRatio: w / h,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ...emojiData.sublist(start, end).map((e) {
                int unicode = e['unicode'] as int;
                return InkWell(
                  onTap: () {
                    emojiTap(String.fromCharCode(unicode));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.transparent,
                      ),
                    ),
                    alignment: Alignment.center,
                    height: 30,
                    width: 30,
                    child: Text(
                      String.fromCharCode(unicode),
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                );
              }).toList(),
              ...[
                InkWell(
                  onTap: deleteTap,
                  child: Container(
                    height: 30,
                    width: 30,
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      'images/ic_emoji_del.svg',
                      package: 'chatkit_ui',
                      height: 20,
                      width: 20,
                    ),
                  ),
                )
              ]
            ],
          );
        },
      ),
    );
  }
}
