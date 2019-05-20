import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';


class RidesPage extends StatelessWidget {

  final channel = IOWebSocketChannel.connect('ws://vkwvlprad.vkw.tu-dresden.de:20042/socket');

  RidesPage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 20),
      child: StreamBuilder(
        stream: channel.stream,
        builder: (context, snapshot) {
          return Text(snapshot.hasData ? '${snapshot.data}' : '');
        },
      ),
    );
  }
}