import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Route;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
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
  final Track track;

  const TrackDetailsDialog({Key? key, required this.track}) : super(key: key);

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
            )
          ],
        ),
      ),
    );
  }
}

class TrackDetailsView extends StatefulWidget {
  final Track track;

  const TrackDetailsView({Key? key, required this.track}) : super(key: key);

  @override
  TrackDetailsViewState createState() => TrackDetailsViewState();
}

class TrackDetailsViewState extends State<TrackDetailsView> with TickerProviderStateMixin {
  /// The distance model.
  final vincenty = const Distance(roundResult: false);

  /// The positions of the track.
  List<Position> positions = [];

  /// The navigation nodes of the driven route.
  List<NavigationNode> routeNodes = [];

  ui.Image? startImage;
  ui.Image? destinationImage;

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
        ByteData startBd = await rootBundle.load("assets/images/start.drawio.png");
        final Uint8List startBytes = Uint8List.view(startBd.buffer);
        final ui.Codec startCodec = await ui.instantiateImageCodec(startBytes);
        startImage = (await startCodec.getNextFrame()).image;

        ByteData destinationBd = await rootBundle.load("assets/images/destination.drawio.png");
        final Uint8List destinationBytes = Uint8List.view(destinationBd.buffer);
        final ui.Codec destinationCodec = await ui.instantiateImageCodec(destinationBytes);
        destinationImage = (await destinationCodec.getNextFrame()).image;

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
    super.dispose();
  }

  /// Display the route on the map.
  Future<void> loadTrack() async {
    routeNodes = getPassedNodes(widget.track.routes.values.toList(), vincenty);
    try {
      final gpsFile = await widget.track.gpsCSVFile;
      final gpsFileLines = await gpsFile.readAsLines();
      positions.clear();
      // Skip the first line, which is the header.
      for (var i = 1; i < gpsFileLines.length; i++) {
        final lineContents = gpsFileLines[i].split(',');
        final time = int.parse(lineContents[0]);
        final lon = double.parse(lineContents[1]);
        final lat = double.parse(lineContents[2]);
        final speed = double.parse(lineContents[3]);
        final accuracy = double.parse(lineContents[4]);
        positions.add(Position(
          timestamp: DateTime.fromMillisecondsSinceEpoch(time),
          latitude: lat,
          longitude: lon,
          speed: speed,
          accuracy: accuracy,
          altitude: 0,
          heading: 0,
          speedAccuracy: 0,
        ));
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
      alignment: Alignment.topCenter,
      children: [
        ClipRect(
          child: SizedBox(
            height: 200,
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
        HPad(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (tabController != null)
                TabPageSelector(
                  controller: tabController!,
                  selectedColor: CI.blue,
                  indicatorSize: 6,
                  borderStyle: BorderStyle.none,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                  key: GlobalKey(),
                ),
              const SmallVSpace(),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 220,
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
                      Column(
                        children: [
                          const Text(
                            "GPS-Aufzeichnung",
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.2,
                              color: CI.blue,
                            ),
                          ),
                          SizedBox(
                            height: 200,
                            width: 200,
                            child: TrackPictogram(
                              key: GlobalKey(),
                              track: positions,
                              minSpeedColor: CI.blue,
                              maxSpeedColor: CI.blueLight,
                            ),
                          ),
                        ],
                      ),
                    if (routeNodes.isNotEmpty && startImage != null && destinationImage != null)
                      Column(
                        children: [
                          const Text(
                            "Voreingestellte Route",
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.2,
                              color: CI.blue,
                            ),
                          ),
                          SizedBox(
                            height: 150,
                            width: 150,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: RoutePictogram(
                                key: GlobalKey(),
                                route: routeNodes,
                                startImage: startImage,
                                destinationImage: destinationImage,
                                lineWidth: 6,
                                iconSize: 20,
                              ),
                            ),
                          ),
                          IconTextButton(
                            iconColor: Colors.white,
                            icon: Icons.arrow_right_alt_rounded,
                            label: "Erneut fahren",
                            boxConstraints: const BoxConstraints(maxWidth: 200),
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
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Small(
                text: "($lastTrackDateFormatted)",
                context: context,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                textAlign: TextAlign.center,
              ),
              if (positions.isNotEmpty) ...[
                const VSpace(),
                GridView.count(
                  crossAxisSpacing: 8,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  mainAxisSpacing: 8,
                  crossAxisCount: 2,
                  childAspectRatio: 4,
                  physics: const NeverScrollableScrollPhysics(),
                  children: rideDetails,
                ),
                const SmallVSpace(),
              ],
            ],
          ),
        )
      ],
    );
  }
}
