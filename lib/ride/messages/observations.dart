import 'package:flutter/material.dart';

class Observation<R> {
  /// The time of this observation, in the format: `2022-11-04T07:40:01.426924794Z`.
  final DateTime phenomenonTime;

  /// The result of this observation.
  final R result;

  /// The result time of this observation, in the format: `2022-11-04T07:40:01.426926419Z`.
  final DateTime resultTime;

  const Observation({
    required this.phenomenonTime,
    required this.result,
    required this.resultTime,
  });
}

enum PrimarySignalState {
  dark,
  red,
  amber,
  green,
  redamber,
  amberflashing,
  greenflashing,
  unknown,
}

extension PrimarySignalStateExtension on PrimarySignalState {
  static PrimarySignalState fromRawValue(int rawValue) {
    switch (rawValue) {
      case 0:
        return PrimarySignalState.dark;
      case 1:
        return PrimarySignalState.red;
      case 2:
        return PrimarySignalState.amber;
      case 3:
        return PrimarySignalState.green;
      case 4:
        return PrimarySignalState.redamber;
      case 5:
        return PrimarySignalState.amberflashing;
      case 6:
        return PrimarySignalState.greenflashing;
      default:
        return PrimarySignalState.unknown;
    }
  }

  Color get color {
    switch (this) {
      case PrimarySignalState.dark:
        return Colors.black;
      case PrimarySignalState.red:
        return Colors.red;
      case PrimarySignalState.amber:
        return Colors.amber;
      case PrimarySignalState.green:
        return Colors.green;
      case PrimarySignalState.redamber:
        return Colors.red;
      case PrimarySignalState.amberflashing:
        return Colors.amber;
      case PrimarySignalState.greenflashing:
        return Colors.green;
      default:
        return Colors.black;
    }
  }
}

class PrimarySignalObservation extends Observation<int> {
  /// Get the value of the primary signal.
  PrimarySignalState get state => PrimarySignalStateExtension.fromRawValue(result);

  const PrimarySignalObservation({
    required super.phenomenonTime,
    required super.result,
    required super.resultTime,
  });

  factory PrimarySignalObservation.fromJson(Map<String, dynamic> json) => PrimarySignalObservation(
        phenomenonTime: DateTime.parse(json['phenomenonTime']),
        result: json['result'],
        resultTime: DateTime.parse(json['resultTime']),
      );
}

class DetectorCarObservation extends Observation<int> {
  /// Get the percentage value of the car detector.
  int get pct => result;

  const DetectorCarObservation({
    required super.phenomenonTime,
    required super.result,
    required super.resultTime,
  });

  factory DetectorCarObservation.fromJson(Map<String, dynamic> json) => DetectorCarObservation(
        phenomenonTime: DateTime.parse(json['phenomenonTime']),
        result: json['result'],
        resultTime: DateTime.parse(json['resultTime']),
      );
}

class DetectorCyclistsObservation extends Observation<int> {
  /// Get the percentage value of the cyclists detector.
  int get pct => result;

  const DetectorCyclistsObservation({
    required super.phenomenonTime,
    required super.result,
    required super.resultTime,
  });

  factory DetectorCyclistsObservation.fromJson(Map<String, dynamic> json) => DetectorCyclistsObservation(
        phenomenonTime: DateTime.parse(json['phenomenonTime']),
        result: json['result'],
        resultTime: DateTime.parse(json['resultTime']),
      );
}

class CycleSecondObservation extends Observation<int> {
  /// Get the value of the cycle second.
  int get second => result;

  const CycleSecondObservation({
    required super.phenomenonTime,
    required super.result,
    required super.resultTime,
  });

  factory CycleSecondObservation.fromJson(Map<String, dynamic> json) => CycleSecondObservation(
        phenomenonTime: DateTime.parse(json['phenomenonTime']),
        result: json['result'],
        resultTime: DateTime.parse(json['resultTime']),
      );
}

class SignalProgramObservation extends Observation<int> {
  /// Get the value of the signal program.
  int get program => result;

  const SignalProgramObservation({
    required super.phenomenonTime,
    required super.result,
    required super.resultTime,
  });

  factory SignalProgramObservation.fromJson(Map<String, dynamic> json) => SignalProgramObservation(
        phenomenonTime: DateTime.parse(json['phenomenonTime']),
        result: json['result'],
        resultTime: DateTime.parse(json['resultTime']),
      );
}
