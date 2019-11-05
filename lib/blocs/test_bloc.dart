import 'package:bike_now_flutter/websocket/mqtt_service.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class TestBloc extends ChangeNotifier implements MqttDelegate{
  Stream<String> get getMessage => _msgSubject.stream;
  final _msgSubject = BehaviorSubject<String>();

  TestBloc(){
    MqttService.instance.delegate = this;
  }


  @override
  void mqttDidReceiveMessage(String msg) {
    _msgSubject.add(msg);

  }

}