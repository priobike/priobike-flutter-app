import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class RouteHeightChart extends StatefulWidget {
  const RouteHeightChart({Key? key}) : super(key: key);

  @override
  RouteHeightChartState createState() => RouteHeightChartState();
}

class HeightData {
  final double height;
  final double distance;

  HeightData(this.height, this.distance);
}

class RouteHeightChartState extends State<RouteHeightChart> {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated routing service, which is injected by the provider.
  late Settings settings;

  /// The processed route data, which is injected by the provider.
  charts.Series<HeightData, double>? series;

  /// The minimum distance.
  double? minDistance;

  /// The maximum distance.
  double? maxDistance;

  @override
  void didChangeDependencies() {
    routing = Provider.of<Routing>(context);
    settings = Provider.of<Settings>(context);
    processRouteData();
    super.didChangeDependencies();
  }

  /// Process the route data and create the chart series.
  Future<void> processRouteData() async {
    if (routing.selectedRoute == null) return;

    // Aggregate the distance along the route.
    const vincenty = Distance(roundResult: false);
    final latlngCoords = routing.selectedRoute!.path.points.coordinates;
    final data = List<HeightData>.empty(growable: true);
    var prevDist = 0.0;
    for (var i = 0; i < latlngCoords.length - 1; i++) {
      var dist = 0.0;
      final p = latlngCoords[i];
      if (i > 0) {
        final pPrev = latlngCoords[i - 1];
        dist = vincenty.distance(LatLng(pPrev.lat, pPrev.lon), LatLng(p.lat, p.lon));
      }
      prevDist += dist;
      data.add(HeightData(p.elevation ?? 0, prevDist / 1000));
    }

    setState(
      () {
        minDistance = data.first.distance;
        maxDistance = data.last.distance;
        series = charts.Series<HeightData, double>(
          id: 'Height',
          colorFn: (_, __) => charts.Color.fromHex(code: '#0073FF'),
          domainFn: (HeightData data, _) => data.distance,
          measureFn: (HeightData data, _) => data.height,
          data: data,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (routing.selectedRoute == null || series == null) return Container();

    final chartAxesColor = Theme.of(context).colorScheme.brightness == Brightness.dark
        ? charts.MaterialPalette.white
        : charts.MaterialPalette.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SmallVSpace(),
          Content(
            text: "Höhenprofil dieser Route",
            context: context,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: 128,
                  child: charts.LineChart(
                    [series!],
                    animate: true,
                    defaultRenderer: charts.LineRendererConfig(
                      includeArea: true,
                      strokeWidthPx: 3,
                      roundEndCaps: true,
                      areaOpacity: 0.5,
                    ),
                    domainAxis: charts.NumericAxisSpec(
                      viewport: charts.NumericExtents(
                        minDistance ?? 0,
                        maxDistance ?? 0,
                      ),
                      tickProviderSpec: const charts.BasicNumericTickProviderSpec(
                        desiredTickCount: 10,
                        desiredMinTickCount: 5,
                        dataIsInWholeNumbers: false,
                      ),
                      tickFormatterSpec: charts.BasicNumericTickFormatterSpec(
                        (num? value) => (value ?? 0) < 0.01 ? "" : "${value?.toStringAsFixed(1)} km",
                      ),
                      renderSpec: charts.GridlineRendererSpec(
                        labelStyle: charts.TextStyleSpec(
                          fontSize: 10,
                          color: chartAxesColor,
                        ),
                        lineStyle: const charts.LineStyleSpec(
                          color: charts.MaterialPalette.transparent,
                        ),
                      ),
                    ),
                    primaryMeasureAxis: charts.NumericAxisSpec(
                      showAxisLine: false,
                      tickProviderSpec: const charts.BasicNumericTickProviderSpec(
                        zeroBound: true,
                        desiredTickCount: 3,
                      ),
                      renderSpec: charts.GridlineRendererSpec(
                        labelStyle: charts.TextStyleSpec(
                          fontSize: 10,
                          color: chartAxesColor,
                        ),
                        lineStyle: const charts.LineStyleSpec(
                          color: charts.MaterialPalette.transparent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              RotatedBox(
                quarterTurns: -1,
                child: Small(text: "Höhe in Meter", context: context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
