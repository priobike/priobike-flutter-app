/// A response from https://brightsky.dev/docs/#get-/current_weather
class WeatherForecastResponse {
  /// The data points.
  final List<WeatherForecastDataPoint> weather;

  const WeatherForecastResponse({
    required this.weather,
  });

  factory WeatherForecastResponse.fromJson(Map<String, dynamic> json) => WeatherForecastResponse(
        weather: List<WeatherForecastDataPoint>.from(json['weather'].map((x) => WeatherForecastDataPoint.fromJson(x))),
      );
}

/// A data point from https://brightsky.dev/docs/#get-/current_weather
class WeatherForecastDataPoint {
  /// ISO 8601-formatted timestamp of this weather record/forecast.
  final DateTime timestamp;

  /// Main Bright Sky source ID for this record.
  final int sourceId;

  /// Total cloud cover at timestamp.
  final double? cloudCover;

  /// Current weather conditions.
  final String? condition;

  /// Dew point at timestamp, 2 m above ground.
  final double? dewPoint;

  /// Icon alias suitable for the current weather conditions.
  /// Can be: clear-day┃clear-night┃partly-cloudy-day┃partly-cloudy-night┃cloudy┃fog┃wind┃rain┃sleet┃snow┃hail┃thunderstorm.
  final String? icon;

  /// Total precipitation during previous 60 minutes.
  final double? precipitation;

  /// Atmospheric pressure at timestamp, reduced to mean sea level.
  final double? pressureMsl;

  /// Relative humidity at timestamp.
  final double? relativeHumidity;

  /// Sunshine duration during previous 60 minutes.
  final double? sunshine;

  /// Air temperature at timestamp, 2 m above the ground.
  final double? temperature;

  /// Visibility at timestamp.
  final double? visibility;

  /// Mean wind direction during previous hour, 10 m above the ground.
  final double? windDirection;

  /// Mean wind speed during previous hour, 10 m above the ground.
  final double? windSpeed;

  /// Direction of maximum wind gust during previous hour, 10 m above the ground.
  final double? windGustDirection;

  /// Speed of maximum wind gust during previous hour, 10 m above the ground.
  final double? windGustSpeed;

  const WeatherForecastDataPoint({
    required this.timestamp,
    required this.sourceId,
    this.cloudCover,
    this.condition,
    this.dewPoint,
    this.icon,
    this.precipitation,
    this.pressureMsl,
    this.relativeHumidity,
    this.sunshine,
    this.temperature,
    this.visibility,
    this.windDirection,
    this.windSpeed,
    this.windGustDirection,
    this.windGustSpeed,
  });

  factory WeatherForecastDataPoint.fromJson(Map<String, dynamic> json) => WeatherForecastDataPoint(
        timestamp: DateTime.parse(json['timestamp']),
        sourceId: json['source_id'],
        cloudCover: json['cloud_cover']?.toDouble(),
        condition: json['condition'],
        dewPoint: json['dew_point']?.toDouble(),
        icon: json['icon'],
        precipitation: json['precipitation']?.toDouble(),
        pressureMsl: json['pressure_msl']?.toDouble(),
        relativeHumidity: json['relative_humidity']?.toDouble(),
        sunshine: json['sunshine']?.toDouble(),
        temperature: json['temperature']?.toDouble(),
        visibility: json['visibility']?.toDouble(),
        windDirection: json['wind_direction']?.toDouble(),
        windSpeed: json['wind_speed']?.toDouble(),
        windGustDirection: json['wind_gust_direction']?.toDouble(),
        windGustSpeed: json['wind_gust_speed']?.toDouble(),
      );
}
