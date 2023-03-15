import 'package:flutter/material.dart';

/// A reusable stylized container with optional on-click listener.
class Tile extends StatelessWidget {
  /// The content of the tile.
  final Widget content;

  /// A callback that is fired when the tile was tapped.
  final void Function()? onPressed;

  /// The fill color of the tile.
  final Color? fill;

  /// The splash of the tile, if the tile is tappable (a callback is passed).
  final Color splash;

  /// The color of the shadow in light mode.
  final Color shadow;

  /// The intensity of the shadow.
  final double shadowIntensity;

  /// If the shadow should be visible.
  final bool showShadow;

  /// The padding of the tile.
  final EdgeInsets padding;

  /// The border radius of the tile.
  final BorderRadius borderRadius;

  /// The gradient of the tile.
  final Gradient? gradient;

  const Tile({
    Key? key,
    required this.content,
    this.onPressed,
    this.fill,
    this.splash = Colors.grey,
    this.shadow = Colors.black,
    this.shadowIntensity = 0.05,
    this.showShadow = true,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(24),
    ),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: borderRadius,
        gradient: gradient,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: shadow.withOpacity(shadowIntensity),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.07),
        ),
      ),
      child: onPressed == null
          ? Padding(padding: padding, child: content)
          : Material(
              borderRadius: borderRadius,
              color: Colors.transparent,
              child: InkWell(
                borderRadius: borderRadius,
                splashColor: splash,
                onTap: onPressed,
                child: Padding(padding: padding, child: content),
              ),
            ),
    );
  }
}
