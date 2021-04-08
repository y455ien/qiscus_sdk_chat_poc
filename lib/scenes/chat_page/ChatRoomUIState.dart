import 'dart:collection';

import 'package:qiscus_chat_sdk/qiscus_chat_sdk.dart';

class ChatRoomUIState {
  QChatRoom room;
  bool isUserTyping = false;
  String userTyping;
  DateTime lastOnline;
  bool isOnline = false;
  var messages = HashMap<String, QMessage>();

}