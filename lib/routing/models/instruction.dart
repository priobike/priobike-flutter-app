import 'package:latlong2/latlong.dart';

/// An enum for the type of the custom instruction.
enum InstructionType {
  directionOnly,
  signalGroupOnly,
  directionAndSignalGroup,
}

class Instruction {
  /// The instruction latitude.
  final double lat;

  /// The instruction longitude.
  final double lon;

  ///  The instruction text.
  String text;

  /// If the instruction has already been executed.
  bool executed = false;

  /// The instruction type.
  final InstructionType instructionType;

  /// The ID of the corresponding signal group.
  final String? signalGroupId;

  /// If the instruction has already been concatenated.
  bool alreadyConcatenated = false;

  Instruction({required this.lat, required this.lon, required this.text, required this.instructionType, this.signalGroupId});
}