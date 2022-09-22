// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

//ignore: implementation_imports
import 'package:intl/src/intl_helpers.dart';

class Intl {
  static MessageLookup fixMessageLookup =
      UninitializedLocaleData('initializeMessages(<locale>)', null);

  static String message(String messageText,
          {String? desc = '',
          Map<String, Object>? examples,
          String? locale,
          String? name,
          List<Object>? args,
          String? meaning,
          bool? skip}) =>
      fixMessageLookup.lookupMessage(messageText, locale, name, args, meaning)!;
}
