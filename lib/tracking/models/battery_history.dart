class BatteryHistory {
  /// The battery level, in percent.
  int? level;

  /// The timestamp of the battery state.
  int? timestamp;

  /// The state of the battery.
  String? batteryState;

  /// If the system is in battery save mode.
  bool? isInBatterySaveMode;

  BatteryHistory(
      {required this.level, required this.timestamp, required this.batteryState, required this.isInBatterySaveMode});

  /// Convert the battery state to a json object.
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'timestamp': timestamp,
      'batteryState': batteryState,
      'isInBatterySaveMode': isInBatterySaveMode,
    };
  }

  /// Create a battery state from a json object.
  factory BatteryHistory.fromJson(Map<String, dynamic> json) {
    return BatteryHistory(
      level: json.containsKey('level') ? json['level'] : null,
      timestamp: json.containsKey('timestamp') ? json['timestamp'] : null,
      batteryState: json.containsKey('batteryState') ? json['batteryState'] : null,
      isInBatterySaveMode: json.containsKey('isInBatterySaveMode') ? json['isInBatterySaveMode'] : null,
    );
  }
}
