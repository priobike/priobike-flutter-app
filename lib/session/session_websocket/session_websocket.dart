import 'dart:async';
import 'dart:convert';

import 'package:priobike/models/api/api_route.dart';
import 'package:priobike/models/message.dart';
import 'package:priobike/models/recommendation.dart';
import 'package:priobike/models/route_request.dart';
import 'package:priobike/models/user_position.dart';
import 'package:priobike/session/session.dart';

import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/status.dart' as status;

class WebSocketSession extends Session {
  String _id;
  WebSocketChannel _channel;

  @override
  StreamController<ApiRoute> routeStreamController =
      new StreamController<ApiRoute>();

  @override
  StreamController<Recommendation> recommendationStreamController =
      new StreamController<Recommendation>();

  WebSocketSession({String id}) {
    this._id = id;
    _channel = WebSocketChannel.connect(Uri.parse('ws://10.0.2.2:8080'));

    _channel.sink.add(
      json.encode(
        new Message(
          id: this._id,
          type: 'hello',
          payload: null,
        ).toJson(),
      ),
    );

    _channel.stream.listen((message) {
      String messageType = Message.fromJson(json.decode(message)).type;
      String messagePayload = Message.fromJson(json.decode(message)).payload;

      switch (messageType) {
        case 'routeresponse':
          {
            routeStreamController.add(
              ApiRoute.fromJson(
                json.decode(messagePayload),
              ),
            );
          }
          break;
        case 'recommendation':
          {
            recommendationStreamController.add(
              Recommendation.fromJson(
                json.decode(messagePayload),
              ),
            );
          }
          break;
      }
    }, onError: (error) async {
      print("error: " + error.toString());
    }, onDone: () async {
      print("websocket closed");
      // TODO: handle reconnection
    });
  }

  @override
  updateRoute(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) {
    _channel.sink.add(
      json.encode(
        new Message(
          id: this._id,
          type: 'routerequest',
          payload: json.encode(
            new RouteRequest(
              fromLat: fromLat,
              fromLon: fromLon,
              toLat: toLat,
              toLon: toLon,
            ).toJson(),
          ),
        ).toJson(),
      ),
    );
  }

  @override
  updatePosition(
    double lat,
    double lon,
    int speed,
  ) {
    _channel.sink.add(
      json.encode(
        new Message(
          id: this._id,
          type: 'position',
          payload: json.encode(
            new UserPosition(
              lat: lat,
              lon: lon,
              speed: speed,
            ).toJson(),
          ),
        ).toJson(),
      ),
    );
  }

  @override
  stopRecommendation() {
    _channel.sink.add(
      json.encode(
        new Message(
          id: this._id,
          type: 'stop',
          payload: null,
        ).toJson(),
      ),
    );

    routeStreamController.close();
    recommendationStreamController.close();
  }
}
