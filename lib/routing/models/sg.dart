import 'package:priobike/common/models/point.dart';

class Sg {
  final String id;
  final String label;
  final Point position;

  const Sg({required this.id, required this.label, required this.position});

  factory Sg.fromJson(Map<String, dynamic> json) => Sg(
    id: json['id'],
    label: json['label'],
    position: Point.fromJson(json['position']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'position': position.toJson(),
  };
}
