import 'package:chat_poc/ChatSDK.dart';
import 'package:chat_poc/scenes/room_list/room_list_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qiscus_chat_sdk/qiscus_chat_sdk.dart';
import '../../extensions.dart';

class ProjectHelperScreen extends StatefulWidget {
  ProjectHelperScreen({
    @required this.qiscus,
    @required this.account,
  });

  final QiscusSDK qiscus;
  final QAccount account;

  @override
  _ProjectHelperScreenState createState() => _ProjectHelperScreenState();
}

class _ProjectHelperScreenState extends State<ProjectHelperScreen> {
  TextEditingController _textEditingController = TextEditingController();
  QAccount account;

  @override
  void initState() {
    super.initState();
    account = widget.account;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          children: [
            TextField(
              controller: _textEditingController,
              onSubmitted: (value) {},
            ),
            SizedBox(height: 10),
            RaisedButton(
              child: Text("Create Mock project"),
              onPressed: () {
                ChatSDK().instance.chatUser(
                    userId: _textEditingController.text.trim().toString(),
                    callback: (chatRoom, error) {
                      if (error != null) {
                        print("error ${error}");
                      }
                      print("success ${chatRoom}");
                      context.pushReplacement(RoomListPage(
                        qiscus: widget.qiscus,
                        account: account,
                      ));
                    });
              },
            )
          ],
        ),
      ),
    );
  }
}
