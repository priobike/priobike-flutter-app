

import 'package:flutter/material.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/ride/views/main.dart';
import 'package:priobike/settings/models/ride.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class RideSelectionView extends StatelessWidget {
  const RideSelectionView({Key? key}) : super(key: key);

  /// A callback that is fired when a ride preference is selected.
  Future<void> onRideSelected(BuildContext context, RidePreference preference) async {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    await settingsService.selectRidePreference(preference);

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

  @override
  Widget build(BuildContext context) {
    final elements = RidePreference.values.map((e) => Tile(
      fill: Theme.of(context).colorScheme.background,
      onPressed: () => onRideSelected(context, e),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          e.icon,
          const Divider(),
          Small(text: e.description, maxLines: 4),
        ],
      ),
    )).toList();
    // Make sure to shuffle the elements to avoid bias.
    elements.shuffle();

    return Scaffold(
      body: SafeArea(
        child: Fade(child: SingleChildScrollView(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 128),
            HPad(child: Header(text: "Wähle eine Fahrtansicht.", color: Theme.of(context).colorScheme.primary)),
            const SmallVSpace(),
            HPad(child: Content(text: "Keine Sorge, durch Wischen kannst du immer zwischen den Ansichten wechseln.")),
            GridView.count(
              primary: false,
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              crossAxisCount: 2,
              children: elements,
            ),
            const SizedBox(height: 128),
          ]),
        )),
      ),
    );
  }
}