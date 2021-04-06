import 'dart:ffi';

import 'package:flutter_downloader/flutter_downloader.dart';

class Downloader {
  static Future<Void> init() async {
    return await FlutterDownloader.initialize();
  }
}