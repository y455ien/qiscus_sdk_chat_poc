import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:flutter_sound/public/tau.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

typedef _Fn = void Function();

class CustomRecorder extends StatefulWidget {
  final Function(File) onSaved;

  @override
  _CustomRecorderState createState() => _CustomRecorderState();

  CustomRecorder({Key key, @required this.onSaved});
}

enum RecordingState {
  UnSet,
  Set,
  Recording,
  Stopped,
}

class _CustomRecorderState extends State<CustomRecorder> {
  FlutterSoundRecorder _mRecorder = FlutterSoundRecorder();
  RecordingState _recordingState = RecordingState.UnSet;

  @override
  void initState() {
    checkPermission();
    super.initState();
  }

  @override
  void dispose() {
    _mRecorder.closeAudioSession();
    _mRecorder = null;
    _recordingState = RecordingState.UnSet;
    super.dispose();
  }

  checkPermission() async {
    var status = await Permission.microphone.request();
    if (status == PermissionStatus.granted) {
      _recordingState = RecordingState.Set;
      await _mRecorder.openAudioSession();
    } else {
      _recordingState = RecordingState.UnSet;
      print("Permission not granted");
    }
  }

  void record() async {
    if (_recordingState == RecordingState.Set ||
        _recordingState == RecordingState.Stopped) {
      Directory appDirectory = await getApplicationDocumentsDirectory();
      String filePath = appDirectory.path +
          '/' +
          DateTime.now().millisecondsSinceEpoch.toString() +
          '.aac';
      _mRecorder
          .startRecorder(toFile: filePath, codec: Codec.aacADTS)
          .then((value) {
        setState(() {
          _recordingState = RecordingState.Recording;
        });
      });
    }
  }

  void stopRecorder() async {
    await _mRecorder.stopRecorder().then((value) {
      setState(() {
        _recordingState = RecordingState.Stopped;
        if (value != null) {
          File file = File(value);
          widget.onSaved(file);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: GestureDetector(
            onTapDown: (details) => record(),
            onTapUp: (details) => stopRecorder(),
            child: Icon(
              Icons.mic,
              color: _recordingState == RecordingState.Recording
                  ? Colors.red
                  : Colors.blue,
            )),
      ),
    );
  }
}
