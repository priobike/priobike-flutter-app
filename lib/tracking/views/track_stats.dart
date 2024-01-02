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
          : '${distanceMeters!.toStringAsFixed(2)} m';
    }
    String speedText = 'Ø --- km/h';
    if (averageSpeedKmH != null) speedText = 'Ø ${averageSpeedKmH!.toStringAsFixed(2)} km/h';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Content(
                text: "Dauer",
                context: context,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
              ),
              BoldContent(text: timeText, context: context),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Content(
                text: "Distanz",
                context: context,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
              ),
              BoldContent(
                text: distanceText,
                context: context,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Content(
                text: "Geschwindigkeit",
                context: context,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
              ),
              BoldContent(text: speedText, context: context),
            ],
          ),
        ),
      ],
    );
  }
}
