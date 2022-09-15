import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';

/// A view that displays alerts in the routing context.
class CompassButton extends StatelessWidget {
  final Function centerNorth;
  const CompassButton({Key? key, required this.centerNorth}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          elevation: 5,
          borderRadius: const BorderRadius.all(Radius.circular(24.0)),
          child: SmallIconButton(
            icon: Icons.explore,
            onPressed: () => centerNorth(),
          ),
        ),
      ),
    );
  }
}
