import 'package:flutter/material.dart';

class SpeedometerShadow extends StatelessWidget {
  final Size size;

  const SpeedometerShadow({Key? key, required this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width * 1.0,
      height: size.width * 1.0,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          stops: Theme.of(context).colorScheme.brightness == Brightness.dark
              ? const [0.7, 1.0] // Dark theme
              : const [0.7, 1.0], // Light theme

          colors: Theme.of(context).colorScheme.brightness == Brightness.dark
              ? [
                  Colors.black.withOpacity(1),
                  Colors.black.withOpacity(0),
                ]
              : [
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.0),
                ],
        ),
      ),
    );
  }
}
