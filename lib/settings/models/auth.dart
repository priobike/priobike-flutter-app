class AuthConfig {
  /// Access token used to fetch Mapbox tiles.
  String mapboxAccessToken;

  /// Username for the prediction service mqtt broker.
  String predictionServiceMQTTUsername;

  /// Password for the prediction service mqtt broker.
  String predictionServiceMQTTPassword;

  /// Username for the predictor mqtt broker.
  String predictorMQTTUsername;

  /// Password for the predictor mqtt broker.
  String predictorMQTTPassword;

  /// Username for the simulator mqtt broker.
  String simulatorMQTTPublishUsername;

  /// Password for the simulator mqtt broker.
  String simulatorMQTTPublishPassword;

  /// API key for the link shortener service.
  String linkShortenerApiKey;

  AuthConfig({
    required this.mapboxAccessToken,
    required this.predictionServiceMQTTUsername,
    required this.predictionServiceMQTTPassword,
    required this.predictorMQTTUsername,
    required this.predictorMQTTPassword,
    required this.simulatorMQTTPublishUsername,
    required this.simulatorMQTTPublishPassword,
    required this.linkShortenerApiKey,
  });

  factory AuthConfig.fromJson(Map<String, dynamic> json) {
    return AuthConfig(
      mapboxAccessToken: json['mapboxAccessToken'],
      predictionServiceMQTTUsername: json['predictionServiceMQTTUsername'],
      predictionServiceMQTTPassword: json['predictionServiceMQTTPassword'],
      predictorMQTTUsername: json['predictorMQTTUsername'],
      predictorMQTTPassword: json['predictorMQTTPassword'],
      simulatorMQTTPublishUsername: json['simulatorMQTTPublishUsername'],
      simulatorMQTTPublishPassword: json['simulatorMQTTPublishPassword'],
      linkShortenerApiKey: json['linkShortenerApiKey'],
    );
  }
}
