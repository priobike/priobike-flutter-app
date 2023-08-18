import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Route;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/feedback/views/pictogram.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/statistics/models/summary.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/tracking/algorithms/converter.dart';
import 'package:priobike/tracking/models/track.dart';
import 'package:priobike/tracking/views/route_pictrogram.dart';

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
    return SizedBox(
      height: MediaQuery.of(context).size.height / 2,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const VSpace(),
            TrackDetailsView(
              track: track,
              startImage: startImage,
              destinationImage: destinationImage,
            )
          ],
        ),
      ),
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

  /// The navigation nodes of the driven route.
  List<NavigationNode> routeNodes = [];

  /// The track summary.
  Summary? trackSummary;

  /// PageController.
  final PageController pageController = PageController(
    viewportFraction: 0.9,
    initialPage: 0,
  );

  /// TabController.
  TabController? tabController;

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

  @override
  void dispose() {
    pageController.dispose();
    tabController?.dispose();
    super.dispose();
  }

  /// Load the track.
  Future<void> loadTrack() async {
    routeNodes = getPassedNodes(widget.track.routes.values.toList(), vincenty);
    positions.clear();

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

      await loadTrackSummary();

      // Only create the tab controller if we have route and GPS.
      tabController = TabController(length: 2, vsync: this);
    } catch (e) {
      log.w('Could not parse GPS file of last track: $e');
    }

    setState(() {});
  }

  Future<void> loadTrackSummary() async {
    if (positions.isEmpty) {
      return;
    }

    final coordinates = positions.map((e) => LatLng(e.latitude, e.longitude)).toList();
    var totalDistance = 0.0;
    for (var i = 0; i < positions.length - 1; i++) {
      totalDistance += vincenty.distance(coordinates[i], coordinates[i + 1]);
    }
    // Aggregate the elevation.
    var totalElevationGain = 0.0;
    var totalElevationLoss = 0.0;
    for (var i = 0; i < positions.length - 1; i++) {
      final elevationChange = positions[i + 1].altitude - positions[i].altitude;
      if (elevationChange > 0) {
        totalElevationGain += elevationChange;
      } else {
        totalElevationLoss += elevationChange;
      }
    }
    // Aggregate the duration.
    final now = positions.last.timestamp;
    final start = positions.first.timestamp;
    if (now == null || start == null) return;
    final totalDuration = now.difference(start).inMilliseconds;

    // Create the summary.
    trackSummary = Summary(
      distanceMeters: totalDistance,
      durationSeconds: totalDuration / 1000,
      elevationGain: totalElevationGain,
      elevationLoss: totalElevationLoss,
    );
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

    final List<Widget> rideDetails = [
      if (trackSummary != null)
        Column(
          children: [
            Text(
              "Dauer",
              style: headerTextStyle,
            ),
            Text(
              formatDuration(Duration(seconds: trackSummary!.durationSeconds.toInt())),
              style: cellTextStyle,
            ),
          ],
        ),
      if (trackSummary != null)
        Column(
          children: [
            Text(
              "Distanz",
              style: headerTextStyle,
            ),
            Text(
              trackSummary!.distanceMeters >= 1000
                  ? "${(trackSummary!.distanceMeters / 1000).toStringAsFixed(2)} km"
                  : "${trackSummary!.distanceMeters.toStringAsFixed(0)} m",
              style: cellTextStyle,
            ),
          ],
        ),
      if (trackSummary != null)
        Column(
          children: [
            Text(
              "Geschwindigkeit",
              style: headerTextStyle,
            ),
            Text(
              "Ø ${trackSummary!.averageSpeedKmH.toStringAsFixed(2)} km/h",
              style: cellTextStyle,
            ),
          ],
        ),
      if (trackSummary != null)
        Column(
          children: [
            Text(
              "CO2 gespart",
              style: headerTextStyle,
            ),
            Text(
              trackSummary!.savedCo2inG >= 1000
                  ? "${(trackSummary!.savedCo2inG / 1000).toStringAsFixed(2)} kg"
                  : "${trackSummary!.savedCo2inG.toStringAsFixed(2)} g",
              style: cellTextStyle,
            ),
          ],
        ),
    ];

    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRect(
          child: SizedBox(
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [0.0, 0.5, 0.9],
                  colors: [Colors.transparent, Colors.black, Colors.transparent],
                ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
              },
              blendMode: BlendMode.dstIn,
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.5, 0.9],
                    colors: [Colors.transparent, Colors.black, Colors.transparent],
                  ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                },
                blendMode: BlendMode.dstIn,
                child: Transform.translate(
                  offset: const Offset(-100, 100),
                  child: Transform.scale(
                    scale: 2.5,
                    child: Image(
                      image: Theme.of(context).colorScheme.brightness == Brightness.dark
                          ? const AssetImage('assets/images/map-dark.png')
                          : const AssetImage('assets/images/map-light.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 32, left: 42, right: 42),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BoldContent(text: "Letzte Fahrt", context: context),
                  Content(
                    text: lastTrackDateFormatted,
                    context: context,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SmallVSpace(),
              SizedBox(
                height: 264,
                child: PageView(
                  controller: pageController,
                  clipBehavior: Clip.none,
                  onPageChanged: (int index) {
                    if (tabController != null) {
                      setState(() {
                        tabController!.index = index;
                      });
                    }
                  },
                  children: [
                    if (positions.isNotEmpty)
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: tabController?.index == 0 ? 1 : 0,
                        child: TrackPictogram(
                          key: GlobalKey(),
                          track: positions,
                          minSpeedColor: CI.blue,
                          maxSpeedColor: CI.blueLight,
                          blurRadius: 2,
                        ),
                      ),
                    if (routeNodes.isNotEmpty)
                      Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: (tabController?.index ?? 1) == 1 ? 1 : 0,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: RoutePictogram(
                                key: GlobalKey(),
                                route: routeNodes,
                                startImage: widget.startImage,
                                destinationImage: widget.destinationImage,
                                lineWidth: 6,
                                iconSize: 20,
                              ),
                            ),
                          ),
                          Tile(
                            fill: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                            onPressed: () {
                              HapticFeedback.mediumImpact();

                              List<Waypoint> waypoints = convertNodesToWaypoints(routeNodes, vincenty);

                              getIt<Routing>().selectWaypoints(waypoints);

                              // Pushes the routing view.
                              // Also handles the reset of services if the user navigates back to the home view after the routing view instead of starting a ride.
                              // If the routing view is popped after the user navigates to the ride view do not reset the services, because they are being used in the ride view.
                              if (context.mounted) {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoutingView())).then(
                                  (comingNotFromRoutingView) {
                                    if (comingNotFromRoutingView == null) {
                                      getIt<Routing>().reset();
                                      getIt<Discomforts>().reset();
                                      getIt<PredictionSGStatus>().reset();
                                    }
                                  },
                                );
                              }
                            },
                            content: BoldContent(text: "Route erneut fahren", context: context),
                          )
                        ],
                      ),
                  ],
                ),
              ),
              if (tabController != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TabPageSelector(
                    controller: tabController!,
                    selectedColor: Theme.of(context).colorScheme.onBackground,
                    indicatorSize: 6,
                    borderStyle: BorderStyle.none,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
                    key: GlobalKey(),
                  ),
                ),
              if (rideDetails.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: rideDetails,
                  ),
                ),
            ],
          ),
        )
      ],
    );
  }
}
