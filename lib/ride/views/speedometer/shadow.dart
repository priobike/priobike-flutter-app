import 'package:flutter/material.dart';

/// The radial shadow of the speedometer, used for landscape mode.
class SpeedometerRadialShadow extends StatelessWidget {
  /// The size of the speedometer.
  final Size size;

  const SpeedometerRadialShadow({Key? key, required this.size}) : super(key: key);

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

/// The linear shadow of the speedometer, used for portrait mode.
class SpeedometerLinearShadow extends StatelessWidget {
  /// The height of the speedometer.
  final double originalSpeedometerHeight;

  /// The width of the speedometer.
  final double originalSpeedometerWidth;

  const SpeedometerLinearShadow({
    Key? key,
    required this.originalSpeedometerHeight,
    required this.originalSpeedometerWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: originalSpeedometerHeight,
      width: originalSpeedometerWidth,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: Theme.of(context).colorScheme.brightness == Brightness.dark
              ? [
                  Colors.black.withOpacity(0),
                  Colors.black.withOpacity(0.5),
                  Colors.black,
                ]
              : [
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.1),
                  Colors.black,
                ],
          stops: Theme.of(context).colorScheme.brightness == Brightness.dark
              ? const [0.1, 0.3, 0.5] // Dark theme
              : const [0.0, 0.1, 0.8], // Light theme
        ),
      ),
    );
  }
}
