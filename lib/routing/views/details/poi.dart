import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';

class PoisChart extends StatefulWidget {
  const PoisChart({super.key});

  @override
  PoisChartState createState() => PoisChartState();
}

class PoisChartState extends State<PoisChart> {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The details state of pois.
  bool showPoiDetails = true;

  /// The chart data.
  Map<String, double> poiDistances = {};

  /// The chart color data.
  Map<String, Color> poiColors = {};

  /// The text for route segments without pois.
  static const noPoisText = 'Keine weiteren Details';

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    processPoiData();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    routing = getIt<Routing>();
    routing.addListener(update);

    processPoiData();
  }

  @override
  void dispose() {
    routing.removeListener(update);
    super.dispose();
  }

  /// Process the route data and create the chart series.
  void processPoiData() {
    if (routing.selectedRoute == null || routing.selectedRoute!.foundPois == null) {
      return setState(() => poiDistances = {});
    }

    const vincenty = Distance(roundResult: false);
    poiDistances = {};
    poiColors = {};
    for (final poi in routing.selectedRoute!.foundPois!) {
      for (var idx = 0; idx < poi.coordinates.length - 1; idx++) {
        final distance = vincenty.distance(LatLng(poi.coordinates[idx].latitude, poi.coordinates[idx].longitude),
            LatLng(poi.coordinates[idx + 1].latitude, poi.coordinates[idx + 1].longitude));
        if (poiDistances.containsKey(poi.description)) {
          poiDistances[poi.description] = poiDistances[poi.description]! + distance;
        } else {
          poiDistances[poi.description] = distance;
          poiColors[poi.description] = poi.color;
        }
      }
    }

    // Fill up with road where no pois were found.
    final totalDistance = poiDistances.values.fold<double>(0, (previousValue, element) => previousValue + element);
    if (totalDistance < routing.selectedRoute!.path.distance) {
      final remainingDistance = routing.selectedRoute!.path.distance - totalDistance;
      poiDistances[noPoisText] = remainingDistance;
      // No poi segments are grey.
      poiColors[noPoisText] = const Color(0xFFd6d6d6);
    }

    // Sort the pois by distance.
    poiDistances = Map.fromEntries(poiDistances.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)));
  }

  /// Render the bar chart.
  Widget renderBar() {
    final fallbackView = Container(
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.07)
            : Colors.black.withOpacity(0.07),
        borderRadius: BorderRadius.circular(4),
      ),
    );

    if (poiDistances.isEmpty || routing.selectedRoute == null || routing.selectedRoute!.foundPois == null) {
      return fallbackView;
    }

    final availableWidth = (MediaQuery.of(context).size.width - 62);
    var elements = <Widget>[];
    var sumOfPoiDistances = poiDistances.values.fold<double>(0, (previousValue, element) => previousValue + element);
    sumOfPoiDistances = max(sumOfPoiDistances, routing.selectedRoute!.path.distance);
    if (sumOfPoiDistances == 0) {
      return fallbackView;
    }
    for (int i = 0; i < poiDistances.length; i++) {
      final e = poiDistances.entries.elementAt(i);
      var pct = (e.value / sumOfPoiDistances);
      // Catch case pct > 1.
      pct = pct > 1 ? 1 : pct;
      elements.add(Container(
        width: (availableWidth * pct).floorToDouble(),
        height: 32,
        decoration: BoxDecoration(
          color: poiColors[e.key],
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.07),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ));
    }
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: elements);
  }

  /// Render the details below the bar chart.
  Widget renderDetails() {
    if (poiDistances.isEmpty || routing.selectedRoute == null) return Container();
    var elements = <Widget>[];
    for (int i = 0; i < poiDistances.length; i++) {
      final e = poiDistances.entries.elementAt(i);
      var text = e.key;
      elements.add(Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 14,
              width: 14,
              decoration: BoxDecoration(
                color: poiColors[e.key],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.black.withOpacity(0.07),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Content(text: text, context: context),
            ),
            const HSpace(),
            Align(
              alignment: Alignment.centerRight,
              child: Content(
                text: e.value > 1000 ? '${(e.value / 1000).toStringAsFixed(0)} km' : '${e.value.toStringAsFixed(0)} m',
                context: context,
              ),
            ),
          ],
        ),
      ));
    }
    return Column(
      children: elements,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (poiDistances.isEmpty || routing.selectedRoute == null || routing.selectedRoute!.foundPois == null) {
      return Container();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.onTertiary.withOpacity(0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                showPoiDetails = !showPoiDetails;
              });
            },
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Content(text: "Weitere Details", context: context),
              SizedBox(
                width: 40,
                height: 40,
                child: SmallIconButtonTertiary(
                  icon: showPoiDetails ? Icons.keyboard_arrow_up_sharp : Icons.keyboard_arrow_down_sharp,
                  onPressed: () => setState(() {
                    showPoiDetails = !showPoiDetails;
                  }),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() {
              showPoiDetails = !showPoiDetails;
            }),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                renderBar(),
                AnimatedCrossFade(
                  firstCurve: Curves.easeInOutCubic,
                  secondCurve: Curves.easeInOutCubic,
                  sizeCurve: Curves.easeInOutCubic,
                  duration: const Duration(milliseconds: 1000),
                  firstChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: renderDetails(),
                  ),
                  secondChild: Container(),
                  crossFadeState: showPoiDetails ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
