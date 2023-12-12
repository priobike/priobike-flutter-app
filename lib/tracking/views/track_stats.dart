import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';

/// A pictogram of a track.
class TrackStats extends StatelessWidget {
  final String? formattedTime;
  final double? distanceMeters;
  final num? averageSpeedKmH;
  final num? savedCo2inG;

  const TrackStats({
    super.key,
    this.formattedTime,
    this.distanceMeters,
    this.averageSpeedKmH,
    this.savedCo2inG,
  });

  @override
  Widget build(BuildContext context) {
    String timeText = '--- s';
    if (formattedTime != null) timeText = formattedTime!;
    String distanceText = '--- m';
    if (distanceMeters != null) {
      distanceText = distanceMeters! >= 1000
          ? '${(distanceMeters! / 1000).toStringAsFixed(2)} km'
          : '${distanceMeters!.toStringAsFixed(0)} m';
    }
    String speedText = 'Ø --- km/h';
    if (averageSpeedKmH != null) speedText = 'Ø ${averageSpeedKmH!.toStringAsFixed(2)} km/h';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background.withOpacity(0.75),
              border: Border.all(width: 1, color: Theme.of(context).colorScheme.tertiary.withOpacity(0.25)),
              borderRadius: const BorderRadius.all(Radius.circular(15))),
          child: Column(
            children: [
              Content(text: "Dauer", context: context),
              BoldContent(text: timeText, context: context),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background.withOpacity(0.75),
              border: Border.all(width: 1, color: Theme.of(context).colorScheme.tertiary.withOpacity(0.25)),
              borderRadius: const BorderRadius.all(Radius.circular(15))),
          child: Column(
            children: [
              Content(text: "Distanz", context: context),
              BoldContent(text: distanceText, context: context),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background.withOpacity(0.75),
              border: Border.all(width: 1, color: Theme.of(context).colorScheme.tertiary.withOpacity(0.25)),
              borderRadius: const BorderRadius.all(Radius.circular(15))),
          child: Column(
            children: [
              Content(text: "Geschwindigkeit", context: context),
              BoldContent(text: speedText, context: context),
            ],
          ),
        ),
      ],
    );
  }
}
