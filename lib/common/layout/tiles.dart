import 'package:flutter/material.dart';

/// A reusable stylized container with optional on-click listener (primary).
class TilePrimary extends StatelessWidget {
  /// The content of the tile.
  final Widget content;

  /// A callback that is fired when the tile was tapped.
  final void Function()? onPressed;

  /// A callback that is fired when the tile is long pressed.
  final void Function()? onLongPressed;

  /// The fill color of the tile.
  final Color? fill;

  /// The splash of the tile, if the tile is tappable (a callback is passed).
  final Color? splash;

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

  /// The color of the border.
  final Color? borderColor;

  /// The width of the border
  final double borderWidth;

  const TilePrimary({
    super.key,
    required this.content,
    this.onPressed,
    this.onLongPressed,
    this.fill,
    this.splash,
    this.shadow = Colors.black,
    this.shadowIntensity = 0.05,
    this.showShadow = true,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(24),
    ),
  });

  @override
  Widget build(BuildContext context) {
    var bColor = borderColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.07)
            : Colors.black.withOpacity(0.07));
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
          width: borderWidth,
          color: bColor,
        ),
      ),
      child: onPressed == null
          ? Padding(padding: padding, child: content)
          : Material(
              borderRadius: borderRadius,
              color: Colors.transparent,
              child: InkWell(
                borderRadius: borderRadius,
                splashColor: splash ?? Theme.of(context).colorScheme.surfaceTint,
                onTap: onPressed,
                onLongPress: onLongPressed,
                child: Padding(padding: padding, child: content),
              ),
            ),
    );
  }
}

/// A reusable stylized container with optional on-click listener (secondary).
class TileSecondary extends StatelessWidget {
  /// The content of the tile.
  final Widget content;

  /// A callback that is fired when the tile was tapped.
  final void Function()? onPressed;

  /// A callback that is fired when the tile is long pressed.
  final void Function()? onLongPressed;

  /// The fill color of the tile.
  final Color? fill;

  /// The splash of the tile, if the tile is tappable (a callback is passed).
  final Color? splash;

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

  /// The color of the border.
  final Color? borderColor;

  /// The width of the border
  final double borderWidth;

  const TileSecondary({
    super.key,
    required this.content,
    this.onPressed,
    this.onLongPressed,
    this.fill = Colors.white,
    this.splash,
    this.shadow = Colors.black,
    this.shadowIntensity = 0.05,
    this.showShadow = true,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.borderColor,
    this.borderWidth = 2.0,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(24),
    ),
  });

  @override
  Widget build(BuildContext context) {
    var bColor = borderColor ?? Theme.of(context).colorScheme.primary;
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
          width: borderWidth,
          color: bColor,
        ),
      ),
      child: onPressed == null
          ? Padding(padding: padding, child: content)
          : Material(
              borderRadius: borderRadius,
              color: Colors.transparent,
              child: InkWell(
                borderRadius: borderRadius,
                splashColor: splash ?? Theme.of(context).colorScheme.surfaceTint,
                onTap: onPressed,
                onLongPress: onLongPressed,
                child: Padding(padding: padding, child: content),
              ),
            ),
    );
  }
}
