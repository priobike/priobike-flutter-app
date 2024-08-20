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

  group('Speed advisory with good quality', () {
    // Needs to be set to provide predictionProvider prediction quality.
    // The other values can be ignored.
    const String predictionJson =
        '{"greentimeThreshold": 95, "predictionQuality": 1.0, "signalGroupId": "test", "startTime": "2024-08-20T11:11:00.000Z", "value": []}';
    final Prediction prediction = PredictionServicePrediction.fromJson(jsonDecode(predictionJson));
    ride.predictionProvider!.prediction = prediction;

    // Create the recommendation for this test.
    final List<Phase> redPhases = List<Phase>.generate(20, (_) => Phase.red);
    final List<Phase> greenPhases = List<Phase>.generate(20, (_) => Phase.green);

    final List<Phase> calcPhasesFromNow1 = redPhases + greenPhases + redPhases + greenPhases;
    final List<double> calcQualitiesFromNow1 = List<double>.generate(80, (_) => 1.0);
    const Phase calcCurrentSignalPhase1 = Phase.red;

    test('Green in 19', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );
      // Generate the text to play. 100m to the next sg. 5m/s speed. => 20s to the sg.
      InstructionText? generatedText = audio.generateTextToPlay(instructionText, 5);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel grün in");
      // 20 seconds - 1 second delay.
      expect(generatedText.countdown, 19);
    });

    test('Green in 19, too fast', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );
      // Generate the text to play. 100m to the next sg. 6m/s speed. => 16,66s to the sg.
      InstructionText? generatedText = audio.generateTextToPlay(instructionText, 6);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel grün in");
      // 20 seconds - 1 second delay.
      expect(generatedText.countdown, 19);
    });

    test('Red in 39, too slow', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );
      // Generate the text to play. 100m to the next sg. 6m/s speed. => 44,44s to the sg.
      InstructionText? generatedText = audio.generateTextToPlay(instructionText, 2.25);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel rot in");
      // 40 seconds - 1 second delay.
      expect(generatedText.countdown, 39);
    });

    test('Red in 39, second green phase', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      // Set new recommendation.
      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 200 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 200.0,
      );
      // Generate the text to play. 200m to the next sg. 5m/s speed. => 40s to the sg.
      InstructionText? generatedText = audio.generateTextToPlay(instructionText, 5);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 200 meter Ampel rot in");
      // 40 seconds - 1 second delay.
      expect(generatedText.countdown, 39);
    });

    test('Green in 59, second green phase', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      // Set new recommendation.
      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 200 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 200.0,
      );
      // Generate the text to play. 200m to the next sg. 3.5m/s speed. => 57s to the sg.
      InstructionText? generatedText = audio.generateTextToPlay(instructionText, 3.5);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 200 meter Ampel grün in");
      // 60 seconds - 1 second delay.
      expect(generatedText.countdown, 59);
    });

    // Test for current phase green and next phase red.
    final List<Phase> calcPhasesFromNow2 = greenPhases + redPhases + greenPhases + redPhases;
    final List<double> calcQualitiesFromNow2 = List<double>.generate(80, (_) => 1.0);
    const Phase calcCurrentSignalPhase2 = Phase.green;

    test('Red in 19', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      // Set new recommendation.
      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow2, calcQualitiesFromNow2, calcCurrentPhaseChangeTime, calcCurrentSignalPhase2);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );
      // Generate the text to play. 100m to the next sg. 6m/s speed. => 16.66s to the sg.
      InstructionText? generatedText = audio.generateTextToPlay(instructionText, 6);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel rot in");
      // 20 seconds - 1 second delay.
      expect(generatedText.countdown, 19);
    });

    test('Red in 19, too slow', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      // Set new recommendation.
      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow2, calcQualitiesFromNow2, calcCurrentPhaseChangeTime, calcCurrentSignalPhase2);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );
      // Generate the text to play. 100m to the next sg. 4m/s speed. => 25s to the sg.
      InstructionText? generatedText = audio.generateTextToPlay(instructionText, 4);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel rot in");
      // 20 seconds - 1 second delay.
      expect(generatedText.countdown, 19);
    });

    test('Green in 39', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      // Set new recommendation.
      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow2, calcQualitiesFromNow2, calcCurrentPhaseChangeTime, calcCurrentSignalPhase2);

      InstructionText instructionText = InstructionText(
        text: "In 200 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 200.0,
      );
      // Generate the text to play. 200m to the next sg. 5m/s speed. => 40s to the sg.
      InstructionText? generatedText = audio.generateTextToPlay(instructionText, 5);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 200 meter Ampel grün in");
      // 20 seconds - 1 second delay.
      expect(generatedText.countdown, 39);
    });

    test('Green in 39, too fast', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      // Set new recommendation.
      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow2, calcQualitiesFromNow2, calcCurrentPhaseChangeTime, calcCurrentSignalPhase2);

      InstructionText instructionText = InstructionText(
        text: "In 200 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 200.0,
      );
      // Generate the text to play. 200m to the next sg. 5.5m/s speed. => 36.36s to the sg.
      InstructionText? generatedText = audio.generateTextToPlay(instructionText, 5.5);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 200 meter Ampel grün in");
      // 20 seconds - 1 second delay.
      expect(generatedText.countdown, 39);
    });
  });

  group('Speed advisory with good quality but exceptions', () {
    // Needs to be set to provide predictionProvider prediction quality.
    // The other values can be ignored.
    const String predictionJson =
        '{"greentimeThreshold": 95, "predictionQuality": 1.0, "signalGroupId": "test", "startTime": "2024-08-20T11:11:00.000Z", "value": []}';
    final Prediction prediction = PredictionServicePrediction.fromJson(jsonDecode(predictionJson));
    ride.predictionProvider!.prediction = prediction;

    // Create the recommendation for this test.
    final List<Phase> redPhases = List<Phase>.generate(20, (_) => Phase.red);
    final List<Phase> greenPhases = List<Phase>.generate(20, (_) => Phase.green);

    test('Phase stays same', () {
      final List<Phase> calcPhasesFromNow = redPhases + redPhases;
      final List<double> calcQualitiesFromNow = List<double>.generate(40, (_) => 1.0);
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));
      const Phase calcCurrentSignalPhase = Phase.red;

      ride.predictionProvider!.recommendation =
          Recommendation(calcPhasesFromNow, calcQualitiesFromNow, calcCurrentPhaseChangeTime, calcCurrentSignalPhase);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );
      // Generate the text to play. 100m to the next sg. 5m/s speed. => 20s to the sg.
      InstructionText? generatedText = audio.generateTextToPlay(instructionText, 5);

      expect(generatedText, null);
    });

    test('Phases too small', () {
      final List<Phase> calcPhasesFromNow = redPhases + greenPhases;
      final List<double> calcQualitiesFromNow = List<double>.generate(40, (_) => 1.0);
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 40));
      const Phase calcCurrentSignalPhase = Phase.red;

      ride.predictionProvider!.recommendation =
          Recommendation(calcPhasesFromNow, calcQualitiesFromNow, calcCurrentPhaseChangeTime, calcCurrentSignalPhase);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );
      // Generate the text to play. 100m to the next sg. 5m/s speed. => 20s to the sg.
      InstructionText? generatedText = audio.generateTextToPlay(instructionText, 5);

      expect(generatedText, null);
    });
  });

  group('Speed advisory with good quality but Recommandation delay', () {
    // Needs to be set to provide predictionProvider prediction quality.
    // The other values can be ignored.
    const String predictionJson =
        '{"greentimeThreshold": 95, "predictionQuality": 1.0, "signalGroupId": "test", "startTime": "2024-08-20T11:11:00.000Z", "value": []}';
    final Prediction prediction = PredictionServicePrediction.fromJson(jsonDecode(predictionJson));
    ride.predictionProvider!.prediction = prediction;

    // Create the recommendation for this test.
    final List<Phase> redPhases = List<Phase>.generate(20, (_) => Phase.red);
    final List<Phase> greenPhases = List<Phase>.generate(20, (_) => Phase.green);

    test('Green in 19', () async {
      final List<Phase> calcPhasesFromNow = redPhases + greenPhases + redPhases + greenPhases;
      final List<double> calcQualitiesFromNow = List<double>.generate(80, (_) => 1.0);
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));
      const Phase calcCurrentSignalPhase = Phase.red;

      ride.predictionProvider!.recommendation =
          Recommendation(calcPhasesFromNow, calcQualitiesFromNow, calcCurrentPhaseChangeTime, calcCurrentSignalPhase);

      // Wait for 2 second to simulate a delay.
      await Future.delayed(const Duration(seconds: 2));

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );
      // Generate the text to play. 100m to the next sg. 5m/s speed. => 20s to the sg.
      InstructionText? generatedText = audio.generateTextToPlay(instructionText, 5);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel grün in");
      // 20 seconds - 1 second delay - 2 simulated delay.
      expect(generatedText.countdown, 17);
    });

    // Test for current phase green and next phase red.
    final List<Phase> calcPhasesFromNow = greenPhases + redPhases + greenPhases + redPhases;
    final List<double> calcQualitiesFromNow = List<double>.generate(80, (_) => 1.0);
    const Phase calcCurrentSignalPhase = Phase.green;

    test('Red in 19', () async {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      // Set new recommendation.
      ride.predictionProvider!.recommendation =
          Recommendation(calcPhasesFromNow, calcQualitiesFromNow, calcCurrentPhaseChangeTime, calcCurrentSignalPhase);

      // Wait for 2 second to simulate a delay.
      await Future.delayed(const Duration(seconds: 2));

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );
      // Generate the text to play. 100m to the next sg. 5m/s speed. => 20s to the sg.
      InstructionText? generatedText = audio.generateTextToPlay(instructionText, 5);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel rot in");
      // 20 seconds - 1 second delay - 2 simulated delay.
      expect(generatedText.countdown, 17);
    });
  });

  group('Speed advisory with bad quality', () {
    // TODO Add more test cases if threshold is finally implemented.
    // Needs to be set to provide predictionProvider prediction quality.
    // The other values can be ignored.
    const String predictionJson =
        '{"greentimeThreshold": 95, "predictionQuality": 0.49, "signalGroupId": "test", "startTime": "2024-08-20T11:11:00.000Z", "value": []}';
    final Prediction prediction = PredictionServicePrediction.fromJson(jsonDecode(predictionJson));
    ride.predictionProvider!.prediction = prediction;

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
      // Generate the text to play. 100m to the next sg. 5m/s speed. => 20s to the sg.
      InstructionText? generatedText = audio.generateTextToPlay(instructionText, 5);

      expect(generatedText, null);
    });
  });
}
