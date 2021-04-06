import 'dart:async';

import 'package:qiscus_chat_sdk/qiscus_chat_sdk.dart';

class ChatSDK {
  ChatSDK._internal();
  static final ChatSDK _instance = ChatSDK._internal();
  QiscusSDK qiscusSDK;
  StreamSubscription<bool> _subs;

  factory ChatSDK() {
    return _instance;
  }

  initSDK() {
    qiscusSDK = QiscusSDK();
  }

  loginStatusService() {
    scheduleMicrotask(() {
      _subs = Stream.periodic(const Duration(seconds: 3), (_) => qiscusSDK.isLogin)
          .where((isLogin) => isLogin)
          .listen((isLogin) {
        if (isLogin) {
          qiscusSDK.publishOnlinePresence(
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