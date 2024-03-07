import 'package:flutter/material.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/status/services/sg.dart';

/// The icon that is shown during loading of the route.
class LoadingIcon extends StatefulWidget {
  const LoadingIcon({super.key});

  @override
  State<StatefulWidget> createState() => LoadingIconState();
}

class LoadingIconState extends State<LoadingIcon> with SingleTickerProviderStateMixin {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated status service, which is injected by the provider.
  late PredictionSGStatus status;

  /// The begin opacity of the icon.
  double beginOpacity = 0.5;

  /// The end opacity of the icon.
  double endOpacity = 1.0;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    routing = getIt<Routing>();
    routing.addListener(update);
    status = getIt<PredictionSGStatus>();
    status.addListener(update);
  }

  @override
  void dispose() {
    routing.removeListener(update);
    status.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The bottom sheet is ready when the route is not being fetched or if the free ride mode was used.
    final bottomSheetIsReady = (!routing.isFetchingRoute && routing.hasloaded && !status.isLoading) ||
        routing.selectedWaypoints == null ||
        routing.selectedWaypoints!.isEmpty;

    if (bottomSheetIsReady) return Container();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: beginOpacity, end: endOpacity),
      duration: const Duration(milliseconds: 1000),
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Image.asset(
            getIt<Profile>().bikeType.iconAsString()!,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 54,
          ),
        );
      },
      onEnd: () {
        setState(
          () {
            // Swap the begin and end opacity to restart the animation in reverse.
            final temp = beginOpacity;
            beginOpacity = endOpacity;
            endOpacity = temp;
          },
        );
      },
    );
  }
}
