import 'dart:async';

import 'package:chat_poc/scenes/chat_page/ChatRoomUIState.dart';

import '../../ChatSDK.dart';
import 'package:qiscus_chat_sdk/qiscus_chat_sdk.dart';

class ChatPageBloc {
  // QChatRoom room;
  QAccount account;

  // var messages = HashMap<String, QMessage>();
  ChatRoomUIState state = ChatRoomUIState();
  StreamController stateStream = StreamController<ChatRoomUIState>();
  var subscriptions = List<StreamSubscription>();

  // bool isUserTyping = false;
  // String userTyping;
  // DateTime lastOnline;
  // bool isOnline = false;

  ChatPageBloc(int roomId, QAccount account) {
    this.account = account;
    scheduleMicrotask(() async {
      var data =
          await ChatSDK().instance.getChatRoomWithMessages$(roomId: roomId);
      _updateMessages(data);
      _updateRoom(data);
      //ToDo: Push new state
      pushState();
      _subscribeToChatRoom();
      _subscribeToMessageReceivedEvents();
      _subscribeToMessageDeliveredEvents();
      _subscribeToMessageReadEvents();
      _subscribeToMessageDeletedEvents();
      _subscribeToUserTypingEvents();
      _subscribeToUserConnectionStatusEvents();
      _clearUnreadMessagesCount();
    });
  }

  void pushState() {
    stateStream.add(this.state);
  }

  void _clearUnreadMessagesCount() {
    if (state.room.lastMessage != null) {
      ChatSDK().instance.markAsRead(
            roomId: state.room.id,
            messageId: state.room.lastMessage.id,
            callback: (err) {
              this.state.room.unreadCount = 0;
              pushState();
            },
          );
    }
  }

  _updateMessages(QChatRoomWithMessages data) {
    var entries = data.messages.map((m) {
      return MapEntry(
        m.uniqueId,
        m,
      );
    });
    state.messages.addEntries(entries);
    data.messages.sort((m1, m2) => m1.timestamp.compareTo(m2.timestamp));
    if (data.messages.length > 0) {
      state.room.lastMessage = data.messages.last;
    }
  }

  _updateRoom(QChatRoomWithMessages data) {
    state.room = data.room;
  }

  _subscribeToChatRoom() {
    ChatSDK().instance.subscribeChatRoom(state.room);
  }

  _subscribeToMessageDeletedEvents() {
    subscriptions.add(ChatSDK().instance.onMessageDeleted$().listen((message) {
      this.state.messages.removeWhere((key, value) => key == message.uniqueId);
    }));
  }

  _subscribeToMessageReadEvents() {
    subscriptions.add(ChatSDK().instance.onMessageRead$().listen((message) {
      var targetedMessage = this.state.messages[message.uniqueId];
      if (targetedMessage != null) {
        this.state.messages.updateAll((key, message) {
          if (message.timestamp.isAfter(targetedMessage.timestamp)) {
            return message;
          }

          message.status = QMessageStatus.read;
          return message;
        });
      }
    }));
  }

  _subscribeToMessageDeliveredEvents() {
    subscriptions
        .add(ChatSDK().instance.onMessageDelivered$().listen((message) {
      var targetedMessage = this.state.messages[message.uniqueId];
      if (targetedMessage != null) {
        this.state.messages.updateAll((key, message) {
          if (message.status == QMessageStatus.read) return message;
          if (message.timestamp.isAfter(targetedMessage.timestamp)) {
            return message;
          }

          message.status = QMessageStatus.delivered;
          return message;
        });
      }
    }));
  }

  _subscribeToMessageReceivedEvents() {
    subscriptions.add(ChatSDK().instance.onMessageReceived$().listen((message) {
      final lastMessage = state.room.lastMessage;
      this.state.messages.addAll({
        message.uniqueId: message,
      });
      if (lastMessage.timestamp.isBefore(message.timestamp)) {
        state.room.lastMessage = message;
      }
      markMessageRead(message);
    }));
  }

  Future markMessageRead(QMessage message) async {
    if (message.chatRoomId == state.room.id) {
      await ChatSDK()
          .instance
          .markAsRead$(roomId: state.room.id, messageId: message.id);
    }
  }

  _subscribeToUserTypingEvents() {
    Timer timer;
    subscriptions.add(ChatSDK()
        .instance
        .onUserTyping$()
        .where((t) => t.userId != ChatSDK().instance.currentUser.id)
        .listen((typing) {
      if (timer != null && timer.isActive) timer.cancel();
      state.isUserTyping = true;
      state.userTyping = typing.userId;

      timer = Timer(const Duration(seconds: 2), () {
        state.isUserTyping = false;
        state.userTyping = null;
      });
    }));
  }

  _subscribeToUserConnectionStatusEvents() {
    if (state.room.type != QRoomType.single) return;
    var partnerId =
        state.room.participants.where((it) => it.id != account.id).first?.id;
    if (partnerId == null) return;
    ChatSDK().instance.subscribeUserOnlinePresence(partnerId);
    subscriptions.add(ChatSDK()
        .instance
        .onUserOnlinePresence$()
        .where((it) => it.userId == partnerId)
        .listen((data) {
      this.state.isOnline = data.isOnline;
      this.state.lastOnline = data.lastOnline;
    }));
  }

  sendMessage(String messageText) async {
    if (messageText.isEmpty) return;

    var message = ChatSDK().instance.generateMessage(chatRoomId: state.room.id, text: messageText);
    this.state.messages.update(message.uniqueId, (m) {
      return message;
    }, ifAbsent: () => message);
    pushState();

    var _message = await ChatSDK().instance.sendMessage$(message: message);
    this.state.messages.update(_message.uniqueId, (m) {
      return _message;
    }, ifAbsent: () => _message);
    this.state.room.lastMessage = _message;
    pushState();

    // messageInputController.clear();

    // scrollController.animateTo(
    //   ((this.messages.length + 1) * 200.0),
    //   duration: const Duration(milliseconds: 300),
    //   curve: Curves.linear,
    // );

  }

  publishTyping() {
    ChatSDK().instance.publishTyping(roomId: state.room.id, isTyping: true);
    Timer(const Duration(seconds: 1), () {
      ChatSDK().instance.publishTyping(roomId: state.room.id, isTyping: false);
    });
  }

  onDispose() {
    this.stateStream.close();
    for (StreamSubscription current in subscriptions) {
      current?.cancel();
    }
  }
}
