// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:azlistview_plus/azlistview_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/manager/subscription_manager.dart';
import 'package:nim_chatkit/model/contact_info.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'contact_kit_az_list.dart';

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

  //首次加载 大于此数量的Item 时候注册，考虑到顶部有默认栏，故此设置为 8
  static const int defaultSubscriptionCount = 8;

  Timer? _scrollEndTimer;

  ItemPositionsListener? _listener;

  bool haveFirstSub = false;

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
    _listener = ItemPositionsListener.create();
    _listener?.itemPositions.addListener(() {
      final length = _listener!.itemPositions.value.length;
      // 大于8条则订阅用户状态
      if (!haveFirstSub) {
        if (length > defaultSubscriptionCount) {
          haveFirstSub = true;
          _scrollEndTimer =
              Timer(const Duration(milliseconds: 100), _subscribeUserStatus);
        }
      }
    });
  }

  void _subscribeUserStatus() {
    List<String> users = [];
    _listener?.itemPositions.value.forEach((item) {
      final itemData = widget.memberList?[item.index].contactInfo;
      if (itemData is ContactInfo) {
        users.add((itemData).user.accountId!);
      }
    });
    SubscriptionManager.instance.subscribeUserStatus(users);
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
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        // 处理不同类型的滚动通知
        if (notification is ScrollStartNotification ||
            notification is ScrollUpdateNotification) {
          // 滚动开始或滚动中，取消之前的定时器
          _scrollEndTimer?.cancel();
        } else if (notification is ScrollEndNotification) {
          // 滚动结束，设置定时器，延迟1秒后执行操作
          _scrollEndTimer =
              Timer(const Duration(milliseconds: 100), _subscribeUserStatus);
        }
        return false; // 不阻止通知继续传递
      },
      child: ContactAzListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        data: _suspensionList,
        susChanged: () {
          _scrollEndTimer?.cancel();
          _scrollEndTimer =
              Timer(const Duration(milliseconds: 100), _subscribeUserStatus);
        },
        itemCount: _suspensionList.length,
        itemBuilder: widget.itemBuilder,
        itemPositionsListener: _listener,
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
      ),
    );
  }

  @override
  void dispose() {
    _scrollEndTimer?.cancel();
    super.dispose();
  }
}

class ISuspensionBeanImpl<T> extends ISuspensionBean {
  String tagIndex;

  T contactInfo;

  ISuspensionBeanImpl({required this.tagIndex, required this.contactInfo});

  @override
  String getSuspensionTag() => tagIndex;
}
