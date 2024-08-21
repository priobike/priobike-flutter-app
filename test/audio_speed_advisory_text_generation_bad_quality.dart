import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:priobike/common/models/point.dart';
import 'package:priobike/ride/interfaces/prediction.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/models/recommendation.dart';
import 'package:priobike/ride/services/audio.dart';
import 'package:priobike/ride/services/prediction.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/models/instruction.dart';
import 'package:priobike/routing/models/sg.dart';
import 'package:priobike/settings/services/settings.dart';

void main() {
  /// The central getIt instance that is used to access the singleton services.
  final getIt = GetIt.instance;

  getIt.registerSingleton<Settings>(Settings());
  getIt.registerSingleton<Audio>(Audio());
  getIt.registerSingleton<Ride>(Ride());

  Audio audio = getIt<Audio>();
  Ride ride = getIt<Ride>();

  // Create test sg for the ride.
  ride.calcCurrentSG = const Sg(id: "test", label: "test", position: Point(lon: 0.0, lat: 0.0));
  PredictionProvider predictionProvider = PredictionProvider(onConnected: () {}, notifyListeners: () {});
  ride.predictionProvider = predictionProvider;

  // TODO Add more test cases if threshold is finally implemented.
  // Needs to be set to provide predictionProvider prediction quality.
  // The other values can be ignored.
  const String predictionJson =
      '{"greentimeThreshold": 95, "predictionQuality": 0.49, "signalGroupId": "test", "startTime": "2024-08-20T11:11:00.000Z", "value": []}';
  final Prediction prediction = PredictionServicePrediction.fromJson(jsonDecode(predictionJson));
  ride.predictionProvider!.prediction = prediction;

  group('Speed advisory with bad quality', () {
    // Create the recommendation for this test.
    final List<Phase> redPhases = List<Phase>.generate(20, (_) => Phase.red);
    final List<Phase> greenPhases = List<Phase>.generate(20, (_) => Phase.green);

    test('Green in 19, but bad quality', () {
      final List<Phase> calcPhasesFromNow = redPhases + greenPhases + redPhases + greenPhases;
      final List<double> calcQualitiesFromNow = List<double>.generate(80, (_) => 0.49);
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));
      const Phase calcCurrentSignalPhase = Phase.red;

      ride.predictionProvider!.recommendation =
          Recommendation(calcPhasesFromNow, calcQualitiesFromNow, calcCurrentPhaseChangeTime, calcCurrentSignalPhase);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = [5.0, 5.0, 5.0, 5.0, 5.0];

      // Generate the text to play. 100m to the next sg. 5m/s speed. => 20s to the sg.
      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      expect(generatedText, null);
    });
  });
}
