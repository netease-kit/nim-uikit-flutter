// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:netease_corekit_im/router/imkit_router_factory.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/login/login_service.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_item.dart';
import 'package:nim_chatkit_ui/view/input/actions.dart';
import 'package:nim_chatkit_ui/view_model/chat_view_model.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_contactkit/repo/contact_repo.dart';
import 'package:nim_contactkit_ui/page/contact_page.dart';
import 'package:nim_conversationkit/repo/conversation_repo.dart';
import 'package:nim_conversationkit_ui/page/conversation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:im_demo/l10n/S.dart';
import 'package:im_demo/src/mine/mine_page.dart';
import 'package:nim_core/nim_core.dart';
import 'package:provider/provider.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../config.dart';

const channelName = "com.netease.yunxin.app.flutter.im/channel";
const pushMethodName = "pushMessage";

class HomePage extends StatefulWidget {
  final int pageIndex;

  const HomePage({Key? key, this.pageIndex = 0}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// 当前选择下标
  int currentIndex = 0;

  int chatUnreadCount = 0;
  int contactUnreadCount = 0;

  initUnread() {
    ConversationRepo.getMsgUnreadCount().then((value) {
      if (value.isSuccess && value.data != null) {
        setState(() {
          chatUnreadCount = value.data!;
        });
      }
    });
    ContactRepo.getNotificationUnreadCount().then((value) {
      if (value.isSuccess && value.data != null) {
        setState(() {
          contactUnreadCount = value.data!;
        });
      }
    });
    ContactRepo.registerNotificationUnreadCountObserver().listen((event) {
      setState(() {
        contactUnreadCount = event;
      });
    });
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == pushMethodName && call.arguments is Map) {
      _dispatchMessage(call.arguments);
    }
  }

  ///解析从Android端传递过来的消息，并分发
  void _handleMessageFromNative() {
    const channel = MethodChannel(channelName);

    //注册回调，用于页面没有被销毁的时候的回调监听
    channel.setMethodCallHandler((call) => _handleMethodCall(call));

    //方法调用，用于页面被销毁时候的情况
    channel.invokeMapMethod<String, dynamic>(pushMethodName).then((value) {
      Alog.d(tag: 'HomePage', content: "Message from Android is = $value}");
      _dispatchMessage(value);
    });
  }

  //分发消息，跳转到聊天页面
  void _dispatchMessage(Map? params) {
    var sessionType = params?['sessionType'] as String?;
    var sessionId = params?['sessionId'] as String?;
    if (sessionType?.isNotEmpty == true && sessionId?.isNotEmpty == true) {
      if (sessionType == 'p2p') {
        goToP2pChat(context, sessionId!);
      } else if (sessionType == 'team') {
        goToTeamChat(context, sessionId!);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    currentIndex = widget.pageIndex;
    initUnread();

    // chat config
    var messageBuilder = ChatKitMessageBuilder();
    messageBuilder.extendBuilder = {
      NIMMessageType.custom: (NIMMessage msg) {
        return Container(
          child: Text(
            msg.content ?? 'default text',
            style: TextStyle(fontSize: 20, color: Colors.red),
          ),
        );
      }
    };
    ChatKitClient.instance.aMapIOSKey = IMDemoConfig.AMapIOS;
    ChatKitClient.instance.aMapAndroidKey = IMDemoConfig.AMapAndroid;
    //注册全局监听撤回消息
    ChatKitClient.instance.registerRevokedMessage(messageRevokedStr: '此消息已撤回');
    ChatKitClient.instance.chatUIConfig = ChatUIConfig(moreActions: [
      ActionItem(
          type: 'custom',
          icon: Icon(Icons.android_outlined),
          title: "自定义",
          onTap: (BuildContext context) async {
            var vm = context.read<ChatViewModel>();
            var msg = await MessageBuilder.createCustomMessage(
                sessionId: vm.sessionId,
                sessionType: vm.sessionType,
                content: '自定义消息');
            if (msg.isSuccess && msg.data != null) {
              Fluttertoast.showToast(msg: '发送自定义消息！ ');
              vm.sendMessage(msg.data!);
            }
          }),
    ], messageBuilder: messageBuilder, getPushPayload: _getPushPayload);
    _handleMessageFromNative();
  }

  @override
  void dispose() {
    super.dispose();
    ChatKitClient.instance.unregisterRevokedMessage();
  }

  //获取pushPayload
  Map<String, dynamic> _getPushPayload(NIMMessage message) {
    Map<String, dynamic> pushPayload = Map();
    var sessionId = message.sessionType == NIMSessionType.p2p
        ? getIt<LoginService>().userInfo?.userId
        : message.sessionId;
    var sessionType =
        message.sessionType == NIMSessionType.p2p ? "p2p" : "team";
    // 添加 apns payload
    // var alert = {
    //   "title" : "your title",
    //   "subtitle" : "your sub Title",
    //   "body" : "your title"
    // };
    // var category = {"category" : "your category"};
    // var apsField = {
    //   "alert":alert,
    //   "category":category
    // };
    // pushPayload["apsField"] = apsField;

    // 添加oppo 的pushPayload
    var oppoParam = {"sessionId": sessionId, "sessionType": sessionType};
    var oppoField = {
      "click_action_type": 4,
      "click_action_activity": 'com.netease.yunxin.app.flutter.im.MainActivity',
      "action_parameters": oppoParam
    };
    pushPayload["oppoField"] = oppoField;
    // 添加vivo 推送参数

    var vivoField = {
      "pushMode": 0 //推送模式 0：正式推送；1：测试推送，不填默认为0
    };

    pushPayload["vivoField"] = vivoField;

    //添加华为推送参数
    var huaweiClickAction = {
      'type': 1,
      'action': 'com.netease.yunxin.app.flutter.im.push'
    };

    var config = {
      'category': 'IM',
      'data': jsonEncode({'sessionId': sessionId, 'sessionType': sessionType})
    };
    pushPayload['hwField'] = {
      'click_action': huaweiClickAction,
      'androidConfig': config
    };
    //添加通用的参数
    pushPayload["sessionId"] = sessionId;
    pushPayload["sessionType"] = sessionType;
    return pushPayload;
  }

  Widget _getIcon(Widget tabIcon, {bool showRedPoint = false}) {
    if (!showRedPoint) {
      return tabIcon;
    } else {
      return Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          tabIcon,
          if (contactUnreadCount > 0 || chatUnreadCount > 0)
            Positioned(
              top: -2.0,
              right: -3.0,
              child: Offstage(
                offstage: false,
                child: Container(
                  height: 6,
                  width: 6,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            )
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: bottomNavigatorList().map((res) => res.widget).toList(),
      ),
      bottomNavigationBar: Theme(
        data: ThemeData(
          brightness: Brightness.light,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: "#F6F8FA".toColor(),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          elevation: 0,
          items: List.generate(
            bottomNavigatorList().length,
            (index) => BottomNavigationBarItem(
              icon: _getIcon(
                  index == currentIndex
                      ? bottomNavigatorList()[index].selectedIcon
                      : bottomNavigatorList()[index].unselectedIcon,
                  showRedPoint: (index == 1 && contactUnreadCount > 0) ||
                      (index == 0 && chatUnreadCount > 0)),
              label: bottomNavigatorList()[index].title,
            ),
          ),
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            _changePage(index);
          },
        ),
      ),
    );
  }

  //如果点击的导航页不是当前项，切换
  void _changePage(int index) {
    if (index != currentIndex) {
      setState(() {
        currentIndex = index;
      });
    }
  }

  List<NavigationBarData> bottomNavigatorList() {
    return getBottomNavigatorList(context);
  }

  List<NavigationBarData> getBottomNavigatorList(BuildContext context) {
    final List<NavigationBarData> bottomNavigatorList = [
      NavigationBarData(
        widget: ConversationPage(
          onUnreadCountChanged: (unreadCount) {
            setState(() {
              chatUnreadCount = unreadCount;
            });
          },
        ),
        title: S.of(context).message,
        selectedIcon: SvgPicture.asset(
          'assets/icon_session_selected.svg',
          width: 28,
          height: 28,
        ),
        unselectedIcon: SvgPicture.asset(
          'assets/icon_session_selected.svg',
          width: 28,
          height: 28,
          color: CommonColors.color_c5c9d2,
        ),
      ),
      NavigationBarData(
        widget: const ContactPage(),
        title: S.of(context).contact,
        selectedIcon: SvgPicture.asset(
          'assets/icon_contact_selected.svg',
          width: 28,
          height: 28,
        ),
        unselectedIcon: SvgPicture.asset(
          'assets/icon_contact_unselected.svg',
          width: 28,
          height: 28,
          color: CommonColors.color_c5c9d2,
        ),
      ),
      NavigationBarData(
        widget: const MinePage(),
        title: S.of(context).mine,
        selectedIcon: SvgPicture.asset(
          'assets/icon_my_selected.svg',
          width: 28,
          height: 28,
        ),
        unselectedIcon: SvgPicture.asset(
          'assets/icon_my_selected.svg',
          width: 28,
          height: 28,
          color: CommonColors.color_c5c9d2,
        ),
      ),
    ];

    return bottomNavigatorList;
  }
}

/// 底部导航栏数据对象
class NavigationBarData {
  /// 未选择时候的图标
  final Widget unselectedIcon;

  /// 选择后的图标
  final Widget selectedIcon;

  /// 标题内容
  final String title;

  /// 页面组件
  final Widget widget;

  NavigationBarData({
    required this.unselectedIcon,
    required this.selectedIcon,
    required this.title,
    required this.widget,
  });
}
