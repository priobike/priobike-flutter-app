/// The model of tap tracking.
class ScreenTrack {
  /// The tap down x coordinate.
  final int tapDownX;

  /// The tap down y coordinate.
  final int tapDownY;

  /// The tap up x coordinate.
  final int tapUpX;

  /// The tap up x coordinate.
  final int tapUpY;

  /// The time when the tap was registered, in milliseconds since the epoch.
  final int? time;

  ScreenTrack({
    required this.tapDownX,
    required this.tapDownY,
    required this.tapUpX,
    required this.tapUpY,
    int? time,
  }) : time = time ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'tapDownX': tapDownX,
        'tapDownY': tapDownY,
        'tapUpX': tapUpX,
        'tapUpY': tapUpY,
        'time': time,
      };

  factory ScreenTrack.fromJson(Map<String, dynamic> json) => ScreenTrack(
        tapDownX: json['tapDownX'] as int,
        tapDownY: json['tapDownY'] as int,
        tapUpX: json['tapUpX'] as int,
        tapUpY: json['tapUpY'] as int,
        time: json['time'] as int?,
      );
}
