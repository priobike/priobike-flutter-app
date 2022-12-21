enum RoutingEndpoint {
  graphhopper,
  graphhopperDRN,
}

extension RoutingDescription on RoutingEndpoint {
  String get description {
    switch (this) {
      case RoutingEndpoint.graphhopper:
        return "Standard";
      case RoutingEndpoint.graphhopperDRN:
        return "DRN (Empfohlen)";
    }
  }
}

extension RoutingEndpointServicePath on RoutingEndpoint {
  String get servicePath {
    switch (this) {
      case RoutingEndpoint.graphhopper:
        return "graphhopper";
      case RoutingEndpoint.graphhopperDRN:
        return "drn-graphhopper";
    }
  }
}
