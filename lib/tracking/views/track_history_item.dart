import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'package:priobike/tracking/models/track.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/tracking/views/pictogram.dart';
import 'package:priobike/tracking/views/track_details.dart';

class TrackHistoryItemView extends StatefulWidget {
  /// The track to display.
  final Track track;

  /// The width of the view.
  final double width;

  /// The image of the route start icon.
  final ui.Image startImage;

  /// The image of the route destination icon.
  final ui.Image destinationImage;

  const TrackHistoryItemView({
    Key? key,
    required this.track,
    required this.width,
    required this.startImage,
    required this.destinationImage,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => TrackHistoryItemViewState();
}

class TrackHistoryItemViewState extends State<TrackHistoryItemView> {
  /// The distance model.
  final vincenty = const Distance(roundResult: false);

  /// The GPS positions of the driven route.
  List<Position> positions = [];

  /// The driven distance in meters.
  double? distanceMeters;

  /// The duration of the track in seconds.
  int? durationSeconds;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        await loadTrack();
        if (mounted) setState(() {});
      },
    );
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
    durationSeconds = (totalDuration / 1000).floorToDouble().toInt();
  }

  /// Show a dialog that asks if the track really shoud be deleted.
  void showDeleteDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.4),
      pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        return DialogLayout(
          title: 'Fahrt löschen',
          text: "Bitte bestätige, dass du diese Fahrt löschen möchtest.",
          icon: Icons.delete_rounded,
          iconColor: Theme.of(context).colorScheme.primary,
          actions: [
            BigButton(
              iconColor: Colors.white,
              icon: Icons.delete_forever_rounded,
              fillColor: CI.red,
              label: "Löschen",
              onPressed: () {
                getIt<Tracking>().deleteTrack(widget.track);
                Navigator.of(context).pop();
              },
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
            ),
            BigButton(
              label: "Abbrechen",
              onPressed: () => Navigator.of(context).pop(),
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the relative date
    var relativeTime = "";
    final now = DateTime.now();
    final trackDate = DateTime.fromMillisecondsSinceEpoch(widget.track.startTime);
    final isToday = trackDate.day == now.day && trackDate.month == now.month && trackDate.year == now.year;
    if (isToday) {
      relativeTime = "Heute";
    } else {
      final yesterday = now.subtract(const Duration(days: 1));
      if (trackDate.day == yesterday.day && trackDate.month == yesterday.month && trackDate.year == yesterday.year) {
        relativeTime = "Gestern";
      } else {
        relativeTime = DateFormat('dd.MM.yy', 'de_DE').format(trackDate);
      }
    }
    // Add the time.
    final clock = "${DateFormat('HH:mm', 'de_DE').format(trackDate)} Uhr";

    // Determine the duration.
    final trackDurationFormatted = durationSeconds != null
        ? '${(durationSeconds! ~/ 60).toString().padLeft(2, '0')}:${(durationSeconds! % 60).toString().padLeft(2, '0')}\nMinuten'
        : null;

    return SizedBox(
      width: widget.width,
      height: widget.width,
      child: Tile(
        borderRadius: BorderRadius.circular(24),
        onPressed: () => showAppSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => TrackDetailsDialog(
              track: widget.track, startImage: widget.startImage, destinationImage: widget.destinationImage),
        ),
        shadow: const Color.fromARGB(255, 0, 0, 0),
        shadowIntensity: 0.08,
        padding: const EdgeInsets.all(1),
        fill: Theme.of(context).colorScheme.background,
        splash: Theme.of(context).colorScheme.primary,
        content: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            if (positions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(2),
                child: TrackPictogram(
                  key: ValueKey(widget.track.sessionId),
                  track: positions,
                  startImage: widget.startImage,
                  destinationImage: widget.destinationImage,
                  blurRadius: 0,
                  showSpeedLegend: false,
                ),
              ),
            Positioned(
                top: 12,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BoldContent(
                      text: relativeTime,
                      context: context,
                    ),
                    Small(
                      text: clock,
                      context: context,
                    )
                  ],
                )),
            if (trackDurationFormatted != null)
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4, left: 6, right: 6),
                    child: Small(
                      text: trackDurationFormatted,
                      context: context,
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                height: 42,
                width: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.white.withOpacity(0.75)
                      : Colors.black.withOpacity(0.25),
                ),
                child: IconButton(
                  onPressed: () => showDeleteDialog(context),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.delete_rounded,
                    size: 24,
                    color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                  ),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
