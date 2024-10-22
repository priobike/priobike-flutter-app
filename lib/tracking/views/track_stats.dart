import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
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
    bool showNoGPSDataWarning = formattedTime == null && distanceMeters == null && averageSpeedKmH == null;

    String timeText = '--- s';
    if (formattedTime != null) timeText = formattedTime!;
    String distanceText = '--- m';
    if (distanceMeters != null) {
      distanceText = distanceMeters! >= 1000
          ? '${(distanceMeters! / 1000).toStringAsFixed(2)} km'
          : '${distanceMeters!.toStringAsFixed(2)} m';
    }
    String speedText = 'Ø ---';
    if (averageSpeedKmH != null) speedText = 'Ø ${averageSpeedKmH!.toStringAsFixed(1)}';

    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            width: MediaQuery.of(context).size.width * 0.25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Small(
                  text: "Dauer",
                  context: context,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                BoldContent(text: timeText, context: context),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            width: MediaQuery.of(context).size.width * 0.25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Small(
                  text: "Distanz",
                  context: context,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                BoldContent(
                  text: distanceText,
                  context: context,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            width: MediaQuery.of(context).size.width * 0.25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Small(
                  text: "km/h",
                  context: context,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                BoldContent(text: speedText, context: context),
              ],
            ),
          ),
        ],
      ),
      if (showNoGPSDataWarning)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off),
            const SmallHSpace(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: BoldSmall(
                text: "Keine GPS-Daten vorhanden",
                context: context,
              ),
            ),
          ],
        )
    ]);
  }
}
