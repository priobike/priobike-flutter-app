import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/text.dart';
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
  "Hauptstraße": const Color(0xFF3758FF),
  "Landstraße": const Color(0xFFACC7FF),
  "???": const Color(0xFFFFFFFF),
  "Wohnstraße": const Color(0xFFFFE4F8),
  "Nicht klassifiziert": const Color(0xFF686868),
  "Zufahrtsstraße": const Color(0xFF282828),
  "Straße": const Color(0xFF282828),
  "Rennstrecke": const Color(0xFFB74093),
  "Reitweg": const Color(0xFF572B28),
  "Treppen": const Color(0xFFB74093),
  "Fahrradweg": const Color(0xFF993D4C),
  "Weg": const Color(0xFF362626),
  "Spielstraße": const Color(0xFF1A4BFF),
  "Fußweg": const Color(0xFF8E8E8E),
  "Fußgängerzone": const Color(0xFF192765),
  "Bahnsteig": const Color(0xFF2A0029),
  "Korridor": const Color(0xFFB74093),
  "Sonstiges": const Color(0xFFB74093)
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
  bool showRoadClassDetails = false;

  /// The chart data.
  Map<String, double> roadClassDistances = {};

  /// Called when a listener callback of a ChangeNotifier is fired.
  late VoidCallback update;

  /// The singleton instance of our dependency injection service.
  final getIt = GetIt.instance;

  @override
  void initState() {
    super.initState();
    update = () {
      processRouteData();
      setState(() {});
    };

    routing = getIt.get<Routing>();
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
    final availableWidth = (MediaQuery.of(context).size.width - 24);
    var elements = <Widget>[];
    for (int i = 0; i < roadClassDistances.length; i++) {
      final e = roadClassDistances.entries.elementAt(i);
      elements.add(Container(
        width: (availableWidth * e.value / routing.selectedRoute!.path.distance).floorToDouble(),
        height: 42,
        decoration: BoxDecoration(
          color: roadClassColor[roadClassTranslation[e.key] ?? "???"],
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              spreadRadius: 0,
              blurRadius: 2,
              offset: const Offset(1, 0.5), // changes position of shadow
            ),
          ],
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
      final pct = (e.value / routing.selectedRoute!.path.distance) * 100;
      elements.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              height: 18,
              width: 18,
              decoration: BoxDecoration(
                color: roadClassColor[roadClassTranslation[e.key] ?? "???"],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    spreadRadius: 0,
                    blurRadius: 2,
                    offset: const Offset(1, 0.5), // changes position of shadow
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Content(text: roadClassTranslation[e.key] ?? "Unbekannt", context: context),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Content(text: "${pct.toStringAsFixed(2)}%", context: context),
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

    return Column(
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
                  ? Icon(Icons.keyboard_arrow_down_sharp, color: Theme.of(context).colorScheme.primary)
                  : Icon(Icons.keyboard_arrow_up_sharp, color: Theme.of(context).colorScheme.primary)
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
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  child: renderDetails(context),
                ),
                secondChild: Container(),
                crossFadeState: showRoadClassDetails ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
