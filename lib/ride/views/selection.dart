import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/ride/views/main.dart';
import 'package:priobike/settings/models/ride.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class RideSelectionView extends StatefulWidget {
  const RideSelectionView({Key? key}) : super(key: key);

  @override
  State<RideSelectionView> createState() => RideSelectionViewState();
}

class RideSelectionViewState extends State<RideSelectionView> {
  /// The seed for the random sorting of ride views.
  int? seed;

  @override
  void initState() {
    super.initState();

    // Load the seed which is generated from the device id.
    // This ensures that a user always sees the same order of ride views.
    () async {
      final deviceInfo = DeviceInfoPlugin();
      var deviceId = "Unknown";
      if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceId = info.identifierForVendor ?? "n/a";
      } else if (Platform.isAndroid) {
        final info = (await deviceInfo.androidInfo);
        deviceId = info.androidId ?? "n/a";
      }
      setState(() => seed = deviceId.hashCode);
    }();
  }

  /// A callback that is fired when a ride preference is selected.
  Future<void> onRideSelected(BuildContext context, RidePreference preference) async {
    final settings = Provider.of<Settings>(context, listen: false);
    await settings.selectRidePreference(preference);

    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      // Avoid navigation back, only allow stop button to be pressed.
      // Note: Don't use pushReplacement since this will call
      // the result handler of the RouteView's host.
      return WillPopScope(
        onWillPop: () async => false,
        child: const RideView(),
      );
    }));
  }

  /// Get a screenshot of a ride preference type.
  Widget screenshot(RidePreference p, BuildContext context) {
    final type = Theme.of(context).colorScheme.brightness == Brightness.dark ? 'dark' : 'light';
    String? asset;
    switch (p) {
      case RidePreference.speedometerView:
        asset = 'assets/images/screenshots/speedometer-$type.png';
        break;
      case RidePreference.defaultCyclingView:
        asset = 'assets/images/screenshots/default-cycling-$type.png';
        break;
      case RidePreference.minimalRecommendationCyclingView:
        asset = 'assets/images/screenshots/minimal-recommendation-$type.png';
        break;
      case RidePreference.minimalCountdownCyclingView:
        asset = 'assets/images/screenshots/minimal-countdown-$type.png';
        break;
    }
    return AspectRatio(
      aspectRatio: 0.65, // Hide debug indicator and status bar.
      child: Image.asset(asset, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    final elements = RidePreference.values
        .map((e) => Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Tile(
                fill: Theme.of(context).colorScheme.background,
                onPressed: () => onRideSelected(context, e),
                padding: const EdgeInsets.all(4),
                content: ClipRRect(borderRadius: BorderRadius.circular(20), child: screenshot(e, context)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Small(text: e.description, maxLines: 4, context: context, textAlign: TextAlign.center),
              ),
            ]))
        .toList();

    // Make sure to shuffle the elements to avoid bias.
    if (seed != null) {
      elements.shuffle(Random(seed));
    } else {
      // If the seed is not yet loaded, don't show the elements.
      elements.clear();
    }

    return Scaffold(
      body: SafeArea(
        child: Fade(
            child: SingleChildScrollView(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 64),
                HPad(
                    child: Header(
                        text: "Wähle eine Fahrtansicht.",
                        color: Theme.of(context).colorScheme.primary,
                        context: context)),
                const SmallVSpace(),
                HPad(
                    child: Content(
                        text:
                            "Um deine Sicherheit zu erhöhen, kannst du während der Fahrt nicht mehr zwischen den Ansichten wechseln. Kehre zu den Einstellungen zurück, um eine andere Ansicht zu wählen.",
                        context: context)),
                const SmallVSpace(),
                GridView.count(
                  primary: false,
                  shrinkWrap: true,
                  childAspectRatio: 0.55,
                  padding: const EdgeInsets.all(20),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  crossAxisCount: 2,
                  children: elements,
                ),
                const SizedBox(height: 64),
              ]),
        )),
      ),
    );
  }
}
