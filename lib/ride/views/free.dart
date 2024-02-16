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
import 'package:priobike/simulator/views/sensor_state.dart';
import 'package:priobike/simulator/views/simulator_state.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class FreeRideView extends StatefulWidget {
  const FreeRideView({super.key});

  @override
  State<StatefulWidget> createState() => FreeRideViewState();
}

class FreeRideViewState extends State<FreeRideView> {
  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// The associated ride service, which is injected by the provider.
  late FreeRide freeRide;

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

        final positioning = getIt<Positioning>();

        // Start a new session.
        freeRide = getIt<FreeRide>();

        // Start geolocating. This must only be executed once.
        await positioning.startGeolocation(
          onNoPermission: () {
            Navigator.of(context).pop();
            showLocationAccessDeniedDialog(context, positioning.positionSource);
          },
          onNewPosition: () async {
            await freeRide.updatePosition();
          },
        );

        // Allow user to rotate the screen in ride view.
        // Landscape-Mode will be removed in FinishRideButton.
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the device active during navigation.
    WakelockPlus.enable();

    return PopScope(
      onPopInvoked: (type) async => false,
      child: Scaffold(
        body: ScreenTrackingView(
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              FreeRideMapView(
                onMapMoved: onMapMoved,
                cameraFollowUserLocation: cameraFollowsUserLocation,
              ),
              if (settings.saveBatteryModeEnabled)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 15,
                  left: 10,
                  child: const Image(
                    width: 100,
                    image: AssetImage('assets/images/mapbox-logo-transparent.png'),
                  ),
                ),
              if (settings.saveBatteryModeEnabled)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 5,
                  right: 10,
                  child: IconButton(
                    onPressed: () => MapboxAttribution.showAttribution(context),
                    icon: const Icon(
                      Icons.info_outline_rounded,
                      size: 25,
                      color: CI.radkulturRed,
                    ),
                  ),
                ),
              FinishRideButton(),
              if (!cameraFollowsUserLocation)
                SafeArea(
                  bottom: true,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: BigButtonPrimary(
                      label: "Zentrieren",
                      elevation: 20,
                      onPressed: () {
                        setState(() {
                          cameraFollowsUserLocation = true;
                        });
                      },
                      boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.3, minHeight: 50),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
