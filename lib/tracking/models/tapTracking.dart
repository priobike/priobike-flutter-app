/// The model of tap tracking.
class ScreenTrack {
  /// The tap down x coordinate.
  final double tapDownX;

  /// The tap down y coordinate.
  final double tapDownY;

  /// The tap up x coordinate.
  final double tapUpX;

  /// The tap up x coordinate.
  final double tapUpY;

  const ScreenTrack({
    required this.tapDownX,
    required this.tapDownY,
    required this.tapUpX,
    required this.tapUpY,
  });

  Map<String, dynamic> toJson() => {
        'tapDownX': tapDownX,
        'tapDownY': tapDownY,
        'tapUpX': tapUpX,
        'tapUpY': tapUpY,
      };

  factory ScreenTrack.fromJson(Map<String, dynamic> json) => ScreenTrack(
        tapDownX: json['tapDownX'] as double,
        tapDownY: json['tapDownY'] as double,
        tapUpX: json['tapUpX'] as double,
        tapUpY: json['tapUpY'] as double,
      );
}
