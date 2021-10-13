import 'package:priobike/models/point.dart';

class Sg {
  String id = '';
  String label = '';
  Point position = Point(lat: 0, lon: 0);

  Sg({required this.id, required this.label});

  Sg.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    label = json['label'];
    position = Point.fromJson(json['position']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['label'] = label;
    data['position'] = position.toJson();
    return data;
  }
}
