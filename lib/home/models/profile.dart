import 'package:flutter/material.dart';

enum BikeType {
  ebike,
  racingbike,
  mountainbike,
  cargobike,
}

extension BikeTypeDescription on BikeType {
  String description() {
    switch (this) {
      case BikeType.ebike:
        return "E-Bike";
      case BikeType.racingbike:
        return "Rennrad";
      case BikeType.mountainbike:
        return "MTB";
      case BikeType.cargobike:
        return "Lastenrad";
    }
  }
}

extension BikeTypeIcon on BikeType {
  IconData icon() {
    switch (this) {
      case BikeType.ebike:
        return Icons.electric_bike_rounded;
      case BikeType.racingbike:
        return Icons.directions_bike_rounded;
      case BikeType.mountainbike:
        return Icons.pedal_bike_rounded;
      case BikeType.cargobike:
        return Icons.pedal_bike_rounded;
    }
  }
}

enum PreferenceType {
  fast,
  comfortible,
}

extension PreferenceTypeDescription on PreferenceType {
  String description() {
    switch (this) {
      case PreferenceType.fast:
        return "Zeit";
      case PreferenceType.comfortible:
        return "Komfort";
    }
  }
}

extension PreferenceTypeIcon on PreferenceType {
  IconData icon() {
    switch (this) {
      case PreferenceType.fast:
        return Icons.access_time_rounded;
      case PreferenceType.comfortible:
        return Icons.chair_rounded;
    }
  }
}

enum ActivityType {
  avoidIncline,
  allowIncline,
}

extension ActivityTypeIcon on ActivityType {
  IconData icon() {
    switch (this) {
      case ActivityType.avoidIncline:
        return Icons.trending_flat;
      case ActivityType.allowIncline:
        return Icons.trending_up;
    }
  }
}

extension ActivityTypeDescription on ActivityType {
  String description() {
    switch (this) {
      case ActivityType.avoidIncline:
        return "Anstieg vermeiden";
      case ActivityType.allowIncline:
        return "Anstieg erlauben";
    }
  }
}
