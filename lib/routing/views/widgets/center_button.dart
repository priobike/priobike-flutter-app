import 'package:flutter/material.dart';
import 'package:priobike/common/layout/tiles.dart';

import 'package:priobike/routing/services/map_functions.dart';
import 'package:priobike/routing/services/map_values.dart';

class CenterButton extends StatefulWidget {
  /// The associated MapValues service, which is injected by the provider.
  final MapValues mapValues;

  /// The associated MapFunctions service, which is injected by the provider.
  final MapFunctions mapFunctions;

  const CenterButton({super.key, required this.mapValues, required this.mapFunctions});

  @override
  State<StatefulWidget> createState() => CenterButtonState();
}

class CenterButtonState extends State<CenterButton> {
  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    widget.mapValues.addListener(update);
  }

  @override
  void dispose() {
    widget.mapValues.removeListener(update);
    super.dispose();
  }

  /// Private GPS Centralization Function which calls mapFunctionsService
  void _gpsCentralization() {
    widget.mapFunctions.setCameraCenterOnUserLocation();
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
          widget.mapValues.isCentered ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
    );
  }
}
