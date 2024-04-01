import 'package:latlong2/latlong.dart';

/// An enum for the type of the custom instruction
/// This type is derived from the InstructionTextType.
enum InstructionType {
  directionOnly,
  signalGroupOnly,
  directionAndSignalGroup,
}

/// An enum for the type of the instruction text.
enum InstructionTextType {
  direction,
  signalGroup,
}

class InstructionText {
  /// The instruction text.
  String text;

  /// The type of the instruction text.
  final InstructionTextType type;

  /// The countdown of the instruction
  /// Only used for InstructionTextType signalGroup.
  int? countdown;

  /// The timestamp when the countdown was started.
  DateTime? countdownTimeStamp;

  InstructionText({required this.text, required this.type, this.countdown, this.countdownTimeStamp});

  /// Adds a countdown to the instructionText as well as the current timestamp.
  void addCountdown(int countdown) {
    this.countdown = countdown;
    countdownTimeStamp = DateTime.now();
  }
}

class Instruction {
  /// The instruction latitude.
  final double lat;

  /// The instruction longitude.
  final double lon;

  ///  The instruction text.
  List<InstructionText> text;

  /// If the instruction has already been executed.
  bool executed = false;

  /// The instruction type.
  InstructionType instructionType;

  /// The ID of the corresponding signal group.
  final String? signalGroupId;

  /// If the instruction has already been concatenated.
  bool alreadyConcatenated = false;

  Instruction({required this.lat, required this.lon, required this.text, required this.instructionType, this.signalGroupId});
}