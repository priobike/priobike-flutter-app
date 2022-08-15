import 'package:priobike/common/models/point.dart';

class Sg {
  final String id;
  final String label;
  final Point position;

  const Sg({required this.id, required this.label, required this.position});

  factory Sg.fromJson(Map<String, dynamic> json) {
    return Sg(
      id: json['id'],
      label: json['label'],
      position: Point.fromJson(json['position']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['label'] = label;
    data['position'] = position.toJson();
    return data;
  }
}
