import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The annotated region sets the colors for the operation system top status bar and bottom navigation bar
class AnnotatedRegionWrapper extends StatelessWidget {
  /// The mode of the app, light mode or dark mode.
  final Brightness colorMode;

  /// The child widget.
  final Widget child;

  /// The background color used for the navigation bar (Android).
  final Color bottomBackgroundColor;

  /// The brightness of the text of the top status bar (Android).
  final Brightness? topTextBrightness;

  /// The brightness of the text of the bottom navigation bar (Android).
  final Brightness? bottomTextBrightness;

  const AnnotatedRegionWrapper({
    super.key,
    required this.bottomBackgroundColor,
    required this.colorMode,
    required this.child,
    this.topTextBrightness,
    this.bottomTextBrightness,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: colorMode == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              // The navigation bar on the bottom of the screen on Android.
              systemNavigationBarColor: bottomBackgroundColor,

              // The text on the navigation bar on Android.
              systemNavigationBarIconBrightness: bottomTextBrightness ?? Brightness.light,

              // The text on the status bar on top on Android.
              statusBarIconBrightness: topTextBrightness ?? Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              systemNavigationBarColor: bottomBackgroundColor,
              systemNavigationBarIconBrightness: bottomTextBrightness ?? Brightness.dark,
              statusBarIconBrightness: topTextBrightness ?? Brightness.dark,
            ),
      child: child,
    );
  }
}
