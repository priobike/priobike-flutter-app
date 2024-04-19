import 'package:flutter/material.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';

import 'package:priobike/routing/services/map_functions.dart';
import 'package:priobike/routing/services/map_values.dart';

class CenterButton extends StatefulWidget {
  const CenterButton({super.key});

  @override
  State<StatefulWidget> createState() => CenterButtonState();
}

class CenterButtonState extends State<CenterButton> {
  /// The associated MapFunctions service, which is injected by the provider.
  late MapFunctions mapFunctions;

  /// The associated MapValues service, which is injected by the provider.
  late MapValues mapValues;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    mapFunctions = getIt<MapFunctions>();
    mapValues = getIt<MapValues>();
    mapValues.addListener(update);
  }

  @override
  void dispose() {
    mapValues.removeListener(update);
    super.dispose();
  }

  /// Private GPS Centralization Function which calls mapFunctionsService
  void _gpsCentralization() {
    mapFunctions.setCameraCenterOnUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Tile(
        fill: Theme.of(context).colorScheme.surfaceVariant,
        onPressed: _gpsCentralization,
        padding: const EdgeInsets.all(0),
        content: Icon(
          mapValues.isCentered ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
    );
  }
}
