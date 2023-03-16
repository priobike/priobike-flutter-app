import 'package:flutter/material.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';

import 'package:priobike/routing/services/map_functions.dart';

class CenterButton extends StatefulWidget {
  const CenterButton({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CenterButtonState();
}

class CenterButtonState extends State<CenterButton> {
  /// The associated MapFunctions service, which is injected by the provider.
  late MapFunctions mapFunctions;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    mapFunctions = getIt<MapFunctions>();
    mapFunctions.addListener(update);
  }

  /// Private GPS Centralization Function which calls mapFunctionsService
  void _gpsCentralization() {
    mapFunctions.setCameraCenterOnUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Tile(
        fill: Theme.of(context).colorScheme.background,
        onPressed: _gpsCentralization,
        content: Icon(
          mapFunctions.isCentered ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
    );
  }
}
