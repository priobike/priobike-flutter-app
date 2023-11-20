import 'package:flutter/material.dart';

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
    final headerTextStyle = TextStyle(
      fontSize: 11,
      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
    );

    final cellTextStyle = TextStyle(
      fontSize: 14,
      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
    );

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
    String co2Text = '--- g';
    if (savedCo2inG != null) {
      co2Text = savedCo2inG! >= 1000
          ? "${(savedCo2inG! / 1000).toStringAsFixed(2)} kg"
          : "${savedCo2inG!.toStringAsFixed(2)} g";
    }
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      direction: Axis.horizontal,
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      children: [
        Column(
          children: [
            Text("Dauer", style: headerTextStyle),
            Text(timeText, style: cellTextStyle),
          ],
        ),
        Column(
          children: [
            Text("Distanz", style: headerTextStyle),
            Text(distanceText, style: cellTextStyle),
          ],
        ),
        Column(
          children: [
            Text("Geschwindigkeit", style: headerTextStyle),
            Text(speedText, style: cellTextStyle),
          ],
        ),
        Column(
          children: [
            Text("CO2 gespart", style: headerTextStyle),
            Text(co2Text, style: cellTextStyle),
          ],
        ),
      ],
    );
  }
}
