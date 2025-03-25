// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

class ThumbHelper {
  /// 生成图片缩略图url
  ///
  ///  [url] 图片url
  ///  [originW] 图片原始宽度
  /// [originH] 图片原始高度
  ///  缩略图url
  static String? makeImageThumbUrl(
      BuildContext context, String url, int originW, int originH) {
    Thumb thumb = Thumb.Internal;
    if (originH > 0 && originW > 0) {
      int ration =
          (originW > originH ? originW ~/ originH : originH ~/ originW);
      thumb = ration > 4 ? Thumb.External : Thumb.Internal;
    }
    var dm = MediaQuery.of(context).size;
    int width = (dm.width < dm.height ? dm.width : dm.height) ~/ 2;

    return appendQueryParams(url, toImageThumbParams(thumb, width, width));
  }

  static String? appendQueryParams(String? url, String params) {
    if (url?.isNotEmpty != true) {
      return null;
    }
    String connectChar = url!.contains("?") ? "&" : "?";

    return url + connectChar + params;
  }

  static String toImageThumbParams(Thumb thumb, int width, int height) {
    if (!checkImageThumb(thumb, width, height)) {
      throw ArgumentError("width=$width, height=$height");
    }

    var sb = StringBuffer();

    sb.write("thumbnail=");
    sb.write(width);
    sb.write(toImageThumbMethod(thumb));
    sb.write(height);

    sb.write("&imageView");

    var gifThumb = gifThumbParams();
    if (gifThumb.isNotEmpty) {
      sb.write(gifThumb);
    }
    return sb.toString();
  }

  static bool checkImageThumb(Thumb thumb, int width, int height) {
    // not allow negative
    if (width < 0 || height < 0) {
      return false;
    }

    switch (thumb) {
      case Thumb.Internal:
        // not allow both zero
        return width > 0 || height > 0;
      case Thumb.Crop:
      case Thumb.External:
        // not allow either zero
        return width > 0 && height > 0;
    }
  }

  static String toImageThumbMethod(Thumb thumb) {
    switch (thumb) {
      case Thumb.Internal:
        return "x";
      case Thumb.Crop:
        return "y";
      case Thumb.External:
        return "z";
    }
  }

  static String gifThumbParams() {
    return "&tostatic=0";
  }

  /// 生成视频缩略图url
  ///
  ///  [url] 视频url
  ///  缩略图url
  static String? makeVideoThumbUrl(String? url) {
    return appendQueryParams(url, toVideoThumbParams());
  }

  /// 生成视频缩略图url,取第一帧
  static String toVideoThumbParams() {
    return "vframe=1";
  }
}

enum Thumb {
  Internal,
  Crop,
  External,
}
