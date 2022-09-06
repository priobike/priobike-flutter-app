import 'package:flutter/material.dart';

enum RidePreference {
  speedometerView,
  defaultCyclingView,
  minimalRecommendationCyclingView,
  minimalCountdownCyclingView,
  minimalNavigationCyclingView,
}

extension RidePreferenceDescription on RidePreference {
  String get description {
    switch (this) {
      case RidePreference.speedometerView: return "Tacho-Ansicht mit Karte und Navigation";
      case RidePreference.defaultCyclingView: return "Empfehlungs-Ansicht mit Navigation";
      case RidePreference.minimalRecommendationCyclingView: return "Nur Langsamer/Schneller";
      case RidePreference.minimalCountdownCyclingView: return "Nur Countdown";
      case RidePreference.minimalNavigationCyclingView: return "Nur Navigation von Oben";
    }
  }
}

extension RidePreferenceIcon on RidePreference {
  Widget get icon {
    switch (this) {
      case RidePreference.speedometerView: 
        return const Icon(Icons.speed, size: 32);
      case RidePreference.defaultCyclingView: 
        return const Icon(Icons.horizontal_distribute, size: 32);
      case RidePreference.minimalRecommendationCyclingView: 
        return Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Icon(Icons.arrow_upward, size: 32),
          Icon(Icons.arrow_downward, size: 32),
        ]);
      case RidePreference.minimalCountdownCyclingView: 
        return Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Icon(Icons.av_timer, size: 32),
          /// Can't use Theme here cause it's not in a build context
          Text(
                "4s",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF000000)),
              ),
            ]);
      case RidePreference.minimalNavigationCyclingView:
        return Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Icon(Icons.roundabout_left, size: 32),
          /// Can't use Theme here cause it's not in a build context
          Text(
            "...",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: Color(0xFF000000)),
          ),
        ]);
    }
  }
}