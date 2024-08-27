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
import 'package:priobike/settings/models/speed.dart';
import 'package:priobike/settings/services/settings.dart';

void main() {
  /// The central getIt instance that is used to access the singleton services.
  final getIt = GetIt.instance;

  getIt.registerSingleton<Settings>(Settings(speedMode: SpeedMode.max30kmh));
  getIt.registerSingleton<Audio>(Audio());
  getIt.registerSingleton<Ride>(Ride());

  Audio audio = getIt<Audio>();
  Ride ride = getIt<Ride>();

  // Create test sg for the ride.
  ride.calcCurrentSG = const Sg(id: "test", label: "test", position: Point(lon: 0.0, lat: 0.0));
  PredictionProvider predictionProvider = PredictionProvider(onConnected: () {}, notifyListeners: () {});
  ride.predictionProvider = predictionProvider;

  // Needs to be set to provide predictionProvider prediction quality.
  // The other values can be ignored.
  const String predictionJson =
      '{"greentimeThreshold": 95, "predictionQuality": 1.0, "signalGroupId": "test", "startTime": "2024-08-20T11:11:00.000Z", "value": []}';
  final Prediction prediction = PredictionServicePrediction.fromJson(jsonDecode(predictionJson));
  ride.predictionProvider!.prediction = prediction;

  List<double> lastSpeedValues3 = [3, 3, 3];
  List<double> lastSpeedValues4 = [4, 4, 4];
  List<double> lastSpeedValues5 = [5, 5, 5];
  List<double> lastSpeedValues6 = [6, 6, 6];
  List<double> lastSpeedValues7 = [7, 7, 7];

  group('300m #1', () {
    // Create the recommendation for this test.
    final List<Phase> redPhases = List<Phase>.generate(20, (_) => Phase.red);
    final List<Phase> greenPhases = List<Phase>.generate(20, (_) => Phase.green);

    final List<Phase> calcPhasesFromNow1 = greenPhases + redPhases + greenPhases + redPhases;
    final List<double> calcQualitiesFromNow1 = List<double>.generate(80, (_) => 1.0);
    const Phase calcCurrentSignalPhase1 = Phase.green;

    test('3m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues3;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 60);
    });

    test('4m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues4;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 60);
    });

    test('5m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues5;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 60);
    });

    test('6m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues6;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 60);
    });

    test('7m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues7;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 60);
    });
  });

  group('300m #2', () {
    // Create the recommendation for this test.
    final List<Phase> redPhases = List<Phase>.generate(38, (_) => Phase.red);
    final List<Phase> greenPhases = List<Phase>.generate(33, (_) => Phase.green);
    final List<Phase> greenPhases2 = List<Phase>.generate(25, (_) => Phase.green);

    final List<Phase> calcPhasesFromNow1 = greenPhases + redPhases + greenPhases2 + redPhases;
    final List<double> calcQualitiesFromNow1 = List<double>.generate(134, (_) => 1.0);
    const Phase calcCurrentSignalPhase1 = Phase.green;

    test('3m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 33));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues3;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel grün in");

      expect(generatedText.countdown, 71);
    });

    test('4m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 33));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues4;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel grün in");

      expect(generatedText.countdown, 71);
    });

    test('5m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 33));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues5;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel grün in");

      expect(generatedText.countdown, 71);
    });

    test('6m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 33));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues6;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel grün in");

      expect(generatedText.countdown, 71);
    });

    test('7m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 33));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues7;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel grün in");

      expect(generatedText.countdown, 71);
    });
  });

  group('300m #3', () {
    // Create the recommendation for this test.
    final List<Phase> redPhases = List<Phase>.generate(60, (_) => Phase.red);
    final List<Phase> greenPhases = List<Phase>.generate(60, (_) => Phase.green);

    final List<Phase> calcPhasesFromNow1 = greenPhases + redPhases;
    final List<double> calcQualitiesFromNow1 = List<double>.generate(120, (_) => 1.0);
    const Phase calcCurrentSignalPhase1 = Phase.green;

    test('3m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 60));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues3;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 60);
    });

    test('4m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 60));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues4;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 60);
    });

    test('5m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 60));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues5;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 60);
    });

    test('6m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 60));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues6;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 60);
    });

    test('7m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 60));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues7;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 60);
    });
  });

  group('300m #4', () {
    // Create the recommendation for this test.
    final List<Phase> redPhases = List<Phase>.generate(60, (_) => Phase.red);
    final List<Phase> greenPhases = List<Phase>.generate(60, (_) => Phase.green);

    final List<Phase> calcPhasesFromNow1 = redPhases + greenPhases;
    final List<double> calcQualitiesFromNow1 = List<double>.generate(120, (_) => 1.0);
    const Phase calcCurrentSignalPhase1 = Phase.red;

    test('3m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 60));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues3;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel grün in");

      expect(generatedText.countdown, 60);
    });

    test('4m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 60));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues4;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel grün in");

      expect(generatedText.countdown, 60);
    });

    test('5m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 60));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues5;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel grün in");

      expect(generatedText.countdown, 60);
    });

    test('6m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 60));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues6;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel grün in");

      expect(generatedText.countdown, 60);
    });

    test('7m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 60));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues7;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel grün in");

      expect(generatedText.countdown, 60);
    });
  });

  group('300m #5', () {
    // Create the recommendation for this test.
    final List<Phase> redPhases = List<Phase>.generate(50, (_) => Phase.red);
    final List<Phase> greenPhases = List<Phase>.generate(10, (_) => Phase.green);

    final List<Phase> calcPhasesFromNow1 = redPhases + greenPhases + redPhases;
    final List<double> calcQualitiesFromNow1 = List<double>.generate(110, (_) => 1.0);
    const Phase calcCurrentSignalPhase1 = Phase.red;

    test('3m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 50));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues3;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 60);
    });

    test('4m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 50));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues4;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 60);
    });

    test('5m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 50));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues5;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 60);
    });

    test('6m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 50));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues6;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel grün in");

      expect(generatedText.countdown, 50);
    });

    test('7m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 50));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues7;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel grün in");

      expect(generatedText.countdown, 50);
    });
  });

  group('300m #5', () {
    // Create the recommendation for this test.
    final List<Phase> redPhases = List<Phase>.generate(50, (_) => Phase.red);
    final List<Phase> greenPhases = List<Phase>.generate(10, (_) => Phase.green);

    final List<Phase> calcPhasesFromNow1 = redPhases + greenPhases + redPhases;
    final List<double> calcQualitiesFromNow1 = List<double>.generate(110, (_) => 1.0);
    const Phase calcCurrentSignalPhase1 = Phase.red;

    test('3m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 50));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues3;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 60);
    });

    test('4m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 50));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues4;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 60);
    });

    test('5m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 50));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues5;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 60);
    });

    test('6m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 50));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues6;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel grün in");

      expect(generatedText.countdown, 50);
    });

    test('7m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 50));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues7;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel grün in");

      expect(generatedText.countdown, 50);
    });
  });

  group('300m #6', () {
    // Create the recommendation for this test.
    final List<Phase> redPhases = List<Phase>.generate(10, (_) => Phase.red);
    final List<Phase> greenPhases = List<Phase>.generate(50, (_) => Phase.green);

    final List<Phase> calcPhasesFromNow1 = greenPhases + redPhases + greenPhases + redPhases;
    final List<double> calcQualitiesFromNow1 = List<double>.generate(110, (_) => 1.0);
    const Phase calcCurrentSignalPhase1 = Phase.green;

    test('3m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 50));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues3;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 110);
    });

    test('4m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 50));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues4;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel grün in");

      expect(generatedText.countdown, 60);
    });

    test('5m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 50));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues5;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel grün in");

      expect(generatedText.countdown, 60);
    });

    test('6m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 50));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues6;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 50);
    });

    test('7m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 50));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues7;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 50);
    });
  });

  // Test for distance to next sg 100m.
  group('100m #1', () {
    // Create the recommendation for this test.
    final List<Phase> redPhases = List<Phase>.generate(20, (_) => Phase.red);
    final List<Phase> greenPhases = List<Phase>.generate(20, (_) => Phase.green);

    final List<Phase> calcPhasesFromNow1 = redPhases + greenPhases + redPhases + greenPhases;
    final List<double> calcQualitiesFromNow1 = List<double>.generate(80, (_) => 1.0);
    const Phase calcCurrentSignalPhase1 = Phase.red;

    test('3m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues3;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel rot in");

      expect(generatedText.countdown, 40);
    });

    test('4m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues4;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel grün in");

      expect(generatedText.countdown, 20);
    });

    test('5m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues5;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel grün in");

      expect(generatedText.countdown, 20);
    });

    test('6m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues6;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel grün in");

      expect(generatedText.countdown, 20);
    });

    test('7m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues7;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel grün in");

      expect(generatedText.countdown, 20);
    });
  });

  group('100m #2', () {
    // Create the recommendation for this test.
    final List<Phase> redPhases = List<Phase>.generate(20, (_) => Phase.red);
    final List<Phase> greenPhases = List<Phase>.generate(20, (_) => Phase.green);

    final List<Phase> calcPhasesFromNow1 = greenPhases + redPhases + greenPhases + redPhases;
    final List<double> calcQualitiesFromNow1 = List<double>.generate(80, (_) => 1.0);
    const Phase calcCurrentSignalPhase1 = Phase.green;

    test('3m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues3;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel rot in");

      expect(generatedText.countdown, 20);
    });

    test('4m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues4;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel rot in");

      expect(generatedText.countdown, 20);
    });

    test('5m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues5;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel rot in");

      expect(generatedText.countdown, 20);
    });

    test('6m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues6;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel rot in");

      expect(generatedText.countdown, 20);
    });

    test('7m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 20));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues7;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel rot in");

      expect(generatedText.countdown, 20);
    });
  });

  group('100m #3', () {
    // Create the recommendation for this test.
    final List<Phase> redPhases = List<Phase>.generate(40, (_) => Phase.red);
    final List<Phase> greenPhases = List<Phase>.generate(40, (_) => Phase.green);

    final List<Phase> calcPhasesFromNow1 = greenPhases + redPhases;
    final List<double> calcQualitiesFromNow1 = List<double>.generate(80, (_) => 1.0);
    const Phase calcCurrentSignalPhase1 = Phase.green;

    test('3m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 40));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues3;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel rot in");

      expect(generatedText.countdown, 40);
    });

    test('4m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 40));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues4;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel rot in");

      expect(generatedText.countdown, 40);
    });

    test('5m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 40));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues5;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel rot in");

      expect(generatedText.countdown, 40);
    });

    test('6m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 40));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues6;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel rot in");

      expect(generatedText.countdown, 40);
    });

    test('7m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 40));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues7;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel rot in");

      expect(generatedText.countdown, 40);
    });
  });

  group('100m #4', () {
    // Create the recommendation for this test.
    final List<Phase> redPhases = List<Phase>.generate(40, (_) => Phase.red);
    final List<Phase> greenPhases = List<Phase>.generate(40, (_) => Phase.green);

    final List<Phase> calcPhasesFromNow1 = redPhases + greenPhases;
    final List<double> calcQualitiesFromNow1 = List<double>.generate(120, (_) => 1.0);
    const Phase calcCurrentSignalPhase1 = Phase.red;

    test('3m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 40));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues3;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel grün in");

      expect(generatedText.countdown, 40);
    });

    test('4m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 40));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues4;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel grün in");

      expect(generatedText.countdown, 40);
    });

    test('5m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 40));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues5;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel grün in");

      expect(generatedText.countdown, 40);
    });

    test('6m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 40));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues6;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel grün in");

      expect(generatedText.countdown, 40);
    });

    test('7m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 40));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNow1, calcQualitiesFromNow1, calcCurrentPhaseChangeTime, calcCurrentSignalPhase1);

      InstructionText instructionText = InstructionText(
        text: "In 100 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 100.0,
      );

      audio.lastSpeedValues = lastSpeedValues7;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel grün in");

      expect(generatedText.countdown, 40);
    });
  });

  group('Speed advisory with good quality but exceptions', () {
    test('Phase stays same', () {
      // Create the recommendation for this test.
      final List<Phase> redPhases = List<Phase>.generate(20, (_) => Phase.red);
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

      audio.lastSpeedValues = lastSpeedValues5;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      expect(generatedText, null);
    });
  });

  group('Speed advisory with regards to max speed 300m and 30km/h max', () {
    // Create the recommendation for this test.
    final List<Phase> redPhases10 = List<Phase>.generate(10, (_) => Phase.red);
    final List<Phase> greenPhases25 = List<Phase>.generate(25, (_) => Phase.green);
    final List<Phase> redPhases25 = List<Phase>.generate(25, (_) => Phase.red);
    final List<Phase> greenPhases20 = List<Phase>.generate(20, (_) => Phase.red);
    final List<Phase> greenPhases3 = List<Phase>.generate(34, (_) => Phase.green);
    final List<Phase> redPhases3 = List<Phase>.generate(16, (_) => Phase.green);

    final List<Phase> calcPhasesFromNowMax = redPhases10 + greenPhases25 + redPhases25 + greenPhases20;
    final List<double> calcQualitiesFromNow = List<double>.generate(80, (_) => 1.0);
    const Phase calcCurrentSignalPhase = Phase.red;

    test('6m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 10));

      ride.predictionProvider!.recommendation = Recommendation(
          calcPhasesFromNowMax, calcQualitiesFromNow, calcCurrentPhaseChangeTime, calcCurrentSignalPhase);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues6;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel grün in");

      expect(generatedText.countdown, 60);
    });

    test('7m/s', () {
      final calcPhasesFromNow2 = redPhases10 + greenPhases3 + redPhases3 + greenPhases20;

      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 10));

      ride.predictionProvider!.recommendation =
          Recommendation(calcPhasesFromNow2, calcQualitiesFromNow, calcCurrentPhaseChangeTime, calcCurrentSignalPhase);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues7;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 60);
    });
  });

  group('Speed advisory with regards to max speed 300m and 40km/h max', () {
    // Create the recommendation for this test.
    final List<Phase> redPhases = List<Phase>.generate(10, (_) => Phase.red);
    final List<Phase> greenPhases = List<Phase>.generate(25, (_) => Phase.green);
    final List<Phase> redPhases2 = List<Phase>.generate(25, (_) => Phase.red);
    final List<Phase> greenPhases2 = List<Phase>.generate(20, (_) => Phase.red);

    List<Phase> calcPhasesFromNow = redPhases + greenPhases + redPhases2 + greenPhases2;
    final List<double> calcQualitiesFromNow = List<double>.generate(80, (_) => 1.0);
    const Phase calcCurrentSignalPhase = Phase.red;

    getIt.unregister<Settings>();
    getIt.registerSingleton<Settings>(Settings(speedMode: SpeedMode.max40kmh));

    test('7m/s', () {
      final DateTime calcCurrentPhaseChangeTime = DateTime.now().add(const Duration(seconds: 10));

      ride.predictionProvider!.recommendation =
          Recommendation(calcPhasesFromNow, calcQualitiesFromNow, calcCurrentPhaseChangeTime, calcCurrentSignalPhase);

      InstructionText instructionText = InstructionText(
        text: "In 300 meter Ampel",
        type: InstructionTextType.signalGroup,
        distanceToNextSg: 300.0,
      );

      audio.lastSpeedValues = lastSpeedValues7;

      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 300 meter Ampel rot in");

      expect(generatedText.countdown, 35);
    });
  });

  group('Speed advisory with good quality but Recommandation delay', () {
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

      audio.lastSpeedValues = lastSpeedValues5;

      // Generate the text to play. 100m to the next sg. 5m/s speed. => 20s to the sg.
      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel grün in");

      expect(generatedText.countdown, 18);
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

      audio.lastSpeedValues = lastSpeedValues5;

      // Generate the text to play. 100m to the next sg. 5m/s speed. => 20s to the sg.
      InstructionText? generatedText = audio.generateTextToPlay(instructionText);

      if (generatedText == null) {
        fail("Generated text is null");
      }

      expect(generatedText.text, "In 100 meter Ampel rot in");

      expect(generatedText.countdown, 18);
    });
  });
}
