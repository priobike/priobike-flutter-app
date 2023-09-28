import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Route;
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'package:priobike/tracking/models/track.dart';
import 'package:priobike/tracking/views/pictogram.dart';

class TrackDetailsDialog extends StatelessWidget {
  /// The track to display.
  final Track track;

  /// The image of the start of the route.
  final ui.Image startImage;

  /// The image of the destination of the route.
  final ui.Image destinationImage;

  const TrackDetailsDialog({
    Key? key,
    required this.track,
    required this.startImage,
    required this.destinationImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Column(
          children: [
            TrackDetailsView(
              key: ValueKey(track.sessionId),
              track: track,
              startImage: startImage,
              destinationImage: destinationImage,
            ),
            const VSpace(),
          ],
        ),
      ],
    );
  }
}

class TrackDetailsView extends StatefulWidget {
  /// The track to display.
  final Track track;

  /// The image of the start of the route.
  final ui.Image startImage;

  /// The image of the destination of the route.
  final ui.Image destinationImage;

  const TrackDetailsView({
    Key? key,
    required this.track,
    required this.startImage,
    required this.destinationImage,
  }) : super(key: key);

  @override
  TrackDetailsViewState createState() => TrackDetailsViewState();
}

class TrackDetailsViewState extends State<TrackDetailsView> with TickerProviderStateMixin {
  /// The distance model.
  final vincenty = const Distance(roundResult: false);

  /// The GPS positions of the track.
  List<Position> positions = [];

  /// The driven distance in meters.
  double? distanceMeters;

  /// The duration of the track in seconds.
  double? durationSeconds;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        await loadTrack();
      },
    );
  }

  @override
  void didUpdateWidget(TrackDetailsView oldWidget) {
    loadTrack();
    super.didUpdateWidget(oldWidget);
  }

  /// Load the track.
  Future<void> loadTrack() async {
    if (positions.isNotEmpty) return;

    // Try to load the GPS file.
    // For old tracks where we deleted the GPS csv file after uploading the data to the tracking service this is not possible.
    try {
      final gpsFile = await widget.track.gpsCSVFile;
      final gpsFileLines = await gpsFile.readAsLines();
      // Skip the first line, which is the header.
      for (var i = 1; i < gpsFileLines.length; i++) {
        final lineContents = gpsFileLines[i].split(',');
        final time = int.parse(lineContents[0]);
        final lon = double.parse(lineContents[1]);
        final lat = double.parse(lineContents[2]);
        final speed = double.parse(lineContents[3]);
        final accuracy = double.parse(lineContents[4]);
        positions.add(
          Position(
            timestamp: DateTime.fromMillisecondsSinceEpoch(time),
            latitude: lat,
            longitude: lon,
            speed: speed,
            accuracy: accuracy,
            altitude: 0,
            heading: 0,
            speedAccuracy: 0,
          ),
        );
      }

      loadTrackSummary();

      setState(() {});
    } catch (e) {
      log.w('Could not parse GPS file of last track: $e');
    }
  }

  /// Load the track summary and calculate the driven distance & duration.
  void loadTrackSummary() {
    if (positions.isEmpty) return;

    final coordinates = positions.map((e) => LatLng(e.latitude, e.longitude)).toList();
    var totalDistance = 0.0;
    for (var i = 0; i < positions.length - 1; i++) {
      totalDistance += vincenty.distance(coordinates[i], coordinates[i + 1]);
    }
    // Aggregate the duration.
    final start = positions.first.timestamp;
    final end = positions.last.timestamp;
    if (end == null || start == null) return;
    final totalDuration = end.difference(start).inMilliseconds;

    // Create the summary.
    distanceMeters = totalDistance;
    durationSeconds = totalDuration / 1000;
  }

  /// Helper method to format the duration of the track.
  String? _formatDuration() {
    if (durationSeconds == null) return null;
    if (durationSeconds! < 60) {
      // Show only seconds.
      final seconds = durationSeconds!.floor();
      return "$seconds s";
    } else if (durationSeconds! < 3600) {
      // Show minutes and seconds.
      final minutes = (durationSeconds! / 60).floor();
      final seconds = (durationSeconds! - (minutes * 60)).floor();
      return "${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")} min";
    } else {
      // Show only hours and minutes.
      final hours = (durationSeconds! / 3600).floor();
      final minutes = ((durationSeconds! - (hours * 3600)) / 60).floor();
      return "${hours.toString().padLeft(2, "0")}:${minutes.toString().padLeft(2, "0")} h";
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastTrackDate = DateTime.fromMillisecondsSinceEpoch(widget.track.startTime);
    final lastTrackDateFormatted = DateFormat.yMMMMd("de").format(lastTrackDate);

    final headerTextStyle = TextStyle(
      fontSize: 11,
      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
    );

    final cellTextStyle = TextStyle(
      fontSize: 14,
      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
    );

    final totalDurationHours = durationSeconds == null ? 0 : durationSeconds! / 3600;
    final totalDistanceKilometres = distanceMeters == null ? 0 : distanceMeters! / 1000;
    final averageSpeedKmH = totalDurationHours == 0 ? 0 : (totalDistanceKilometres / totalDurationHours);

    String? formattedTime = _formatDuration();

    const co2PerKm = 0.1187; // Data according to statista.com in KG
    final savedCo2inG = distanceMeters == null ? 0 : (distanceMeters! / 1000) * co2PerKm * 1000;

    final List<Widget> rideDetails;
    if (distanceMeters != null && durationSeconds != null && formattedTime != null) {
      rideDetails = [
        Column(
          children: [
            Text(
              "Dauer",
              style: headerTextStyle,
            ),
            Text(
              formattedTime,
              style: cellTextStyle,
            ),
          ],
        ),
        Column(
          children: [
            Text(
              "Distanz",
              style: headerTextStyle,
            ),
            Text(
              distanceMeters! >= 1000
                  ? "${(distanceMeters! / 1000).toStringAsFixed(2)} km"
                  : "${distanceMeters!.toStringAsFixed(0)} m",
              style: cellTextStyle,
            ),
          ],
        ),
        Column(
          children: [
            Text(
              "Geschwindigkeit",
              style: headerTextStyle,
            ),
            Text(
              "Ø ${averageSpeedKmH.toStringAsFixed(2)} km/h",
              style: cellTextStyle,
            ),
          ],
        ),
        Column(
          children: [
            Text(
              "CO2 gespart",
              style: headerTextStyle,
            ),
            Text(
              savedCo2inG >= 1000
                  ? "${(savedCo2inG / 1000).toStringAsFixed(2)} kg"
                  : "${savedCo2inG.toStringAsFixed(2)} g",
              style: cellTextStyle,
            ),
          ],
        ),
      ];
    } else {
      rideDetails = [];
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BoldContent(text: "Deine Fahrt vom", context: context),
                  Content(
                    text: lastTrackDateFormatted,
                    context: context,
                    color: Theme.of(context).colorScheme.onBackground,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SmallVSpace(),
            Container(
              // use width as height to make it a square
              height: MediaQuery.of(context).size.width,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(24),
              child: positions.isNotEmpty
                  ? Tile(
                      padding: const EdgeInsets.all(0),
                      borderRadius: BorderRadius.circular(20),
                      content: TrackPictogram(
                        key: ValueKey(widget.track.sessionId),
                        track: positions,
                        colors: const [
                          CI.blue,
                          CI.red,
                        ],
                        blurRadius: 2,
                        startImage: widget.startImage,
                        destinationImage: widget.destinationImage,
                        iconSize: 16,
                        lineWidth: 6,
                      ),
                    )
                  : Center(
                      child: Small(context: context, text: "Keine GPS-Daten für diesen Track"),
                    ),
            ),
            if (rideDetails.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  direction: Axis.horizontal,
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  children: rideDetails,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
