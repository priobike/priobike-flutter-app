import 'package:bike_now/models/location.dart';
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
                    height: 250,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                        child: Text(snapshot.hasData ? '${snapshot.data}' : '')),
                  ),
                );
              },
            ),

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
    list.add(new Subscription(4, 'Musterstrasse', sgList));
    List<Location> locations = new List<Location>();
    locations.add(new Location(51.052446, 13.747352, 6, 138.5, 13, 5.546, DateTime.now(), 'gps', 133, "R3", 2, 133, 24, 4, 20, true, false, true, 56));
    locations.add(new Location(51.052446, 13.747352, 6, 138.5, 13, 5.546, DateTime.now(), 'gps', 133, "R3", 2, 133, 24, 4, 20, true, false, true, 56));


    if (_controller.text.isNotEmpty) {
      switch(_controller.text){
        case "1":
          print(new Login(sessionId).toJson().toString());
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
        case "3":
          var i = new PushLocations(locations, sessionId).toJson().toString();
          print(i);
          channel.sink.add(i);
          break;
        case "4":
          String s = new UpdateSubscription(list, sessionId).toJson().toString();
          print(s);
          channel.sink.add(new UpdateSubscription(list, sessionId).toJson().toString());
          break;
        case "7":
          String s = new GetLocationFromAddress(sessionId, "TU Dresden").toJson().toString();
          channel.sink.add(s);
          break;
        case "8":
          String s = new GetAddressFromLocation(51.052446, 13.747352, sessionId).toJson().toString();
          channel.sink.add(s);
      }
      }else{
        channel.sink.add(_controller.text);
      }
    }
  }