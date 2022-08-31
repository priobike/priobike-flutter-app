import 'package:flutter/material.dart';

class Tile extends StatelessWidget {
  /// The content of the tile.
  final Widget content;

  /// A callback that is fired when the tile was tapped.
  final void Function()? onPressed;

  /// The fill color of the tile.
  final Color? fill;

  /// The splash of the tile, if the tile is tappable (a callback is passed).
  final Color splash;

  /// The padding of the tile.
  final EdgeInsets padding;

  /// The border radius of the tile.
  final BorderRadius borderRadius;

  const Tile({
    Key? key, 
    required this.content, 
    this.onPressed,
    this.fill,
    this.splash = Colors.grey,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  }) : super(key: key);
  
  @override 
  Widget build(BuildContext context) {
    // If we have no callback, we use a container wrapper.
    if (onPressed == null) {
      return Container(
        padding: padding, 
        decoration: BoxDecoration(
          color: fill,
          borderRadius: borderRadius,
          border: Border.all(color: Colors.black.withOpacity(0.1)),
        ),
        child: content,
      );
    }
    // Otherwise, we use a button wrapper with splash color.
    return RawMaterialButton(
      elevation: 0,
      hoverElevation: 0,
      focusElevation: 0,
      highlightElevation: 0,
      fillColor: fill ?? Theme.of(context).colorScheme.background,
      splashColor: splash,
      child: Container(
        padding: padding, 
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: Colors.black.withOpacity(0.1)),
        ),
        child: content,
      ),
      onPressed: onPressed,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
    );
  }
}