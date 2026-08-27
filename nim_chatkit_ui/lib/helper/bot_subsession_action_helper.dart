// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:nim_chatkit/utils/toast_utils.dart';
import 'package:nim_chatkit_ui/l10n/S.dart';
import 'package:nim_core_v2/nim_core.dart';

enum _BotSubsessionAction {
  rename,
  delete,
}

class BotSubsessionActionHelper {
  static const int maxTopicNameLength = 20;

  static Future<void> showTopicActions({
    required BuildContext context,
    required String currentTitle,
    required Future<NIMResult<dynamic>> Function(String title) onRename,
    required Future<NIMResult<void>> Function() onDelete,
    bool Function()? checkNetwork,
  }) async {
    final action = await showCupertinoModalPopup<_BotSubsessionAction>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context, _BotSubsessionAction.rename);
              },
              child: Text(S.of(context).botSubsessionRename),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context, _BotSubsessionAction.delete);
              },
              child: Text(S.of(context).chatMessageActionDelete),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(S.of(context).messageCancel),
          ),
        );
      },
    );
    if (!context.mounted) {
      return;
    }
    switch (action) {
      case _BotSubsessionAction.rename:
        await _renameTopic(
          context: context,
          currentTitle: currentTitle,
          onRename: onRename,
          checkNetwork: checkNetwork,
        );
        break;
      case _BotSubsessionAction.delete:
        await _deleteTopic(
          context: context,
          onDelete: onDelete,
          checkNetwork: checkNetwork,
        );
        break;
      case null:
        break;
    }
  }

  static Future<void> showDesktopTopicActions({
    required BuildContext context,
    required Offset globalPosition,
    required String currentTitle,
    required Future<NIMResult<dynamic>> Function(String title) onRename,
    required Future<NIMResult<void>> Function() onDelete,
    bool Function()? checkNetwork,
  }) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) {
      return;
    }
    final action = await material.showMenu<_BotSubsessionAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      shape: material.RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      items: [
        material.PopupMenuItem(
          value: _BotSubsessionAction.rename,
          height: 36,
          child: Text(S.of(context).botSubsessionRename),
        ),
        material.PopupMenuItem(
          value: _BotSubsessionAction.delete,
          height: 36,
          child: Text(
            S.of(context).chatMessageActionDelete,
            style: const TextStyle(color: material.Color(0xFFF5222D)),
          ),
        ),
      ],
    );
    if (!context.mounted) {
      return;
    }
    switch (action) {
      case _BotSubsessionAction.rename:
        await _renameTopic(
          context: context,
          currentTitle: currentTitle,
          onRename: onRename,
          checkNetwork: checkNetwork,
        );
        break;
      case _BotSubsessionAction.delete:
        await _deleteTopic(
          context: context,
          onDelete: onDelete,
          checkNetwork: checkNetwork,
        );
        break;
      case null:
        break;
    }
  }

  static Future<void> _renameTopic({
    required BuildContext context,
    required String currentTitle,
    required Future<NIMResult<dynamic>> Function(String title) onRename,
    bool Function()? checkNetwork,
  }) async {
    final controller = TextEditingController(text: currentTitle);
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: Text(S.of(dialogContext).botSubsessionRename),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: controller,
              autofocus: true,
              maxLength: maxTopicNameLength,
              placeholder: S.of(dialogContext).botSubsessionRenameHint,
              clearButtonMode: OverlayVisibilityMode.editing,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(S.of(dialogContext).messageCancel),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(S.of(dialogContext).messageSure),
            ),
          ],
        );
      },
    );
    final title = controller.text;
    controller.dispose();
    if (confirmed != true || !context.mounted) {
      return;
    }
    if (checkNetwork?.call() == false) {
      return;
    }
    if (!_isValidTitle(title)) {
      ChatUIToast.show(
        S.of(context).botSubsessionNameInvalid,
        context: context,
      );
      return;
    }
    final result = await onRename(title);
    if (!result.isSuccess) {
      ChatUIToast.show(
        result.errorDetails ?? S.of(context).botSubsessionRenameFailed,
        context: context,
      );
    }
  }

  static Future<void> _deleteTopic({
    required BuildContext context,
    required Future<NIMResult<void>> Function() onDelete,
    bool Function()? checkNetwork,
  }) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: Text(S.of(dialogContext).botSubsessionDeleteTitle),
          content: Text(S.of(dialogContext).botSubsessionDeleteConfirm),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(S.of(dialogContext).messageCancel),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(S.of(dialogContext).chatMessageActionDelete),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    if (checkNetwork?.call() == false) {
      return;
    }
    final result = await onDelete();
    if (!result.isSuccess) {
      ChatUIToast.show(
        S.of(context).botSubsessionDeleteFailed,
        context: context,
      );
    }
  }

  static bool _isValidTitle(String title) {
    final trimmed = title.trim();
    return trimmed.isNotEmpty && trimmed.length <= maxTopicNameLength;
  }
}
