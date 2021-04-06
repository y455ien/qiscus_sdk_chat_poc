import 'dart:async';
import 'dart:collection';

import 'package:chat_poc/ChatSDK.dart';
import 'package:qiscus_chat_sdk/qiscus_chat_sdk.dart';

class RoomListBloc {
  var rooms = HashMap<int, QChatRoom>();
  StreamController chatRoomsStream =
      StreamController<HashMap<int, QChatRoom>>();

  RoomListBloc() {
    ChatSDK().qiscusSDK.onMessageReceived(_onMessageReceived);
    getAllChatRooms();
  }

  getAllChatRooms() {
    scheduleMicrotask(() async {
      ChatSDK().qiscusSDK.getAllChatRooms(callback: (rooms, err) {
        if (err != null) {
          throw err;
        }
        if (err == null) {
          var entries = rooms.map((r) => MapEntry(r.id, r));
          this.rooms.addEntries(entries);
          chatRoomsStream.add(this.rooms);
        }
      });
    });
  }

  refresh() async {
    var rooms = await ChatSDK().qiscusSDK.getAllChatRooms$();
    this.rooms.addEntries(rooms.map((r) => MapEntry(r.id, r)));
    this.chatRoomsStream.add(this.rooms);
  }

  void _onMessageReceived(QMessage message) async {
    var roomId = message.chatRoomId;
    var hasRoom = this.rooms.containsKey(roomId);

    QChatRoom room;
    if (!hasRoom) {
      var rooms = await ChatSDK().qiscusSDK.getChatRooms$(roomIds: [roomId]);
      room = rooms.first;
    }

    this.rooms.update(roomId, (room) {
      room.lastMessage = message;
      room.unreadCount++;
      return room;
    }, ifAbsent: () {
      return room;
    });

    this.chatRoomsStream.add(this.rooms);
  }

  onDispose() {
    chatRoomsStream?.close();
    ChatSDK().qiscusSDK.onMessageReceived(null);
  }
}
