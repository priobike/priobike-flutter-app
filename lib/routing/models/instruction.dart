class InstructionText {
  /// The instruction text.
  String text;

  /// The countdown of the instruction
  /// Only used for InstructionTextType signalGroup.
  int? countdown;

  /// The timestamp when the countdown was started.
  DateTime countdownTimeStamp = DateTime.now();

  /// The distance to the next signal group.
  double distanceToNextSg = 0;

  InstructionText({required this.text, this.countdown, required this.distanceToNextSg});

  /// Adds a countdown to the instructionText as well as the current timestamp.
  void addCountdown(int countdown) {
    this.countdown = countdown;
  }
}
