import 'package:flutter/material.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/routing/services/profile.dart';
import 'package:priobike/main.dart';

/// The icon that is shown during loading of the route.
class LoadingIcon extends StatefulWidget {
  const LoadingIcon({super.key});

  @override
  State<StatefulWidget> createState() => LoadingIconState();
}

class LoadingIconState extends State<LoadingIcon> {
  /// The begin opacity of the icon.
  double beginOpacity = 0.5;

  /// The end opacity of the icon.
  double endOpacity = 1.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: beginOpacity, end: endOpacity),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Image.asset(
            getIt<Profile>().bikeType.iconAsString(),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 54,
          ),
        );
      },
      onEnd: () {
        setState(
          () {
            // Restart the animation in reverse.
            final temp = beginOpacity;
            beginOpacity = endOpacity;
            endOpacity = temp;
          },
        );
      },
    );
  }
}
