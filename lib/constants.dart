 import 'package:flutter/material.dart';

const APP_ID = 'qchatsdk--icenmhyxsln';

class HeroTags {
  static const accountAvatar = 'account-avatar';
  static String roomAvatar({@required int roomId}) {
    return 'room-avatar-$roomId';
  }

  static String roomName({@required String roomName}) {
    return 'room-name-$roomName';
  }
}
