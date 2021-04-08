import 'dart:async';
import 'dart:collection';

import 'package:chat_poc/ChatSDK.dart';
import 'package:chat_poc/scenes/room_list/RoomListBloc.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qiscus_chat_sdk/qiscus_chat_sdk.dart';

import '../../ChatSDK.dart';
import '../../constants.dart';
import '../../extensions.dart';
import '../../widget/avatar_widget.dart';
import '../chat_page/chat_page.dart';
import '../login_page.dart';
import '../profile_page.dart';
import '../user_list_page.dart';

class RoomListPage extends StatefulWidget {
  RoomListPage({
    @required this.qiscus,
    @required this.account,
  });

  final QiscusSDK qiscus;
  final QAccount account;

  @override
  _RoomListPageState createState() => _RoomListPageState();
}

enum MenuItems {
  profile,
  logout,
}

class _RoomListPageState extends State<RoomListPage> {
  RoomListBloc _bloc;
  QAccount account;

  @override
  void initState() {
    super.initState();
    account = widget.account;
    _bloc = RoomListBloc();
  }

  @override
  void dispose() {
    super.dispose();
    _bloc.onDispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Hero(
            tag: HeroTags.accountAvatar,
            child: Avatar(url: account.avatarUrl),
          ),
        ),
        title: Text(account.name),
        actions: <Widget>[
          PopupMenuButton<MenuItems>(
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: MenuItems.profile,
                  child: Text('Profile'),
                ),
                PopupMenuItem(
                  value: MenuItems.logout,
                  child: Text('Logout'),
                ),
              ];
            },
            onSelected: (item) async {
              switch (item) {
                case MenuItems.logout:
                  {
                    await ChatSDK().instance.clearUser$();
                    context.pushReplacement(LoginPage());

                    break;
                  }

                case MenuItems.profile:
                // var _account = await context.push(
                //   ProfilePage(
                //     qiscus: qiscus,
                //     account: account,
                //   ),
                // );
                // setState(() {
                //   this.account = _account;
                // });
                // break;
              }
            },
          ),
        ],
      ),
      body: Container(
        child: RefreshIndicator(
          onRefresh: () => _bloc.getAllChatRooms(),
          child: StreamBuilder<HashMap<int, QChatRoom>>(
            stream: _bloc.chatRoomsStream.stream,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                print("LOG: " + snapshot.data.toString());
                return ListView.separated(
                  itemBuilder: (context, index) {
                    var room = snapshot.data.values.elementAt(index);
                    var lastMessage = _getLastMessage(room.lastMessage);
                    return ListTile(
                      leading: avatar(room),
                      title: Text(room.participants.firstWhere((element) => element.id != account.id).name),
                      subtitle: info(room, lastMessage),
                      trailing: timeStamp(room),
                      onTap: () async {
                        await navigate(context, room);
                      },
                    );
                  },
                  itemCount: snapshot.data.length,
                  separatorBuilder: (context, index) {
                    return Divider(
                      color: Colors.black38,
                    );
                  },
                );
              } else {
                return Container();
              }
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.search),
        onPressed: () {
          context.push(UserListPage(
            qiscus: ChatSDK().instance,
            account: account,
          ));
        },
      ),
    );
  }

  Future navigate(BuildContext context, QChatRoom room) async {
    var _room = await context.push(
      ChatPage(
        qiscus: ChatSDK().instance,
        account: account,
        room: room,
      ),
    );
    _bloc.updateRoom(_room, room);
  }

  StatelessWidget timeStamp(QChatRoom room) {
    return room.lastMessage != null
        ? Text(
            formatDate(
              room.lastMessage?.timestamp,
              [HH, ':', mm],
            ),
          )
        : Container();
  }

  Widget info(QChatRoom room, String lastMessage) {
    return room.type == QRoomType.single
        ? Text(
            lastMessage,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          )
        : Row(
            children: <Widget>[
              Expanded(
                flex: 0,
                child: Text(
                  '${room.lastMessage.sender.name}: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  lastMessage,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
  }

  Stack avatar(QChatRoom room) {
    return Stack(
      overflow: Overflow.visible,
      children: <Widget>[
        Hero(
          tag: HeroTags.roomAvatar(roomId: room.id),
          child: Avatar(url: room.avatarUrl),
        ),
        if (room.unreadCount > 0)
          Positioned(
            bottom: -3,
            right: -3,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(50)),
                color: Colors.redAccent,
                border: Border.fromBorderSide(BorderSide(
                  color: Colors.white,
                  width: 1,
                )),
              ),
              child: Center(
                child: Text(
                  room.unreadCount > 9 ? '9+' : room.unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getLastMessage(QMessage lastMessage) {
    if (lastMessage == null || lastMessage.text.isEmpty) return 'No messages';
    if (lastMessage.text.contains('[file]')) return 'File attachment';
    return lastMessage.text;
  }
}
