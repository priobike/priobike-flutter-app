import 'package:priobike/common/models/point.dart';

class Sg {
  /// The id of the signal group.
  final String id;

  /// The label of the signal group.
  final String label;

  /// The position of the signal group.
  final Point position;

  /// The bearing of the start of the signal group.
  final double? bearingStart;

  /// The bearing of the end of the signal group.
  final double? bearingEnd;

  /// The datastream id for a car detector, if exists (layerType == detector_car).
  final String? datastreamDetectorCar;

  /// The datastream id for a cyclists detector, if exists (layerType == detector_cyclists).
  final String? datastreamDetectorCyclists;

  /// The datastream id for the cycle second, if exists (layerType == cycle_second).
  final String? datastreamCycleSecond;

  /// The datastream id for the primary signal, if exists (layerType == primary_signal).
  final String? datastreamPrimarySignal;

  /// The datastream id for the signal program, if exists (layerType == signal_program).
  final String? datastreamSignalProgram;

  const Sg({
    required this.id,
    required this.label,
    required this.position,
    this.bearingStart,
    this.bearingEnd,
    this.datastreamDetectorCar,
    this.datastreamDetectorCyclists,
    this.datastreamCycleSecond,
    this.datastreamPrimarySignal,
    this.datastreamSignalProgram,
  });

  factory Sg.fromJson(Map<String, dynamic> json) => Sg(
        id: json['id'],
        label: json['label'],
        position: Point.fromJson(json['position']),
        bearingStart: json['bearingStart'],
        bearingEnd: json['bearingEnd'],
        datastreamDetectorCar: json['datastreamDetectorCar'],
        datastreamDetectorCyclists: json['datastreamDetectorCyclists'],
        datastreamCycleSecond: json['datastreamCycleSecond'],
        datastreamPrimarySignal: json['datastreamPrimarySignal'],
        datastreamSignalProgram: json['datastreamSignalProgram'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'position': position.toJson(),
        'bearingStart': bearingStart,
        'bearingEnd': bearingEnd,
        'datastreamDetectorCar': datastreamDetectorCar,
        'datastreamDetectorCyclists': datastreamDetectorCyclists,
        'datastreamCycleSecond': datastreamCycleSecond,
        'datastreamPrimarySignal': datastreamPrimarySignal,
        'datastreamSignalProgram': datastreamSignalProgram,
      };
}
