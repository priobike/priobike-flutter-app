import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/services/routing.dart';

/// The translation of the surface.
final surfaceTypeTranslation = {
  "asphalt": "Asphalt",
  "cobblestone": "Kopfsteinpflaster",
  "compacted": "Fester Boden",
  "concrete": "Beton",
  "dirt": "Erde",
  "fine_gravel": "Feiner Kies",
  "grass": "Graß",
  "gravel": "Kies",
  "ground": "Boden",
  "other": "Sonstiges",
  "paving_stones": "Pflastersteine",
  "sand": "Sand",
  "unpaved": "Unbefestigter Boden",
};

/// The color translation of the surface.
final surfaceTypeColor = {
  "Asphalt": const Color(0xFF323232),
  "Kopfsteinpflaster": const Color(0xFF434849),
  "Fester Boden": const Color(0xFFEEB072),
  "Beton": const Color(0xFFBFBFBF),
  "Erde": const Color(0xFF402F22),
  "Feiner Kies": const Color(0xFF7B7B7B),
  "Graß": const Color(0xFF2B442F),
  "Kies": const Color(0xFFB6C5FA),
  "Boden": const Color(0xFFDEE5FD),
  "Sonstiges": const Color(0xFF00056D),
  "Pflastersteine": const Color(0xFF4C4C4C),
  "Sand": const Color(0xFFFFE74E),
  "Unbefestigter Boden": const Color(0xFF473E36),
};

class SurfaceTypeChart extends StatefulWidget {
  const SurfaceTypeChart({Key? key}) : super(key: key);

  @override
  SurfaceTypeChartState createState() => SurfaceTypeChartState();
}

class SurfaceTypeChartState extends State<SurfaceTypeChart> {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The details state of road class.
  bool showSurfaceTypeDetails = false;

  /// The chart data.
  Map<String, double> surfaceTypeDistances = {};

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
    if (routing.selectedRoute == null) return setState(() => surfaceTypeDistances = {});

    const vincenty = Distance(roundResult: false);
    surfaceTypeDistances = {};
    for (GHSegment segment in routing.selectedRoute!.path.details.surface) {
      for (var coordIdx = segment.from; coordIdx < segment.to; coordIdx++) {
        final coordFrom = routing.selectedRoute!.path.points.coordinates[coordIdx];
        final coordTo = routing.selectedRoute!.path.points.coordinates[coordIdx + 1];
        final distance = vincenty.distance(LatLng(coordFrom.lat, coordFrom.lon), LatLng(coordTo.lat, coordTo.lon));
        if (surfaceTypeDistances.containsKey(segment.value)) {
          surfaceTypeDistances[segment.value] = surfaceTypeDistances[segment.value]! + distance;
        } else {
          surfaceTypeDistances[segment.value] = distance;
        }
      }
    }
  }

  /// Render the bar chart.
  Widget renderBar() {
    if (surfaceTypeDistances.isEmpty) return Container();
    if (routing.selectedRoute == null) return Container();
    final availableWidth = (MediaQuery.of(context).size.width - 24);
    var elements = <Widget>[];
    for (int i = 0; i < surfaceTypeDistances.length; i++) {
      final e = surfaceTypeDistances.entries.elementAt(i);
      var pct = (e.value / routing.selectedRoute!.path.distance);
      // Catch case pct > 1.
      pct = pct > 1 ? 1 : pct;
      elements.add(Container(
        width: (availableWidth * pct).floorToDouble(),
        height: 42,
        decoration: BoxDecoration(
          color: surfaceTypeColor[surfaceTypeTranslation[e.key] ?? "???"],
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
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: elements);
  }

  /// Render the details below the bar chart.
  Widget renderDetails() {
    if (surfaceTypeDistances.isEmpty) return Container();
    if (routing.selectedRoute == null) return Container();
    var elements = <Widget>[];
    for (int i = 0; i < surfaceTypeDistances.length; i++) {
      final e = surfaceTypeDistances.entries.elementAt(i);
      var pct = ((e.value / routing.selectedRoute!.path.distance) * 100);
      // Catch case pct > 100.
      pct = pct > 100 ? 100 : pct;
      elements.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              height: 18,
              width: 18,
              decoration: BoxDecoration(
                color: surfaceTypeColor[surfaceTypeTranslation[e.key] ?? "???"],
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
            Content(text: surfaceTypeTranslation[e.key] ?? "Unbekannt", context: context),
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
    return Column(
      children: elements,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (routing.selectedRoute == null) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              showSurfaceTypeDetails = !showSurfaceTypeDetails;
            });
          },
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Content(text: "Oberfläche", context: context),
            Row(children: [
              Content(
                text: "Details",
                context: context,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              showSurfaceTypeDetails
                  ? Icon(Icons.keyboard_arrow_up_sharp, color: Theme.of(context).colorScheme.primary)
                  : Icon(Icons.keyboard_arrow_down_sharp, color: Theme.of(context).colorScheme.primary)
            ]),
          ]),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() {
            showSurfaceTypeDetails = !showSurfaceTypeDetails;
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
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  child: renderDetails(),
                ),
                secondChild: Container(),
                crossFadeState: showSurfaceTypeDetails ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
