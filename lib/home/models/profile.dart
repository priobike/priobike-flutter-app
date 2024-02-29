import 'package:flutter/material.dart';

enum BikeType {
  citybike,
  racingbike,
  mountainbike,
  cargobike,
}

extension BikeTypeDescription on BikeType {
  String description() {
    switch (this) {
      case BikeType.citybike:
        return "Stadtrad";
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
  IconData? icon() {
    switch (this) {
      case BikeType.citybike:
        return null;
      case BikeType.racingbike:
        return null;
      case BikeType.mountainbike:
        return null;
      case BikeType.cargobike:
        return null;
    }
  }
}

extension BikeTypeIconAsSting on BikeType {
  String? iconAsString() {
    switch (this) {
      case BikeType.citybike:
        return "assets/icons/fahrrad.png";
      case BikeType.racingbike:
        return "assets/icons/rennrad.png";
      case BikeType.mountainbike:
        return "assets/icons/mtb.png";
      case BikeType.cargobike:
        return "assets/icons/lastenrad.png";
    }
  }
}

enum PreferenceType {
  balanced,
  fast,
}

extension PreferenceTypeDescription on PreferenceType {
  String description() {
    switch (this) {
      case PreferenceType.balanced:
        return "Ausgeglichen";
      case PreferenceType.fast:
        return "Zeit";
    }
  }
}

extension PreferenceTypeIcon on PreferenceType {
  IconData icon() {
    switch (this) {
      case PreferenceType.balanced:
        return Icons.balance_rounded;
      case PreferenceType.fast:
        return Icons.access_time_outlined;
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
        return Icons.trending_flat_outlined;
      case ActivityType.allowIncline:
        return Icons.trending_up_outlined;
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
