import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The annotated region sets the colors for the operation system top status bar and bottom navigation bar
class AnnotatedRegionWrapper extends StatelessWidget {
  /// The background color used for the navigation bar (Android).
  final Color backgroundColor;

  /// The mode of the app, light mode or dark mode.
  final Brightness brightness;

  /// The child widget.
  final Widget child;

  /// The brightness of the text of the top status bar (Android).
  final Brightness? statusBarIconBrightness;

  /// The brightness of the text of the bottom navigation bar (Android).
  final Brightness? systemNavigationBarIconBrightness;

  const AnnotatedRegionWrapper({
    super.key,
    required this.backgroundColor,
    required this.brightness,
    required this.child,
    this.statusBarIconBrightness,
    this.systemNavigationBarIconBrightness,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              // The navigation bar on the bottom of the screen on Android.
              systemNavigationBarColor: backgroundColor,

              // The text on the navigation bar on Android.
              systemNavigationBarIconBrightness: systemNavigationBarIconBrightness ?? Brightness.light,

              // The text on the status bar on top on Android.
              statusBarIconBrightness: statusBarIconBrightness ?? Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              systemNavigationBarColor: backgroundColor,
              systemNavigationBarIconBrightness: systemNavigationBarIconBrightness ?? Brightness.dark,
              statusBarIconBrightness: statusBarIconBrightness ?? Brightness.dark,
            ),
      child: child,
    );
  }
}
