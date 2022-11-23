import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/routing/services/routing.dart';
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
  late Routing s;

  /// The processed route data, which is injected by the provider.
  charts.Series<HeightData, double>? series;

  /// The minimum distance.
  double? minDistance;

  /// The maximum distance.
  double? maxDistance;

  @override
  void didChangeDependencies() {
    s = Provider.of<Routing>(context);
    processRouteData();
    super.didChangeDependencies();
  }

  /// Process the route data and create the chart series.
  Future<void> processRouteData() async {
    if (s.selectedRoute == null) return;

    // Aggregate the distance along the route.
    const vincenty = Distance(roundResult: false);
    final latlngCoords = s.selectedRoute!.path.points.coordinates;
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

    setState(() {
      minDistance = data.first.distance;
      maxDistance = data.last.distance;
      series = charts.Series<HeightData, double>(
        id: 'Height',
        colorFn: (_, __) => charts.Color.fromHex(code: '#0073FF'),
        domainFn: (HeightData data, _) => data.distance,
        measureFn: (HeightData data, _) => data.height,
        data: data,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (s.selectedRoute == null || series == null) return Container();

    processRouteData();

    final frame = MediaQuery.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BoldContent(
            text: "Höhenprofil dieser Route",
            context: context,
          ),
          Row(
            children: [
              RotatedBox(
                quarterTurns: -1,
                child: Small(text: "Höhe in Meter", context: context),
              ),
              SizedBox(
                height: 128,
                width: frame.size.width - 50,
                child: charts.LineChart([series!],
                    animate: true,
                    defaultRenderer: charts.LineRendererConfig(
                      includeArea: true,
                      strokeWidthPx: 4,
                    ),
                    domainAxis: charts.NumericAxisSpec(
                      viewport: charts.NumericExtents(
                        minDistance ?? 0,
                        maxDistance ?? 0,
                      ),
                      tickProviderSpec: const charts.BasicNumericTickProviderSpec(
                        desiredTickCount: 5,
                        desiredMinTickCount: 3,
                        dataIsInWholeNumbers: false,
                      ),
                    ),
                    primaryMeasureAxis: const charts.NumericAxisSpec(
                      showAxisLine: false,
                      tickProviderSpec: charts.BasicNumericTickProviderSpec(
                        zeroBound: true,
                      ),
                    )),
              ),
            ],
          ),
          Small(text: "Distanz der Route in Kilometer", context: context),
        ],
      ),
    );
  }
}
