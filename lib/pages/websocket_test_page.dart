import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:bike_now/websocket/websocket_commands.dart';
import 'package:bike_now/models/subscription.dart';
import 'package:bike_now/models/sg_subscription.dart';


class WebSocketTestPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _WebSocketTestState();
  }
}

class _WebSocketTestState extends State<WebSocketTestPage>{
  TextEditingController _controller = TextEditingController();
  final channel = IOWebSocketChannel.connect('ws://vkwvlprad.vkw.tu-dresden.de:20042/socket');
  //final channel = IOWebSocketChannel.connect('ws://echo.websocket.org');
  final sessionId = "abcdef123456";


  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('WebSocketTest'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Form(
              child: TextFormField(
                controller: _controller,
                decoration: InputDecoration(labelText: 'Send a message'),
              ),
            ),
            StreamBuilder(
              stream: channel.stream,
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Container(
                    height: 300,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                        child: Text(snapshot.hasData ? '${snapshot.data}' : '')),
                  ),
                );
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendMessage,
        tooltip: 'Send message',
        child: Icon(Icons.send),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
  void _sendMessage() {
    List<SGSubscription> sgList = new List<SGSubscription>();
    sgList.add(new SGSubscription('R4', true));
    List<Subscription> list = new List<Subscription>();
    list.add(new Subscription(1, 'Hallo', sgList));

    if (_controller.text.isNotEmpty) {
      switch(_controller.text){
        case "1":
          channel.sink.add(new Login(sessionId).toJson().toString());
          break;
        case "-1":
          channel.sink.add(new Logout(sessionId).toJson().toString());
          break;
        case "0":
          channel.sink.add(new Ping(sessionId).toJson().toString());
          break;
        case "2":
          channel.sink.add(new CalcRoute(51.032121130051934,13.713843309443668,51.05381424100282,13.757071206504207,sessionId).toJson().toString());
          break;
        case "4":
          channel.sink.add(Subscription.fromJson(new Subscription(1, 'Hallo', sgList).toJson()).toJson().toString());
          break;
      }
      }else{
        channel.sink.add(_controller.text);
      }
    }
  }