import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/services/routing.dart';

/// The translation from of the road class.
final roadClassTranslation = {
  "motorway": "Autobahn",
  "trunk": "Fernstraße",
  "primary": "Hauptstraße",
  "secondary": "Landstraße",
  "tertiary": "Straße",
  "residential": "Wohnstraße",
  "unclassified": "Nicht klassifiziert",
  "service": "Zufahrtsstraße",
  "road": "Straße",
  "track": "Rennstrecke",
  "bridleway": "Reitweg",
  "steps": "Treppen",
  "cycleway": "Fahrradweg",
  "path": "Weg",
  "living_street": "Spielstraße",
  "footway": "Fußweg",
  "pedestrian": "Fußgängerzone",
  "platform": "Bahnsteig",
  "corridor": "Korridor",
  "other": "Sonstiges"
};

/// The color translation of road class.
final roadClassColor = {
  "Autobahn": const Color(0xFF5B81FF),
  "Fernstraße": const Color(0xFF90A9FF),
  "Hauptstraße": const Color(0xFF7f8c8d),
  "Landstraße": const Color(0xFFbdc3c7),
  "???": const Color(0xFFc0392b),
  "Wohnstraße": const Color(0xFFd35400),
  "Nicht klassifiziert": const Color(0xFFf39c12),
  "Zufahrtsstraße": const Color(0xFF95a5a6),
  "Straße": const Color(0xFFecf0f1),
  "Rennstrecke": const Color(0xFFf1c40f),
  "Reitweg": const Color(0xFF2c3e50),
  "Treppen": const Color(0xFF8e44ad),
  "Fahrradweg": const Color(0xFF2980b9),
  "Weg": const Color(0xFF27ae60),
  "Spielstraße": const Color(0xFF16a085),
  "Fußweg": const Color(0xFF34495e),
  "Fußgängerzone": const Color(0xFF9b59b6),
  "Bahnsteig": const Color(0xFF3498db),
  "Korridor": const Color(0xFF2ecc71),
  "Sonstiges": const Color(0xFF1abc9c)
};

class RoadClassChart extends StatefulWidget {
  const RoadClassChart({Key? key}) : super(key: key);

  @override
  RoadClassChartState createState() => RoadClassChartState();
}

class RoadClassChartState extends State<RoadClassChart> {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The details state of road class.
  bool showRoadClassDetails = true;

  /// The chart data.
  Map<String, double> roadClassDistances = {};

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    processRouteData();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    routing = getIt<Routing>();
    routing.addListener(update);

    processRouteData();
  }

  @override
  void dispose() {
    routing.removeListener(update);
    super.dispose();
  }

  /// Process the route data and create the chart series.
  Future<void> processRouteData() async {
    if (routing.selectedRoute == null) return setState(() => roadClassDistances = {});

    const vincenty = Distance(roundResult: false);
    roadClassDistances = {};
    for (GHSegment segment in routing.selectedRoute!.path.details.roadClass) {
      for (var coordIdx = segment.from; coordIdx < segment.to; coordIdx++) {
        final coordFrom = routing.selectedRoute!.path.points.coordinates[coordIdx];
        final coordTo = routing.selectedRoute!.path.points.coordinates[coordIdx + 1];
        final distance = vincenty.distance(LatLng(coordFrom.lat, coordFrom.lon), LatLng(coordTo.lat, coordTo.lon));
        if (roadClassDistances.containsKey(segment.value)) {
          roadClassDistances[segment.value] = roadClassDistances[segment.value]! + distance;
        } else {
          roadClassDistances[segment.value] = distance;
        }
      }
    }
  }

  /// Render the bar chart.
  Widget renderBar(BuildContext context) {
    if (roadClassDistances.isEmpty) return Container();
    if (routing.selectedRoute == null) return Container();
    final availableWidth = (MediaQuery.of(context).size.width - 62);
    var elements = <Widget>[];
    for (int i = 0; i < roadClassDistances.length; i++) {
      final e = roadClassDistances.entries.elementAt(i);
      var pct = (e.value / routing.selectedRoute!.path.distance);
      // Catch case pct > 1.
      pct = pct > 1 ? 1 : pct;
      elements.add(Container(
        width: (availableWidth * pct).floorToDouble(),
        height: 32,
        decoration: BoxDecoration(
          color: roadClassColor[roadClassTranslation[e.key] ?? "???"],
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.07),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: elements,
    );
  }

  /// Render the details below the bar chart.
  Widget renderDetails(BuildContext context) {
    if (roadClassDistances.isEmpty) return Container();
    if (routing.selectedRoute == null) return Container();
    var elements = <Widget>[];
    for (int i = 0; i < roadClassDistances.length; i++) {
      final e = roadClassDistances.entries.elementAt(i);
      var pct = ((e.value / routing.selectedRoute!.path.distance) * 100);
      // Catch case pct > 100.
      pct = pct > 100 ? 100 : pct;
      elements.add(Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 14,
              width: 14,
              decoration: BoxDecoration(
                color: roadClassColor[roadClassTranslation[e.key] ?? "???"],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.black.withOpacity(0.07),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Content(text: roadClassTranslation[e.key] ?? "Unbekannt", context: context),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Content(text: "${pct < 1 ? pct.toStringAsFixed(2) : pct.toStringAsFixed(0)}%", context: context),
              ),
            ),
          ],
        ),
      ));
    }
    return Column(children: elements);
  }

  @override
  Widget build(BuildContext context) {
    if (routing.selectedRoute == null) return Container();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => setState(() {
              showRoadClassDetails = !showRoadClassDetails;
            }),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Content(text: "Wegtypen", context: context),
              Row(children: [
                Content(
                  text: "Details",
                  context: context,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                showRoadClassDetails
                    ? Icon(Icons.keyboard_arrow_up_sharp, color: Theme.of(context).colorScheme.primary)
                    : Icon(Icons.keyboard_arrow_down_sharp, color: Theme.of(context).colorScheme.primary)
              ]),
            ]),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() {
              showRoadClassDetails = !showRoadClassDetails;
            }),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                renderBar(context),
                AnimatedCrossFade(
                  firstCurve: Curves.easeInOutCubic,
                  secondCurve: Curves.easeInOutCubic,
                  sizeCurve: Curves.easeInOutCubic,
                  duration: const Duration(milliseconds: 1000),
                  firstChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: renderDetails(context),
                  ),
                  secondChild: Container(),
                  crossFadeState: showRoadClassDetails ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
