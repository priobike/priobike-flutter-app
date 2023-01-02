/// A response from https://brightsky.dev/docs/#get-/current_weather
class WeatherForecastResponse {
  /// The data points.
  final List<WeatherForecast> weather;

  const WeatherForecastResponse({
    required this.weather,
  });

  factory WeatherForecastResponse.fromJson(Map<String, dynamic> json) => WeatherForecastResponse(
        weather: List<WeatherForecast>.from(json['weather'].map((x) => WeatherForecast.fromJson(x))),
      );
}

/// A data point from https://brightsky.dev/docs/#get-/current_weather
class WeatherForecast {
  /// ISO 8601-formatted timestamp of this weather record/forecast.
  final DateTime timestamp;

  /// Main Bright Sky source ID for this record.
  final int sourceId;

  /// Total cloud cover at timestamp.
  final num? cloudCover;

  /// Current weather conditions.
  final String? condition;

  /// Dew point at timestamp, 2 m above ground.
  final num? dewPoint;

  /// Icon alias suitable for the current weather conditions.
  /// Can be: clear-day┃clear-night┃partly-cloudy-day┃partly-cloudy-night┃cloudy┃fog┃wind┃rain┃sleet┃snow┃hail┃thunderstorm.
  final String? icon;

  /// Total precipitation during previous 60 minutes.
  final num? precipitation;

  /// Atmospheric pressure at timestamp, reduced to mean sea level.
  final num? pressureMsl;

  /// Relative humidity at timestamp.
  final num? relativeHumidity;

  /// Sunshine duration during previous 60 minutes.
  final num? sunshine;

  /// Air temperature at timestamp, 2 m above the ground.
  final num? temperature;

  /// Visibility at timestamp.
  final num? visibility;

  /// Mean wind direction during previous hour, 10 m above the ground.
  final num? windDirection;

  /// Mean wind speed during previous hour, 10 m above the ground.
  final num? windSpeed;

  /// Direction of maximum wind gust during previous hour, 10 m above the ground.
  final num? windGustDirection;

  /// Speed of maximum wind gust during previous hour, 10 m above the ground.
  final num? windGustSpeed;

  const WeatherForecast({
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

  factory WeatherForecast.fromJson(Map<String, dynamic> json) => WeatherForecast(
        timestamp: DateTime.parse(json['timestamp']),
        sourceId: json['source_id'],
        cloudCover: json['cloud_cover'],
        condition: json['condition'],
        dewPoint: json['dew_point'],
        icon: json['icon'],
        precipitation: json['precipitation'],
        pressureMsl: json['pressure_msl'],
        relativeHumidity: json['relative_humidity'],
        sunshine: json['sunshine'],
        temperature: json['temperature'],
        visibility: json['visibility'],
        windDirection: json['wind_direction'],
        windSpeed: json['wind_speed'],
        windGustDirection: json['wind_gust_direction'],
        windGustSpeed: json['wind_gust_speed'],
      );
}

/// A response from https://brightsky.dev/docs/#get-/current_weather
class CurrentWeatherResponse {
  /// The weather.
  final CurrentWeather weather;

  const CurrentWeatherResponse({
    required this.weather,
  });

  factory CurrentWeatherResponse.fromJson(Map<String, dynamic> json) => CurrentWeatherResponse(
        weather: CurrentWeather.fromJson(json['weather']),
      );
}

class CurrentWeather {
  /// ISO 8601-formatted timestamp of this weather record/forecast.
  final DateTime timestamp;

  /// Bright Sky source ID for this record.
  final int sourceId;

  /// Total cloud cover at timestamp.
  final num? cloudCover;

  /// Current weather conditions.
  /// Can be: dry┃fog┃rain┃sleet┃snow┃hail┃thunderstorm.
  final String? condition;

  /// Dew point at timestamp, 2 m above ground.
  final num? dewPoint;

  /// Icon alias suitable for the current weather conditions.
  /// Can be: clear-day┃clear-night┃partly-cloudy-day┃partly-cloudy-night┃cloudy┃fog┃wind┃rain┃sleet┃snow┃hail┃thunderstorm.
  final String? icon;

  /// Total precipitation during previous 10 minutes.
  final num? precipitation10;

  /// Total precipitation during previous 30 minutes.
  final num? precipitation30;

  /// Total precipitation during previous 60 minutes.
  final num? precipitation60;

  /// Atmospheric pressure at timestamp, reduced to mean sea level.
  final num? pressureMsl;

  /// Relative humidity at timestamp.
  final num? relativeHumidity;

  /// Sunshine duration during previous 30 minutes.
  final num? sunshine30;

  /// Sunshine duration during previous 60 minutes.
  final num? sunshine60;

  /// Air temperature at timestamp, 2 m above the ground.
  final num? temperature;

  /// Visibility at timestamp.
  final num? visibility;

  /// Mean wind direction during previous 10 minutes, 10 m above the ground.
  final num? windDirection10;

  /// Mean wind direction during previous 30 minutes, 10 m above the ground.
  final num? windDirection30;

  /// Mean wind direction during previous 60 minutes, 10 m above the ground.
  final num? windDirection60;

  /// Mean wind speed during previous 10 minutes, 10 m above the ground.
  final num? windSpeed10;

  /// Mean wind speed during previous 30 minutes, 10 m above the ground.
  final num? windSpeed30;

  /// Mean wind speed during previous 60 minutes, 10 m above the ground.
  final num? windSpeed60;

  /// Direction of maximum wind gust during previous 10 minutes, 10 m above the ground.
  final num? windGustDirection10;

  /// Direction of maximum wind gust during previous 30 minutes, 10 m above the ground.
  final num? windGustDirection30;

  /// Direction of maximum wind gust during previous 60 minutes, 10 m above the ground.
  final num? windGustDirection60;

  const CurrentWeather({
    required this.timestamp,
    required this.sourceId,
    this.cloudCover,
    this.condition,
    this.dewPoint,
    this.icon,
    this.precipitation10,
    this.precipitation30,
    this.precipitation60,
    this.pressureMsl,
    this.relativeHumidity,
    this.sunshine30,
    this.sunshine60,
    this.temperature,
    this.visibility,
    this.windDirection10,
    this.windDirection30,
    this.windDirection60,
    this.windSpeed10,
    this.windSpeed30,
    this.windSpeed60,
    this.windGustDirection10,
    this.windGustDirection30,
    this.windGustDirection60,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) => CurrentWeather(
        timestamp: DateTime.parse(json['timestamp']),
        sourceId: json['source_id'],
        cloudCover: json['cloud_cover'],
        condition: json['condition'],
        dewPoint: json['dew_point'],
        icon: json['icon'],
        precipitation10: json['precipitation_10'],
        precipitation30: json['precipitation_30'],
        precipitation60: json['precipitation_60'],
        pressureMsl: json['pressure_msl'],
        relativeHumidity: json['relative_humidity'],
        sunshine30: json['sunshine_30'],
        sunshine60: json['sunshine_60'],
        temperature: json['temperature'],
        visibility: json['visibility'],
        windDirection10: json['wind_direction_10'],
        windDirection30: json['wind_direction_30'],
        windDirection60: json['wind_direction_60'],
        windSpeed10: json['wind_speed_10'],
        windSpeed30: json['wind_speed_30'],
        windSpeed60: json['wind_speed_60'],
        windGustDirection10: json['wind_gust_direction_10'],
        windGustDirection30: json['wind_gust_direction_30'],
        windGustDirection60: json['wind_gust_direction_60'],
      );
}
