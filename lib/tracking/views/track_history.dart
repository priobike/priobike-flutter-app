import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/navigation.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/tracking/models/track.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/tracking/views/route_pictrogram.dart';

class TrackHistoryView extends StatefulWidget {
  const TrackHistoryView({Key? key}) : super(key: key);

  @override
  TrackHistoryViewState createState() => TrackHistoryViewState();
}

class TrackHistoryViewState extends State<TrackHistoryView> {
  /// The distance model.
  static const vincenty = Distance(roundResult: false);

  /// The associated tracking service, which is injected by the provider.
  late Tracking tracking;

  /// The navigation nodes of the driven route.
  List<List<NavigationNode>> routesNodes = [];

  late ui.Image startImage;
  late ui.Image destinationImage;

  /// Called when a listener callback of a ChangeNotifier is fired.
  Future<void> update() async {
    await loadRoutes();
    setState(() {});
  }

  Future<void> loadRoutes() async {
    if (tracking.previousTracks == null) {
      return;
    }
    if (tracking.previousTracks!.isEmpty) {
      return;
    }

    routesNodes.clear();

    for (final track in tracking.previousTracks!) {
      final routes = track.routes;
      // Find reroute locations
      List<int> rerouteNodeIndices = [];
      if (routes.values.length > 1) {
        for (var routeIdx = 0; routeIdx < routes.values.length; routeIdx++) {
          if (routeIdx >= routes.values.length - 1) {
            // If it's the last route, we can stop here.
            break;
          }
          final navigationNodes = routes.values.toList()[routeIdx].route;
          final nextRoutesFirstNavigationNode = routes.values.toList()[routeIdx + 1].route[0];
          var currentShortestDistance = double.infinity;
          var currentShortestDistanceIdx = -1;
          for (var navigationNodeIdx = 0; navigationNodeIdx < navigationNodes.length; navigationNodeIdx++) {
            final distance = vincenty.distance(
              LatLng(navigationNodes[navigationNodeIdx].lat, navigationNodes[navigationNodeIdx].lon),
              LatLng(nextRoutesFirstNavigationNode.lat, nextRoutesFirstNavigationNode.lon),
            );
            if (distance < currentShortestDistance) {
              currentShortestDistance = distance;
              currentShortestDistanceIdx = navigationNodeIdx;
            }
          }
          rerouteNodeIndices.add(currentShortestDistanceIdx);
        }
      }

      List<NavigationNode> drivenRoute = [];

      // Add points
      for (var routeIdx = 0; routeIdx < routes.values.length; routeIdx++) {
        final navigationNodes = routes.values.toList()[routeIdx].route;
        for (var navigationNodeIdx = 0; navigationNodeIdx < navigationNodes.length; navigationNodeIdx++) {
          // If it's the last route, add all navigation nodes
          if (routeIdx >= routes.values.length - 1) {
            drivenRoute.add(navigationNodes[navigationNodeIdx]);
          } else {
            if (navigationNodeIdx == rerouteNodeIndices[routeIdx]) {
              // Go to next route.
              break;
            }
            drivenRoute.add(navigationNodes[navigationNodeIdx]);
          }
        }
      }

      routesNodes.add(drivenRoute);
    }
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    tracking = getIt<Tracking>();
    tracking.addListener(update);

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

        await tracking.loadPreviousTracks();
      },
    );
  }

  @override
  void dispose() {
    tracking.removeListener(update);
    super.dispose();
  }

  String formatDuration(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds < 60) {
      return "$seconds Sekunden";
    }
    if (seconds < 3600) {
      final minutes = seconds / 60;
      return "$minutes Minuten";
    }
    final hours = seconds / 3600;
    return "$hours Stunden";
  }

  /// Widget that displays a shortcut.
  Widget routeListItem(Track track, int trackIndex) {
    final lastTrackDate = DateTime.fromMillisecondsSinceEpoch(track.startTime);
    final lastTrackDateFormatted = DateFormat.yMMMMd("de").format(lastTrackDate);
    final lastTrackDuration = track.endTime != null ? Duration(milliseconds: track.endTime! - track.startTime) : null;
    final lastTrackDurationFormatted = lastTrackDuration != null ? formatDuration(lastTrackDuration) : null;

    return HPad(
      child: Tile(
        fill: Theme.of(context).colorScheme.background,
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.35,
              height: MediaQuery.of(context).size.width * 0.35,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        foregroundDecoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: Theme.of(context).colorScheme.brightness == Brightness.dark
                                ? [
                                    Theme.of(context).colorScheme.background,
                                    Theme.of(context).colorScheme.background,
                                    Theme.of(context).colorScheme.background.withOpacity(0.9),
                                    Theme.of(context).colorScheme.background.withOpacity(0.8),
                                    Theme.of(context).colorScheme.background.withOpacity(0.7),
                                  ]
                                : [
                                    Theme.of(context).colorScheme.background,
                                    Theme.of(context).colorScheme.background,
                                    Theme.of(context).colorScheme.background.withOpacity(0.6),
                                    Theme.of(context).colorScheme.background.withOpacity(0.5),
                                    Theme.of(context).colorScheme.background.withOpacity(0.3),
                                  ],
                          ),
                          borderRadius:
                              const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                          child: Image(
                            image: Theme.of(context).colorScheme.brightness == Brightness.dark
                                ? const AssetImage('assets/images/map-dark.png')
                                : const AssetImage('assets/images/map-light.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: RoutePictogram(
                        route: routesNodes[trackIndex],
                        startImage: startImage,
                        destinationImage: destinationImage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const HSpace(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Content(
                          text: "🗓",
                          context: context,
                        ),
                        if (lastTrackDurationFormatted != null) ...[
                          const SmallVSpace(),
                          Content(
                            text: "⏱️",
                            context: context,
                          ),
                        ],
                      ],
                    ),
                    const SmallHSpace(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Content(
                          text: lastTrackDateFormatted,
                          context: context,
                        ),
                        if (lastTrackDurationFormatted != null) ...[
                          const SmallVSpace(),
                          Content(
                            text: lastTrackDurationFormatted,
                            context: context,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SmallVSpace(),
                IconTextButton(
                  iconColor: Colors.white,
                  icon: Icons.arrow_right_alt_rounded,
                  label: "Erneut fahren",
                  onPressed: () {
                    HapticFeedback.mediumImpact();

                    List<dynamic> waypoints = List.generate(routesNodes[trackIndex].length, (index) {
                      final routeNode = routesNodes[trackIndex][index];

                      // Add first and last waypoint.
                      if (index == 0 || index == routesNodes[trackIndex].length - 1) {
                        return Waypoint(
                          routeNode.lat,
                          routeNode.lon,
                          address: "Wegpunkt",
                        );
                      }

                      // Only add those where the direction of the route changes significantly.
                      // This is to avoid too many waypoints.
                      const directionThreshold = 50.0;
                      if (index > 1) {
                        final previousRouteNode = routesNodes[trackIndex][index - 1];
                        final previousPreviousRouteNode = routesNodes[trackIndex][index - 2];
                        final direction = vincenty.bearing(
                          LatLng(previousRouteNode.lat, previousRouteNode.lon),
                          LatLng(routeNode.lat, routeNode.lon),
                        );
                        final previousDirection = vincenty.bearing(
                          LatLng(previousPreviousRouteNode.lat, previousPreviousRouteNode.lon),
                          LatLng(previousRouteNode.lat, previousRouteNode.lon),
                        );
                        final directionDifference = (direction - previousDirection).abs();
                        if (directionDifference > directionThreshold) {
                          return Waypoint(
                            routeNode.lat,
                            routeNode.lon,
                            address: "Wegpunkt",
                          );
                        }
                      }

                      // Skip those where the distance to the previous waypoint is too small.
                      const distanceThreshold = 500.0;
                      if (index > 0) {
                        final previousRouteNode = routesNodes[trackIndex][index - 1];
                        final distance = vincenty.distance(
                          LatLng(previousRouteNode.lat, previousRouteNode.lon),
                          LatLng(routeNode.lat, routeNode.lon),
                        );
                        if (distance > distanceThreshold) {
                          return Waypoint(
                            routeNode.lat,
                            routeNode.lon,
                            address: "Wegpunkt",
                          );
                        }
                      }
                      return null;
                    });

                    // Remove null values from the list.
                    List<Waypoint> filteredWaypoints = [];
                    for (var waypoint in waypoints) {
                      if (waypoint != null) {
                        filteredWaypoints.add(waypoint);
                      }
                    }

                    getIt<Routing>().selectWaypoints(filteredWaypoints);

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
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Fade(
          child: SingleChildScrollView(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      AppBackButton(onPressed: () => Navigator.pop(context)),
                      const HSpace(),
                      SubHeader(text: "Deine Fahrten", context: context),
                    ],
                  ),
                  if (routesNodes.isNotEmpty)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tracking.previousTracks!.length,
                      reverse: true,
                      separatorBuilder: (BuildContext context, int index) => const SmallVSpace(),
                      itemBuilder: (_, int index) => routeListItem(tracking.previousTracks![index], index),
                    ),
                  const SmallVSpace(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
