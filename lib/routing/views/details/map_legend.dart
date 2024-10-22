import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/images.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/status/services/sg.dart';

class MapLegend extends StatefulWidget {
  const MapLegend({super.key});

  @override
  MapLegendState createState() => MapLegendState();
}

class MapLegendState extends State<MapLegend> {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated status service, which is injected by the provider.
  late PredictionSGStatus status;

  /// Whether the crossing info should be shown.
  bool showInfo = false;

  /// Called when a listener callback of a ChangeNotifier is fired.
  Future<void> update() async {
    // Small delay to ensure timing for tutorial view.
    await Future.delayed(const Duration(milliseconds: 250));

    if (mounted) {
      setState(() {
        showInfo = !routing.isFetchingRoute && routing.selectedRoute != null;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    routing = getIt<Routing>();
    routing.addListener(update);

    status = getIt<PredictionSGStatus>();
    status.addListener(update);

    // To ensure animating for routing tutorial view.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      setState(() {
        showInfo = !routing.isFetchingRoute && routing.selectedRoute != null;
      });
    });
  }

  @override
  void dispose() {
    routing.removeListener(update);
    status.removeListener(update);
    super.dispose();
  }

  /// A callback that is fired when the user wants to select the displayed layers.
  void showMapLegendSheet() {
    showAppSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MapLegendView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: showMapLegendSheet,
          child: Container(
            margin: const EdgeInsets.only(top: 20),
            width: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border: Border.all(
                width: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.5)
                    : Colors.black.withOpacity(0.07),
              ),
            ),
            child: AnimatedCrossFade(
              crossFadeState: showInfo ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 1000),
              firstCurve: Curves.easeInOutCubic,
              secondCurve: Curves.easeInOutCubic,
              sizeCurve: Curves.easeInOutCubic,
              secondChild: Container(),
              firstChild: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    const SmallVSpace(),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).brightness == Brightness.dark ? CI.darkModeRoute : CI.lightModeRoute,
                        border: Border.all(color: CI.routeBackground, width: 2),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: Platform.isAndroid ? 3 : 0),
                        child: Center(
                          child: BoldSmall(
                            context: context,
                            text: routing.isFetchingRoute || routing.selectedRoute == null
                                ? "-"
                                : ((routing.selectedRoute!.bad) + (routing.selectedRoute!.offline)).toString(),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SmallVSpace(),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color.fromRGBO(0, 255, 106, 1),
                        border: Border.all(color: CI.radkulturGreen, width: 2),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: Platform.isAndroid ? 3 : 0),
                        child: Center(
                          child: BoldSmall(
                            context: context,
                            text: routing.isFetchingRoute || routing.selectedRoute == null
                                ? "-"
                                : (routing.selectedRoute!.ok).toString(),
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SmallVSpace(),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color.fromRGBO(217, 217, 217, 1),
                        border: Border.all(color: const Color.fromRGBO(152, 152, 152, 1), width: 2),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: Platform.isAndroid ? 3 : 0),
                        child: Center(
                          child: BoldSmall(
                            context: context,
                            text: routing.isFetchingRoute || routing.selectedRoute == null
                                ? "-"
                                : (routing.selectedRoute!.disconnected).toString(),
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SmallVSpace(),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 42,
          height: 42,
          child: Tile(
            fill: Theme.of(context).colorScheme.surfaceVariant,
            padding: const EdgeInsets.all(0),
            // Needed to center the icon
            onPressed: showMapLegendSheet,
            borderColor: Theme.of(context).brightness == Brightness.light
                ? null
                : Theme.of(context).colorScheme.onPrimary.withOpacity(0.35),
            content: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapLegendView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 5 / 1,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CurrentPositionWithoutShadow(context: context),
                    ),
                    const HSpace(),
                    Flexible(
                      child: Content(text: "Aktuelle Position", context: context),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: StartIcon(),
                    ),
                    const HSpace(),
                    Flexible(
                      child: Content(text: "Startpunkt", context: context),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: WaypointIcon(),
                    ),
                    const HSpace(),
                    Flexible(
                      child: Content(text: "Wegpunkt", context: context),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: DestinationIcon(),
                    ),
                    const HSpace(),
                    Flexible(
                      child: Content(text: "Ziel", context: context),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).brightness == Brightness.dark ? CI.darkModeRoute : CI.lightModeRoute,
                      ),
                    ),
                    const SmallHSpace(),
                    Flexible(
                      child: Content(
                        text: "Ausgewählte Route",
                        context: context,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? CI.darkModeSecondaryRoute
                            : CI.lightModeSecondaryRoute,
                      ),
                    ),
                    const SmallHSpace(),
                    Flexible(
                      child: Content(
                        text: "Alternative Route",
                        context: context,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color.fromRGBO(0, 255, 106, 1),
                      ),
                    ),
                    const SmallHSpace(),
                    Flexible(
                      child: Content(
                        text: "Prognosen vorhanden",
                        context: context,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: CI.radkulturYellow,
                            ),
                          ),
                        ),
                        // Icon
                        Image.asset(
                          "assets/images/pois/accidenthotspot.png",
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    const SmallHSpace(),
                    Flexible(
                      child: Content(
                        text: "Warnungen",
                        context: context,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const VSpace(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromRGBO(0, 255, 106, 1),
                    border: Border.all(color: const Color.fromRGBO(0, 179, 74, 1), width: 1),
                  ),
                ),
                const HSpace(),
                Flexible(
                  child: Content(text: "Ampeln entlang Deiner Route mit Geschwindigkeitsempfehlung.", context: context),
                ),
              ],
            ),
            const VSpace(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromRGBO(0, 115, 255, 1),
                    border: Border.all(color: const Color.fromRGBO(0, 69, 150, 1), width: 1),
                  ),
                ),
                const HSpace(),
                Flexible(
                  child: Content(
                    text:
                        "Weitere angebundene Ampeln entlang Deiner Route, die aktuell jedoch keine Geschwindigkeitsempfehlung haben.",
                    context: context,
                    maxLines: 5,
                  ),
                ),
              ],
            ),
            const VSpace(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromRGBO(217, 217, 217, 1),
                    border: Border.all(color: const Color.fromRGBO(152, 152, 152, 1), width: 1),
                  ),
                ),
                const HSpace(),
                Flexible(
                  child: Content(
                      text:
                          "Weitere Kreuzungen, an welchen Ampeln liegen könnten, die jedoch nicht im System angebunden sind.",
                      context: context),
                ),
              ],
            ),
            const VSpace(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color.fromRGBO(0, 75, 130, 1) : const Color.fromRGBO(196, 220, 248, 1),
                  ),
                ),
                const HSpace(),
                Flexible(
                  child: Content(text: "Alle Kreuzungen, welche im System angebunden sind.", context: context),
                ),
              ],
            ),
            const VSpace(),
          ],
        ),
      ),
    );
  }
}
