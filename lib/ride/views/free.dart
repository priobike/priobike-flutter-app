import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/mapbox_attribution.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/positioning/views/location_access_denied_dialog.dart';
import 'package:priobike/ride/services/free_ride.dart';
import 'package:priobike/ride/views/free_map.dart';
import 'package:priobike/ride/views/screen_tracking.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class FreeRideView extends StatefulWidget {
  const FreeRideView({super.key});

  @override
  State<StatefulWidget> createState() => FreeRideViewState();
}

class FreeRideViewState extends State<FreeRideView> {
  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// The associated free ride service, which is injected by the provider.
  late FreeRide freeRide;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    settings = getIt<Settings>();
    settings.addListener(update);
    freeRide = getIt<FreeRide>();
    freeRide.addListener(update);

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        final positioning = getIt<Positioning>();
        freeRide.fetchSgs();

        // Start geolocating. This must only be executed once.
        await positioning.startGeolocation(
          onNoPermission: () {
            Navigator.of(context).pop();
            showLocationAccessDeniedDialog(context, positioning.positionSource);
          },
          onNewPosition: () async {},
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
          child: freeRide.isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : freeRide.sgs != null && freeRide.sgs!.isNotEmpty
                  ? Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        const FreeRideMapView(),
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
                      ],
                    )
                  : const Center(
                      child: Text('Error.'),
                    ),
        ),
      ),
    );
  }
}
