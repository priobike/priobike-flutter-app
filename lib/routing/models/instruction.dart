import 'package:latlong2/latlong.dart';

class Instruction {
  /// The instruction latitude.
  final double lat;

  /// The instruction longitude.
  final double lon;

  ///  The instruction text.
  String text;

  /// If the instruction has already been executed.
  bool executed = false;

  Instruction({required this.lat, required this.lon, required this.text});
}