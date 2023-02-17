import 'package:priobike/ride/messages/prediction.dart';

class Recommendation {
  /// The current predicted phases.
  final List<Phase> calcPhasesFromNow;

  /// The prediction qualities from now in [0.0, 1.0], calculated periodically.
  final List<double> calcQualitiesFromNow;

  /// The current predicted time of the next phase change, calculated periodically.
  /// The phase change time may be null in case the prediction ends before the next phase change.
  final DateTime? calcCurrentPhaseChangeTime;

  /// The predicted current signal phase, calculated periodically.
  final Phase calcCurrentSignalPhase;

  Recommendation(
      this.calcPhasesFromNow, this.calcQualitiesFromNow, this.calcCurrentPhaseChangeTime, this.calcCurrentSignalPhase);
}
