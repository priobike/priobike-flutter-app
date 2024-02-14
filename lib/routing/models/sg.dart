import 'package:priobike/common/models/point.dart';

class Sg {
  /// The id of the signal group.
  final String id;

  /// The label of the signal group.
  final String label;

  /// The position of the signal group.
  final Point position;

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

  /// The bearing of the signal group.
  final double? bearing;

  const Sg({
    required this.id,
    required this.label,
    required this.position,
    this.datastreamDetectorCar,
    this.datastreamDetectorCyclists,
    this.datastreamCycleSecond,
    this.datastreamPrimarySignal,
    this.datastreamSignalProgram,
    this.bearing,
  });

  factory Sg.fromJson(Map<String, dynamic> json) => Sg(
        id: json['id'],
        label: json['label'],
        position: Point.fromJson(json['position']),
        datastreamDetectorCar: json['datastreamDetectorCar'],
        datastreamDetectorCyclists: json['datastreamDetectorCyclists'],
        datastreamCycleSecond: json['datastreamCycleSecond'],
        datastreamPrimarySignal: json['datastreamPrimarySignal'],
        datastreamSignalProgram: json['datastreamSignalProgram'],
        bearing: json['bearing'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'position': position.toJson(),
        'datastreamDetectorCar': datastreamDetectorCar,
        'datastreamDetectorCyclists': datastreamDetectorCyclists,
        'datastreamCycleSecond': datastreamCycleSecond,
        'datastreamPrimarySignal': datastreamPrimarySignal,
        'datastreamSignalProgram': datastreamSignalProgram,
        'bearing': bearing,
      };
}
