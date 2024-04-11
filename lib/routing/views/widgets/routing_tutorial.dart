import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';

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

  /// Whether the info text should be animated into the screen.
  double infoTextOpacity = 0.0;

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
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      infoTextOpacity = 1.0;
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
            // Pad right plus half icon width.
            right: 8 + 29,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInCubic,
                  // Screen width - padding left - icon width - padding - padding right - half map legend width.
                  width: showInfoContainer ? size.width - 8 - 64 - 8 - 29 : 0,
                  // MapLegend height: Icon + Padding + Icon + Padding + Icon + Padding + Icon + Padding + Border.
                  height: 58 + 8 + 24 + 8 + 24 + 8 + 24 + 8 + 2,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    border: Border.all(
                      width: 1,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.07)
                          : Colors.black.withOpacity(0.07),
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(seconds: 1),
                    opacity: infoTextOpacity,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 4),
                      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 58,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SubHeader(text: "Prognoseverfügbarkeit", context: context),
                                    Content(
                                      text: "entlang deiner Route",
                                      context: context,
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 32,
                                child: Row(children: [
                                  Flexible(
                                    flex: 1,
                                    child: Small(text: "Angebundene Kreuzungen ohne Prognose", context: context),
                                  ),
                                  const HSpace(),
                                  const Icon(
                                    Icons.play_arrow_rounded,
                                    color: CI.route,
                                  ),
                                ]),
                              ),
                              SizedBox(
                                height: 32,
                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Flexible(
                                    flex: 1,
                                    child: Small(
                                      text: "Angebundene Kreuzungen mit Prognose",
                                      context: context,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const HSpace(),
                                  const Icon(
                                    Icons.play_arrow_rounded,
                                    color: CI.radkulturGreen,
                                  ),
                                ]),
                              ),
                              SizedBox(
                                height: 32,
                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Flexible(
                                    flex: 1,
                                    child: Small(text: "Nicht Angebundene Kreuzungen", context: context),
                                  ),
                                  const HSpace(),
                                  const Icon(
                                    Icons.play_arrow_rounded,
                                    color: CI.secondaryRoute,
                                  ),
                                ]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          // half map legend width.
                          width: 29,
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
