import 'package:latlong2/latlong.dart';

class Instruction {
  /// The instruction location
  final LatLng location;

  ///  The instruction text
  final String text;

  /// If the instruction has already been executed
  bool executed = false;

  Instruction({required this.location, required this.text});

}