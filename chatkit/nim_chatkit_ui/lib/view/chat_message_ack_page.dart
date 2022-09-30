// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'package:nim_chatkit/repo/chat_message_repo.dart';
import 'package:netease_common_ui/ui/avatar.dart';
import 'package:netease_common_ui/utils/color_utils.dart';
import 'package:netease_common_ui/widgets/keepalive_wrapper.dart';
import 'package:netease_corekit_im/model/contact_info.dart';
import 'package:netease_corekit_im/service_locator.dart';
import 'package:netease_corekit_im/services/contact/contact_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nim_core/nim_core.dart';
import 'package:yunxin_alog/yunxin_alog.dart';

import '../generated/l10n.dart';

class ChatMessageAckPage extends StatefulWidget {
  final NIMMessage message;

  ChatMessageAckPage({Key? key, required this.message}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MessageAckState();
}

enum _State { init, done }

class _MessageAckState extends State<ChatMessageAckPage> {
  _State _state = _State.init;

  NIMTeamMessageAckInfo? ackInfo;

  Widget _getAckList(List<String> reads, bool read) {
    if (_state == _State.init) {
      return Container();
    } else if (_state == _State.done && reads.isEmpty) {
      return Column(
        children: [
          const SizedBox(
            height: 68,
          ),
          SvgPicture.asset(
            'images/ic_message_read.svg',
            package: 'nim_chatkit_ui',
          ),
          const SizedBox(
            height: 18,
          ),
          Text(
            read
                ? S.of(context).message_all_unread
                : S.of(context).message_all_read,
            style: TextStyle(color: Color(0xffb3b7bc), fontSize: 14),
          )
        ],
      );
    } else {
      return ListView.builder(
          itemCount: reads.length,
          itemBuilder: (context, index) {
            String accId = reads[index];
            return FutureBuilder<ContactInfo?>(
                future: getIt<ContactProvider>().getContact(accId),
                builder: (context, snapShat) {
                  var contact = snapShat.data;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Avatar(
                          width: 36,
                          height: 36,
                          avatar: contact?.user.avatar,
                          name: contact?.getName(),
                          bgCode: AvatarColor.avatarColor(
                              content: contact?.user.userId),
                        ),
                        Expanded(
                          child: Container(
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.only(left: 12),
                              child: Text(
                                contact?.getName() ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 14, color: '#333333'.toColor()),
                              )),
                        )
                      ],
                    ),
                  );
                });
          });
    }
  }

  @override
  void initState() {
    super.initState();
    ChatMessageRepo.fetchTeamMessageReceiptDetail(widget.message).then((value) {
      Alog.d(
          tag: 'ChatKit',
          moduleName: 'Ack Page',
          content:
              'initState fetchTeamMessageReceiptDetail ${widget.message.uuid} -->> ${value?.toMap()}');
      setState(() {
        _state = _State.done;
        ackInfo = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var readList = ackInfo?.ackAccountList ?? List.empty();
    var unreadList = ackInfo?.unAckAccountList ?? List.empty();
    return DefaultTabController(
        length: 2,
        initialIndex: 1,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              S.of(context).message_read_status,
              style: TextStyle(fontSize: 16, color: '#333333'.toColor()),
            ),
            bottom: TabBar(
              unselectedLabelColor: '#333333'.toColor(),
              labelColor: '#337EFF'.toColor(),
              tabs: [
                Text(
                  S
                      .of(context)
                      .message_read_with_number(readList.length.toString()),
                ),
                Text(
                  S
                      .of(context)
                      .message_unread_with_number(unreadList.length.toString()),
                )
              ],
            ),
            centerTitle: true,
          ),
          body: TabBarView(children: [
            KeepAliveWrapper(child: _getAckList(readList, true)),
            KeepAliveWrapper(child: _getAckList(unreadList, false)),
          ]),
        ));
  }
}
