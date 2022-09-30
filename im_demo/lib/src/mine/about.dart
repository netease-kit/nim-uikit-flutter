// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/common_browse_page.dart';

import '../../generated/l10n.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget divider = const Divider(
      color: CommonColors.color_f5f8fc,
      height: 1,
      thickness: 1,
      indent: 20,
    );
    TextStyle _style =
        const TextStyle(fontSize: 14, color: CommonColors.color_333333);
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(
              height: 102,
            ),
            SvgPicture.asset(
              'assets/ic_yunxin.svg',
              width: 46,
              height: 46,
            ),
            Text(
              S.of(context).yunxin_name,
              style: const TextStyle(
                  fontSize: 24, color: CommonColors.color_333333),
            ),
            const SizedBox(
              height: 45,
            ),
            divider,
            ListTile(
              title: Text(
                S.of(context).mine_version,
                style: _style,
              ),
              trailing: Text(
                'V1.0.0',
                style: _style,
              ),
            ),
            divider,
            ListTile(
              title: Text(
                S.of(context).mine_product,
                style: _style,
              ),
              trailing: SvgPicture.asset(
                'assets/ic_right_arrow.svg',
                height: 16,
                width: 16,
              ),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CommonBrowser(
                            title: S.of(context).mine_about,
                            url: 'https://netease.im/m/')));
              },
            ),
            divider
          ],
        ),
      ),
    );
  }
}
