import 'dart:async';
import 'dart:convert';

import 'package:bikenow/config/logger.dart';
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
  Logger log = Logger("AppService");

  MqttService _mqttService;
  String clientId = Uuid().v4();

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
        route = ApiRoute.fromJson(json.decode(message.payload));
        log.i('-> Route');
      }

      if (message.topic.contains('recommendation')) {
        recommendation = Recommendation.fromJson(json.decode(message.payload));
        log.i('-> Recommendation');
      }

      // log.i('New Message! topic: ${message.topic}, payload: ${message.payload}');

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

    log.i('<- Route Request');
  }

  startGeolocation() async {
    DateTime localTime = DateTime.now().toLocal();

    log.i('Get time offset ...');

    int offset = await NTP.getNtpOffset(
      lookUpAddress: 'time.zih.tu-dresden.de',
      localTime: localTime,
    );

    log.i('NTP time offset: $offset ms');

    isGeolocating = true;

    positionStream = getPositionStream(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 7,
      timeInterval: 3,
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
              timestamp: localTime
                  .add(new Duration(milliseconds: offset))
                  .millisecondsSinceEpoch,
            ).toJson(),
          ),
        );

        _mqttService.publish(positionMessage);
        log.i('<- Position');
      }
    });
    log.i('GEOLOCATOR STARTED!');
  }

  stopGeolocation() {
    Message stopRequest = new Message(
      topic: 'reqstop/$clientId',
      payload: json.encode(
        StopRequest(
          id: clientId,
        ).toJson(),
      ),
    );

    _mqttService.publish(stopRequest);
    log.i('<- Stop Request');

    isGeolocating = false;
    positionStream.cancel();
    recommendation = null;

    log.i('GEOLOCATOR STOPPED!');
  }
}
