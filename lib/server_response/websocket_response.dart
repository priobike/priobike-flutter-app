import 'package:bike_now_flutter/websocket/web_socket_method.dart';
import 'package:bike_now_flutter/models/route.dart';

class WebsocketResponse {
  WebsocketMode mode;
  WebSocketMethod method;

  WebsocketResponse({this.mode, this.method});

  WebsocketResponse.fromJson(Map<String, dynamic> json) {
    mode = WebsocketModeHelper.getMode(json['mode']);
    method = WebSocketMethodHelper.getMethod(json['method']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['mode'] = WebsocketModeHelper.getValue(this.mode);
    data['method'] = WebSocketMethodHelper.getValue(this.method);
    return data;
  }
}

class WebSocketResponseGeneric {
  int mode;
  String msg;
  int method;

  WebSocketResponseGeneric({this.mode, this.msg, this.method});

  WebSocketResponseGeneric.fromJson(Map<String, dynamic> json) {
    mode = json['mode'];
    msg = json['msg'];
    method = json['method'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['mode'] = this.mode;
    data['msg'] = this.msg;
    data['method'] = this.method;
    return data;
  }
}

class WebSocketResponseRoute {
  int mode;
  Route route;
  int method;

  WebSocketResponseRoute({this.mode, this.route, this.method});

  WebSocketResponseRoute.fromJson(Map<String, dynamic> json) {
    mode = json['mode'];
    route = Route.fromJson(json['route']);
    method = json['method'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['mode'] = this.mode;
    data['msg'] = this.route.toJson();
    data['method'] = this.method;
    return data;
  }
}
