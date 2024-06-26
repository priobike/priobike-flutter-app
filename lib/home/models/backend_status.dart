class BackendStatus {
  /// If another backend should be used.
  final bool recommendOtherBackend;

  /// If the backend has a load warning.
  final bool warning;

  /// The timestamp of the current load status data.
  final DateTime timestamp;

  BackendStatus({required this.recommendOtherBackend, required this.warning, required this.timestamp});

  factory BackendStatus.fromJson(Map<String, dynamic> json) => BackendStatus(
        recommendOtherBackend: json['recommendOtherBackend'],
        warning: json['warning'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000),
      );

  Map<String, dynamic> toJson() => {
        'recommendOtherBackend': recommendOtherBackend,
        'warning': warning,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };
}
