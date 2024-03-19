import 'package:flutter/services.dart';
import 'package:flutter_smartglasses_tooz/flutter_smartglasses_tooz.dart';

import '../logging/logger.dart';

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

  void show(String text, int sign) async {
    log.w("Update smartglass view with text: $text, $sign");
    await _flutterSmartglassesToozPlugin.drawTacho(text, sign);
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