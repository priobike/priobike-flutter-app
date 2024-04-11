import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/services/routing.dart';

/// The translation from of the road class.
/// Information from: https://wiki.openstreetmap.org/wiki/Key:highway and https://wiki.openstreetmap.org/wiki/Attribuierung_von_Stra%C3%9Fen_in_Deutschland
final roadClassTranslation = {
  // A restricted access major divided highway, normally with 2 or more running lanes plus emergency hard shoulder. Equivalent to the Freeway, Autobahn, etc..
  "motorway": "Autobahn",
  // The most important roads in a country's system that aren't motorways. (Need not necessarily be a divided highway.)
  "trunk": "Fernstraße",
  // The next most important roads in a country's system. (Often link larger towns.)
  "primary": "Bundesstraße",
  // The next most important roads in a country's system. (Often link towns.)
  "secondary": "Landstraße",
  // The next most important roads in a country's system. (Often link smaller towns and villages)
  // For more clarity we leave out "Kreis" from "Kreisstraße".
  "tertiary": "Straße",
  // Roads which serve as an access to housing, without function of connecting settlements. Often lined with housing.
  "residential": "Straße",
  // The least important through roads in a country's system. The word 'unclassified' is a historical artefact of the UK road system and does not mean that the classification is unknown.
  // Therefore similar to tertiary. More detailed would be "Nebenstraße".
  "unclassified": "Straße",
  // For access roads to, or within an industrial estate, camp site, business park, car park, alleys.
  "service": "Zufahrtsstraße",
  // A road/way/street/motorway/etc. of unknown type. It can stand for anything ranging from a footpath to a motorway.
  "road": "Unbekannt",
  // Roads for mostly agricultural or forestry uses.
  "track": "Feldweg",
  // For horse riders.
  "bridleway": "Reitweg",
  // For flights of steps (stairs) on footways.
  "steps": "Treppen",
  // For designated cycleways.
  "cycleway": "Fahrradweg",
  // A non-specific path.
  "path": "Weg",
  // For living streets, which are residential streets where pedestrians have legal priority over cars.
  "living_street": "Spielstraße",
  // For designated footpaths.
  "footway": "Fußweg",
  // For roads used mainly/exclusively for pedestrians in shopping and some residential areas which may allow access by motorised vehicles.
  "pedestrian": "Fußgängerzone",
  // A platform at a bus stop or station.
  "platform": "Bahnsteig",
  // For a hallway inside of a building.
  "corridor": "Korridor",
  "other": "Sonstiges"
};

/// The color translation of road class.
final roadClassColor = {
  "Autobahn": const Color(0xFFFA1E41),
  "Fernstraße": const Color(0xFFD4B700),
  "Bundesstraße": const Color(0xFFE6AA10),
  "Landstraße": const Color(0xFFFFDC00),
  "Straße": const Color(0xFF8CCF9C),
  "Zufahrtsstraße": const Color(0xFF9C9C9C),
  "Unbekannt": const Color(0xFF7C7C7C),
  "Feldweg": const Color(0xFFA8EDB9),
  "Reitweg": const Color(0xFFA79000),
  "Treppen": const Color(0xFF9C4452),
  "Fahrradweg": const Color(0xFF28CD50),
  "Weg": const Color(0xFF58755F),
  "Spielstraße": const Color(0xFF405645),
  "Fußweg": const Color(0xFFD8CD88),
  "Fußgängerzone": const Color(0xFFEB9034),
  "Absteigen": const Color(0xFFFFD600),
  "Bahnsteig": const Color(0xFFDC576C),
  "Korridor": const Color(0xFFFF4260),
  "Sonstiges": const Color(0xFF676767)
};

class RoadClassChart extends StatefulWidget {
  const RoadClassChart({super.key});

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

    // Check if we need to get off the bike at certain parts of the route.
    final getOffBikeIndices = HashSet<int>();
    for (GHSegment segment in routing.selectedRoute!.path.details.getOffBike) {
      if (segment.value) {
        for (var coordIdx = segment.from; coordIdx < segment.to; coordIdx++) {
          getOffBikeIndices.add(coordIdx);
        }
      }
    }

    // Gather corresponding OSM way IDs.
    final List<int> osmWayIDs = [];
    for (GHSegment segment in routing.selectedRoute!.path.details.osmWayId) {
      for (var coordIdx = segment.from; coordIdx < segment.to; coordIdx++) {
        osmWayIDs.add(segment.value);
      }
    }

    const vincenty = Distance(roundResult: false);
    roadClassDistances = {};
    for (GHSegment segment in routing.selectedRoute!.path.details.roadClass) {
      for (var coordIdx = segment.from; coordIdx < segment.to; coordIdx++) {
        final coordFrom = routing.selectedRoute!.path.points.coordinates[coordIdx];
        final coordTo = routing.selectedRoute!.path.points.coordinates[coordIdx + 1];
        final distance = vincenty.distance(LatLng(coordFrom.lat, coordFrom.lon), LatLng(coordTo.lat, coordTo.lon));
        String key = "Unbekannt";
        final osmWayID = osmWayIDs[coordIdx];
        if (routing.selectedRoute!.osmWayNames.containsKey(osmWayID)) {
          key = routing.selectedRoute!.osmWayNames[osmWayID]!;
        } else if (roadClassTranslation.containsKey(segment.value)) {
          key = roadClassTranslation[segment.value]!;
        }
        if (getOffBikeIndices.contains(coordIdx)) {
          key = "$key (Absteigen)";
        }
        if (roadClassDistances.containsKey(key)) {
          roadClassDistances[key] = roadClassDistances[key]! + distance;
        } else {
          roadClassDistances[key] = distance;
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
      elements.add(
        Container(
          width: (availableWidth * pct).floorToDouble(),
          height: 32,
          decoration: BoxDecoration(
            color: roadClassColor[e.key.contains("Absteigen") ? "Absteigen" : e.key],
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.07),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
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
      elements.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: 14,
                decoration: BoxDecoration(
                  color: roadClassColor[e.key.contains("Absteigen") ? "Absteigen" : e.key],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.07)
                        : Colors.black.withOpacity(0.07),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: Content(text: e.key, context: context)),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child:
                      Content(text: "${pct < 1 ? pct.toStringAsFixed(2) : pct.toStringAsFixed(0)}%", context: context),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: elements);
  }

  @override
  Widget build(BuildContext context) {
    if (routing.selectedRoute == null) return Container();

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
            onTap: () => setState(() {
              showRoadClassDetails = !showRoadClassDetails;
            }),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Content(text: "Wegtypen", context: context),
              SizedBox(
                width: 40,
                height: 40,
                child: SmallIconButtonTertiary(
                  icon: showRoadClassDetails ? Icons.keyboard_arrow_up_sharp : Icons.keyboard_arrow_down_sharp,
                  onPressed: () => setState(() {
                    showRoadClassDetails = !showRoadClassDetails;
                  }),
                ),
              ),
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
