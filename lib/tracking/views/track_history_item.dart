import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/formatting/duration.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/navigation.dart';
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

    _loadTrack(widget.track).then(
      (value) {
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

    // Determine the duration.
    final trackDurationFormatted = durationSeconds != null
        ? '${(durationSeconds! ~/ 60).toString().padLeft(2, '0')}:${(durationSeconds! % 60).toString().padLeft(2, '0')}\nMinuten'
        : "--:--\nMinuten";

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
            positions: positions,
            distanceMeters: distanceMeters,
            durationSeconds: durationSeconds,
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
            positions.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(2),
                    child: TrackPictogram(
                      key: ValueKey(widget.track.sessionId),
                      track: positions,
                      startImage: widget.startImage,
                      destinationImage: widget.destinationImage,
                      blurRadius: 0,
                      showSpeedLegend: false,
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? const [CI.darkModeRoute, ui.Color.fromARGB(255, 0, 255, 247)]
                          : [CI.lightModeRoute, const ui.Color.fromARGB(255, 0, 217, 255)],
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.location_off,
                      size: 32,
                    ),
                  ),
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.75),
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: Platform.isAndroid ? 4 : 0),
                  child: BoldContent(
                    text: relativeTime,
                    context: context,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.75),
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: Platform.isAndroid ? 2 : 0),
                  child: BoldSmall(
                    text: trackDurationFormatted,
                    context: context,
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

        String? formattedTime = formatDuration(durationSeconds);

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

        // We only want to visualize the first calculated route.
        // Therefore we compare the timestamps of all routes and take the earliest one.
        int? timestampOfFirstRoute;
        widget.track.routes.forEach((timestamp, _) {
          if (timestampOfFirstRoute == null) {
            timestampOfFirstRoute = timestamp;
          } else if (timestamp < timestampOfFirstRoute!) {
            timestampOfFirstRoute = timestamp;
          }
        });
        List<NavigationNode> routeNodes = widget.track.routes[timestampOfFirstRoute]!.route;

        if (snapshot.connectionState == ConnectionState.done) {
          content = TrackPictogram(
            key: ValueKey(widget.track.sessionId),
            track: positions,
            blurRadius: 2,
            startImage: widget.startImage,
            destinationImage: widget.destinationImage,
            iconSize: 16,
            lineWidth: 10,
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [CI.darkModeRoute, ui.Color.fromARGB(255, 0, 255, 247)]
                : [CI.lightModeRoute, const ui.Color.fromARGB(255, 0, 217, 255)],
            // Note: in the feedback view the background image map (1000x1000 pixel) is displayed in full height.
            // Therefore the track pictogram needs to be extended outside the screen (logically).
            // So we calculate, how much the height is greater then the width.
            // This means the ratio is height / width.
            imageHeightRatio: MediaQuery.of(context).size.height / MediaQuery.of(context).size.width,
            mapboxTop: MediaQuery.of(context).padding.top + 96,
            mapboxRight: 20,
            mapboxWidth: 64,
            // Padding + 2 * button height + padding + padding bottom.
            speedLegendBottom: 20 + 2 * 64 + 20 + MediaQuery.of(context).padding.bottom,
            speedLegendLeft: 20,
            routeNodes: routeNodes,
            routeLegendBottom: 20 + 2 * 64 + 20 + MediaQuery.of(context).padding.bottom,
            routeLegendRight: 20,
            showSpeedLegend: positions.isNotEmpty,
          );
        }

        return SizedBox(
          height: widget.height ?? MediaQuery.of(context).size.height,
          width: widget.width ?? MediaQuery.of(context).size.width,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              content,
              Column(children: [
                SizedBox(
                  height: MediaQuery.of(context).padding.top,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Material(
                        color: Theme.of(context).colorScheme.background.withOpacity(0.5),
                        child: Container(),
                      ), // Extra container is required for the blur.
                    ),
                  ),
                ),
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Material(
                      color: Theme.of(context).colorScheme.background.withOpacity(0.5),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
                        child: trackStats,
                      ),
                    ),
                  ),
                ),
              ]),
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

  /// The GPS positions of the driven route.
  final List<Position> positions;

  /// The driven distance in meters.
  final double? distanceMeters;

  /// The duration of the track in seconds.
  final int? durationSeconds;

  const TrackHistoryItemAppSheetView(
      {super.key,
      required this.track,
      required this.startImage,
      required this.destinationImage,
      required this.height,
      required this.positions,
      this.distanceMeters,
      this.durationSeconds});

  @override
  State<StatefulWidget> createState() => TrackHistoryItemAppSheetViewState();
}

class TrackHistoryItemAppSheetViewState extends State<TrackHistoryItemAppSheetView> {
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
          track: widget.positions,
          blurRadius: 2,
          startImage: widget.startImage,
          destinationImage: widget.destinationImage,
          iconSize: 16,
          lineWidth: 6,
          imageWidthRatio: 1,
          mapboxTop: MediaQuery.of(context).padding.top + 10,
          mapboxRight: 20,
          mapboxWidth: 64,
          colors: Theme.of(context).brightness == Brightness.dark
              ? const [CI.darkModeRoute, ui.Color.fromARGB(255, 0, 255, 247)]
              : [CI.lightModeRoute, const ui.Color.fromARGB(255, 0, 217, 255)],
          showSpeedLegend: widget.positions.isNotEmpty,
        );
      });
    });
    initializeDateFormatting();
  }

  /// Show a dialog that asks if the track really shoud be deleted.
  void _showDeleteDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionBuilder: (context, animation, secondaryAnimation, child) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4 * animation.value, sigmaY: 4 * animation.value),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
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
                // We want to pop two times.
                Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final totalDurationHours = widget.durationSeconds == null ? 0 : widget.durationSeconds! / 3600;
    final totalDistanceKilometres = widget.distanceMeters == null ? 0 : widget.distanceMeters! / 1000;
    final averageSpeedKmH = totalDurationHours == 0 ? 0 : (totalDistanceKilometres / totalDurationHours);

    String? formattedTime = formatDuration(widget.durationSeconds);

    const co2PerKm = 0.1187; // Data according to statista.com in KG
    final savedCo2inG = widget.distanceMeters == null && widget.durationSeconds == null
        ? 0
        : (widget.distanceMeters! / 1000) * co2PerKm * 1000;

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

    final Widget trackStats;
    if (widget.distanceMeters != null && widget.durationSeconds != null && formattedTime != null) {
      trackStats = TrackStats(
        formattedTime: formattedTime,
        distanceMeters: widget.distanceMeters,
        averageSpeedKmH: averageSpeedKmH,
        savedCo2inG: savedCo2inG,
      );
    } else {
      trackStats = const TrackStats();
    }

    return Container(
      // VSpace + Content + SmallVSpace + Track map size + 20 + Details + padding + 44 Stats.
      height: (24 + 32 + 16 + 20 + widget.height + 20 + 42 + 62 + MediaQuery.of(context).padding.bottom),
      // width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.background,
      ),
      child: Column(
        children: [
          const VSpace(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              BoldContent(text: relativeTime, context: context),
              Content(text: clock, context: context),
            ]),
          ),
          const VSpace(),
          SizedBox(width: MediaQuery.of(context).size.width - 40, height: widget.height, child: trackPictogram),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            child: trackStats,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            height: 42,
            child: BigButtonTertiary(
              label: "Fahrt löschen",
              onPressed: () => _showDeleteDialog(context),
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom,
          ),
          const SmallVSpace(),
          // Button to delete track
        ],
      ),
    );
  }
}
