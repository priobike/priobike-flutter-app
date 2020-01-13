import 'dart:async';
import 'package:web_socket_channel/io.dart';
import 'package:logging/logging.dart';
import 'dart:convert';

import 'package:bike_now_flutter/helper/configuration.dart';
import 'package:bike_now_flutter/websocket/websocket_commands.dart';
import 'package:bike_now_flutter/server_response/websocket_response.dart';
import 'package:bike_now_flutter/websocket/web_socket_method.dart';

enum WebSocketServiceState { connected, disconnected, authorized, error }

class WebSocketService implements WebSocketServiceDelegate {
  WebSocketServiceState state = WebSocketServiceState.disconnected;
  bool keepAlive;
  Timer keepAliveTimer;
  int pingIntervalSeconds = 30;
  IOWebSocketChannel webSocketChannel;
  WebSocketServiceDelegate delegate;
  final Logger log = new Logger('Websocket');

  WebSocketService._privateConstructor() {
    this.keepAlive = keepAlive;
    connect();
    authenticate();
    delegate = this;
  }
  static final WebSocketService instance =
      WebSocketService._privateConstructor();

  void keepConnectionAlive() {
    if (keepAlive != null && keepAlive == true) {
      var ping = new Ping(Configuration.sessionUUID).toJson().toString();
      webSocketChannel.sink.add(ping);
      log.fine("Send Ping");
    }
    keepAliveTimer = Timer.periodic(Duration(seconds: pingIntervalSeconds),
        (timer) => sendCommand(Ping(Configuration.sessionUUID)));
  }

  void connect() {
    this.webSocketChannel = IOWebSocketChannel.connect(
        'ws://vkwvlprad.vkw.tu-dresden.de:20042/socket',
        pingInterval: Duration(seconds: pingIntervalSeconds));
    webSocketChannel.stream
        .listen(onWebSocketResponse, onDone: websocketDidDisconnect);
    state = WebSocketServiceState.connected;
    log.fine("Websocket connected");
  }

  void websocketDidDisconnect() {
    state = WebSocketServiceState.disconnected;
    log.fine("WebSocket did disconnect");
  }

  void sendCommand(WebSocketCommand command) {
    if (command.requiresAuthentication &&
        state != WebSocketServiceState.authorized) {
      authenticate();
      log.fine(
          "Cannot send payload, because the web socket service is not authenticated. Authenticating now...");
      return;
    }
    log.fine('Send Command JSON: ${jsonEncode(command)}');
    webSocketChannel.sink.add(jsonEncode(command));
  }

  void authenticate() {
    if (state == WebSocketServiceState.connected) {
      sendCommand(Login(Configuration.sessionUUID));
    } else {
      log.fine("Web socket is not connected at the moment. Connecting now...");
      connect();
    }
  }

  void onWebSocketResponse(dynamic data) {
    if (state == WebSocketServiceState.disconnected) {
      state = WebSocketServiceState.connected;
      sendCommand(Login(Configuration.sessionUUID));
    }
    String msg = data as String;
    WebsocketResponse response = WebsocketResponse.fromJson(jsonDecode(msg));
    switch (response.method) {
      case WebSocketMethod.logout:
        break;
      case WebSocketMethod.ping:
        break;
      case WebSocketMethod.login:
        handleLogin();
        print('Login Response');
        break;
      case WebSocketMethod.calcRoute:
        print('CalcRoute Response');
        handleCalcRoute(msg);
        break;
      case WebSocketMethod.pushLocations:
        print('pushLocations Response');
        break;
      case WebSocketMethod.updateSubscriptions:
        print('updateSubscriptions Response');
        break;
      case WebSocketMethod.pushPredictions:
        print('pushPredictions Response');
        break;
      case WebSocketMethod.pushInstructions:
        print('pushInstructions Response');
        break;
      case WebSocketMethod.getLocationFromAddress:
        print('getLocationFromAddress Response');
        break;
      case WebSocketMethod.getAddressFromLocation:
        print('getAddressFromLocation Response');
        break;
      case WebSocketMethod.routeStart:
        print('routeStart Response');
        break;
      case WebSocketMethod.routeFinish:
        print('routeFinish Response');
        break;
      case WebSocketMethod.pushFeedback:
        print('pushFeedback Response');
        break;
    }

    log.fine("Websocket message Reveived: $msg");

    delegate?.websocketDidReceiveMessage(msg);
  }

  void handleLogin() {
    state = WebSocketServiceState.authorized;
    keepConnectionAlive();
  }

  void handleCalcRoute(String msg) {}

  void handleUpdateSubscriptions(String msg) {}

  @override
  void websocketDidReceiveMessage(String msg) {}
}

abstract class WebSocketServiceDelegate {
  void websocketDidReceiveMessage(String msg);
}
