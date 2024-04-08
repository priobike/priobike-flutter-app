import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// The routing tutorial view that is shown when first creating a route.
class RoutingTutorialView extends StatefulWidget {
  const RoutingTutorialView({super.key});

  @override
  State<StatefulWidget> createState() => RoutingTutorialViewState();
}

class RoutingTutorialViewState extends State<RoutingTutorialView> {
  /// The background color of the underlying container.
  Color backgroundColor = Colors.black.withOpacity(0);

  /// Whether the info container should be animated into the screen.
  bool showInfoContainer = false;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _startAnimation();
    });
  }

  /// Function that starts the animation of the tutorial view.
  void _startAnimation() async {
    setState(() {
      backgroundColor = Colors.black.withOpacity(0.5);
    });
    // Wait for map legend animation.
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      showInfoContainer = true;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      width: size.width,
      height: size.height,
      color: backgroundColor,
      child: Stack(
        children: [
          // Side Bar right
          Positioned(
            right: 8,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  // Screen width - padding left - icon width - padding - padding right.
                  width: showInfoContainer ? size.width - 8 - 64 - 8 - 8 : 58,
                  // MapLegend height: 58 + 8 + 24 + 8 + 24 + 8 + 24 + 8.
                  height: 58 + 8 + 24 + 8 + 24 + 8 + 24 + 8 + 2,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    border: Border.all(
                      width: 1,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.07)
                          : Colors.black.withOpacity(0.07),
                    ),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(24),
                    ),
                  ),
                  child: Container(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
