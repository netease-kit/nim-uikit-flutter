// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/view/input/emoji.dart';
import 'package:collection/collection.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:flutter/widgets.dart';

class ChatKitMessageTextItem extends StatefulWidget {
  final String text;

  final ChatUIConfig? chatUIConfig;

  const ChatKitMessageTextItem(
      {Key? key, required this.text, this.chatUIConfig})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatKitMessageTextState();
}

class ChatKitMessageTextState extends State<ChatKitMessageTextItem> {
  TextSpan _textSpan(String text) {
    return TextSpan(
        text: text,
        style: const TextStyle(fontSize: 16, color: CommonColors.color_333333));
  }

  WidgetSpan? _imageSpan(String? tag) {
    var item = emojiData.firstWhereOrNull((element) => element['tag'] == tag);
    if (item == null) return null;
    String name = item['name'] as String;
    return WidgetSpan(
      child: Image.asset(
        name,
        package: 'nim_chatkit_ui',
        height: 24,
        width: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var matches = RegExp("\\[[^\\[]{1,10}\\]").allMatches(widget.text);
    List<InlineSpan> spans = [];
    int preIndex = 0;
    if (matches.isNotEmpty) {
      final String text = widget.text;
      for (final match in matches) {
        if (match.start > preIndex) {
          spans.add(_textSpan(text.substring(preIndex, match.start)));
        }
        var span = _imageSpan(match.group(0));
        if (span != null) {
          spans.add(span);
        }
        preIndex = match.end;
      }
      if (preIndex < text.length) {
        spans.add(_textSpan(text.substring(preIndex, text.length)));
      }
    }
    return Container(
      //放到里面
      padding: const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 12),
      child: matches.isEmpty
          ? Text(
              widget.text,
              style: TextStyle(
                  fontSize: widget.chatUIConfig?.messageTextSize ?? 16,
                  color: widget.chatUIConfig?.messageTextColor ??
                      '#333333'.toColor()),
            )
          : Text.rich(TextSpan(children: spans)),
    );
  }
}
