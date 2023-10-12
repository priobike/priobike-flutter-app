import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/lock.dart';
import 'package:priobike/common/mapbox_attribution.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/positioning/views/location_access_denied_dialog.dart';
import 'package:priobike/ride/services/datastream.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/ride/views/datastream.dart';
import 'package:priobike/ride/views/finish_button.dart';
import 'package:priobike/ride/views/map.dart';
import 'package:priobike/ride/views/screen_tracking.dart';
import 'package:priobike/ride/views/speedometer/view.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/datastream.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:wakelock/wakelock.dart';

class RideView extends StatefulWidget {
  const RideView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RideViewState();
}

class RideViewState extends State<RideView> {
  /// The distance in meters at which a new route is requested.
  static double rerouteDistance = 50;

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated ride service, which is injected by the provider.
  late Ride ride;

  /// A lock that avoids rapid rerouting.
  final lock = Lock(milliseconds: 10000);

  /// A bool indicating whether we are currently requiring a reroute but it's not yet successful.
  /// e.g. because we have an error or the user is outside of the cities boundary.
  bool needsReroute = false;

  /// A bool indicating whether the camera should follow the user location.
  bool cameraFollowsUserLocation = true;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    settings = getIt<Settings>();
    settings.addListener(update);

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        final deviceWidth = MediaQuery.of(context).size.width;
        final deviceHeight = MediaQuery.of(context).size.height;

        final tracking = getIt<Tracking>();
        final positioning = getIt<Positioning>();
        final datastream = getIt<Datastream>();
        final routing = getIt<Routing>();
        final sgStatus = getIt<PredictionSGStatus>();

        if (routing.selectedRoute == null) return;
        await positioning.selectRoute(routing.selectedRoute);
        // Start a new session.
        final ride = getIt<Ride>();

        // Save the shortcut id if there exists a matching shortcut for the selected waypoints.
        ride.setShortcut(routing.selectedWaypoints!);

        // Save current route if the app crashes or the user unintentionally closes it.
        ride.setLastRoute(routing.selectedWaypoints!, routing.selectedRoute!.id);

        // Set `sessionId` to a random new value and bind the callbacks.
        await ride.startNavigation(sgStatus.onNewPredictionStatusDuringRide);
        await ride.selectRoute(routing.selectedRoute!);
        // Connect the datastream mqtt client, if the user enabled real-time data.
        final settings = getIt<Settings>();
        if (settings.datastreamMode == DatastreamMode.enabled) {
          await datastream.connect();
          // Link the ride to the datastream.
          ride.onSelectNextSignalGroup = (sg) => datastream.select(sg: sg);
        }
        // Start geolocating. This must only be executed once.
        await positioning.startGeolocation(
          onNoPermission: () {
            Navigator.of(context).pop();
            showLocationAccessDeniedDialog(context, positioning.positionSource);
          },
          onNewPosition: () async {
            await ride.updatePosition();
            await tracking.updatePosition();

            // If we are > <x>m from the route, we need to reroute.
            if ((positioning.snap?.distanceToRoute ?? 0) > rerouteDistance || needsReroute) {
              // Use a timed lock to avoid rapid refreshing of routes.
              lock.run(() async {
                await routing.selectRemainingWaypoints();
                final routes = await routing.loadRoutes();

                if (routes == null || routes.isEmpty) {
                  // If we have no routes (e.g. because of routing error or because the user left the city boundaries),
                  // we need to reroute in the future.
                  needsReroute = true;
                  return;
                }

                // Save current route if the app crashes or the user unintentionally closes it.
                ride.setLastRoute(routing.selectedWaypoints!, routing.selectedRoute!.id);

                needsReroute = false;
                await ride.selectRoute(routes.first);
                await positioning.selectRoute(routes.first);
                await tracking.selectRoute(routes.first);
              });
            }
          },
        );

        // Start tracking once the `sessionId` is set and the positioning stream is available.
        await tracking.start(deviceWidth, deviceHeight);

        // Allow user to rotate the screen.
        // Landscape-Mode needs to be removed in dispose().
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ]);
      },
    );
  }

  /// Called when the user moves the map.
  Future<void> onMapMoved() async {
    if (cameraFollowsUserLocation) {
      setState(() {
        cameraFollowsUserLocation = false;
      });
    }
  }

  @override
  void dispose() {
    settings.removeListener(update);

    // Allows only portrait mode again.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the device active during navigation.
    Wakelock.enable();

    final EdgeInsets paddingCenterButton;
    final double heightToPuckBoundingBox;
    final double positionSpeedometerRight;

    final orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.portrait) {
      // Portrait mode
      final displayHeight = MediaQuery.of(context).size.height;
      final heightToPuck = displayHeight / 2;
      heightToPuckBoundingBox = heightToPuck - (displayHeight * 0.05);
      paddingCenterButton = EdgeInsets.only(
        bottom: heightToPuckBoundingBox < MediaQuery.of(context).size.width
            ? heightToPuckBoundingBox - 35
            : MediaQuery.of(context).size.width - 35,
      );
      positionSpeedometerRight = 0.0;
    } else {
      // Landscape mode
      final displayWidth = MediaQuery.of(context).size.width;
      final displayHeight = MediaQuery.of(context).size.height;
      final heightToPuck = displayWidth / 2;
      heightToPuckBoundingBox = heightToPuck - (displayWidth * 0.05);
      paddingCenterButton = EdgeInsets.only(bottom: displayHeight * 0.15, right: displayWidth * 0.42);
      positionSpeedometerRight = 6.0;
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: SafeArea(
        top: Platform.isAndroid ? true : false,
        child: Scaffold(
          body: ScreenTrackingView(
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                RideMapView(
                  onMapMoved: onMapMoved,
                  cameraFollowUserLocation: cameraFollowsUserLocation,
                ),
                if (settings.saveBatteryModeEnabled)
                  Positioned(
                    // needs to be different on Android because of SafeArea
                    top: Platform.isAndroid ? 10 : MediaQuery.of(context).size.height * 0.07,
                    left: 10,
                    child: const Image(
                      width: 100,
                      image: AssetImage('assets/images/mapbox-logo-transparent.png'),
                    ),
                  ),
                if (settings.saveBatteryModeEnabled)
                  Positioned(
                    top: Platform.isAndroid ? 5 : MediaQuery.of(context).size.height * 0.05,
                    right: 10,
                    child: IconButton(
                      onPressed: () => MapboxAttribution.showAttribution(context),
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        size: 25,
                        color: CI.blue,
                      ),
                    ),
                  ),
                Positioned(
                  right: positionSpeedometerRight,
                  child: RideSpeedometerView(puckHeight: heightToPuckBoundingBox),
                ),
                const DatastreamView(),
                const FinishRideButton(),
                if (!cameraFollowsUserLocation)
                  SafeArea(
                    bottom: true,
                    child: Padding(
                      padding: paddingCenterButton,
                      child: BigButton(
                        icon: Icons.navigation_rounded,
                        iconColor: Colors.white,
                        fillColor: Theme.of(context).colorScheme.primary,
                        label: "Zentrieren",
                        elevation: 20,
                        onPressed: () {
                          final ride = getIt<Ride>();
                          if (ride.userSelectedSG != null) ride.unselectSG();
                          setState(() {
                            cameraFollowsUserLocation = true;
                          });
                        },
                        boxConstraints:
                            BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.3, minHeight: 50),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
