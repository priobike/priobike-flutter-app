enum RoutingView {
  stable,
  beta,
}

extension RoutingViewDescription on RoutingView {
  String get description {
    switch (this) {
      case RoutingView.stable:
        return "Standard";
      case RoutingView.beta:
        return "Beta";
    }
  }
}
