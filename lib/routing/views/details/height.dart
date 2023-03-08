import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/services/settings.dart';

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

  /// The processed route data for the alternative routes, which is injected by the provider.
  charts.Series<HeightData, double>? alternativeSeries;

  /// The minimum distance.
  double? minDistance;

  /// The maximum distance.
  double? maxDistance;

  bool? isAlternative;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    processRouteData(false);
    processRouteData(true);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    routing = getIt<Routing>();
    routing.addListener(update);
    settings = getIt<Settings>();
    settings.addListener(update);
    processRouteData(false);
    processRouteData(true);
  }

  @override
  void dispose() {
    routing.removeListener(update);
    settings.removeListener(update);
    super.dispose();
  }

  /// Process the route data and create the chart series.
  void processRouteData(bool useAlternative) {
    if (routing.selectedRoute == null) return;
    if (useAlternative && (routing.allRoutes == null || routing.allRoutes!.length < 2)) return;

    // Aggregate the distance along the route.
    const vincenty = Distance(roundResult: false);
    final latlngCoords = useAlternative
        ? routing.allRoutes!.elementAt(1).path.points.coordinates
        : routing.selectedRoute!.path.points.coordinates;
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
        minDistance = useAlternative ? minDistance : data.first.distance;
        maxDistance = useAlternative ? maxDistance : data.last.distance;
        useAlternative
            ? alternativeSeries = charts.Series<HeightData, double>(
                id: 'AlternativeHeight',
                colorFn: (_, __) => charts.Color.fromHex(code: '#838991'),
                domainFn: (HeightData data, _) => data.distance,
                measureFn: (HeightData data, _) => data.height,
                data: data,
              )
            : series = charts.Series<HeightData, double>(
                id: 'Height',
                colorFn: (_, __) => charts.Color.fromHex(code: '#0073FF'),
                domainFn: (HeightData data, _) => data.distance,
                measureFn: (HeightData data, _) => data.height,
                data: data,
              );
      },
    );
  }

  Widget renderLineChart(bool useAlternative) {
    final chartAxesColor = Theme.of(context).colorScheme.brightness == Brightness.dark
        ? charts.MaterialPalette.white
        : charts.MaterialPalette.black;

    return charts.LineChart(
      useAlternative ? [alternativeSeries!] : [series!],
      animate: true,
      defaultRenderer: charts.LineRendererConfig(
        includeArea: true,
        strokeWidthPx: 3,
        roundEndCaps: true,
        areaOpacity: useAlternative ? 0 : 0.5,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (routing.selectedRoute == null || series == null) return Container();

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
                  child: Stack(
                    children: [
                      renderLineChart(false),
                      if (alternativeSeries != null) renderLineChart(true),
                    ],
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
