enum WebSocketMethod {
  logout,
  ping,
  login,
  calcRoute,
  pushLocations,
  updateSubscriptions,
  pushPredictions,
  pushInstructions,
  getLocationFromAddress,
  getAddressFromLocation,
  routeStart,
  routeFinish,
  pushFeedback
}

enum WebsocketMode {
  ok, error
}
class WebsocketModeHelper{
  static int getValue(WebsocketMode mode){
    switch (mode){

      case WebsocketMode.ok:
        return 1;
        break;
      case WebsocketMode.error:
        return 0;
        break;
    }
  }

  static WebsocketMode getMode(int mode){
    switch (mode){
      case 1:
        return WebsocketMode.ok;
        break;
      case 0:
        return WebsocketMode.error;
        break;
    }
  }
}

class WebSocketMethodHelper{
  static WebSocketMethod getMethod(int index){
    switch(index){
      case -1:
        return WebSocketMethod.logout;
      case 0:
        return WebSocketMethod.ping;
      case 1:
        return WebSocketMethod.login ;
      case 2:
        return WebSocketMethod.calcRoute ;
      case 3:
        return WebSocketMethod.pushLocations;
      case  4:
        return WebSocketMethod.updateSubscriptions;
      case 5:
        return WebSocketMethod.pushPredictions ;
      case 6:
        return WebSocketMethod.pushInstructions ;
      case 7:
        return WebSocketMethod.getLocationFromAddress ;
      case 8:
        return WebSocketMethod.getAddressFromLocation ;
      case 9:
        return WebSocketMethod.routeStart;
      case 10:
        return WebSocketMethod.routeFinish ;
      case 20:
        return WebSocketMethod.pushFeedback ;
    }
  }
  static int getValue(WebSocketMethod method){
    switch(method){
      case WebSocketMethod.logout:
        return -1;
      case WebSocketMethod.ping:
        return 0;
      case WebSocketMethod.login:
        return 1;
      case WebSocketMethod.calcRoute:
        return 2;
      case WebSocketMethod.pushLocations:
        return 3;
      case WebSocketMethod.updateSubscriptions:
        return 4;
      case WebSocketMethod.pushPredictions:
        return 5;
      case WebSocketMethod.pushInstructions:
        return 6;
      case WebSocketMethod.getLocationFromAddress:
        return 7;
      case WebSocketMethod.getAddressFromLocation:
        return 8;
      case WebSocketMethod.routeStart:
        return 9;
      case WebSocketMethod.routeFinish:
        return 10;
      case WebSocketMethod.pushFeedback:
        return 20;
    }

  }
}