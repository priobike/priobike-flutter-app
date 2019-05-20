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

class WebSocketMethodHelper{
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