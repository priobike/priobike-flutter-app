import 'dart:async';

import 'package:priobike/models/api/api_route.dart';
import 'package:priobike/models/recommendation.dart';
import 'package:priobike/session/session.dart';

class LocalSession extends Session {
  String _id;

  @override
  StreamController<ApiRoute> routeStreamController =
      new StreamController<ApiRoute>();

  @override
  StreamController<Recommendation> recommendationStreamController =
      new StreamController<Recommendation>();

  LocalSession({String id}) {
    this._id = id;
    print("local session created " + _id);
  }

  @override
  updateRoute(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) {
    /*

    Implement local functions here

    */
  }

  @override
  updatePosition(
    double lat,
    double lon,
    int speed,
  ) {
    /*

    Implement local functions here

    */
  }

  @override
  stopRecommendation() {
    routeStreamController.close();
    recommendationStreamController.close();
  }
}

// List<String> subscribeToTopics = [
//   'resroute/$clientId',
//   'recommendation/$clientId'
// ];

// _mqttService = new MqttService(clientId, subscribeToTopics);

// _mqttService.messageStreamController.stream.listen((message) {
//   if (message.topic.contains('resroute')) {
//     route = ApiRoute.fromJson(json.decode(message.payload));
//     log.i('<- Route');
//   }

//   if (message.topic.contains('recommendation')) {
//     recommendation = Recommendation.fromJson(json.decode(message.payload));
//     log.i('<- Recommendation');
//   }
// });

// log.i('New Message! topic: ${message.topic}, payload: ${message.payload}');

//  Message routeRequest = new Message(
//   topic: 'reqroute/$clientId',
//   payload: json.encode(
//     RouteRequest(
//       id: clientId,
//       fromLat: fromLat,
//       fromLon: fromLon,
//       toLat: toLat,
//       toLon: toLon,
//     ).toJson(),
//   ),
// );

// _mqttService.publish(routeRequest);

// Message positionMessage = new Message(
//   topic: 'position/$clientId',
//   payload: json.encode(
//     new UserPosition(
//       id: clientId,
//       lat: position.latitude,
//       lon: position.longitude,
//       speed: (position.speed * 3.6).round(),
//     ).toJson(),
//   ),
// );

// _mqttService.publish(positionMessage);

// Message stopRequest = new Message(
//       topic: 'reqstop/$clientId',
//       payload: json.encode(
//         StopRequest(
//           id: clientId,
//         ).toJson(),
//       ),
//     );

//     _mqttService.publish(stopRequest);
