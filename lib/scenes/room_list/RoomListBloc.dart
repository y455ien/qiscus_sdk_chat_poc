import 'dart:async';
import 'dart:collection';

import 'package:chat_poc/ChatSDK.dart';
import 'package:qiscus_chat_sdk/qiscus_chat_sdk.dart';

class RoomListBloc {
  var rooms = HashMap<int, QChatRoom>();
  StreamController chatRoomsStream =
      StreamController<HashMap<int, QChatRoom>>();

  RoomListBloc() {
    ChatSDK().instance.onMessageReceived(_onMessageReceived);
    getAllChatRooms();
  }

  getAllChatRooms() async {
    var rooms = await ChatSDK().instance.getAllChatRooms$(
          showParticipant: true,
          showEmpty: true,
        );
    var entries = rooms.map((r) => MapEntry(r.id, r));
    this.rooms.addEntries(entries);
    _sortChatRooms();
    chatRoomsStream.add(this.rooms);

    // scheduleMicrotask(() async {
    //   ChatSDK().instance.getAllChatRooms(showParticipant: true, showEmpty: true, callback: (rooms, err) {
    //     if (err != null) {
    //       throw err;
    //     }
    //     if (err == null) {
    //       var entries = rooms.map((r) => MapEntry(r.id, r));
    //       this.rooms.addEntries(entries);
    //       _sortChatRooms();
    //       chatRoomsStream.add(this.rooms);
    //     }
    //   });
    // });
  }

  updateRoom(QChatRoom _room, QChatRoom selectedRoom) {
    if (_room != null) {
      this.rooms.update(selectedRoom.id, (r) {
        return _room;
      });
      this.chatRoomsStream.add(this.rooms);
    }
  }

  // refresh() async {
  //   var rooms = await ChatSDK().instance.getAllChatRooms$();
  //   this.rooms.addEntries(rooms.map((r) => MapEntry(r.id, r)));
  //   this.chatRoomsStream.add(this.rooms);
  // }

  void _sortChatRooms() {
    this.rooms.values.where((r) => r.lastMessage != null).toList()
      ..sort((r1, r2) {
        return r2.lastMessage.timestamp.compareTo(r1.lastMessage.timestamp);
      });
  }

  void _onMessageReceived(QMessage message) async {
    var roomId = message.chatRoomId;
    var hasRoom = this.rooms.containsKey(roomId);

    QChatRoom room;
    if (!hasRoom) {
      var rooms = await ChatSDK().instance.getChatRooms$(roomIds: [roomId]);
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
    ChatSDK().instance.onMessageReceived(null);
  }
}
