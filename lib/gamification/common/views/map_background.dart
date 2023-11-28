import 'package:flutter/material.dart';

/// Class which displays a faded map behind the child widget. The child widget has to have a fixed size.
class MapBackground extends StatelessWidget {
  /// The child to be displayed above the map.
  final Widget child;

  const MapBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    var isLightMode = Theme.of(context).brightness == Brightness.light;
    List<Color> darkModeGradient = [
      Theme.of(context).colorScheme.background,
      Theme.of(context).colorScheme.background.withOpacity(0.8),
      Theme.of(context).colorScheme.background.withOpacity(0.4),
      Theme.of(context).colorScheme.background.withOpacity(0.4),
      Theme.of(context).colorScheme.background.withOpacity(0.8),
      Theme.of(context).colorScheme.background,
    ];

    List<Color> lightModeGradient = [
      Theme.of(context).colorScheme.background,
      Theme.of(context).colorScheme.background.withOpacity(0.6),
      Theme.of(context).colorScheme.background.withOpacity(0.3),
      Theme.of(context).colorScheme.background.withOpacity(0.3),
      Theme.of(context).colorScheme.background.withOpacity(0.6),
      Theme.of(context).colorScheme.background,
    ];
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Container(
            foregroundDecoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: isLightMode ? lightModeGradient : darkModeGradient,
              ),
            ),
            child: Container(
              foregroundDecoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isLightMode ? lightModeGradient : darkModeGradient,
                ),
              ),
              child: ClipRRect(
                child: Image(
                  image: Theme.of(context).colorScheme.brightness == Brightness.dark
                      ? const AssetImage('assets/images/map-dark.png')
                      : const AssetImage('assets/images/map-light.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
