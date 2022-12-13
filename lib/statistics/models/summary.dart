/// A statistics summary of a bicycle ride.
class Summary {
  /// The total distance of the ride.
  final double distanceMeters;

  /// The total duration of the ride.
  final double durationSeconds;

  /// The total elevation gain of the ride.
  final double elevationGain;

  /// The total elevation loss of the ride.
  final double elevationLoss;

  /// Calculate the average speed of the ride.
  double get averageSpeedKmH {
    if (durationSeconds == 0) return 0;
    return distanceMeters / durationSeconds * 3.6;
  }

  /// Calculate the saved CO2 emissions of the ride.
  double get savedCo2inG {
    const co2PerKm = 0.1187; // Data according to statista.com in KG
    return (distanceMeters / 1000) * (durationSeconds / 3600) * co2PerKm * 1000;
  }

  const Summary({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.elevationGain,
    required this.elevationLoss,
  });

  Map<String, dynamic> toJson() => {
        'distanceMeters': distanceMeters,
        'durationSeconds': durationSeconds,
        'elevationGain': elevationGain,
        'elevationLoss': elevationLoss,
      };

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
        distanceMeters: json['distanceMeters'] as double,
        durationSeconds: json['durationSeconds'] as double,
        elevationGain: json['elevationGain'] as double,
        elevationLoss: json['elevationLoss'] as double,
      );
}
