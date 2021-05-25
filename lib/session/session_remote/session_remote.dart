import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:priobike/models/recommendation.dart';
import 'package:priobike/models/user_position.dart';
import 'package:priobike/session/session.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RemoteSession extends Session {
  WebSocketChannel socket;
  Peer jsonRPC;

  void connect() {
    // local address outside emulator for development
    socket = WebSocketChannel.connect(Uri.parse('ws://10.0.2.2:8080/'));
    // it is currently not possible to catch, when the server is not reachable

    jsonRPC = Peer(socket.cast<String>());

    jsonRPC.listen().then((done) {
      print('Disconnected: ${socket.closeCode} ${socket.closeReason}');
      print('reconnect in 3 seconds');
      Future.delayed(Duration(seconds: 3), connect);
    });

    jsonRPC.registerMethod('RecommendationUpdate', (Parameters params) {
      print('got recommendation');
      super
          .recommendationStreamController
          .add(Recommendation.fromJsonRPC(params));
    });
  }

  RemoteSession({String id}) {
    connect();
  }

  @override
  void updatePosition(
    double lat,
    double lon,
    int speed,
  ) {
    jsonRPC.sendNotification(
      'PositionUpdate',
      new UserPosition(
        lat: lat,
        lon: lon,
        speed: speed,
      ).toJson(),
    );
  }

  @override
  void startRecommendation() {
    jsonRPC.sendRequest(
      'Navigation',
      {'active': true},
    ).then((value) => print(value));
  }

  @override
  void stopRecommendation() {
    jsonRPC.sendRequest(
      'Navigation',
      {'active': false},
    ).then((value) => print(value));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
