import 'package:flutter/material.dart';
import 'package:priobike/common/layout/images.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'dart:math' as math;

import 'package:priobike/routing/services/map_functions.dart';
import 'package:priobike/routing/services/map_values.dart';

class CompassButton extends StatefulWidget {
  const CompassButton({super.key});

  @override
  State<StatefulWidget> createState() => CompassButtonState();
}

class CompassButtonState extends State<CompassButton> {
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

  /// Private center north Function which calls mapFunctionsService
  void _centerNorth() {
    mapFunctions.setCameraCenterNorth();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: TilePrimary(
        fill: Theme.of(context).colorScheme.background,
        onPressed: _centerNorth,
        content: Transform.rotate(
          angle: mapValues.cameraBearing.toInt() * math.pi / -180,
          child: CompassIcon(
            context: context,
          ),
        ),
        padding: const EdgeInsets.all(10),
      ),
    );
  }
}
