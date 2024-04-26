import 'package:flutter/material.dart';
import 'package:priobike/common/layout/images.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'dart:math' as math;

import 'package:priobike/routing/services/map_functions.dart';
import 'package:priobike/routing/services/map_values.dart';

class CompassButton extends StatefulWidget {
  /// The associated MapValues service, which is injected by the provider.
  final MapValues mapValues;

  /// The associated MapFunctions service, which is injected by the provider.
  final MapFunctions mapFunctions;

  const CompassButton({super.key, required this.mapValues, required this.mapFunctions});

  @override
  State<StatefulWidget> createState() => CompassButtonState();
}

class CompassButtonState extends State<CompassButton> {
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

  /// Private center north Function which calls mapFunctionsService
  void _centerNorth() {
    widget.mapFunctions.setCameraCenterNorth();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Tile(
        fill: Theme.of(context).colorScheme.surfaceVariant,
        onPressed: _centerNorth,
        padding: const EdgeInsets.all(4),
        content: Transform.rotate(
          angle: widget.mapValues.cameraBearing.toInt() * math.pi / -180,
          child: CompassIcon(
            context: context,
          ),
        ),
      ),
    );
  }
}
