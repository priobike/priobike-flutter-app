class SpeedAdvisoryInstruction {
  /// The instruction text.
  String text;

  /// The given countdown.
  int countdown;

  /// The latitude of the instruction.
  double lat;

  /// The longitude of the instruction.
  double lon;

  SpeedAdvisoryInstruction({required this.text, required this.countdown, required this.lat, required this.lon});

  /// Convert the speed advisory instruction to a json object.
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'countdown': countdown,
      'lat': lat,
      'lon': lon,
    };
  }

  /// Create a speed advisroy instruction from a json object.
  factory SpeedAdvisoryInstruction.fromJson(Map<String, dynamic> json) {
    return SpeedAdvisoryInstruction(
      text: json.containsKey('text') ? json['text'] : null,
      countdown: json.containsKey('countdown') ? json['countdown'] : null,
      lat: json.containsKey('lat') ? json['lat'] : null,
      lon: json.containsKey('lon') ? json['lon'] : null,
    );
  }
}
