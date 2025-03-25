// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:azlistview_plus/azlistview_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:netease_common_ui/utils/color_utils.dart';

class AZListViewContainer extends StatefulWidget {
  final List<ISuspensionBeanImpl>? memberList;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Widget Function(BuildContext context, int index)? susItemBuilder;
  final bool isShowIndexBar;
  final double? textSize;
  final Color? textColor;
  final Color? divideLineColor;

  const AZListViewContainer(
      {Key? key,
      required this.memberList,
      required this.itemBuilder,
      this.susItemBuilder,
      this.textSize,
      this.textColor,
      this.divideLineColor,
      this.isShowIndexBar = true})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _AZListViewContainerState();
}

class _AZListViewContainerState extends State<AZListViewContainer> {
  List<ISuspensionBeanImpl> _suspensionList = List.empty(growable: true);

  addShowSuspension(List<ISuspensionBeanImpl> curList) {
    for (int i = 0; i < curList.length; i++) {
      if (i == 0 || curList[i].tagIndex != curList[i - 1].tagIndex) {
        curList[i].isShowSuspension = true;
      }
    }
    return curList;
  }

  Widget getSusItem(BuildContext context, String tag, {double susHeight = 40}) {
    return Container(
      height: susHeight,
      padding: const EdgeInsets.only(left: 20, top: 12, right: 20),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag,
            softWrap: true,
            style: TextStyle(
                fontSize: widget.textSize ?? 14,
                color: widget.textColor ?? CommonColors.color_333333),
          ),
          SizedBox(
            height: 8,
          ),
          Container(
            height: 1,
            color: widget.divideLineColor ?? CommonColors.color_dbe0e8,
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _suspensionList = addShowSuspension(widget.memberList!);
    });
  }

  @override
  void didUpdateWidget(covariant AZListViewContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      _suspensionList = addShowSuspension(widget.memberList!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AzListView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      data: _suspensionList,
      itemCount: _suspensionList.length,
      itemBuilder: widget.itemBuilder,
      indexBarData: widget.isShowIndexBar
          ? SuspensionUtil.getTagIndexList(_suspensionList)
              .where((e) => e != '@')
              .toList()
          : [],
      susItemBuilder: (context, index) {
        if (widget.susItemBuilder != null) {
          return widget.susItemBuilder!(context, index);
        }
        ISuspensionBeanImpl model = _suspensionList[index];
        if (model.getSuspensionTag() == '@') {
          return Container();
        }
        return getSusItem(context, model.getSuspensionTag());
      },
      //fixme azListView 没有提供悬浮功能开关，这里是一个规避办法
      susPosition: Offset(10000, 10000),
    );
  }
}

class ISuspensionBeanImpl<T> extends ISuspensionBean {
  String tagIndex;

  T contactInfo;

  ISuspensionBeanImpl({required this.tagIndex, required this.contactInfo});

  @override
  String getSuspensionTag() => tagIndex;
}
