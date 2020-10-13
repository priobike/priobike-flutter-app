import 'dart:async';
import 'dart:convert';

import 'package:bikenow/models/api/api_route.dart';
import 'package:bikenow/models/message.dart';
import 'package:bikenow/models/stopRequest.dart';
import 'package:bikenow/models/user_position.dart';
import 'package:bikenow/models/recommendation.dart';
import 'package:bikenow/models/routeRequest.dart';
import 'package:bikenow/services/mqtt_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:ntp/ntp.dart';

class AppService with ChangeNotifier {
  MqttService _mqttService;
  String clientId = Uuid().v4();

  Timer timer;

  bool loading = false;

  bool isGeolocating = false;

  StreamSubscription<Position> positionStream;

  ApiRoute route;
  Recommendation recommendation;

  AppService() {
    List<String> subscribeToTopics = [
      'resroute/$clientId',
      'recommendation/$clientId'
    ];

    _mqttService = new MqttService(clientId, subscribeToTopics);

    _mqttService.messageStreamController.stream.listen((message) {
      if (message.topic.contains('resroute')) {
        debugPrint('Neue Route');
        route = ApiRoute.fromJson(json.decode(message.payload));
      }

      if (message.topic.contains('recommendation')) {
        debugPrint('Neue Empfehlung');
        recommendation = Recommendation.fromJson(json.decode(message.payload));
      }

      debugPrint(
          'New Message! topic: ${message.topic}, payload: ${message.payload}');

      loading = false;

      notifyListeners();
    });
  }

  updateRoute(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) {
    route = null;
    loading = true;

    notifyListeners();

    Message routeRequest = new Message(
      topic: 'reqroute/$clientId',
      payload: json.encode(
        RouteRequest(
          id: clientId,
          fromLat: fromLat,
          fromLon: fromLon,
          toLat: toLat,
          toLon: toLon,
        ).toJson(),
      ),
    );

    _mqttService.publish(routeRequest);
  }

  startGeolocation() async {
    DateTime startDate = DateTime.now().toLocal();
    int offset = await NTP.getNtpOffset(localTime: startDate);

    print(
        'Offset to NTP Time: $offset, NTP DateTime aligned: ${startDate.add(new Duration(milliseconds: offset))}');

    if (timer == null || !timer.isActive) {
      isGeolocating = true;

      positionStream = getPositionStream(
        desiredAccuracy: LocationAccuracy.best,
        distanceFilter: 1,
        timeInterval: 1,
      ).listen((Position position) {
        if (position != null && isGeolocating == true) {
          Message positionMessage = new Message(
            topic: 'position/$clientId',
            payload: json.encode(
              new UserPosition(
                id: clientId,
                lat: position.latitude,
                lon: position.longitude,
                speed: (position.speed * 3.6).round(),
                timestamp: startDate
                    .add(new Duration(milliseconds: offset))
                    .millisecondsSinceEpoch,
              ).toJson(),
            ),
          );

          _mqttService.publish(positionMessage);
        }
      });
    } else {
      print('Geolocation was started twice!!');
    }
  }

  stopGeolocation() {
    timer.cancel();
    print('Geolocator stopped!');

    isGeolocating = false;

    positionStream.cancel();

    recommendation = null;

    Message stopRequest = new Message(
      topic: 'reqstop/$clientId',
      payload: json.encode(
        StopRequest(
          id: clientId,
        ).toJson(),
      ),
    );

    _mqttService.publish(stopRequest);
  }
}
