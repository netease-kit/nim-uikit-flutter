// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/transparent_scaffold.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/helper/chat_message_helper.dart';

class ChatKitMessageDetailTextPage extends StatelessWidget {
  final String? title;
  final String content;
  final ChatUIConfig? chatUIConfig;

  const ChatKitMessageDetailTextPage({
    Key? key,
    this.title,
    required this.content,
    this.chatUIConfig,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
      title: "",
      body: Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null && title!.isNotEmpty) ...[
                Text(
                  title!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CommonColors.color_333333,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              _buildContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final String text = content;
    var matches = RegExp("\\[[^\\[]{1,10}\\]").allMatches(text);
    List<InlineSpan> spans = [];
    int preIndex = 0;

    // Explicitly null to avoid @ mentions
    var remoteExtension = null;

    if (matches.isNotEmpty) {
      for (final match in matches) {
        if (match.start > preIndex) {
          spans.addAll(ChatMessageHelper.buildTextSpansWithPhoneAndUrlDetection(
              context, false, text.substring(preIndex, match.start), preIndex,
              end: match.start,
              chatUIConfig: chatUIConfig,
              remoteExtension: remoteExtension));
        }
        var span = ChatMessageHelper.imageSpan(match.group(0));
        if (span != null) {
          spans.add(span);
        } else if (match.group(0)?.isNotEmpty == true) {
          spans.addAll(ChatMessageHelper.buildTextSpansWithPhoneAndUrlDetection(
              context, false, match.group(0)!, 0,
              chatUIConfig: chatUIConfig, remoteExtension: remoteExtension));
        }
        preIndex = match.end;
      }
      if (preIndex < text.length) {
        spans.addAll(ChatMessageHelper.buildTextSpansWithPhoneAndUrlDetection(
            context, false, text.substring(preIndex, text.length), preIndex,
            chatUIConfig: chatUIConfig, remoteExtension: remoteExtension));
      }
    } else {
      spans.addAll(ChatMessageHelper.buildTextSpansWithPhoneAndUrlDetection(
          context, false, text, 0,
          chatUIConfig: chatUIConfig, remoteExtension: remoteExtension));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      style: TextStyle(
        fontSize: 16,
        color: CommonColors.color_333333,
      ),
    );
  }
}
