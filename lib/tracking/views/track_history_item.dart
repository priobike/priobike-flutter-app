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
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'package:priobike/tracking/models/track.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/tracking/views/pictogram.dart';
import 'package:priobike/tracking/views/track_stats.dart';

mixin TrackHistoryItem {
  /// The distance model.
  final vincenty = const Distance(roundResult: false);

  /// The GPS positions of the driven route.
  List<Position> positions = [];

  /// The driven distance in meters.
  double? distanceMeters;

  /// The duration of the track in seconds.
  int? durationSeconds;

  /// Load the track.
  Future<void> _loadTrack(Track track) async {
    if (positions.isNotEmpty) return;

    // Try to load the GPS file.
    // For old tracks where we deleted the GPS csv file after uploading the data to the tracking service this is not possible.
    try {
      final gpsFile = await track.gpsCSVFile;
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
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          ),
        );
      }

      _loadTrackSummary();
    } catch (e) {
      log.w('Could not parse GPS file of last track: $e');
    }
  }

  /// Load the track summary and calculate the driven distance & duration.
  void _loadTrackSummary() {
    if (positions.isEmpty) return;

    final coordinates = positions.map((e) => LatLng(e.latitude, e.longitude)).toList();
    var totalDistance = 0.0;
    for (var i = 0; i < positions.length - 1; i++) {
      totalDistance += vincenty.distance(coordinates[i], coordinates[i + 1]);
    }
    // Aggregate the duration.
    final start = positions.first.timestamp;
    final end = positions.last.timestamp;
    final totalDuration = end.difference(start).inMilliseconds;

    // Create the summary.
    distanceMeters = totalDistance;
    durationSeconds = (totalDuration / 1000).floorToDouble().toInt();
  }
}

class TrackHistoryItemTileView extends StatefulWidget {
  /// The track to display.
  final Track track;

  /// The width of the view.
  final double? width;

  /// The image of the route start icon.
  final ui.Image startImage;

  /// The image of the route destination icon.
  final ui.Image destinationImage;

  const TrackHistoryItemTileView({
    super.key,
    required this.track,
    required this.startImage,
    required this.destinationImage,
    this.width,
  });

  @override
  State<StatefulWidget> createState() => TrackHistoryItemTileViewState();
}

class TrackHistoryItemTileViewState extends State<TrackHistoryItemTileView> with TrackHistoryItem {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting();

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        await _loadTrack(widget.track);
        if (mounted) setState(() {});
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
          builder: (context) => TrackHistoryItemAppSheetView(
            track: widget.track,
            startImage: widget.startImage,
            destinationImage: widget.destinationImage,
            height: MediaQuery.of(context).size.width - 40,
          ),
        ),
        shadow: const Color.fromARGB(255, 0, 0, 0),
        shadowIntensity: 0.08,
        padding: const EdgeInsets.all(1),
        fill: Theme.of(context).colorScheme.surfaceVariant,
        splash: Theme.of(context).colorScheme.surfaceTint,
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
                  onPressed: () => _showDeleteDialog(context),
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

  /// Show a dialog that asks if the track really shoud be deleted.
  void _showDeleteDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.4),
      pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        return DialogLayout(
          title: 'Fahrt löschen',
          text: "Bitte bestätige, dass Du diese Fahrt löschen möchtest.",
          actions: [
            BigButtonPrimary(
              textColor: Colors.black,
              fillColor: CI.radkulturYellow,
              label: "Löschen",
              onPressed: () {
                getIt<Tracking>().deleteTrack(widget.track);
                Navigator.of(context).pop();
              },
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
            ),
            BigButtonTertiary(
              label: "Abbrechen",
              onPressed: () => Navigator.of(context).pop(),
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
            ),
          ],
        );
      },
    );
  }
}

class TrackHistoryItemDetailView extends StatefulWidget {
  /// The track to display.
  final Track track;

  /// The width of the view.
  final double? width;

  /// The height of this widget.
  final double? height;

  /// The image of the route start icon.
  final ui.Image startImage;

  /// The image of the route destination icon.
  final ui.Image destinationImage;

  const TrackHistoryItemDetailView({
    super.key,
    required this.track,
    required this.startImage,
    required this.destinationImage,
    this.width,
    this.height,
  });

  @override
  State<StatefulWidget> createState() => TrackHistoryItemDetailViewState();
}

class TrackHistoryItemDetailViewState extends State<TrackHistoryItemDetailView> with TrackHistoryItem {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadTrack(widget.track),
      builder: (context, snapshot) {
        final totalDurationHours = durationSeconds == null ? 0 : durationSeconds! / 3600;
        final totalDistanceKilometres = distanceMeters == null ? 0 : distanceMeters! / 1000;
        final averageSpeedKmH = totalDurationHours == 0 ? 0 : (totalDistanceKilometres / totalDurationHours);

        String? formattedTime = _formatDuration(durationSeconds);

        const co2PerKm = 0.1187; // Data according to statista.com in KG
        final savedCo2inG =
            distanceMeters == null && durationSeconds == null ? 0 : (distanceMeters! / 1000) * co2PerKm * 1000;

        final Widget trackStats;
        if (distanceMeters != null && durationSeconds != null && formattedTime != null) {
          trackStats = TrackStats(
            formattedTime: formattedTime,
            distanceMeters: distanceMeters,
            averageSpeedKmH: averageSpeedKmH,
            savedCo2inG: savedCo2inG,
          );
        } else {
          trackStats = const TrackStats();
        }

        Widget content = Tile(
          padding: const EdgeInsets.all(0),
          borderRadius: BorderRadius.circular(20),
          content: const SizedBox(
            height: 64,
            width: 64,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );

        if (snapshot.connectionState == ConnectionState.done) {
          content = positions.isNotEmpty
              ? TrackPictogram(
                  key: ValueKey(widget.track.sessionId),
                  track: positions,
                  blurRadius: 2,
                  startImage: widget.startImage,
                  destinationImage: widget.destinationImage,
                  iconSize: 16,
                  lineWidth: 6,
                  imageWidthRatio: (widget.width ?? MediaQuery.of(context).size.width) /
                      (widget.height ?? MediaQuery.of(context).size.height),
                  mapboxTop: MediaQuery.of(context).padding.top + 10,
                  mapboxRight: 20,
                  mapboxWidth: 64,
                  // Padding + 2 * button height + padding + padding bottom.
                  speedLegendBottom: 20 + 2 * 64 + 20 + MediaQuery.of(context).padding.bottom,
                  speedLegendLeft: 20,
                )
              : Center(
                  child: Small(context: context, text: "Keine GPS-Daten für diesen Track"),
                );
        }

        return SizedBox(
          height: widget.height ?? MediaQuery.of(context).size.height,
          width: widget.width ?? MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              content,
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 20,
                right: 20,
                child: Content(
                  text: "Deine Fahrt",
                  context: context,
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 40,
                left: 20,
                right: 20,
                child: trackStats,
              )
            ],
          ),
        );
      },
    );
  }
}

class TrackHistoryItemAppSheetView extends StatefulWidget {
  /// The track to display.
  final Track track;

  /// The height of this widget.
  final double height;

  /// The image of the route start icon.
  final ui.Image startImage;

  /// The image of the route destination icon.
  final ui.Image destinationImage;

  const TrackHistoryItemAppSheetView({
    super.key,
    required this.track,
    required this.startImage,
    required this.destinationImage,
    required this.height,
  });

  @override
  State<StatefulWidget> createState() => TrackHistoryItemAppSheetViewState();
}

class TrackHistoryItemAppSheetViewState extends State<TrackHistoryItemAppSheetView> with TrackHistoryItem {
  /// The widget that displays the track on a map.
  Widget trackPictogram = Container();

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      // Create TrackHistory once to prevent getting rebuild on every setState.
      setState(() {
        trackPictogram = TrackPictogram(
          key: ValueKey(widget.track.sessionId),
          track: positions,
          blurRadius: 2,
          startImage: widget.startImage,
          destinationImage: widget.destinationImage,
          iconSize: 16,
          lineWidth: 6,
          imageWidthRatio: 1,
          mapboxTop: MediaQuery.of(context).padding.top + 10,
          mapboxRight: 20,
          mapboxWidth: 64,
        );
      });
    });
    initializeDateFormatting();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadTrack(widget.track),
      builder: (context, snapshot) {
        final totalDurationHours = durationSeconds == null ? 0 : durationSeconds! / 3600;
        final totalDistanceKilometres = distanceMeters == null ? 0 : distanceMeters! / 1000;
        final averageSpeedKmH = totalDurationHours == 0 ? 0 : (totalDistanceKilometres / totalDurationHours);

        String? formattedTime = _formatDuration(durationSeconds);

        const co2PerKm = 0.1187; // Data according to statista.com in KG
        final savedCo2inG =
            distanceMeters == null && durationSeconds == null ? 0 : (distanceMeters! / 1000) * co2PerKm * 1000;

        var relativeTime = "";
        final now = DateTime.now();
        final trackDate = DateTime.fromMillisecondsSinceEpoch(widget.track.startTime);
        final isToday = trackDate.day == now.day && trackDate.month == now.month && trackDate.year == now.year;
        if (isToday) {
          relativeTime = "Heute";
        } else {
          final yesterday = now.subtract(const Duration(days: 1));
          if (trackDate.day == yesterday.day &&
              trackDate.month == yesterday.month &&
              trackDate.year == yesterday.year) {
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

        final Widget trackStats;
        if (distanceMeters != null && durationSeconds != null && formattedTime != null) {
          trackStats = TrackStats(
            formattedTime: formattedTime,
            distanceMeters: distanceMeters,
            averageSpeedKmH: averageSpeedKmH,
            savedCo2inG: savedCo2inG,
          );
        } else {
          trackStats = const TrackStats();
        }

        return Container(
          // VSpace + Content + SmallVSpace + Track map size + 20 + Details + padding + 44 Stats.
          height: (24 + 32 + 8 + widget.height + 20 + 62 + 8 + MediaQuery.of(context).padding.bottom),
          // width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Theme.of(context).colorScheme.background,
          ),
          child: Column(
            children: [
              const VSpace(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    BoldContent(text: relativeTime, context: context),
                    Content(text: clock, context: context),
                  ]),
                  Content(
                    text: trackDurationFormatted ?? "",
                    context: context,
                    textAlign: TextAlign.end,
                  ),
                ]),
              ),
              const SmallVSpace(),
              SizedBox(width: MediaQuery.of(context).size.width - 40, height: widget.height, child: trackPictogram),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: trackStats,
              ),
              const SmallVSpace(),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Helper method to format the duration of the track.
String? _formatDuration(int? durationSeconds) {
  if (durationSeconds == null) return null;
  if (durationSeconds < 60) {
    // Show only seconds.
    final seconds = durationSeconds.floor();
    return "$seconds s";
  } else if (durationSeconds < 3600) {
    // Show minutes and seconds.
    final minutes = (durationSeconds / 60).floor();
    final seconds = (durationSeconds - (minutes * 60)).floor();
    return "${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")} min";
  } else {
    // Show only hours and minutes.
    final hours = (durationSeconds / 3600).floor();
    final minutes = ((durationSeconds - (hours * 3600)) / 60).floor();
    return "${hours.toString().padLeft(2, "0")}:${minutes.toString().padLeft(2, "0")} h";
  }
}
