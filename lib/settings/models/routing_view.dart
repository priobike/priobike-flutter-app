enum RoutingViewOption {
  stable,
  beta,
}

extension RoutingViewDescription on RoutingViewOption {
  String get description {
    switch (this) {
      case RoutingViewOption.stable:
        return "Standard";
      case RoutingViewOption.beta:
        return "Beta";
    }
  }
}
