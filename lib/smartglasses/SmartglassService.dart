import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:flutter_smartglasses_tooz/flutter_smartglasses_tooz.dart';

import '../logging/logger.dart';
import '../ride/messages/prediction.dart';

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
    await _flutterSmartglassesToozPlugin.drawTacho(text, sign, tachoItems);
  }

  List<Map<String, dynamic>> createTachoForGlasses(List<Phase> phases) {
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
    return tachoItems;
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