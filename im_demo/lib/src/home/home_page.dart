// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:im_demo/l10n/S.dart';
import 'package:im_demo/src/mine/mine_page.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:nim_chatkit/router/imkit_router_factory.dart';
import 'package:nim_chatkit/service_locator.dart';
import 'package:nim_chatkit/services/login/im_login_service.dart';
import 'package:nim_chatkit_ui/chat_kit_client.dart';
import 'package:nim_chatkit_ui/view/chat_kit_message_list/item/chat_kit_message_item.dart';
import 'package:nim_chatkit_ui/view/input/actions.dart';
import 'package:nim_chatkit/chatkit_utils.dart';
import 'package:nim_chatkit/repo/contact_repo.dart';
import 'package:nim_chatkit/repo/team_repo.dart';
import 'package:nim_contactkit_ui/page/contact_page.dart';
import 'package:nim_chatkit/repo/conversation_repo.dart';
import 'package:nim_conversationkit_ui/conversation_kit_client.dart';
import 'package:nim_conversationkit_ui/page/conversation_page.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:yunxin_alog/yunxin_alog.dart';
import 'package:nim_chatkit/repo/config_repo.dart';

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

  int teamActionsUnreadCount = 0;

  initUnread() {
    ConversationRepo.getMsgUnreadCount().then((value) {
      if (value.isSuccess && value.data != null) {
        setState(() {
          chatUnreadCount = value.data!;
        });
      }
    });
    ContactRepo.addApplicationUnreadCountNotifier.listen((count) {
      setState(() {
        contactUnreadCount = count;
      });
    });
    TeamRepo.teamActionsUnreadCountNotifier.listen((count) {
      setState(() {
        teamActionsUnreadCount = count;
      });
    });
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == pushMethodName && call.arguments is Map) {
      _dispatchMessage(call.arguments);
    }
  }

  ///解析从Native端传递过来的消息，并分发
  void _handleMessageFromNative() {
    const channel = MethodChannel(channelName);

    //注册回调，用于页面没有被销毁的时候的回调监听
    channel.setMethodCallHandler((call) => _handleMethodCall(call));

    //方法调用，用于页面被销毁时候的情况
    channel.invokeMapMethod<String, dynamic>(pushMethodName).then((value) {
      Alog.d(tag: 'HomePage', content: "Message from Native is = $value}");
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
    //注册撤回消息监听
    ChatKitClient.instance.registerRevokedMessage();
    //设置pushPayload
    ChatKitClient.instance.chatUIConfig.getPushPayload = _getPushPayload;
    //处理native端传递过来的消息
    _handleMessageFromNative();

    // todo 以下演示添加自定义消息发送，客户根据自己需求定制
    ChatKitClient.instance.showWarningTyps = true;
    var messageBuilder = ChatKitMessageBuilder();
    messageBuilder.extendBuilder = {
      NIMMessageType.custom: (NIMMessage msg) {
        return Container(
          child: Text(
            msg.text ?? 'default text',
            style: TextStyle(fontSize: 20, color: Colors.red),
          ),
        );
      }
    };

    // chat config
    ChatKitClient.instance.chatUIConfig.moreActions = [
      ActionItem(
          type: 'custom',
          icon: Icon(Icons.android_outlined),
          title: "自定义",
          onTap: (BuildContext context, String conversationId,
              NIMConversationType sessionType,
              {NIMMessageSender? messageSender}) async {
            var msg = await MessageCreator.createCustomMessage('自定义消息', '');
            if (msg.isSuccess && msg.data != null) {
              Fluttertoast.showToast(msg: '发送自定义消息！ ');
              messageSender?.call(msg.data!);
            }
          }),
    ];

    ChatKitClient.instance.chatUIConfig.messageBuilder = messageBuilder;

    //如果需要自己设置的更多按钮覆盖默认的，请设置keepDefaultMoreAction = false
    // 默认为true，表示保留默认的更多按钮，包括拍摄，位置，文件
    ChatKitClient.instance.chatUIConfig.keepDefaultMoreAction = true;

    //设置自定义消息在会话列表的展示
    ConversationKitClient.instance.conversationUIConfig = ConversationUIConfig(
        itemConfig: ConversationItemConfig(
            lastMessageContentBuilder: (context, conversationInfo) {
      if (conversationInfo.conversation.lastMessage?.messageType ==
              NIMMessageType.custom &&
          conversationInfo.conversation.lastMessage?.attachment == null) {
        return S.of(context).customMessage;
      }
      return null;
    }));
  }

  @override
  void dispose() {
    super.dispose();
    ChatKitClient.instance.unregisterRevokedMessage();
  }

  //获取pushPayload
  Future<Map<String, dynamic>> _getPushPayload(
      NIMMessage message, String conversationId) async {
    Map<String, dynamic> pushPayload = Map();
    String? sessionId;
    String? sessionType;
    if ((await NimCore.instance.conversationIdUtil
                .conversationType(conversationId))
            .data ==
        NIMConversationType.p2p) {
      sessionId = getIt<IMLoginService>().userInfo?.accountId;
      sessionType = "p2p";
    } else {
      sessionId = ChatKitUtils.getConversationTargetId(conversationId);
      sessionType = "team";
    }
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
          if ((contactUnreadCount + teamActionsUnreadCount) > 0 ||
              chatUnreadCount > 0)
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
                  showRedPoint: (index == 1 &&
                          (contactUnreadCount + teamActionsUnreadCount) > 0) ||
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

  Widget getSwindleWidget() {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
        alignment: Alignment.center,
        color: Color(0xfffff5e1),
        child: Text(
          S.of(context).swindleTips,
          style: TextStyle(fontSize: 14, color: Color(0xffeb9718)),
        ));
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
          topWidget: getSwindleWidget(),
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
          colorFilter:
              ColorFilter.mode(CommonColors.color_c5c9d2, BlendMode.srcIn),
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
          colorFilter:
              ColorFilter.mode(CommonColors.color_c5c9d2, BlendMode.srcIn),
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
          colorFilter:
              ColorFilter.mode(CommonColors.color_c5c9d2, BlendMode.srcIn),
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
