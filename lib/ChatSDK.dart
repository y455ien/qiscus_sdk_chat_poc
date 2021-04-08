import 'dart:async';

import 'package:qiscus_chat_sdk/qiscus_chat_sdk.dart';

class ChatSDK {
  static final ChatSDK _singleton = ChatSDK._internal();
  ChatSDK._internal();
  QiscusSDK instance;
  StreamSubscription<bool> _subs;

  factory ChatSDK() {
    return _singleton;
  }

  initSDK() {
    instance = QiscusSDK();
  }

  loginStatusService() {
    scheduleMicrotask(() {
      _subs = Stream.periodic(const Duration(seconds: 3), (_) => instance.isLogin)
          .where((isLogin) => isLogin)
          .listen((isLogin) {
        if (isLogin) {
          instance.publishOnlinePresence(
              isOnline: isLogin,
              callback: (error) {
                print('error while publishing online presence: $error');
              });
        }
      });
    });
  }

  clearSubs() {
    _subs?.cancel();
  }

}