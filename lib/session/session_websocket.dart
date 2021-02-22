import 'package:priobike/session/session.dart';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketSession extends Session {
  String _id;

  WebSocketChannel _channel;

  // currentRoute;
  // currentPosition;
  // currentRecommendation;

  WebSocketSession({String id}) {
    this._id = id;

    _channel = WebSocketChannel.connect(Uri.parse('ws://10.0.2.2:8080'));

    _channel.sink.add("Hallo, i am $_id");

    _channel.stream.listen((message) {
      print(message);
    }, onError: (error) async {
      print("onerror" + error.toString());
    }, onDone: () async {
      print("ondone");
      await Future.delayed(Duration(milliseconds: 2000));
      print("retry");
      _channel = WebSocketChannel.connect(Uri.parse('ws://10.0.2.2:8080'));
      _channel.sink.add("Hello again");
    });
  }

  @override
  updateRoute(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) {}

  updatePosition() {}

  stopRecommendation() {}
}
