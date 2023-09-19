
import 'package:flutter/material.dart';

/// This object holds information about a weekend event pulled from the server.
class WeekendEvent {
  /// Unique id of the event.
  final int id;

  /// Title given to the event.
  final String title;

  /// Description of the event.
  final String description;

  /// Time where the event starts and the user gets access to its locations.
  final DateTime startTime;

  /// Time the event ends.
  final DateTime endTime;

  /// Color corresponding to the event as an int.
  final int colorValue;

  IconData get icon => IconData(colorValue, fontFamily: 'MaterialIcons');

  WeekendEvent(this.id, this.title, this.description, this.startTime, this.endTime, this.colorValue);

  WeekendEvent.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        description = json['description'],
        startTime = DateTime.fromMillisecondsSinceEpoch(json['startTime']),
        endTime = DateTime.fromMillisecondsSinceEpoch(json['endTime']),
        colorValue = json['color'];
}
