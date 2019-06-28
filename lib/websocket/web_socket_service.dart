import 'dart:async';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:logging/logging.dart';
import 'dart:convert';


import 'package:bike_now/configuration.dart';
import 'package:bike_now/websocket/websocket_commands.dart';
import 'package:bike_now/server_response/session_invalid.dart';
import 'package:bike_now/server_response/websocket_response.dart';
import 'package:bike_now/websocket/web_socket_method.dart';
import 'package:bike_now/server_response/websocket_response.dart';

enum WebSocketServiceState {
  connected,
  disconnected,
  authorized,
  error
}

class WebSocketService{
  WebSocketServiceState state = WebSocketServiceState.disconnected;
  bool keepAlive;
  Timer keepAliveTimer;
  int pingIntervalSeconds = 5;
  IOWebSocketChannel webSocketChannel;
  WebSocketServiceDelegate delegate;
  final Logger log = new Logger('Websocket');




  WebSocketService._privateConstructor(){
    this.keepAlive = keepAlive;
    connect();
    authenticate();


  }
  static final WebSocketService instance = WebSocketService._privateConstructor();

  void keepConnectionAlive(){
    if (keepAlive != null && keepAlive == true){
      var ping = new Ping(Configuration.sessionUUID).toJson().toString();
      webSocketChannel.sink.add(ping);
      log.fine("Send Ping");
    }
    keepAliveTimer = Timer.periodic(Duration(seconds: pingIntervalSeconds), (timer) => sendCommand(Ping(Configuration.sessionUUID)));

  }

  void connect(){
    this.webSocketChannel = IOWebSocketChannel.connect('ws://vkwvlprad.vkw.tu-dresden.de:20042/socket', pingInterval: Duration(seconds: pingIntervalSeconds));
    webSocketChannel.stream.listen(onWebSocketResponse, onDone: websocketDidDisconnect);
    state = WebSocketServiceState.connected;
    log.fine("Websocket connected");

  }
  void websocketDidDisconnect(){
    state = WebSocketServiceState.disconnected;
    log.fine("WebSocket did disconnect");
  }

  void sendCommand(WebSocketCommand command){
    if (command.requiresAuthentication && state != WebSocketServiceState.authorized){
      authenticate();
      log.fine("Cannot send payload, because the web socket service is not authenticated. Authenticating now...");
      return;

    }
    webSocketChannel.sink.add(command.toJson().toString());
  }

  void authenticate(){
    if (state == WebSocketServiceState.connected){
      sendCommand(Login(Configuration.sessionUUID));
    }else{
      log.fine("Web socket is not connected at the moment. Connecting now...");
      connect();
    }

  }


  void onWebSocketResponse(dynamic data){
    String msg = data as String;
    WebsocketResponse response = WebsocketResponse.fromJson(jsonDecode(msg));

    switch (response.method){
      case WebSocketMethod.logout:
        print('Logout Response');
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

    delegate?.websocketDidReceiveMessage(msg);
  }

  void handleLogin(){
    state = WebSocketServiceState.authorized;
    sendCommand(CalcRoute(51.032121130051934, 13.713843309443668, 51.05381424100282, 13.757071206504207, Configuration.sessionUUID));
  }

  void handleCalcRoute(String msg){
    var te = WebSocketResponseRoute.fromJson(jsonDecode(msg));
    print(te.route.time);


  }

}

abstract class WebSocketServiceDelegate{
  void websocketDidReceiveMessage(String msg);
}