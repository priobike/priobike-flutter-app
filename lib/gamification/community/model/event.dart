import 'package:flutter/material.dart';

class CommunityEvent {
  final int id;

  final String title;

  final String description;

  final DateTime startTime;

  final DateTime endTime;

  final int colorValue;

  Color get color => Color(colorValue);

  CommunityEvent(this.id, this.title, this.description, this.startTime, this.endTime, this.colorValue);

  CommunityEvent.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        description = json['description'],
        startTime = DateTime.fromMillisecondsSinceEpoch(json['startTime']),
        endTime = DateTime.fromMillisecondsSinceEpoch(json['endTime']),
        colorValue = json['color'];
}
