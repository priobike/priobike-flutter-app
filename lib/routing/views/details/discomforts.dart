import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';

class DiscomfortsChart extends StatefulWidget {
  const DiscomfortsChart({super.key});

  @override
  DiscomfortsChartState createState() => DiscomfortsChartState();
}

class DiscomfortsChartState extends State<DiscomfortsChart> {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The details state of discomforts.
  bool showDiscomfortDetails = true;

  /// The chart data.
  Map<String, double> discomfortDistances = {};

  /// The chart color data.
  Map<String, Color> discomfortColors = {};

  /// The text for route segments without discomforts.
  static const noDiscomfortsText = 'Keine bekannten Probleme';

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    processDiscomfortData();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    routing = getIt<Routing>();
    routing.addListener(update);

    processDiscomfortData();
  }

  @override
  void dispose() {
    routing.removeListener(update);
    super.dispose();
  }

  /// Process the route data and create the chart series.
  void processDiscomfortData() {
    if (routing.selectedRoute == null || routing.selectedRoute!.foundDiscomforts == null) {
      return setState(() => discomfortDistances = {});
    }

    const vincenty = Distance(roundResult: false);
    discomfortDistances = {};
    discomfortColors = {};
    for (final discomfort in routing.selectedRoute!.foundDiscomforts!) {
      for (var idx = 0; idx < discomfort.coordinates.length - 1; idx++) {
        final distance = vincenty.distance(
            LatLng(discomfort.coordinates[idx].latitude, discomfort.coordinates[idx].longitude),
            LatLng(discomfort.coordinates[idx + 1].latitude, discomfort.coordinates[idx + 1].longitude));
        if (discomfortDistances.containsKey(discomfort.description)) {
          discomfortDistances[discomfort.description] = discomfortDistances[discomfort.description]! + distance;
        } else {
          discomfortDistances[discomfort.description] = distance;
          discomfortColors[discomfort.description] = discomfort.color;
        }
      }
    }

    // Fill up with road where no discomforts were found.
    final totalDistance =
        discomfortDistances.values.fold<double>(0, (previousValue, element) => previousValue + element);
    if (totalDistance < routing.selectedRoute!.path.distance) {
      final remainingDistance = routing.selectedRoute!.path.distance - totalDistance;
      discomfortDistances[noDiscomfortsText] = remainingDistance;
      // No discomfort segments are grey.
      discomfortColors[noDiscomfortsText] = const Color(0xFFd6d6d6);
    }

    // Sort the discomforts by distance.
    discomfortDistances =
        Map.fromEntries(discomfortDistances.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)));
  }

  /// Render the bar chart.
  Widget renderBar() {
    if (discomfortDistances.isEmpty ||
        routing.selectedRoute == null ||
        routing.selectedRoute!.foundDiscomforts == null) {
      return Container();
    }

    final availableWidth = (MediaQuery.of(context).size.width - 62);
    var elements = <Widget>[];
    for (int i = 0; i < discomfortDistances.length; i++) {
      final e = discomfortDistances.entries.elementAt(i);
      var pct = (e.value / routing.selectedRoute!.path.distance);
      // Catch case pct > 1.
      pct = pct > 1 ? 1 : pct;
      elements.add(Container(
        width: (availableWidth * pct).floorToDouble(),
        height: 32,
        decoration: BoxDecoration(
          color: discomfortColors[e.key],
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
    if (discomfortDistances.isEmpty || routing.selectedRoute == null) return Container();
    var elements = <Widget>[];
    for (int i = 0; i < discomfortDistances.length; i++) {
      final e = discomfortDistances.entries.elementAt(i);
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
                color: discomfortColors[e.key],
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
    if (discomfortDistances.isEmpty ||
        routing.selectedRoute == null ||
        routing.selectedRoute!.foundDiscomforts == null) {
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
                showDiscomfortDetails = !showDiscomfortDetails;
              });
            },
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Content(text: "Unwegsamkeiten", context: context),
              SizedBox(
                width: 40,
                height: 40,
                child: SmallIconButtonTertiary(
                  icon: showDiscomfortDetails ? Icons.keyboard_arrow_up_sharp : Icons.keyboard_arrow_down_sharp,
                  onPressed: () => setState(() {
                    showDiscomfortDetails = !showDiscomfortDetails;
                  }),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() {
              showDiscomfortDetails = !showDiscomfortDetails;
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
                  crossFadeState: showDiscomfortDetails ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
