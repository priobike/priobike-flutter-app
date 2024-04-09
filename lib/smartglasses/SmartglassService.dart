import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:flutter_smartglasses_tooz/flutter_smartglasses_tooz.dart';
import 'package:priobike/ride/views/speedometer/view.dart';
import 'package:priobike/settings/models/speed.dart';

import '../logging/logger.dart';
import '../main.dart';
import '../positioning/services/positioning.dart';
import '../ride/messages/prediction.dart';
import '../ride/services/ride.dart';
import '../settings/services/settings.dart';

class SmartglassService {
  final log = Logger("smartglasses-tooz");

  final _flutterSmartglassesToozPlugin = FlutterSmartglassesTooz();
  final eventChannel = const EventChannel('flutter_smartglasses_tooz/events');
  var is_registered = false;

  SmartglassService init() {
    eventChannel.receiveBroadcastStream().listen(_onEvent);
    //_flutterSmartglassesToozPlugin.register();
    return this;
  }

  void _onEvent(Object? event) {
    log.w("Called from native: $event");
    if (event == "onDeregisterSuccess") {
      is_registered = false;
    }else if (event == "onRegisterSuccess") {
      is_registered = true;
    }
  }

  void showGreeting() async {
    await _flutterSmartglassesToozPlugin.updateCard();
  }

  void show(String text, int sign, List<Map<String, dynamic>> tachoItems) async {
    log.w("Update smartglass view with text: $text, $sign");
    await _flutterSmartglassesToozPlugin.drawTacho(text, sign, tachoItems, calcCurrentSpeed());
  }
  void updateInstructions(String text, int sign) async {
    log.w("Update smartglass view with text: $text, $sign");
    await _flutterSmartglassesToozPlugin.toozifierUpdateInstructions(text, sign);
  }
  void updateTacho(List<Map<String, dynamic>> tachoItems) async {
    await _flutterSmartglassesToozPlugin.toozifierUpdateTacho(tachoItems, calcCurrentSpeed());
  }

  List<Map<String, dynamic>> createTachoForGlasses(List<Phase> phases, Ride ride, double minSpeed, double maxSpeed) {
    /*
    We calculate the duration of the phases in seconds for now.
    This means, the gauge will show the seconds of the green phase or red phase.
     */
    List<Map<String, dynamic>> tachoItems = List.empty(growable: true);
    for(var phase in phases) {
      var lastItem = tachoItems.lastOrNull;
      if (lastItem == null || !tachoSameColor(tachoItems.last["isRed"], phase)) {
        var start = 0;
        if (lastItem != null) start = lastItem["end"];
        tachoItems.add({'isRed': phase == Phase.red ? 1 : 0, "start": start, "end": start});
      }else{
        tachoItems.last["end"] = tachoItems.last["end"] + 1;
      }
    }
    for (var tachoItem in tachoItems) {
      var tmp = tachoItem["end"];
      tachoItem["end"] = calcSpeedKmh(tachoItem["start"], ride, minSpeed, maxSpeed);
      tachoItem["start"] = calcSpeedKmh(tmp, ride, minSpeed, maxSpeed);
    }
    return tachoItems.reversed.toList();
  }

  double calcSpeedKmh(int second, Ride ride, double minSpeed, double maxSpeed) {
    if (second == 0) {
      // FIXME we need something useful for this
      return 1;
    }
    var speedKmh = (ride.calcDistanceToNextSG! / second) * 3.6;
    // Scale the speed between minSpeed and maxSpeed
    var scaledSpeed= (speedKmh - minSpeed) / (maxSpeed - minSpeed);
    return scaledSpeed > 1 ? 1 : scaledSpeed;
  }

  calcCurrentSpeed() {
    // Fetch the maximum speed from the settings service.
    var maxSpeed = getIt<Settings>().speedMode.maxSpeed;
    var positioning = getIt<Positioning>();
    var minSpeed = 0.0;

    final kmh = (positioning.lastPosition?.speed ?? 0.0 / maxSpeed) * 3.6;

    // Scale between minSpeed and maxSpeed.
    return (kmh - minSpeed) / (maxSpeed - minSpeed);
  }

  bool tachoSameColor(int isRed, Phase phase) {
    return isRed == 1 && phase == Phase.red || isRed == 0 && phase == Phase.green;
  }

  void drawRaster() async {
    await _flutterSmartglassesToozPlugin.drawRaster();
  }
  void drawMap() async {
    await _flutterSmartglassesToozPlugin.drawMap();
  }
  void register() async {
    is_registered = (await _flutterSmartglassesToozPlugin.isRegistered())!;
    log.w("Try to register tooz smart glasses... $is_registered");
    if(!is_registered) {
      await _flutterSmartglassesToozPlugin.register();
    }
    await _flutterSmartglassesToozPlugin.drawInitialView();
  }

}