import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/details/map_legend.dart';
import 'package:priobike/tutorial/service.dart';

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

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated Tutorial service, which is injected by the provider.
  late Tutorial tutorial;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    setState(() {});
    // If animation started already return;
    if (showInfoContainer == true) return;

    // Start animation if needed.
    if (routing.selectedRoute != null &&
        tutorial.isCompleted("priobike.tutorial.routing.info") != null &&
        !tutorial.isCompleted("priobike.tutorial.routing.info")!) {
      _startAnimation();
    }
  }

  @override
  void initState() {
    super.initState();

    routing = getIt<Routing>();
    routing.addListener(update);

    tutorial = getIt<Tutorial>();
    tutorial.addListener(update);
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
  }

  /// Function that starts the animation of the tutorial view.
  void _endAnimation() async {
    setState(() {
      backgroundColor = Colors.black.withOpacity(0);
      showInfoContainer = false;
    });
    await Future.delayed(const Duration(seconds: 1));
    tutorial.complete("priobike.tutorial.routing.info");
  }

  @override
  void dispose() {
    routing.removeListener(update);
    tutorial.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Display the tutorial for the routing info when the first route got created to inform the user about the traffic lights.
    if (routing.selectedRoute == null) return Container();
    if (tutorial.isCompleted("priobike.tutorial.routing.info") == null ||
        tutorial.isCompleted("priobike.tutorial.routing.info")!) return Container();

    Size size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        // To prevent accidentally closing the tutorial.
        if (!showInfoContainer) return;
        _endAnimation();
      },
      child: AnimatedContainer(
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                      border: Border.all(
                        width: showInfoContainer ? 1 : 0,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.07)
                            : Colors.black.withOpacity(0.07),
                      ),
                    ),
                    child: AnimatedCrossFade(
                      crossFadeState: showInfoContainer ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 1000),
                      firstCurve: Curves.easeInOutCubic,
                      secondCurve: Curves.easeInOutCubic,
                      sizeCurve: Curves.easeInOutCubic,
                      firstChild: Container(
                        // Screen width - padding left - icon width - padding - padding right - half map legend width.
                        width: size.width - 8 - 64 - 8 - 29,
                        // MapLegend height: Icon + Padding + Icon + Padding + Icon + Padding + Icon + Padding.
                        height: 58 + 8 + 24 + 8 + 24 + 8 + 24 + 8,
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
                                        BoldContent(
                                          text: "Prognoseverfügbarkeit",
                                          context: context,
                                        ),
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
                      secondChild: Container(
                        // MapLegend height: Icon + Padding + Icon + Padding + Icon + Padding + Icon + Padding.
                        height: 58 + 8 + 24 + 8 + 24 + 8 + 24 + 8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: MapLegend(
                    tutorialViewClose: _endAnimation,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
