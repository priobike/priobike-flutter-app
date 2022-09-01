import 'package:flutter/material.dart';

enum BikeType {
  bike,
  ebike,
  racingbike,
  mountainbike,
  cargobike,
}

extension BikeTypeDescription on BikeType {
  String description() {
    switch (this) {
      case BikeType.bike: return "Standard";
      case BikeType.ebike: return "E-Bike";
      case BikeType.racingbike: return "Rennrad";
      case BikeType.mountainbike: return "MTB";
      case BikeType.cargobike: return "Lastenrad";
    }
  }
}

extension BikeTypeColor on BikeType {
  Color color() {
    switch (this) {
      case BikeType.bike: return const Color.fromRGBO(163, 203, 56,1.0);
      case BikeType.ebike: return const Color.fromRGBO(0, 148, 50,1.0);
      case BikeType.racingbike: return const Color.fromRGBO(234, 32, 39,1.0);
      case BikeType.mountainbike: return const Color.fromRGBO(6, 82, 221,1.0);
      case BikeType.cargobike: return const Color.fromRGBO(247, 159, 31,1.0);
    }
  }
}

extension BikeTypeIcon on BikeType {
  IconData icon() {
    switch (this) {
      case BikeType.bike: return Icons.pedal_bike;
      case BikeType.ebike: return Icons.electric_bike;
      case BikeType.racingbike: return Icons.directions_bike;
      case BikeType.mountainbike: return Icons.pedal_bike;
      case BikeType.cargobike: return Icons.pedal_bike;
    }
  }
}

enum PreferenceType {
  fast,
  short,
  comfortible,
}

extension PreferenceTypeDescription on PreferenceType {
  String description() {
    switch (this) {
      case PreferenceType.fast: return "Zeit";
      case PreferenceType.short: return "Distanz";
      case PreferenceType.comfortible: return "Komfort";
    }
  }
}

extension PreferenceTypeColor on PreferenceType {
  Color color() {
    switch (this) {
      case PreferenceType.fast: return const Color.fromRGBO(234, 32, 39,1.0);
      case PreferenceType.short: return const Color.fromRGBO(6, 82, 221,1.0);
      case PreferenceType.comfortible: return const Color.fromRGBO(163, 203, 56,1.0);
    }
  }
}

extension PreferenceTypeIcon on PreferenceType {
  IconData icon() {
    switch (this) {
      case PreferenceType.fast: return Icons.access_time;
      case PreferenceType.short: return Icons.straighten;
      case PreferenceType.comfortible: return Icons.chair;
    }
  }
}

enum ActivityType {
  work,
  sport,
}

extension ActivityTypeColor on ActivityType {
  Color color() {
    switch (this) {
      case ActivityType.work: return const Color.fromRGBO(6, 82, 221,1.0);
      case ActivityType.sport: return const Color.fromRGBO(234, 32, 39,1.0);
    }
  }
}

extension ActivityTypeIcon on ActivityType {
  IconData icon() {
    switch (this) {
      case ActivityType.work: return Icons.work;
      case ActivityType.sport: return Icons.sports_gymnastics;
    }
  }
}

extension ActivityTypeDescription on ActivityType {
  String description() {
    switch (this) {
      case ActivityType.work: return "Arbeit";
      case ActivityType.sport: return "Sport";
    }
  }
}