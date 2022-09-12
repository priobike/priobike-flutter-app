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